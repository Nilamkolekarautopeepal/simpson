import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/all.models.dart' as all_ds;
import 'package:simpson/modals/dtcDataset.model.dart' as dtc_ds;
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/modals/harness.model.dart' as harness_ds;
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/services/apiServices.dart';

enum StepType { single, iqaGroup }

class ScanStep {
  final String key;
  final String label;
  final StepType type;
  ScanStep(this.key, this.label, {this.type = StepType.single});
}

class HomePageController extends GetxController {
  late final String station;

  final List<ScanStep> steps = [
    ScanStep('esn', 'ESN'),
    ScanStep('list', 'List'),
    ScanStep('harness', 'Harness'),
    ScanStep('iqa', 'IQA', type: StepType.iqaGroup),
  ];

  late final List<TextEditingController> stepControllers;
  late final List<FocusNode> stepFocusNodes;
  late final List<Timer?> _idleTimers;
  static const _defaultIqaCount = 4;
  List<String> iqaLabels =
      List.generate(_defaultIqaCount, (i) => 'IQA ${i + 1}');
  List<String>? _iqaFiringOrder;

  late List<TextEditingController> iqaControllers;
  late List<FocusNode> iqaFocusNodes;
  late List<Timer?> _iqaIdleTimers;

  static const _idleDuration = Duration(milliseconds: 400);

  final RxInt currentStepIndex = 0.obs;
  bool get allStepsComplete => currentStepIndex.value >= steps.length;

  final RxString esnError = ''.obs;
  final RxString listError = ''.obs;

  // ── API ──
  final AuthService _authService = AuthService();
  String? _accessToken;
  list_ds.ListNumber? _variantListCache;
  all_ds.AllModel? _modelsCache;

  // ── Flash File ──
  final RxBool flashInProgress = false.obs;
  final RxBool flashComplete = false.obs;
  final RxDouble flashProgress = 0.0.obs;
  final RxInt flashElapsedSeconds = 0.obs;
  final RxBool flashExpanded = true.obs;
  Timer? _flashStopwatch;

  void toggleFlash() => flashExpanded.toggle();

  final RxBool flashFilesLoading = false.obs;
  final RxString flashFilesError = ''.obs;
  final RxList<String> availableFlashFiles = <String>[].obs;
  final Rx<String?> selectedFlashFile = Rx<String?>(null);
  final Map<String, int> _fileToDtcDatasetId = {};
  final Map<String, int> _fileToPidDatasetId = {};

  int? _currentDtcDatasetId;
  int? _currentPidDatasetId;

  String get formattedElapsed {
    final s = flashElapsedSeconds.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── DTC ──
  final RxBool dtcExpanded = true.obs;
  final RxList<String> dtcList = <String>[].obs;
  int get dtcCount => dtcList.length;

  // ── PID ──
  final RxBool pidExpanded = true.obs;
  final RxList<String> pidList = <String>[].obs;

  // ── Activity log (newest first) ──
  final RxList<String> activityLog = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    station =
        (Get.arguments is String) ? Get.arguments as String : 'Unknown Station';

    stepControllers =
        List.generate(steps.length, (_) => TextEditingController());
    stepFocusNodes = List.generate(steps.length, (_) => FocusNode());
    _idleTimers = List.generate(steps.length, (_) => null);

    iqaControllers =
        List.generate(_defaultIqaCount, (_) => TextEditingController());
    iqaFocusNodes = List.generate(_defaultIqaCount, (_) => FocusNode());
    _iqaIdleTimers = List.generate(_defaultIqaCount, (_) => null);

    _log('Session started on "$station"');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stepFocusNodes[0].requestFocus();
    });

    _loadAccessToken();
  }

  Future<void> _loadAccessToken() async {
    _accessToken = await SecureStorageService.getAccessToken();
  }

  String _timestamp() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  void _log(String message) {
    activityLog.insert(0, '[${_timestamp()}] $message');
  }

  void _showErrorPopup(String message, {String title = 'Error'}) {
    if (Get.isDialogOpen == true) {
      Get.back(); // close any existing dialog first so they don't stack
    }
    Get.dialog(
      CustomPopup(
        title: title,
        message: message,
        confirmText: 'OK',
      ),
      barrierDismissible: true,
    );
  }

  Future<bool> _isValidEsn(String value) async {
    final scanned = value.trim();
    final esnList = await _authService.getEsnList(
      engSlno: scanned,
      accessToken: _accessToken,
    );

    final match = (esnList.results ?? []).firstWhereOrNull(
      (r) => (r.engSlno ?? '').trim().toUpperCase() == scanned.toUpperCase(),
    );

    if (match == null) return false;
    if (match.isActive != true) return false;

    _esnVehicleModelName = match.model?.name;
    _esnVehicleSubModelName = match.subModel?.name;
    return true;
  }

  final RxString vehicleDisplayName = ''.obs;
  String? _esnVehicleModelName;
  String? _esnVehicleSubModelName;
  List<all_ds.SubmodelModelecu> vehicleEcuEntries = [];

  Future<void> _resolveVehicleFromEsn() async {
    final modelName = _esnVehicleModelName?.trim();
    final subModelName = _esnVehicleSubModelName?.trim();

    if (modelName == null ||
        modelName.isEmpty ||
        subModelName == null ||
        subModelName.isEmpty) {
      _log('Vehicle context: ESN match missing model/sub_model name');
      vehicleDisplayName.value = '';
      vehicleEcuEntries = [];
      return;
    }

    try {
      final models = await _ensureModels();

      all_ds.Result? matchedModel;
      all_ds.SubModel? matchedSubModel;

      for (final result in models.results ?? <all_ds.Result>[]) {
        if ((result.name ?? '').trim().toUpperCase() !=
            modelName.toUpperCase()) {
          continue;
        }
        matchedModel = result;
        for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
          if ((subModel.name ?? '').trim().toUpperCase() ==
              subModelName.toUpperCase()) {
            matchedSubModel = subModel;
            break;
          }
        }
        break;
      }

      if (matchedModel == null || matchedSubModel == null) {
        _log(
            'Vehicle context: no match for model="$modelName", sub_model="$subModelName" in models/get-models/');
        vehicleDisplayName.value =
            '$modelName — $subModelName (unrecognized combination)';
        vehicleEcuEntries = [];
        return;
      }

      vehicleDisplayName.value =
          '${matchedModel.name} — ${matchedSubModel.name}';
      vehicleEcuEntries =
          matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

      _log('Vehicle resolved from ESN: ${vehicleDisplayName.value} '
          '(${vehicleEcuEntries.length} ECU entr${vehicleEcuEntries.length == 1 ? 'y' : 'ies'})');
    } catch (e) {
      _log('Vehicle context resolution failed: $e');
      vehicleDisplayName.value = '';
      vehicleEcuEntries = [];
    }
  }

  Future<list_ds.ListNumber> _ensureVariantList() async {
    if (_variantListCache != null) return _variantListCache!;
    _accessToken ??= await SecureStorageService.getAccessToken();
    _variantListCache =
        await _authService.getVariantsList(accessToken: _accessToken);
    return _variantListCache!;
  }

  Future<all_ds.AllModel> _ensureModels() async {
    if (_modelsCache != null) return _modelsCache!;
    _accessToken ??= await SecureStorageService.getAccessToken();
    _modelsCache = await _authService.getModels(accessToken: _accessToken);
    return _modelsCache!;
  }

  Future<bool> _isValidListNumber(String value) async {
    final list = await _ensureVariantList(); // let exceptions propagate to
    final scanned = value.trim().toUpperCase();
    return (list.results ?? []).any(
      (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
    );
  }

  Future<void> _resolveInjectorConfig(String scannedListValue) async {
    try {
      final list = await _ensureVariantList();
      final scanned = scannedListValue.trim().toUpperCase();

      final variant = (list.results ?? []).firstWhereOrNull(
        (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
      );
      if (variant == null) {
        _log('Injector config: no matching variant for "$scannedListValue"');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final vehicleModelId = variant.vehicleModel;
      final subModelId = variant.subModel;
      final ecuId = (variant.variantEcu ?? [])
          .map((ve) => ve.ecu)
          .whereType<int>()
          .firstOrNull;

      if (vehicleModelId == null || subModelId == null || ecuId == null) {
        _log('Injector config: variant missing model/submodel/ecu ids');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final models = await _ensureModels();
      all_ds.SubmodelModelecu? matched;

      for (final result in models.results ?? <all_ds.Result>[]) {
        if (result.id != vehicleModelId) continue;
        for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
          if (subModel.id != subModelId) continue;

          final candidates =
              subModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];
          if (candidates.isEmpty) continue;
          matched =
              candidates.firstWhereOrNull((sme) => sme.ecu?.id == ecuId) ??
                  candidates.first;

          if (matched.ecu?.id != ecuId) {
            _log(
                'Injector config: ecu mismatch (variant says $ecuId, models/get-models/ has ${matched.ecu?.id}) — using the submodel\'s entry anyway');
          }
        }
      }

      if (matched == null) {
        _log(
            'Injector config: no submodel_modelecu match in models/get-models/');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final noOfInjectors = matched.noOfInjectors;
      final firingSequenceEnum = matched.firingSequence;

      if (noOfInjectors == null || noOfInjectors <= 0) {
        _log(
            'Injector config: no_of_injectors missing/invalid — using default');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final firingSequenceStr = firingSequenceEnum != null
          ? (all_ds.firingSequenceValues.reverse[firingSequenceEnum] ?? '')
          : '';

      final firingOrder = firingSequenceStr
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      _log(
          'Injector config resolved: $noOfInjectors injector(s), firing sequence [${firingOrder.join(',')}]');
      _configureIqaFields(
        noOfInjectors,
        firingOrder.length == noOfInjectors ? firingOrder : null,
      );
    } catch (e) {
      _log('Injector config resolution failed: $e — using default');
      _configureIqaFields(_defaultIqaCount, null);
    }
  }

  List<harness_ds.Receipe> harnessReceipes = [];

  Future<bool> _isValidHarness(String value) async {
    final scanned = value.trim();
    final harnessList = await _authService.getHarnessList(
      harnessName: scanned,
      accessToken: _accessToken,
    );

    final match = (harnessList.results ?? []).firstWhereOrNull(
      (r) => (r.name ?? '').trim().toUpperCase() == scanned.toUpperCase(),
    );

    if (match == null) return false;
    if (match.isActive != true) return false;

    harnessReceipes = match.receipes ?? [];
    _log(
        'Harness matched: "${match.name}" (${harnessReceipes.length} recipe sensor(s))');
    return true;
  }

  void _configureIqaFields(int count, List<String>? firingOrder) {
    for (final c in iqaControllers) {
      c.dispose();
    }
    for (final f in iqaFocusNodes) {
      f.dispose();
    }
    for (final t in _iqaIdleTimers) {
      t?.cancel();
    }

    iqaControllers = List.generate(count, (_) => TextEditingController());
    iqaFocusNodes = List.generate(count, (_) => FocusNode());
    _iqaIdleTimers = List.generate(count, (_) => null);

    iqaLabels = List.generate(count, (i) => 'IQA ${i + 1}');
    _iqaFiringOrder = firingOrder;
  }

  String _iqaRecordLabel(int i) {
    final order = _iqaFiringOrder;
    if (order != null && i < order.length) {
      return 'IQA (Cyl ${order[i]})';
    }
    return iqaLabels[i];
  }

  void _resetForEsnEdit() {
    _log('ESN changed — resetting flow from the start');

    for (int i = 1; i < stepControllers.length; i++) {
      stepControllers[i].clear();
      _idleTimers[i]?.cancel();
    }
    _configureIqaFields(_defaultIqaCount, null);

    harnessReceipes = [];

    _flashStopwatch?.cancel();
    flashInProgress.value = false;
    flashComplete.value = false;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;

    dtcList.clear();
    pidList.clear();

    availableFlashFiles.clear();
    _fileToDtcDatasetId.clear();
    _fileToPidDatasetId.clear();
    _currentDtcDatasetId = null;
    _currentPidDatasetId = null;
    selectedFlashFile.value = null;
    flashFilesError.value = '';

    esnError.value = '';
    listError.value = '';
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
      try {
        final isValid = await _isValidEsn(value);
        if (!isValid) {
          final message = 'ESN not recognized. Please rescan.';
          esnError.value = message;
          _log('ESN mismatch: scanned "$value"');
          _showErrorPopup(message, title: 'ESN Mismatch');
          return;
        }
        await _resolveVehicleFromEsn();
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        esnError.value = message;
        _log('Failed to validate ESN: $e');
        _showErrorPopup(message, title: 'ESN Validation Failed');
        return;
      }
    }

    if (step.key == 'list') {
      listError.value = '';
      try {
        final isValid = await _isValidListNumber(value);
        if (!isValid) {
          final message = 'List number not recognized. Please rescan.';
          listError.value = message;
          _log('List number mismatch: scanned "$value"');
          _showErrorPopup(message, title: 'List Number Mismatch');
          return;
        }
        await _resolveInjectorConfig(value);
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        listError.value = message;
        _log('Failed to validate list number: $e');
        _showErrorPopup(message, title: 'List Validation Failed');
        return;
      }
    }

    if (step.key == 'harness') {
      try {
        final isValid = await _isValidHarness(value);
        if (!isValid) {
          final message = 'Harness not recognized. Please rescan.';
          _log('Harness mismatch: scanned "$value"');
          _showErrorPopup(message, title: 'Harness Mismatch');
          return;
        }
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        _log('Failed to validate harness: $e');
        _showErrorPopup(message, title: 'Harness Validation Failed');
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

  // ── IQA group (IQA1..IQAn shown together, n = resolved injector count) ──

  void onIqaFieldChanged(int subIndex) {
    _iqaIdleTimers[subIndex]?.cancel();
    _iqaIdleTimers[subIndex] =
        Timer(_idleDuration, () => submitIqaField(subIndex));
  }

  void submitIqaField(int subIndex) {
    if (allStepsComplete) return;

    _iqaIdleTimers[subIndex]?.cancel();
    final value = iqaControllers[subIndex].text.trim();
    if (value.isEmpty) return;

    _log('${_iqaRecordLabel(subIndex)} scanned: $value');

    if (subIndex < iqaLabels.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        iqaFocusNodes[subIndex + 1].requestFocus();
      });
      return;
    }

    final allFilled = iqaControllers.every((c) => c.text.trim().isNotEmpty);
    if (!allFilled) return;

    _log('IQA group complete');
    currentStepIndex.value = currentStepIndex.value + 1;

    if (allStepsComplete) {
      _log('All scan steps complete. Ready to flash.');
      _onAllStepsComplete();
    }
  }

  void _onAllStepsComplete() {
    _loadAvailableFlashFiles();
  }

  Future<void> _loadAvailableFlashFiles() async {
    flashFilesLoading.value = true;
    flashFilesError.value = '';
    try {
      final modelName = _esnVehicleModelName?.trim();
      final subModelName = _esnVehicleSubModelName?.trim();

      if (modelName == null ||
          modelName.isEmpty ||
          subModelName == null ||
          subModelName.isEmpty) {
        _log('Flash files: no ESN-resolved model/sub_model name to filter by');
        availableFlashFiles.assignAll(<String>[]);
        selectedFlashFile.value = null;
        return;
      }

      final all_ds.AllModel models = await _ensureModels();

      all_ds.Result? matchedModel;
      all_ds.SubModel? matchedSubModel;

      for (final result in models.results ?? <all_ds.Result>[]) {
        if ((result.name ?? '').trim().toUpperCase() !=
            modelName.toUpperCase()) {
          continue;
        }
        matchedModel = result;
        for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
          if ((subModel.name ?? '').trim().toUpperCase() ==
              subModelName.toUpperCase()) {
            matchedSubModel = subModel;
            break;
          }
        }
        break;
      }

      if (matchedModel == null || matchedSubModel == null) {
        _log(
            'Flash files: no match for model="$modelName", sub_model="$subModelName" in models/get-models/');
        availableFlashFiles.assignAll(<String>[]);
        selectedFlashFile.value = null;
        return;
      }

      final ecuEntries =
          matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

      final files = <String>[];
      _fileToDtcDatasetId.clear();
      _fileToPidDatasetId.clear();

      for (final sme in ecuEntries) {
        final flashFiles = sme.flashFile?.file ?? <all_ds.FileElement>[];
        if (flashFiles.isEmpty) continue; // flash_file can be null

        final dtcDatasetId =
            (sme.datasets ?? []).isNotEmpty ? sme.datasets!.first.id : null;
        final pidDatasetId = (sme.pidDatasets ?? []).isNotEmpty
            ? sme.pidDatasets!.first.id
            : null;

        for (final f in flashFiles) {
          final name = f.dataFileName ?? f.swPartNo;
          if (name == null) continue;
          if (!files.contains(name)) files.add(name);
          if (dtcDatasetId != null) {
            _fileToDtcDatasetId[name] = dtcDatasetId;
          }
          if (pidDatasetId != null) {
            _fileToPidDatasetId[name] = pidDatasetId;
          }
        }
      }

      availableFlashFiles.assignAll(files);
      selectedFlashFile.value = null;
      _log(
          'Loaded ${files.length} flash file(s) for $modelName — $subModelName');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      flashFilesError.value = message;
      _log('Failed to load flash files: $e');
      _showErrorPopup(message, title: 'Failed to Load Flash Files');
    } finally {
      flashFilesLoading.value = false;
    }
  }

  void selectFlashFile(String? file) {
    selectedFlashFile.value = file;
    _currentDtcDatasetId = file != null ? _fileToDtcDatasetId[file] : null;
    _currentPidDatasetId = file != null ? _fileToPidDatasetId[file] : null;
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

    await _loadDtcResults();
    await _loadPidResults();

    _showFlashCompletePopup();
  }

  Future<void> _loadDtcResults() async {
    final datasetId = _currentDtcDatasetId;
    if (datasetId == null) {
      _log('No DTC dataset id available — skipping');
      return;
    }

    _accessToken ??= await SecureStorageService.getAccessToken();

    try {
      final dtc_ds.DtcDataset dtc = await _authService.getDtcDataset(
        id: datasetId,
        accessToken: _accessToken,
      );

      final dtcStrings = <String>[];
      for (final result in dtc.results ?? <dtc_ds.Result>[]) {
        for (final code in result.dtcCode ?? <dtc_ds.DtcCode>[]) {
          final c = code.code ?? '';
          final desc = code.description ?? '';
          final line = desc.isNotEmpty ? '$c - $desc' : c;
          if (line.trim().isNotEmpty) dtcStrings.add(line);
        }
      }
      dtcList.assignAll(dtcStrings);
      _log('DTC (${dtcList.length}) data loaded');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _log('Failed to load DTC dataset: $e');
      dtcList.clear();
      _showErrorPopup(message, title: 'Failed to Load DTC');
    }
  }

  Future<void> _loadPidResults() async {
    final datasetId = _currentPidDatasetId;
    if (datasetId == null) {
      _log('No PID dataset id available — skipping');
      return;
    }

    _accessToken ??= await SecureStorageService.getAccessToken();

    try {
      final pid_ds.PidDataset pid = await _authService.getPidDataset(
        id: datasetId,
        accessToken: _accessToken,
      );

      final pidStrings = <String>[];
      for (final result in pid.results ?? <pid_ds.Result>[]) {
        for (final code in result.codes ?? <pid_ds.Code>[]) {
          for (final v in code.piCodeVariable ?? <pid_ds.PiCodeVariable>[]) {
            final name = v.longName ??
                v.shortName ??
                code.shortName ??
                code.code ??
                'PID';
            final unit = v.unit ?? '';
            pidStrings.add(unit.isNotEmpty ? '$name — $unit' : name);
          }
        }
      }
      pidList.assignAll(pidStrings);
      _log('PID (${pidList.length}) data loaded');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _log('Failed to load PID dataset: $e');
      pidList.clear();
      _showErrorPopup(message, title: 'Failed to Load PID');
    }
  }

  void _showFlashCompletePopup() {
    final iqaSummary = List.generate(
      iqaLabels.length,
      (i) => '${_iqaRecordLabel(i)}: ${iqaControllers[i].text.trim()}',
    ).join('\n');

    final message = 'File: ${selectedFlashFile.value ?? '-'}\n\n$iqaSummary';

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
