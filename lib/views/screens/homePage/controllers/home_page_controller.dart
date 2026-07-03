import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/popup.dart'; // adjust to wherever CustomPopup actually lives

enum StepType { single, iqaGroup }

class ScanStep {
  final String key;
  final String label;
  final StepType type;
  ScanStep(this.key, this.label, {this.type = StepType.single});
}

class HomePageController extends GetxController {
  /// Station selected on the login screen, passed via
  /// Get.offAllNamed(Routes.CLI_CARD, arguments: station).
  late final String station;

  // Sequential steps. IQA1-4 are grouped into a single "IQA" step —
  // once Harness is confirmed, all 4 IQA fields appear together.
  final List<ScanStep> steps = [
    ScanStep('esn', 'ESN'),
    ScanStep('list', 'List'),
    ScanStep('harness', 'Harness'),
    ScanStep('iqa', 'IQA', type: StepType.iqaGroup),
  ];

  // Controllers/focus nodes for the single-field steps (esn, list, harness).
  // The iqa-group step's index in these arrays is unused/placeholder.
  late final List<TextEditingController> stepControllers;
  late final List<FocusNode> stepFocusNodes;
  late final List<Timer?> _idleTimers;

  // IQA group sub-fields (IQA1..IQA4), all shown together once unlocked.
  final List<String> iqaLabels = const ['IQA1', 'IQA2', 'IQA3', 'IQA4'];
  late final List<TextEditingController> iqaControllers;
  late final List<FocusNode> iqaFocusNodes;
  late final List<Timer?> _iqaIdleTimers;

  static const _idleDuration = Duration(milliseconds: 400);

  /// Index of the step currently enabled for input.
  /// Steps before this index are completed. Steps after this index are
  /// not shown at all yet (sidebar only renders 0..currentStepIndex).
  final RxInt currentStepIndex = 0.obs;

  bool get allStepsComplete => currentStepIndex.value >= steps.length;

  /// Shown under the ESN field if the scanned value doesn't match the ECU.
  final RxString esnError = ''.obs;

  // ── Flash File ──
  final RxBool flashInProgress = false.obs;
  final RxBool flashComplete = false.obs;
  final RxDouble flashProgress = 0.0.obs;
  final RxInt flashElapsedSeconds = 0.obs;
  final RxBool flashExpanded = true.obs;
  Timer? _flashStopwatch;

  void toggleFlash() => flashExpanded.toggle();

  /// Files available to flash against the connected ECU.
  /// TODO: replace with the real file list fetched from the ECU/API once
  /// all scan steps are complete — currently dummy data for UI testing.
  final RxList<String> availableFlashFiles = <String>[].obs;
  final Rx<String?> selectedFlashFile = Rx<String?>(null);

  String get formattedElapsed {
    final s = flashElapsedSeconds.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── DTC ──
  final RxBool dtcExpanded = false.obs;
  final RxList<String> dtcList = <String>[].obs;
  int get dtcCount => dtcList.length;

  // ── PID ──
  final RxBool pidExpanded = false.obs;
  final RxList<String> pidList = <String>[].obs;

  // ── Activity log (newest first) ──
  final RxList<String> activityLog = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    station = (Get.arguments is String)
        ? Get.arguments as String
        : 'Unknown Station';

    stepControllers = List.generate(steps.length, (_) => TextEditingController());
    stepFocusNodes = List.generate(steps.length, (_) => FocusNode());
    _idleTimers = List.generate(steps.length, (_) => null);

    iqaControllers = List.generate(iqaLabels.length, (_) => TextEditingController());
    iqaFocusNodes = List.generate(iqaLabels.length, (_) => FocusNode());
    _iqaIdleTimers = List.generate(iqaLabels.length, (_) => null);

    _log('Session started on "$station"');

    // Auto-focus the ESN field once the screen has finished building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      stepFocusNodes[0].requestFocus();
    });
  }

  String _timestamp() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  void _log(String message) {
    activityLog.insert(0, '[${_timestamp()}] $message');
  }

  /// TODO: replace with the real ECU communication/API call that reads
  /// back the connected device's actual ESN. Stubbed for now so the flow
  /// is testable without hardware — always "matches" whatever is typed.
  Future<String> _fetchEcuEsn(String scannedValue) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return scannedValue; // TODO: return the real ECU ESN here instead
  }

  /// If the ESN field is edited after already being confirmed (i.e. the
  /// user goes back and retypes it), everything that depended on the old
  /// ESN is no longer valid — reset List, Harness, IQA, Flash, DTC, and
  /// PID, and restart the flow from ESN.
  void _resetForEsnEdit() {
    _log('ESN changed — resetting flow from the start');

    // Clear List/Harness values and their pending idle timers.
    for (int i = 1; i < stepControllers.length; i++) {
      stepControllers[i].clear();
      _idleTimers[i]?.cancel();
    }

    // Clear IQA group.
    for (final c in iqaControllers) {
      c.clear();
    }
    for (final t in _iqaIdleTimers) {
      t?.cancel();
    }

    // Reset Flash state.
    _flashStopwatch?.cancel();
    flashInProgress.value = false;
    flashComplete.value = false;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;

    // Clear DTC/PID results.
    dtcList.clear();
    pidList.clear();
    dtcExpanded.value = false;
    pidExpanded.value = false;

    // Clear flash file selection.
    availableFlashFiles.clear();
    selectedFlashFile.value = null;

    esnError.value = '';
    currentStepIndex.value = 0;
  }

  // ── Single-field steps (ESN, List, Harness) ──

  void onFieldChanged(int index) {
    if (index == 0 && currentStepIndex.value != 0) {
      _resetForEsnEdit();
    }
    if (index != currentStepIndex.value) return;
    _idleTimers[index]?.cancel();
    _idleTimers[index] = Timer(_idleDuration, () => submitStep(index));
  }

  Future<void> submitStep(int index) async {
    if (index == 0 && currentStepIndex.value != 0) {
      _resetForEsnEdit();
    }
    if (index != currentStepIndex.value) return;
    _idleTimers[index]?.cancel();

    final value = stepControllers[index].text.trim();
    if (value.isEmpty) return;

    final step = steps[index];

    if (step.key == 'esn') {
      esnError.value = '';
      final ecuEsn = await _fetchEcuEsn(value);
      if (value.toUpperCase() != ecuEsn.toUpperCase()) {
        esnError.value = 'ESN does not match the connected ECU. Please rescan.';
        _log('ESN mismatch: scanned "$value"');
        return;
      }
    }

    _log('${step.label} scanned: $value');
    currentStepIndex.value = index + 1;

    if (allStepsComplete) {
      _log('All scan steps complete. Ready to flash.');
      _onAllStepsComplete();
      return;
    }

    final nextStep = steps[currentStepIndex.value];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (nextStep.type == StepType.single) {
        stepFocusNodes[currentStepIndex.value].requestFocus();
      } else {
        iqaFocusNodes[0].requestFocus();
      }
    });
  }

  // ── IQA group (IQA1..IQA4 shown together) ──

  void onIqaFieldChanged(int subIndex) {
    _iqaIdleTimers[subIndex]?.cancel();
    _iqaIdleTimers[subIndex] = Timer(_idleDuration, () => submitIqaField(subIndex));
  }

  void submitIqaField(int subIndex) {
    _iqaIdleTimers[subIndex]?.cancel();
    final value = iqaControllers[subIndex].text.trim();
    if (value.isEmpty) return;

    _log('${iqaLabels[subIndex]} scanned: $value');

    if (subIndex < iqaLabels.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        iqaFocusNodes[subIndex + 1].requestFocus();
      });
      return;
    }

    // Last IQA field submitted — confirm the whole group is filled.
    final allFilled = iqaControllers.every((c) => c.text.trim().isNotEmpty);
    if (!allFilled) return;

    _log('IQA group complete');
    currentStepIndex.value = currentStepIndex.value + 1; // advances past the iqa step

    if (allStepsComplete) {
      _log('All scan steps complete. Ready to flash.');
      _onAllStepsComplete();
    }
  }

  void _onAllStepsComplete() {
    _loadAvailableFlashFiles();
  }

  /// TODO: replace with a real call to fetch the files available for this
  /// ECU/vehicle model. Dummy list for now so the dropdown is testable.
  void _loadAvailableFlashFiles() {
    availableFlashFiles.assignAll([
      'ECU_Firmware_v1.2.3.bin',
      'ECU_Firmware_v1.3.0.bin',
      'ECU_Calibration_2024_Q3.bin',
    ]);
    selectedFlashFile.value = null;
  }

  void selectFlashFile(String? file) {
    selectedFlashFile.value = file;
  }

  Future<void> startFlashing() async {
    if (!allStepsComplete ||
        flashInProgress.value ||
        flashComplete.value ||
        selectedFlashFile.value == null) {
      return;
    }

    _log('Selected flash file: ${selectedFlashFile.value}');

    flashInProgress.value = true;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;
    _log('Flashing started');

    _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
      flashElapsedSeconds.value++;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      flashProgress.value = i / 10;
    }

    _flashStopwatch?.cancel();
    flashInProgress.value = false;
    flashComplete.value = true;
    _log('Flashing completed successfully (${formattedElapsed})');

    // TODO: replace with real DTC/PID results pulled from the device/API.
    dtcList.assignAll([
      'P0001 - Fuel Volume Regulator Control Circuit/Open',
      'P0217 - Engine Overtemperature Condition',
      'P0335 - Crankshaft Position Sensor A Circuit',
      'P0463 - Fuel Level Sensor Circuit High Input',
    ]);
    pidList.assignAll([
      'Engine RPM — 812 rpm',
      'Coolant Temperature — 84°C',
      'Vehicle Speed — 0 km/h',
      'Battery Voltage — 13.6 V',
      'Fuel Level — 62%',
      'Intake Air Temperature — 31°C',
    ]);
    _log('DTC (${dtcList.length}) and PID (${pidList.length}) data loaded');

    _showFlashCompletePopup();
  }

  /// Shows a summary popup once flashing finishes: which file was flashed
  /// and all 4 scanned IQA values, for the operator to visually confirm.
  void _showFlashCompletePopup() {
    final iqaSummary = List.generate(
      iqaLabels.length,
      (i) => '${iqaLabels[i]}: ${iqaControllers[i].text.trim()}',
    ).join('\n');

    final message =
        'File: ${selectedFlashFile.value ?? '-'}\n\n$iqaSummary';

    Get.dialog(
      CustomPopup(
        title: 'Flashing Complete',
        message: message,
        confirmText: 'OK',
      ),
      barrierDismissible: true,
    );
  }

  void toggleDtc() => dtcExpanded.toggle();
  void togglePid() => pidExpanded.toggle();

  void logout() {
    _log('Logged out');
    // TODO: adjust to your actual login route name/constant
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    for (final c in stepControllers) {
      c.dispose();
    }
    for (final f in stepFocusNodes) {
      f.dispose();
    }
    for (final t in _idleTimers) {
      t?.cancel();
    }
    for (final c in iqaControllers) {
      c.dispose();
    }
    for (final f in iqaFocusNodes) {
      f.dispose();
    }
    for (final t in _iqaIdleTimers) {
      t?.cancel();
    }
    _flashStopwatch?.cancel();
    super.onClose();
  }
}