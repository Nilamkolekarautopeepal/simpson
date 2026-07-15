import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
//import 'package:ap_diagnostic/models/writeParameterPIDModel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/app.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/all.models.dart' as all_ds;
import 'package:simpson/modals/liveParameter_model.dart';
import 'package:simpson/modals/pidDataset.model.dart';
import 'package:simpson/modals/staticData.dart';
import 'package:simpson/modals/dtcDataset.model.dart' as dtc_ds;
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/modals/harness.model.dart' as harness_ds;
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/services/apiServices.dart';
import 'package:simpson/services/plc/plc_service.dart';
import 'package:simpson/services/connectionWifiService.dart';
import 'package:simpson/services/getJson_service.dart';
import 'package:simpson/views/screens/ecu_flashing_page/views/ecu_flashing_page_view.dart';


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
  final RxBool isDongleBusy = false.obs;

  /// Wraps any block of code that talks to the dongle, pausing the
  /// heartbeat for its duration. Safe to nest.
  Future<T> _withDongleBusy<T>(Future<T> Function() action) async {
    final wasAlreadyBusy = isDongleBusy.value;
    isDongleBusy.value = true;
    try {
      return await action();
    } finally {
      if (!wasAlreadyBusy) isDongleBusy.value = false;
    }
  }

  // ── API ──
  final AuthService _authService = AuthService();
  String? _accessToken;
  list_ds.ListNumber? _variantListCache;
  all_ds.AllModel? _modelsCache;

  // ── PLC connection (auto-connects, no manual IP/port entry) ──
  // PLC IP/port come ONLY from the login response (station_data[0].plc_ip /
  // .plc_port) — no hardcoded IP anywhere. Port falls back to 502 (the
  // standard Modbus TCP port) only if login data is somehow missing it.
  String? _plcIp;
  int _plcPort = 502;

  Future<void> _loadPlcConfig() async {
    _plcIp = await SecureStorageService.getPlcIp();
    final portStr = await SecureStorageService.getPlcPort();
    _plcPort = int.tryParse(portStr ?? '') ?? 502;
    if (_plcIp == null || _plcIp!.isEmpty) {
      _log('PLC: no IP found from login data');
    }
  }

  final PlcService plcService = Get.find<PlcService>();
  RxBool get isPlcConnected => plcService.isConnected;
  RxBool get isPlcConnecting => plcService.isConnecting;
  RxString get plcStatus => plcService.status;

  Timer? _plcRetryTimer;
  Timer? _plcHeartbeatTimer;

  Future<void> _autoConnectPlc() async {
    if (plcService.isConnected.value || plcService.isConnecting.value) return;
    if (_plcIp == null || _plcIp!.isEmpty) {
      _log('PLC: no IP on record from login — cannot connect');
      return;
    }
    _log('Connecting to PLC at $_plcIp:$_plcPort…');
    try {
      await plcService.connect(_plcIp!, port: _plcPort);
      _log('PLC connected ($_plcIp:$_plcPort)');
      _plcRetryTimer?.cancel();
    } catch (e) {
      _log('PLC connection failed: $e — will keep retrying in the background');
      _startPlcRetryTimer();
    }
  }

  /// Keeps trying every 10s in the background, so if the PLC comes
  /// online later (or the IP gets corrected) it connects automatically
  /// without needing an app restart or manual retry.
  void _startPlcRetryTimer() {
    _plcRetryTimer?.cancel();
    _plcRetryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (plcService.isConnected.value) {
        _plcRetryTimer?.cancel();
        return;
      }
      _autoConnectPlc();
    });
  }

  /// Tap the status indicator to retry immediately instead of waiting
  /// for the next background retry tick.
  void retryPlcConnection() {
    if (isPlcConnected.value) return;
    _autoConnectPlc();
  }

  /// Runs continuously in the background. A silently-dropped WiFi/TCP
  /// connection often doesn't fire any socket error or close event —
  /// the OS just goes quiet, so isConnected can stay stuck at true
  /// forever unless something actually tries to talk to the PLC and
  /// notices it doesn't answer. This is that check: a real register
  /// read, on a short timeout, done periodically. Skips itself while
  /// a real sensor read is already in progress (isReadingPlcValues) so
  /// it never collides with actual work.
  void _startPlcHeartbeat() {
    _plcHeartbeatTimer?.cancel();
    _plcHeartbeatTimer = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!plcService.isConnected.value) return;
      if (isReadingPlcValues.value) return;

      final pingReg = harnessReceipes.isNotEmpty
          ? (harnessReceipes.first.regAddress ?? 4)
          : 4;

      // One retry before declaring the connection actually dead — this
      // test rig is single-threaded and can occasionally be a moment
      // late to respond even when it's perfectly fine; a single missed
      // beat shouldn't force a full reconnect.
      try {
        await plcService.readRegister(pingReg).timeout(const Duration(seconds: 3));
        return; // first attempt succeeded, all good
      } catch (_) {
        // fall through to retry below
      }

      try {
        await Future.delayed(const Duration(milliseconds: 300));
        await plcService.readRegister(pingReg).timeout(const Duration(seconds: 3));
        // second attempt succeeded — connection is fine, no action needed
      } catch (e) {
        _log('❌ PLC heartbeat failed (twice) — connection lost: $e');
        plcService.isConnected.value = false;
        _startPlcRetryTimer();
      }
    });
  }

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
  final RxList<String> activityLog = <String>[].obs;

  // ── Dongle connection ──
  final RxBool canConnectDongle = false.obs; // true once ESN/vehicle resolved
  final RxBool dongleConnecting = false.obs;
  final RxBool dongleConnected = false.obs;
  final RxString dongleIp = ''.obs;
  final ConnectionWifi _connectionWifi = ConnectionWifi();

  String? _dongleIp;
  Timer? _dongleRetryTimer;
  Timer? _dongleHeartbeatTimer;

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
    _loadDongleIp();
    _loadPlcConfig().then((_) => _autoConnectPlc());
    _startDongleHeartbeat();
    _startPlcHeartbeat();
  }

  Future<void> _loadAccessToken() async {
    _accessToken = await SecureStorageService.getAccessToken();
  }

  /// Loads the dongle IP that was saved at login time (from
  /// station_data[0].prodbud_dongles[*].ip in the login response).
  Future<void> _loadDongleIp() async {
    _dongleIp = await SecureStorageService.getDongleIp();
    dongleIp.value = _dongleIp ?? '';
    if (_dongleIp == null || _dongleIp!.isEmpty) {
      _log('Dongle: no IP found from login data');
    }
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
      Get.back();
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
      canConnectDongle.value = false;
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
        canConnectDongle.value = false;
        return;
      }

      vehicleDisplayName.value =
          '${matchedModel.name} — ${matchedSubModel.name}';
      vehicleEcuEntries =
          matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

      _log('Vehicle resolved from ESN: ${vehicleDisplayName.value} '
          '(${vehicleEcuEntries.length} ECU entr${vehicleEcuEntries.length == 1 ? 'y' : 'ies'})');

      canConnectDongle.value = vehicleEcuEntries.isNotEmpty;

      if (canConnectDongle.value) {
        _autoConnectDongle();
      }
    } catch (e) {
      _log('Vehicle context resolution failed: $e');
      vehicleDisplayName.value = '';
      vehicleEcuEntries = [];
      canConnectDongle.value = false;
    }
  }

  Future<list_ds.ListNumber> _ensureVariantList(
      {bool forceRefresh = false}) async {
    if (!forceRefresh && _variantListCache != null) return _variantListCache!;
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
    final scanned = value.trim().toUpperCase();

    bool checkAgainst(list_ds.ListNumber list) {
      return (list.results ?? []).any(
        (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
      );
    }

    final cached = await _ensureVariantList();
    if (checkAgainst(cached)) return true;

    _log(
        'List validation: no match in cached list — refetching to rule out stale cache');
    final fresh = await _ensureVariantList(forceRefresh: true);
    return checkAgainst(fresh);
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
      final firingSequenceStr = matched.firingSequence ?? '';

      if (noOfInjectors == null || noOfInjectors <= 0) {
        _log(
            'Injector config: no_of_injectors missing/invalid — using default');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

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

  /// Runs automatically once flashing succeeds (see startFlashing()) —
  /// no button, no user interaction. Writes whatever IQA values were
  /// typed into the sidebar fields to the ECU and returns a short
  /// status line that gets folded into the "Flashing Complete" popup.
  /// Never throws — any failure is captured in the returned message.
  // Future<String> _autoWriteIqaValues() {
  //   return _withDongleBusy(() async {
  //     try {
  //       final iqaPid = await _findIqaPidCode();

  //       if (iqaPid == null) {
  //         _log('IQA auto-write: IQA PID not found — skipping');
  //         return 'IQA write skipped: IQA PID not found';
  //       }

  //       for (int i = 0; i < iqaControllers.length; i++) {
  //         final value = iqaControllers[i].text.trim();
  //         if (value.length != 7) {
  //           _log(
  //               'IQA auto-write: ${_iqaRecordLabel(i)} is not 7 characters — skipping write');
  //           return 'IQA write skipped: enter a valid 7-character value for each cylinder';
  //         }
  //       }

  //       List<PiCodeVariables> variables =
  //           List<PiCodeVariables>.from(iqaPid.piCodeVariable ?? []);

  //       variables.sort(
  //         (a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0),
  //       );

  //       if (_iqaFiringOrder != null &&
  //           _iqaFiringOrder!.length == variables.length) {
  //         variables =
  //             _iqaFiringOrder!.map((e) => variables[int.parse(e) - 1]).toList();
  //       }

  //       final writeInput = Uint8List(iqaPid.totalLen ?? 0);
  //       final List<VariantDataLists> variantList = [];

  //       for (int i = 0; i < variables.length; i++) {
  //         final variable = variables[i];

  //         final value = iqaControllers[i].text.trim().toUpperCase();

  //         final bytes = latin1.encode(value);

  //         final start = variable.bytePosition! - 1;

  //         writeInput.setRange(
  //           start,
  //           start + bytes.length,
  //           bytes,
  //         );

  //         variantList.add(
  //           VariantDataLists(
  //             pidId: variable.id,
  //             pidName: variable.shortName,
  //             startByte: variable.bytePosition,
  //             noOfBytes: variable.length,
  //             datatype: variable.messageType.toString(),
  //             resolution: variable.resolution,
  //             offset: variable.offset,
  //             unit: variable.unit,
  //             isBitcoded: variable.bitcoded,
  //             startBit: variable.startBitPosition ?? 0,
  //             noofBits: 0,
  //           ),
  //         );
  //       }

  //       final int startByte = variantList
  //           .map((e) => e.startByte!)
  //           .reduce((a, b) => a < b ? a : b);

  //       final ecu = StaticData.ecuInfo.firstWhereOrNull(
  //         (e) => e.writePidIndex != null,
  //       );

  //       if (ecu == null) {
  //         _log('IQA auto-write: ECU configuration not found — skipping');
  //         return 'IQA write skipped: ECU configuration not found';
  //       }

  //       final pid = WriteParameterPid(
  //         writePamIndex: ecu.writePidIndex,
  //         seedKeyIndex: ecu.seedKeyIndex,
  //         writePid: iqaPid.writePid,
  //         writeParaDataSize: iqaPid.totalLen,
  //         writeInput: writeInput,
  //         pid: iqaPid.code,
  //         totalLen: iqaPid.totalLen,
  //         totalBytes: iqaPid.totalLen,
  //         startByte: startByte,
  //         variantList: variantList,
  //       );

  //       print("--------------- WRITE DATA ----------------");
  //       print("PID : ${pid.pid}");
  //       print("Start Byte : ${pid.startByte}");
  //       print("Total Bytes : ${pid.totalBytes}");
  //       print("Write Input : ${writeInput.toList()}");
  //       for (final v in variantList) {
  //         print(
  //           "PID=${v.pidName}, "
  //           "Start=${v.startByte}, "
  //           "Len=${v.noOfBytes}, "
  //           "Type=${v.datatype}",
  //         );
  //       }
  //       print("-------------------------------------------");

  //       _log('Writing IQA values to ECU...');
  //       final response = await App.dllFunctions!.writePid(
  //         ecu.writePidIndex!,
  //         [pid],
  //       );

  //       if (response != null &&
  //           response.isNotEmpty &&
  //           response.first.status?.toUpperCase() == "NOERROR") {
  //         await _readIqaCurrentValues(iqaPid);
  //         _log('✅ IQA write successful');
  //         return 'IQA write: Successful';
  //       } else {
  //         final failMsg = (response == null || response.isEmpty)
  //             ? "No response from ECU"
  //             : (response.first.status ?? "Write Failed");
  //         _log('❌ IQA write failed: $failMsg');
  //         return 'IQA write failed: $failMsg';
  //       }
  //     } catch (e) {
  //       _log('❌ IQA auto-write exception: $e');
  //       return 'IQA write failed: $e';
  //     }
  //   });
  // }

  Future<String> _autoWriteIqaValues() async {
    try {
      final iqaPid = await _findIqaPidCode();

      if (iqaPid == null) {
        _log('IQA auto-write: IQA PID not found — skipping');
        return 'IQA write skipped: IQA PID not found';
      }

      // Validate
      for (int i = 0; i < iqaControllers.length; i++) {
        final value = iqaControllers[i].text.trim();
        if (value.length != 7) {
          _log(
              'IQA auto-write: ${_iqaRecordLabel(i)} is not 7 characters — skipping write');
          return 'IQA write skipped: enter a valid 7-character value for each cylinder';
        }
      }

      // Copy variables
      List<PiCodeVariables> variables =
          List<PiCodeVariables>.from(iqaPid.piCodeVariable ?? []);

      // Sort by priority
      variables.sort(
        (a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0),
      );

      // Reorder according to firing sequence
      if (_iqaFiringOrder != null &&
          _iqaFiringOrder!.length == variables.length) {
        variables =
            _iqaFiringOrder!.map((e) => variables[int.parse(e) - 1]).toList();
      }

      final writeInput = Uint8List(iqaPid.totalLen ?? 0);
      final List<VariantDataLists> variantList = [];

      for (int i = 0; i < variables.length; i++) {
        final variable = variables[i];

        final value = iqaControllers[i].text.trim().toUpperCase();

        final bytes = latin1.encode(value);

        final start = variable.bytePosition! - 1;

        writeInput.setRange(
          start,
          start + bytes.length,
          bytes,
        );

        variantList.add(
          VariantDataLists(
            pidId: variable.id,
            pidName: variable.shortName,
            startByte: variable.bytePosition,
            noOfBytes: variable.length,
            datatype: variable.messageType.toString(),
            resolution: variable.resolution,
            offset: variable.offset,
            unit: variable.unit,
            isBitcoded: variable.bitcoded,
            startBit: variable.startBitPosition ?? 0,
            noofBits: 0,
          ),
        );
      }

      final int startByte =
          variantList.map((e) => e.startByte!).reduce((a, b) => a < b ? a : b);

      final ecu = StaticData.ecuInfo.firstWhereOrNull(
        (e) => e.writePidIndex != null,
      );

      if (ecu == null) {
        _log('IQA auto-write: ECU configuration not found — skipping');
        return 'IQA write skipped: ECU configuration not found';
      }

      final pid = WriteParameterPid(
        writePamIndex: ecu.writePidIndex,
        seedKeyIndex: ecu.seedKeyIndex,
        writePid: iqaPid.writePid,
        writeParaDataSize: iqaPid.totalLen,
        writeInput: writeInput,
        pid: iqaPid.code,
        totalLen: iqaPid.totalLen,
        totalBytes: iqaPid.totalLen,
        startByte: startByte,
        variantList: variantList,
      );

      print("--------------- WRITE DATA ----------------");
      print("PID : ${pid.pid}");
      print("Start Byte : ${pid.startByte}");
      print("Total Bytes : ${pid.totalBytes}");
      print("Write Input : ${writeInput.toList()}");
      for (final v in variantList) {
        print(
          "PID=${v.pidName}, "
          "Start=${v.startByte}, "
          "Len=${v.noOfBytes}, "
          "Type=${v.datatype}",
        );
      }
      print("-------------------------------------------");

      const maxRetries = 4;
      const initialDelay = Duration(seconds: 2);
      var delay = initialDelay;

      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        _log('Writing IQA values to ECU... (attempt $attempt/$maxRetries)');

        final response = await App.dllFunctions!.writePid(
          ecu.writePidIndex!,
          [pid],
        );

        final status = response?.first.status?.toUpperCase();

        if (response != null && response.isNotEmpty && status == "NOERROR") {
          await _readIqaCurrentValues(iqaPid);
          _log('✅ IQA write successful');
          return 'IQA write: Successful';
        }

        if (status != null && status.contains('REQUIREDTIMEDELAYNOTEXPIRED')) {
          _log('⏳ ECU not ready yet (requiredTimeDelayNotExpired) — '
              'waiting ${delay.inSeconds}s before retry ${attempt + 1}/$maxRetries');
          await Future.delayed(delay);
          delay *= 2; // back off: 2s, 4s, 8s, 16s
          continue;
        }

        // Any other failure — don't keep retrying blindly.
        final failMsg = (response == null || response.isEmpty)
            ? "No response from ECU"
            : (response.first.status ?? "Write Failed");
        _log('❌ IQA write failed: $failMsg');
        return 'IQA write failed: $failMsg';
      }

      _log('❌ IQA write failed: ECU still busy after $maxRetries attempts');
      return 'IQA write failed: requiredTimeDelayNotExpired (gave up after retries)';
    } catch (e) {
      _log('❌ IQA auto-write exception: $e');
      return 'IQA write failed: $e';
    }
  }

  Future<pid_ds.Code?> _findIqaPidCode() async {
    var datasetId = _currentPidDatasetId;

    if (datasetId == null && selectedFlashFile.value != null) {
      datasetId = _fileToPidDatasetId[selectedFlashFile.value];
      print('IQA write: _currentPidDatasetId was null, falling back to '
          'file-based dataset id: $datasetId');
    }

    if (datasetId == null) {
      print('IQA write: no PID dataset id available at all — '
          'select a flash file first');
      return null;
    }

    _accessToken ??= await SecureStorageService.getAccessToken();
    final pid = await _authService.getPidDataset(
      id: datasetId,
      accessToken: _accessToken,
    );

    print('IQA write: PID dataset $datasetId loaded, '
        '${pid.results?.length ?? 0} result group(s)');

    for (final result in pid.results ?? <pid_ds.Result>[]) {
      for (final code in result.codes ?? <pid_ds.Code>[]) {
        final firstVar = code.piCodeVariable?.firstOrNull;
        print(
            '  checking code=${code.code} messageType=${firstVar?.messageType}');
        if (firstVar?.messageType == pid_ds.MessageType.IQA) {
          return code;
        }
      }
    }

    _log(
        'IQA write: no code with messageType == IQA found in dataset $datasetId');
    return null;
  }

  Future<List<String>?> _readIqaCurrentValues(pid_ds.Code iqaPid) async {
    try {
      final datasetId = _currentPidDatasetId;
      if (datasetId == null) {
        print('_readIqaCurrentValues: no datasetId, skipping read');
        return null;
      }

      _accessToken ??= await SecureStorageService.getAccessToken();
      final dataset = await _authService.getPidDataset(
        id: datasetId,
        accessToken: _accessToken,
      );

      App.dllFunctions!.readPID(dataset);
      print('_readIqaCurrentValues: converted dataset via readPID, '
          'but no actual device-read call exists yet — returning null');
    } catch (e) {
      print('Read current IQA values failed: $e');
      return null;
    }
    return null;
  }

  final RxList<harness_ds.Receipe> harnessReceipes = <harness_ds.Receipe>[].obs;

  // ── Live PLC value per sensor. The ONLY way this ever gets populated
  // is writeSensorValue() below (write, then read back for real
  // confirmation) — there is NO automatic read when a harness is
  // scanned. Until a sensor's value is explicitly written, the Recipe
  // dialog just shows the static reference value straight from the
  // harness API.
  final RxMap<int, String> livePlcValues = <int, String>{}.obs;
  final RxBool isReadingPlcValues = false.obs;

  // ── Write ──
  final RxBool isWritingSensor = false.obs;
  final RxSet<int> writeInFlightSensorIds = <int>{}.obs;

  /// Writes [value] to [sensor]'s register on the PLC, then reads the
  /// register back for real confirmation (not just an echo of what was
  /// requested) and stores that in livePlcValues. This is the ONLY
  /// place a live PLC value ever gets set — the harness scan itself
  /// only shows the static API reference values.
  Future<void> writeSensorValue(harness_ds.Receipe sensor, int value) async {
    final id = sensor.id;
    final reg = sensor.regAddress;
    if (id == null || reg == null) return;

    if (!plcService.isConnected.value) {
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Write FAILED: PLC not connected');
      return;
    }

    writeInFlightSensorIds.add(id);
    try {
      final bool confirmed = await plcService.writeRegister(reg, value);

      print(
          '[PLC WRITE] ${sensor.sensorName} | Reg $reg | Value=$value | Confirmed=$confirmed');

      if (!confirmed) {
        _log(
            '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Write NOT CONFIRMED (PLC did not echo the value back)');
        return;
      }
      final int rawReadBack = await plcService.readRegister(reg);
      final double engineeringValue = _applySensorFormula(sensor.type, rawReadBack);
      final String formatted = engineeringValue.toStringAsFixed(2);

      livePlcValues[id] = formatted;

      print(
          '[PLC READ-BACK] ${sensor.sensorName} | Reg $reg | Raw=$rawReadBack | Value=$formatted');

      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Type: ${sensor.type ?? '-'}  |  Written & Confirmed: $formatted ${sensor.unit ?? ''}'
              .trim());
    } catch (e) {
      print('[PLC WRITE] ${sensor.sensorName} | Reg $reg | FAILED: $e');
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Write FAILED: $e');
    } finally {
      writeInFlightSensorIds.remove(id);
    }
  }

  /// Reads [sensor]'s current value straight from the PLC and shows it
  /// in the Recipe table's VALUE cell. No writing involved — this is
  /// purely "what does the PLC have right now for this sensor."
  Future<void> readSensorValue(harness_ds.Receipe sensor) async {
    final id = sensor.id;
    final reg = sensor.regAddress;
    if (id == null || reg == null) return;

    if (!plcService.isConnected.value) {
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Read FAILED: PLC not connected');
      return;
    }

    writeInFlightSensorIds.add(id); // reused as a generic "busy" marker for this row
    try {
      int raw;
      try {
        raw = await plcService.readRegister(reg);
      } catch (firstError) {
        // One quick retry — this test rig runs over WiFi, and a single
        // dropped packet shouldn't be treated the same as a genuinely
        // dead connection. If this second attempt also fails, give up
        // for real and let the heartbeat/reconnect logic handle it.
        print('[PLC READ] ${sensor.sensorName} | Reg $reg | first attempt failed ($firstError), retrying once...');
        await Future.delayed(const Duration(milliseconds: 200));
        raw = await plcService.readRegister(reg);
      }

      final double engineeringValue = _applySensorFormula(sensor.type, raw);
      final String formatted = engineeringValue.toStringAsFixed(2);

      livePlcValues[id] = formatted;

      print('[PLC READ] ${sensor.sensorName} | Reg $reg | Raw=$raw | Value=$formatted');

      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Type: ${sensor.type ?? '-'}  |  Value: $formatted ${sensor.unit ?? ''}'
              .trim());
    } catch (e) {
      livePlcValues[id] = 'ERR';
      print('[PLC READ] ${sensor.sensorName} | Reg $reg | FAILED after retry: $e');
      _log('  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Read FAILED: $e');
    } finally {
      writeInFlightSensorIds.remove(id);
    }
  }

  /// Reads every sensor's value from the PLC, one at a time, and shows
  /// all of them in the Recipe table's VALUE cells. Same as tapping
  /// "GET VALUE" on every row, just in one click.
  Future<void> readAllSensorValues() async {
    if (harnessReceipes.isEmpty) return;

    if (!plcService.isConnected.value) {
      _log('PLC not connected — cannot read values');
      return;
    }

    isReadingPlcValues.value = true;
    _log('Reading ${harnessReceipes.length} sensor value(s) from PLC…');

    for (final sensor in harnessReceipes) {
      await readSensorValue(sensor);
      // Small gap between requests — same reasoning as everywhere else
      // in this file: most PLCs can't handle overlapping requests.
      await Future.delayed(const Duration(milliseconds: 50));
    }

    isReadingPlcValues.value = false;
    _log('PLC read complete for ${harnessReceipes.length} sensor(s)');
  }

  Future<void> writeAllSensorValues() async {
    for (final sensor in harnessReceipes) {
      if (sensor.value == null) continue;

      final int? value = int.tryParse(sensor.value.toString());

      if (value == null) {
        _log("Invalid value for ${sensor.sensorName}");
        continue;
      }

      await writeSensorValue(sensor, value);

      // Optional delay
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

 
  /// the recipe API doesn't currently give us multiplier/offset — the
  /// register is assumed to already be PLC-scaled). Extend the other
  /// branches once the real formulas/constants for Resistance/Current
  /// sensors are confirmed for this API.
  double _applySensorFormula(String? type, int raw) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('resistance')) {
      return raw.toDouble();
    }
    if (t.contains('current')) {
      return raw.toDouble();
    }
    return raw.toDouble();
  }

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

    harnessReceipes.assignAll(match.receipes ?? []);
    _log(
        'Harness matched: "${match.name}" (${harnessReceipes.length} recipe sensor(s))');

    // NOTE: no value logging here at all — sensor name / reg address /
    // type / pin no are visible in the Recipe dialog's table straight
    // from the API, but VALUE only ever gets read (and only ever gets
    // logged to Activity) when the operator clicks "Show All Values"
    // in that dialog (see readAllSensorValues() / readSensorValue()).

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
    iqaAllFilled.value = false;
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

    harnessReceipes.clear();
    livePlcValues.clear();
    isReadingPlcValues.value = false;

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

    canConnectDongle.value = false;
    dongleConnected.value = false;
    _dongleRetryTimer?.cancel();
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
        await loadAvailableFlashFiles();
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        listError.value = message;
        _log('Failed to validate list number: $e');
        _showErrorPopup(message, title: 'List Validation Failed');
        return;
      }
    }

    // if (step.key == 'harness') {
    //   try {
    //     final isValid = await _isValidHarness(value);
    //     if (!isValid) {
    //       final message = 'Harness not recognized. Please rescan.';
    //       _log('Harness mismatch: scanned "$value"');
    //       _showErrorPopup(message, title: 'Harness Mismatch');
    //       return;
    //     }
    //   } catch (e) {
    //     final message = e.toString().replaceFirst('Exception: ', '');
    //     _log('Failed to validate harness: $e');
    //     _showErrorPopup(message, title: 'Harness Validation Failed');
    //     return;
    //   }
    // }

    if (step.key == 'harness') {
      try {
        final isValid = await _isValidHarness(value);
        if (!isValid) {
          final message = 'Wrong harness entered. Please rescan.';
          _log('Harness mismatch: scanned "$value"');
          _showErrorPopup(message, title: 'Wrong Harness');
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

  // ── IQA group ──

  final RxBool iqaAllFilled = false.obs;
  // void onIqaFieldChanged(int subIndex) {
  //   _iqaIdleTimers[subIndex]?.cancel();
  //   _iqaIdleTimers[subIndex] =
  //       Timer(_idleDuration, () => submitIqaField(subIndex));

  //   iqaAllFilled.value = iqaControllers.every((c) => c.text.trim().length == 7);
  // }

  void onIqaFieldChanged(int subIndex) {
    _iqaIdleTimers[subIndex]?.cancel();
    _iqaIdleTimers[subIndex] =
        Timer(_idleDuration, () => submitIqaField(subIndex));

    iqaAllFilled.value = iqaControllers.every((c) => c.text.trim().length == 7);
  }

  void submitIqaField(int subIndex) {
    if (allStepsComplete) return;

    _iqaIdleTimers[subIndex]?.cancel();
    final value = iqaControllers[subIndex].text.trim();

    // Only proceed once exactly 7 characters have been entered — not
    // before. Anything shorter (including empty) just waits for more
    // input instead of advancing early.
    if (value.length != 7) return;

    _log('${_iqaRecordLabel(subIndex)} scanned: $value');

    if (subIndex < iqaLabels.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        iqaFocusNodes[subIndex + 1].requestFocus();
      });
      return;
    }

    final allFilled = iqaControllers.every((c) => c.text.trim().length == 7);
    if (!allFilled) return;

    _log('IQA group complete');
    currentStepIndex.value = currentStepIndex.value + 1;

    if (allStepsComplete) {
      _log('All scan steps complete. Ready to flash.');
      _onAllStepsComplete();
    }
  }

  // void submitIqaField(int subIndex) {
  //   if (allStepsComplete) return;

  //   _iqaIdleTimers[subIndex]?.cancel();
  //   final value = iqaControllers[subIndex].text.trim();
  //   if (value.isEmpty) return;

  //   _log('${_iqaRecordLabel(subIndex)} scanned: $value');

  //   if (subIndex < iqaLabels.length - 1) {
  //     WidgetsBinding.instance.addPostFrameCallback((_) {
  //       iqaFocusNodes[subIndex + 1].requestFocus();
  //     });
  //     return;
  //   }

  //   final allFilled = iqaControllers.every((c) => c.text.trim().isNotEmpty);
  //   if (!allFilled) return;

  //   _log('IQA group complete');
  //   currentStepIndex.value = currentStepIndex.value + 1;

  //   if (allStepsComplete) {
  //     _log('All scan steps complete. Ready to flash.');
  //     _onAllStepsComplete();
  //   }
  // }

  void _onAllStepsComplete() {
    _log('All scan steps complete.');
  }

  final Map<String, int> _fileToEcuId = {};

  Future<void> loadAvailableFlashFiles() async {
    print("============= loadAvailableFlashFiles() =============");

    flashFilesLoading.value = true;
    flashFilesError.value = '';

    try {
      final scannedList = stepControllers[1].text.trim().toUpperCase();

      final variants = await _ensureVariantList();

      list_ds.Result? variant;
      for (final v in variants.results ?? []) {
        if ((v.variantCode ?? '').trim().toUpperCase() == scannedList) {
          variant = v;
          break;
        }
      }

      if (variant == null) {
        print("Variant not found");
        availableFlashFiles.clear();
        selectedFlashFile.value = null;
        _currentDtcDatasetId = null;
        _currentPidDatasetId = null;
        return;
      }

      final vehicleModelId = variant.vehicleModel;
      final subModelId = variant.subModel;

      final models = await _ensureModels();

      final files = <String>[];
      _fileToDtcDatasetId.clear();
      _fileToPidDatasetId.clear();
      _fileToEcuId.clear();

      for (final variantEcu in variant.variantEcu ?? []) {
        final ecuId = variantEcu.ecu;
        if (ecuId == null) continue;

        all_ds.SubmodelModelecu? ecuModel;

        for (final model in models.results ?? []) {
          if (model.id != vehicleModelId) continue;
          for (final sub in model.subModels ?? []) {
            if (sub.id != subModelId) continue;
            for (final ecu in sub.submodelModelecu ?? []) {
              if (ecu.ecu?.id == ecuId) {
                ecuModel = ecu;
                break;
              }
            }
            if (ecuModel != null) break;
          }
          if (ecuModel != null) break;
        }

        if (ecuModel == null) {
          print("ECU Model not found for ECU ID : $ecuId");
          continue;
        }

        final dataFile = variantEcu.dataFile;
        if (dataFile == null) continue;

        final fileName = dataFile.dataFile.split('/').last;
        print("Flash File : $fileName");

        files.add(fileName);
        _fileToEcuId[fileName] = ecuId;

        if (ecuModel.datasets != null && ecuModel.datasets!.isNotEmpty) {
          _fileToDtcDatasetId[fileName] = ecuModel.datasets!.first.id!;
        }
        if (ecuModel.pidDatasets != null && ecuModel.pidDatasets!.isNotEmpty) {
          _fileToPidDatasetId[fileName] = ecuModel.pidDatasets!.first.id!;
        }
      }

      availableFlashFiles.assignAll(files);

      selectedFlashFile.value = null;
      _currentDtcDatasetId = null;
      _currentPidDatasetId = null;

      print("Available Files : $files");
    } catch (e, s) {
      print("loadAvailableFlashFiles ERROR : $e");
      print(s);
      flashFilesError.value = e.toString();
    } finally {
      flashFilesLoading.value = false;
    }
  }

  void selectFlashFile(String? file) {
    selectedFlashFile.value = file;

    _currentDtcDatasetId = file == null ? null : _fileToDtcDatasetId[file];

    _currentPidDatasetId = file == null ? null : _fileToPidDatasetId[file];

    print("Selected File : $file");
    print("DTC Dataset : $_currentDtcDatasetId");
    print("PID Dataset : $_currentPidDatasetId");
  }

  Future<void> saveActivityLog() async {
    try {
      if (activityLog.isEmpty) {
        Get.snackbar("Info", "Activity log is empty.");
        return;
      }

      // Base application documents directory
      final Directory documentsDir = await getApplicationDocumentsDirectory();

      // Create Styajeet/Activity folder
      final Directory activityDir = Directory(
        '${documentsDir.path}/ActivityLog',
      );

      if (!await activityDir.exists()) {
        await activityDir.create(recursive: true);
      }

      final String fileName =
          'ActivityLog_${DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}.txt';

      final File file = File('${activityDir.path}/$fileName');

      await file.writeAsString(activityLog.join('\n'));

      Get.snackbar(
        "Success",
        "Activity log saved successfully.",
      );

      print("Saved at: ${file.path}");
    } catch (e) {
      Get.snackbar("Error", e.toString());
    }
  }

  // ── Dongle auto-connect ──
  Future<void> _autoConnectDongle() async {
    if (dongleConnected.value || dongleConnecting.value) return;

    if (_dongleIp == null || _dongleIp!.isEmpty) {
      _log('Dongle: no IP on record from login — cannot connect');
      return;
    }
    if (vehicleEcuEntries.isEmpty) {
      _log('Dongle: no ECU data resolved yet — scan ESN first');
      return;
    }

    dongleConnecting.value = true;
    await _withDongleBusy(() async {
      try {
        StaticData.ecuInfo = <EcuDataSet>[];

        for (final sme in vehicleEcuEntries) {
          StaticData.ecuInfo.add(EcuDataSet(
            ecuID: sme.ecu?.id,
            ecuName: sme.ecu?.name,
            txHeader: sme.ecu?.txHeader,
            rxHeader: sme.ecu?.rxHeader,
            protocol: sme.ecu?.protocol,
            channelId: sme.ecu?.channel,
            seedKeyIndex: sme.ecu?.seedkeyalgoFnIndex?.value,
            readDtcIndex: sme.ecu?.readDtcFnIndex?.value,
            clearDtcIndex: sme.ecu?.clearDtcFnIndex?.value,
            writePidIndex: sme.ecu?.writeDataFnIndex?.value,
            iorTestFnIndex: sme.ecu?.iorTestFnIndex?.value,
            firingSequence: sme.firingSequence,
            noOfInjectors: sme.noOfInjectors,
          ));
        }

        if (StaticData.ecuInfo.isEmpty) {
          _log('Dongle: no ECU entries to configure — will retry');
          dongleConnected.value = false;
          _startDongleRetryTimer();
          return;
        }

        final channelParts = StaticData.ecuInfo.first.channelId?.split('-');
        final channelId = (channelParts != null && channelParts.length > 1)
            ? '0${channelParts[1]}'
            : '00';

        _log('Connecting to dongle at $_dongleIp...');
        final macId = await _connectionWifi.getDongleMacID(_dongleIp!,
            channelId: channelId);

        if (macId.isEmpty) {
          _log('❌ Failed to connect to dongle at $_dongleIp — will retry');
          dongleConnected.value = false;
          _startDongleRetryTimer();
          return;
        }
        _log('✅ Dongle connected. MAC: $macId');

        final firmware = await App.dllFunctions?.setDongleProperties1() ?? '';
        if (firmware.isEmpty) {
          _log('❌ Connected, but failed to configure dongle — will retry');
          dongleConnected.value = false;
          _startDongleRetryTimer();
          return;
        }

        _log('✅ Dongle ready — firmware $firmware');
        dongleConnected.value = true;
        _dongleRetryTimer?.cancel();
      } catch (e) {
        _log('❌ Dongle connect exception: $e — will retry');
        dongleConnected.value = false;
        _startDongleRetryTimer();
      } finally {
        dongleConnecting.value = false;
      }
    });
  }

  void _startDongleRetryTimer() {
    _dongleRetryTimer?.cancel();
    _dongleRetryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (dongleConnected.value) {
        _dongleRetryTimer?.cancel();
        return;
      }
      _autoConnectDongle();
    });
  }

  /// Tap the status indicator to retry immediately instead of waiting
  /// for the next background retry tick.
  void retryDongleConnection() {
    if (dongleConnected.value) return;
    _autoConnectDongle();
  }

  List<all_ds.EcuMapFile> _parseEcuMapFilesFromSequence(
      String sequenceContent) {
    final result = <all_ds.EcuMapFile>[];

    for (final rawLine in sequenceContent.split('\n')) {
      final line = rawLine.replaceAll('\r', '').trim();
      if (!line.startsWith('EcuMapFile')) continue;

      final colonIdx = line.indexOf(':');
      if (colonIdx == -1) continue;
      final info = line.substring(colonIdx + 1);

      String? startAddress;
      String? endAddress;

      for (final item in info.split('+')) {
        final trimmed = item.trim();
        if (!trimmed.startsWith('<')) continue;
        final endIdx = trimmed.indexOf('>');
        if (endIdx == -1) continue;

        final bracket = trimmed.substring(1, endIdx);
        final values = bracket.split(',');
        if (values.length < 2) continue;

        final reference = values[0].trim();
        final value = values[1].trim();

        if (reference.contains('start_address')) {
          startAddress = value;
        } else if (reference.contains('end_address')) {
          endAddress = value;
        }
      }

      if (startAddress != null && endAddress != null) {
        result.add(all_ds.EcuMapFile(
          startAddress: startAddress,
          startAddr: int.tryParse(startAddress, radix: 16),
          endAddress: endAddress,
          endAddr: int.tryParse(endAddress, radix: 16),
        ));
      }
    }

    return result;
  }

  Future<void> startFlashing() async {
    if (flashInProgress.value) {
      return;
    }

    final fileName = selectedFlashFile.value;
    if (fileName == null) {
      _showErrorPopup('Select a flash file from the list first',
          title: 'No File Selected');
      return;
    }

    if (!dongleConnected.value || App.dllFunctions == null) {
      _log('❌ Cannot flash — dongle not connected');
      _showErrorPopup('Waiting for the dongle to connect before flashing',
          title: 'Not Connected');
      return;
    }

    // Reset ALL flash state synchronously BEFORE navigating, so the new
    // page never renders a stale frame from the previous flash run.
    flashErrorMessage.value = '';
    flashComplete.value = false;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;

    Get.to(() => const EcuFlashingPage()); // navigate to flashing page

    await _withDongleBusy(() async {
      flashInProgress.value = true;
      _log('Flashing started');

      _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
        flashElapsedSeconds.value++;
      });

      Timer? percentTimer;

      String? result;
      try {
        final scannedList = stepControllers[1].text.trim().toUpperCase();
        final variants = await _ensureVariantList();

        final variant = (variants.results ?? []).firstWhereOrNull(
          (v) => (v.variantCode ?? '').trim().toUpperCase() == scannedList,
        );
        if (variant == null) throw Exception("Variant not found");

        final targetEcuId = _fileToEcuId[fileName];
        if (targetEcuId == null) {
          throw Exception(
              "Could not resolve ECU for selected file \"$fileName\"");
        }

        final variantEcu = (variant.variantEcu ?? [])
            .firstWhereOrNull((ve) => ve.ecu == targetEcuId);
        if (variantEcu == null) {
          throw Exception("Variant ECU entry not found for selected file");
        }

        print("ECU ID (selected file) : $targetEcuId");
        print("HEX FILE                : ${variantEcu.dataFile?.dataFile}");

        final models = await _ensureModels();
        all_ds.SubmodelModelecu? selectedEcu;

        for (final model in models.results ?? []) {
          if (model.id != variant.vehicleModel) continue;
          for (final sub in model.subModels ?? []) {
            if (sub.id != variant.subModel) continue;
            for (final ecu in sub.submodelModelecu ?? []) {
              if (ecu.ecu?.id == targetEcuId) {
                selectedEcu = ecu;
                break;
              }
            }
            if (selectedEcu != null) break;
          }
          if (selectedEcu != null) break;
        }

        if (selectedEcu == null) {
          throw Exception("ECU configuration not found for selected file");
        }

        print("Selected ECU : ${selectedEcu.ecu?.name}");

        if (selectedEcu.flashFile == null) {
          final fallback = vehicleEcuEntries
              .firstWhereOrNull((e) => e.ecu?.id == targetEcuId);
          if (fallback?.flashFile != null) {
            selectedEcu = fallback;
          }
        }

        if (selectedEcu!.flashFile == null) {
          throw Exception("Flash file missing");
        }

        final flashConfig = selectedEcu.flashFile!;

        _log('Selected flash file: $fileName');

        await App.dllFunctions!.setDongleProperties(
          selectedEcu.ecu?.protocol?.name ?? '',
          selectedEcu.ecu?.protocol?.autopeepal ?? '',
          selectedEcu.ecu?.txHeader ?? '',
          selectedEcu.ecu?.rxHeader ?? '',
        );

        _log('Downloading sequence file...');
        final sequenceContent =
            await _downloadAsRawString(flashConfig.sequenceFile!);

        var ecuMapFiles = flashConfig.ecuMapFile ?? <all_ds.EcuMapFile>[];
        if (ecuMapFiles.isEmpty) {
          print('⚠️ API ecu_map_file empty — parsing from sequence file text.');
          ecuMapFiles = _parseEcuMapFilesFromSequence(sequenceContent);
        }
        if (ecuMapFiles.isEmpty) {
          throw Exception("ECU MAP FILE missing — cannot generate flash JSON.");
        }

        _log('Downloading firmware file: $fileName');
        final hexContent =
            await _downloadAsRawString(variantEcu.dataFile!.dataFile!);

        final flashJson = await readJson(
          ecuMapFiles,
          flashConfig.flashCheckSumType?.toString() ?? '',
          Uint8List.fromList(hexContent.codeUnits),
        );

        if (flashJson.isEmpty) {
          throw Exception("Flash JSON generation failed");
        }
        _currentDtcDatasetId = _fileToDtcDatasetId[fileName];
        _currentPidDatasetId = _fileToPidDatasetId[fileName];

        // Only NOW start polling the DLL for progress — right before the
        // actual flash write begins, so we never display stale progress
        // left over from a previous flash run.
        flashProgress.value = 0;
        percentTimer =
            Timer.periodic(const Duration(milliseconds: 500), (_) async {
          try {
            flashProgress.value = await App.dllFunctions!.flashingData();
          } catch (_) {}
        });

        result = await App.dllFunctions!.startECUFlashing(
          flashJson,
          sequenceContent,
          selectedEcu.ecu!,
          selectedEcu.ecu?.seedkeyalgoFnIndex?.value ?? '',
        );

        print("Flash Result : $result");
      } catch (e, s) {
        print("❌ FATAL ERROR : $e");
        print(s);
        result = e.toString();
      }

      _flashStopwatch?.cancel();
      percentTimer?.cancel();
      flashInProgress.value = false;

      if (result == null || result.isEmpty || result != 'NOERROR') {
        flashComplete.value = false;
        _log('❌ Flashing failed: $result');

        final r = (result ?? '').toLowerCase();
        final looksDisconnected = r.contains('no resp') ||
            r.contains('socket_closed') ||
            r.contains('noresponsefromecu');

        if (looksDisconnected) {
          dongleConnected.value = false;
          _startDongleRetryTimer();
          _showReconnectPopup(); // still shows over the flashing page
        }

        // Inline error on the flashing page itself instead of a popup —
        // gives the operator a Back button right there.
        flashErrorMessage.value = result ?? 'Unknown error';
        return;
      }

      flashComplete.value = true;
      _log('Flashing completed successfully (${formattedElapsed})');

      await _loadDtcResults();
      await _loadPidResults();

      final iqaWriteStatus = await _autoWriteIqaValues();

      // Pop back to Home, then show the same complete popup as before.
      if (Get.isDialogOpen != true) {
        Get.back();
      }
      _showFlashCompletePopup(iqaWriteStatus);
    });
  }

  Future<String> _downloadAsRawString(String url) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes =
        await response.fold<List<int>>(<int>[], (p, c) => p..addAll(c));
    client.close();
    return latin1.decode(bytes);
  }

  List<all_ds.EcuMapFile>? parsedEcuMapFiles;
  RxBool isBusy = false.obs;
  RxString loaderText = ''.obs;
  Future<String> readJson(
    List<all_ds.EcuMapFile> ecuMapFiles,
    String checksumAlgo,
    Uint8List hexBytes,
  ) async {
    try {
      print("========== READ JSON START ==========");

      print("ECU MAP COUNT : ${ecuMapFiles.length}");
      print("CHECKSUM TYPE : $checksumAlgo");
      print("HEX SIZE      : ${hexBytes.length}");

      for (final map in ecuMapFiles) {
        print(
          "START ADDRESS : ${map.startAddress} "
          "END ADDRESS : ${map.endAddress}",
        );
      }

      final flashJson = await GetJson().convertToJson(
        hexBytes,
        ecuMapFiles,
        checksumAlgo,
      );

      print(
        "FLASH JSON LENGTH : ${flashJson.length}",
      );

      print("========== READ JSON END ==========");

      _resetLoader();

      return flashJson;
    } catch (e, stack) {
      print("readJson ERROR : $e");
      print(stack);

      _resetLoader();

      return "";
    }
  }

  void _setBusy(bool busy, String text) {
    isBusy.value = busy;
    loaderText.value = text;
  }

  void _resetLoader() => _setBusy(false, "");

  Future<void> _loadDtcResults() {
    return _withDongleBusy(() async {
      final datasetId = _currentDtcDatasetId;
      if (datasetId == null) {
        _log('No DTC dataset id available — skipping');
        return;
      }

      final ecu =
          StaticData.ecuInfo.firstWhereOrNull((e) => e.readDtcIndex != null);
      if (ecu == null) {
        _log('DTC read: no ECU with read_dtc_index configured — skipping');
        return;
      }

      _accessToken ??= await SecureStorageService.getAccessToken();

      try {
        final dtc_ds.DtcDataset dtc = await _authService.getDtcDataset(
          id: datasetId,
          accessToken: _accessToken,
        );

        final serverCodes = <dtc_ds.DtcCode>[];
        for (final result in dtc.results ?? <dtc_ds.Result>[]) {
          serverCodes.addAll(result.dtcCode ?? <dtc_ds.DtcCode>[]);
        }

        await App.dllFunctions!.setDongleProperties(
          ecu.protocol?.name ?? '',
          ecu.protocol?.autopeepal ?? '',
          ecu.txHeader ?? '',
          ecu.rxHeader ?? '',
        );

        _log('Reading DTCs from ${ecu.ecuName}...');
        final readResult = await App.dllFunctions!.readDtc(ecu.readDtcIndex!);

        if (readResult == null) {
          _log('DTC read: ECU_COMMUNICATION_ERROR');
          dtcList.clear();
          dongleConnected.value = false;
          _startDongleRetryTimer();
          _showReconnectPopup();
          return;
        }

        if (readResult.status != 'NO_ERROR') {
          _log('DTC read failed: ${readResult.status}');
          dtcList.clear();
          if (readResult.status == 'No Resp From Dongle' ||
              readResult.status == 'SOCKET_CLOSED' ||
              readResult.status.toString().toLowerCase().contains('no resp')) {
            dongleConnected.value = false;
            _startDongleRetryTimer();
            _showReconnectPopup();
          }
          return;
        }

        final rows = readResult.dtcs ?? [];
        final dummy = <String, String>{};

        for (final row in rows) {
          if (row.length < 2) continue;
          final code = row[0];
          final status = row[1];

          final match = serverCodes.firstWhereOrNull((c) => c.code == code);
          final desc = match?.description ?? 'Description not found';

          dummy[code] = '$code - $desc ($status)';
        }

        dtcList.assignAll(dummy.values.toList());
        _log('DTC (${dtcList.length}) data loaded');
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        _log('Failed to load DTC dataset: $e');
        dtcList.clear();
        _showErrorPopup(message, title: 'Failed to Load DTC');
      }
    });
  }

  void _showReconnectPopup() {
    Get.dialog(
      AlertDialog(
        title: const Text("Dongle Disconnected"),
        content: const Text(
          "Connection to the dongle was lost — this can happen right after "
          "flashing while the ECU resets. Reconnect to reload DTC and PID data.",
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Get.back();
              await _reconnectDongleAndReload();
            },
            child: const Text("OK", style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  final RxString flashErrorMessage = ''.obs;

  Future<void> _reconnectDongleAndReload() {
    return _withDongleBusy(() async {
      final ip = _dongleIp ?? '';

      if (ip.isEmpty) {
        _log('Reconnect: no dongle IP on record');
        _showErrorPopup('No dongle IP on record from login.',
            title: 'Reconnect Failed');
        return;
      }

      if (StaticData.ecuInfo.isEmpty) {
        _log('Reconnect: no ECU config available');
        _showErrorPopup('No ECU configuration found — scan ESN again.',
            title: 'Reconnect Failed');
        return;
      }

      Get.dialog(
        const Center(
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Reconnecting..."),
                ],
              ),
            ),
          ),
        ),
        barrierDismissible: false,
      );

      try {
        final channelParts = StaticData.ecuInfo.first.channelId?.split('-');
        final channelId = (channelParts != null && channelParts.length > 1)
            ? '0${channelParts[1]}'
            : '00';

        _log('Reconnecting to dongle at $ip...');
        final macId =
            await _connectionWifi.getDongleMacID(ip, channelId: channelId);

        if (macId.isEmpty) {
          if (Get.isDialogOpen == true) Get.back();
          _log('❌ Reconnect failed at $ip');
          dongleConnected.value = false;
          _showErrorPopup('Could not reconnect to dongle at $ip',
              title: 'Reconnect Failed');
          _startDongleRetryTimer();
          return;
        }

        _log('✅ Reconnected. MAC: $macId');

        final firmware = await App.dllFunctions?.setDongleProperties1() ?? '';
        if (firmware.isEmpty) {
          if (Get.isDialogOpen == true) Get.back();
          _log('❌ Reconnected but failed to confirm dongle properties');
          dongleConnected.value = false;
          _showErrorPopup(
              'Reconnected, but dongle did not respond to configuration.',
              title: 'Reconnect Failed');
          _startDongleRetryTimer();
          return;
        }

        _log('✅ Dongle ready — firmware $firmware');
        dongleConnected.value = true;
        _dongleRetryTimer?.cancel();

        if (Get.isDialogOpen == true) Get.back();

        await _loadDtcResults();
        await _loadPidResults();
      } catch (e) {
        if (Get.isDialogOpen == true) Get.back();
        _log('❌ Reconnect exception: $e');
        dongleConnected.value = false;
        _showErrorPopup(e.toString(), title: 'Reconnect Failed');
        _startDongleRetryTimer();
      }
    });
  }

  Future<void> _loadPidResults() {
    return _withDongleBusy(() async {
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
            for (final v in code.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
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
    });
  }

  void _showFlashCompletePopup(String iqaWriteStatus) {
    final iqaSummary = List.generate(
      iqaLabels.length,
      (i) => '${_iqaRecordLabel(i)}: ${iqaControllers[i].text.trim()}',
    ).join('\n');

    final message =
        'File: ${selectedFlashFile.value ?? '-'}\n\n$iqaSummary\n\n$iqaWriteStatus';

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

  /// Runs continuously in the background, independent of any user
  /// action. Catches silent disconnects that would otherwise sit
  /// undetected until the next real dongle operation happens to fail.
  /// Skips its own tick entirely whenever isDongleBusy is true, so it
  /// never collides with real dongle traffic from flashing/DTC/PID/IQA.
  void _startDongleHeartbeat() {
    _dongleHeartbeatTimer?.cancel();
    _dongleHeartbeatTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!dongleConnected.value) return;
      if (isDongleBusy.value) return;
      if (_dongleIp == null || _dongleIp!.isEmpty) return;

      try {
        final channelParts = StaticData.ecuInfo.isNotEmpty
            ? StaticData.ecuInfo.first.channelId?.split('-')
            : null;
        final channelId = (channelParts != null && channelParts.length > 1)
            ? '0${channelParts[1]}'
            : '00';

        final macId = await _connectionWifi
            .getDongleMacID(_dongleIp!, channelId: channelId)
            .timeout(const Duration(seconds: 3));

        if (macId.isEmpty) {
          _log('❌ Dongle heartbeat failed — connection lost (check wiring)');
          dongleConnected.value = false;
          _startDongleRetryTimer();
        }
      } catch (e) {
        _log('❌ Dongle heartbeat failed: $e — connection lost (check wiring)');
        dongleConnected.value = false;
        _startDongleRetryTimer();
      }
    });
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
    _plcRetryTimer?.cancel();
    _plcHeartbeatTimer?.cancel();
    _dongleRetryTimer?.cancel();
    _dongleHeartbeatTimer?.cancel();
    super.onClose();
  }
}

