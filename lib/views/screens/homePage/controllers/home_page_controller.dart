import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/app.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/all.models.dart' as all_ds;
import 'package:simpson/modals/esn_ds.dart' as esn_ds;
import 'package:simpson/modals/liveParameter_model.dart';
import 'package:simpson/modals/pidDataset.model.dart';
import 'package:simpson/modals/staticData.dart';
import 'package:simpson/modals/dtcDataset.model.dart' as dtc_ds;
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/routes/app_pages.dart';
import 'package:simpson/services/apiServices.dart';
import 'package:simpson/services/connectionWifiService.dart';
import 'package:simpson/services/plc/plc_service.dart';
import 'package:simpson/services/connectionWifiService.dart';
import 'package:simpson/services/getJson_service.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:simpson/services/pending_session_storage.dart';

import '../../../../services/connectionWifiService.dart';

enum StepType { single, iqaGroup }

class ScanStep {
  final String key;
  final String label;
  final StepType type;
  ScanStep(this.key, this.label, {this.type = StepType.single});
}

class HomePageController extends GetxController with WidgetsBindingObserver {
  late final String station;
  final List<ScanStep> steps = [
    ScanStep('esn', 'ESN'),
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
  final RxList<Map<String, dynamic>> testbedSessionHistory =
      <Map<String, dynamic>>[].obs;
  final RxString currentEsn = ''.obs;
  static const _idleDuration = Duration(milliseconds: 400);

  final RxInt currentStepIndex = 0.obs;
  bool get allStepsComplete => currentStepIndex.value >= steps.length;

  final RxString esnError = ''.obs;
  final RxString listError = ''.obs;
  final RxBool isDongleBusy = false.obs;
  final RxString resolvedListNumber = ''.obs;
  final RxString resolvedHarnessName = ''.obs;

  // ── Local draft/session tracking (for interrupted-session recovery) ──
  String? _currentSessionKey;
  String? _draftFlashStatus;
  String? _draftIqaStatus;
  String? _draftDtcStatus;
  bool _sessionReportSent = false;

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
  int? _esnRecordId;
  String? _resolvedDatasetType;
  String? _resolvedDatasetFileName;
  int? _dongleDbId;
  DateTime? _flashCycleStartTime;

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

  void _startPlcRetryTimer() {
    _plcRetryTimer?.cancel();
    _plcRetryTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (plcService.isConnected.value) {
        _plcRetryTimer?.cancel();
        return;
      }
      _autoConnectPlc();
    });
  }

  void retryPlcConnection() {
    if (isPlcConnected.value) return;
    _autoConnectPlc();
  }

  void _startPlcHeartbeat() {
    _plcHeartbeatTimer?.cancel();
    _plcHeartbeatTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (!plcService.isConnected.value) return;
      if (isReadingPlcValues.value) return;

      final pingReg = harnessReceipes.isNotEmpty
          ? (harnessReceipes.first.regAddress ?? 4)
          : 4;

      try {
        await plcService
            .readRegister(pingReg)
            .timeout(const Duration(milliseconds: 800));
        return; // first attempt succeeded, all good
      } catch (_) {
        // fall through to retry below
      }

      try {
        await Future.delayed(const Duration(milliseconds: 150));
        await plcService
            .readRegister(pingReg)
            .timeout(const Duration(milliseconds: 800));
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
  final RxString flashPhaseLabel = ''.obs;
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
    WidgetsBinding.instance
        .addObserver(this); // ✅ observe app lifecycle for exit-flush

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

    _loadAccessToken().then((_) => _resendPendingSessions()); // ✅ resend first
    _loadDongleEntries();
    _loadPlcConfig().then((_) => _autoConnectPlc());
    _startDongleHeartbeat();
    _startPlcHeartbeat();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(flushPendingSessionOnExit());
    }
  }

  Future<void> _resendPendingSessions() async {
    final drafts = PendingSessionStorage.getAllDrafts();
    if (drafts.isEmpty) return;

    _log(
        'Found ${drafts.length} unsent session report(s) from a previous run — resending...');

    const validStatuses = {'Pass', 'Fail'};
    String sanitizeStatus(dynamic raw) {
      final value = raw as String?;
      return validStatuses.contains(value) ? value! : 'Fail';
    }

    for (final draft in drafts) {
      final key = draft['sessionKey'] as String?;
      if (key == null) continue;

      final datasetType = draft['datasetType'] as String?;
      final datafileName = draft['datafileName'] as String?;
      if (datasetType == null ||
          datasetType.isEmpty ||
          datafileName == null ||
          datafileName.isEmpty) {
        await PendingSessionStorage.removeDraft(key);
        _log(
            'Discarded invalid draft ($key) — no dataset resolved, nothing worth resending');
        continue;
      }

      final flashStatus = sanitizeStatus(draft['flashStatus']);
      final iqaStatus = sanitizeStatus(draft['iqaStatus']);
      final dtcStatus = sanitizeStatus(draft['dtcStatus']);

      try {
        await _authService.createTestBedSession(
          esnId: draft['esnId'] as int?,
          dongleId: draft['dongleId'] as int?,
          datasetType: datasetType,
          datafileName: datafileName,
          startDate: DateTime.tryParse(draft['startDate'] as String? ?? '') ??
              DateTime.now(),
          endDate: DateTime.tryParse(draft['endDate'] as String? ?? '') ??
              DateTime.now(),
          flashStatus: flashStatus,
          iqaStatus: iqaStatus,
          dtcStatus: dtcStatus,
          activityLog: List<String>.from(draft['activityLog'] as List? ?? []),
          accessToken: _accessToken,
        );
        await PendingSessionStorage.removeDraft(key);
        _log('✅ Resent previously unsent session report ($key)');
      } catch (e) {
        _log(
            '❌ Failed to resend session report ($key): $e — will retry next launch');
      }
    }
  }

  final RxBool isReadingDtcManually = false.obs;

  Future<void> readDtcsManually() async {
    if (!dongleConnected.value || App.dllFunctions == null) {
      _showErrorPopup('Waiting for the dongle to connect first',
          title: 'Not Connected');
      return;
    }

    if (_currentDtcDatasetId == null) {
      _showErrorPopup(
          'Select a flash file first so the correct DTC '
          'dataset is known.',
          title: 'No Flash File Selected');
      return;
    }

    isReadingDtcManually.value = true;
    try {
      _log('Manual DTC read requested (no flashing)');
      await _loadDtcResults(); // <- exact same call the post-flash path uses
    } finally {
      isReadingDtcManually.value = false;
    }
  }

  Future<void> _loadAccessToken() async {
    _accessToken = await SecureStorageService.getAccessToken();
  }

  List<_DongleEntry> _dongleEntries = [];

  Future<void> _loadDongleEntries() async {
    final raw = await SecureStorageService.getDongleList();
    if (raw == null || raw.isEmpty) {
      _log('Dongle: no dongle list found from login data');
      return;
    }
    try {
      final List<dynamic> decoded = jsonDecode(raw);
      _dongleEntries = decoded.map((d) {
        final ecuIdsRaw = (d['ecu_ids'] as List?) ?? [];
        return _DongleEntry(
          macId: d['mac_id'] as String?,
          ip: d['ip'] as String?,
          isActive: d['is_active'] == true,
          ecuIds: ecuIdsRaw.whereType<num>().map((n) => n.toInt()).toList(),
          dongleDbId: d['dongleDbId'] as int?,
        );
      }).toList();
      _log('Dongle: loaded ${_dongleEntries.length} dongle(s) from login data');
    } catch (e) {
      _log('Dongle: failed to parse dongle list — $e');
    }
  }

  String _timestamp() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  void _log(String message, {String? tag}) {
    final resolvedTag = tag ?? _inferLogTag(message);
    activityLog.insert(0, '[${_timestamp()}] [$resolvedTag] $message');
    unawaited(_persistSessionDraft()); // ✅ save locally after every log line
  }

  Future<void> _persistSessionDraft() async {
    final key = _currentSessionKey;
    if (key == null) return; // no active session yet (e.g. before ESN scan)
    if (_sessionReportSent)
      return; // ✅ already sent — never write this session's draft again

    if (_resolvedDatasetType == null || _resolvedDatasetFileName == null) {
      return;
    }

    await PendingSessionStorage.saveDraft(key, {
      'sessionKey': key,
      'esnId': _esnRecordId,
      'dongleId': _dongleDbId,
      'datasetType': _resolvedDatasetType,
      'datafileName': _resolvedDatasetFileName,
      'startDate': (_flashCycleStartTime ?? DateTime.now()).toIso8601String(),
      'endDate': DateTime.now().toIso8601String(),
      'flashStatus': _draftFlashStatus ?? 'Fail',
      'iqaStatus': _draftIqaStatus ?? 'Fail',
      'dtcStatus': _draftDtcStatus ?? 'Fail',
      'activityLog': activityLog.toList(),
    });
  }

  Future<void> _sendPartialSessionReport(String reason) async {
    final key = _currentSessionKey;
    if (key == null) return;

    if (_sessionReportSent) {
      _log(
          'Skipping duplicate report ($reason) — already sent for this session');
      return;
    }

    if (_resolvedDatasetType == null ||
        _resolvedDatasetType!.isEmpty ||
        _resolvedDatasetFileName == null ||
        _resolvedDatasetFileName!.isEmpty) {
      _log(
          'Skipping session report ($reason) — dataset_type/datafile_name not resolved yet, nothing valid to send');
      return;
    }
    _sessionReportSent = true;

    _log('Sending partial session report to server ($reason)...');

    try {
      await _authService.createTestBedSession(
        esnId: _esnRecordId,
        dongleId: _dongleDbId,
        datasetType: _resolvedDatasetType,
        datafileName: _resolvedDatasetFileName,
        startDate: _flashCycleStartTime ?? DateTime.now(),
        endDate: DateTime.now(),
        flashStatus: _draftFlashStatus ?? 'Fail',
        iqaStatus: _draftIqaStatus ?? 'Fail',
        dtcStatus: _draftDtcStatus ?? 'Fail',
        activityLog: activityLog.toList(),
        accessToken: _accessToken,
      );
      _log('✅ Partial session report sent successfully ($reason)');
      await PendingSessionStorage.removeDraft(key);
    } catch (e) {
      _sessionReportSent = false;
      _log(
          '❌ Failed to send partial session report ($reason): $e — will retry later');
    }
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

    final variant = match.prodbudVariant;
    if (variant == null) return false;
    _esnVehicleModelId = variant.vehicleModel;
    _esnVehicleSubModelId = variant.subModel;
    _resolvedVariant = variant;
    _esnRecordId = match.id;
    _flashCycleStartTime = DateTime.now();

    _currentSessionKey =
        '${scanned}_${_flashCycleStartTime!.millisecondsSinceEpoch}';
    _draftFlashStatus = null;
    _draftIqaStatus = null;
    _draftDtcStatus = null;
    _resolvedDatasetType = null;
    _resolvedDatasetFileName = null;
// reset for the new session's own tracking
    _sessionReportSent = false; // ✅ fresh session — allow one report to send
// ✅ fresh session — nothing persisted until flashing starts

    currentEsn.value = scanned; // ← history screen needs it

    // Fetch this ESN's session history and actually store it.
    unawaited(_authService
        .getSessionHistory(esn: scanned, accessToken: _accessToken)
        .then((history) {
      final eol = (history['eol_sessions'] as List?) ?? [];
      final testbed = (history['testbed_sessions'] as List?) ?? [];

      testbedSessionHistory.assignAll(
        testbed.map((e) => Map<String, dynamic>.from(e as Map)),
      );

      _log(
          'History for ESN $scanned → ${eol.length} EOL, ${testbed.length} testbed session(s) found');
    }).catchError((e) {
      _log('Failed to load session history: $e');
    }));

    return true;
  }

  //---------------------------------
  Future<void> _resolveInjectorConfigFromVariant() async {
    try {
      final variant = _resolvedVariant;
      if (variant == null) {
        _log('Injector config: no resolved variant — using default');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final vehicleModelId = variant.vehicleModel;
      final subModelId = variant.subModel;

      final activetDatasets =
          (variant.tDatasetEcu ?? []).where((t) => t.isActive == true);
      final ecuId =
          activetDatasets.map((t) => t.ecu).whereType<int>().firstOrNull;

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
        }
      }

      if (matched == null) {
        _log('Injector config: no submodel_modelecu match');
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

  Future<void> _resolveHarnessRequirementFromVariant() async {
    final variant = _resolvedVariant;

    resolvedListNumber.value = variant?.variantCode ?? '';

    if (variant == null) {
      resolvedHarnessName.value = '';
      return;
    }

    final harnesses = variant.prodbudVariantHarness ?? [];

    final activeHarness = harnesses.firstWhereOrNull(
      (h) =>
          h.isActive == true &&
          (h.stationType ?? '').trim().toLowerCase() == 'testing',
    );

    if (activeHarness == null) {
      _log('No active harness entry found for this variant.');
      resolvedHarnessName.value = '';
      harnessReceipes.clear();
      return;
    }

    resolvedHarnessName.value =
        '${activeHarness.name ?? '-'} (${activeHarness.harnessType ?? '-'})';
    harnessReceipes.assignAll(activeHarness.receipes ?? []);
    _log(
        'Harness resolved: "${activeHarness.name}" (${activeHarness.harnessType}) — '
        '${harnessReceipes.length} recipe sensor(s).');
  }

  Future<void> loadAvailableFlashFilesFromVariant() async {
    print("============= loadAvailableFlashFilesFromVariant() =============");

    flashFilesLoading.value = true;
    flashFilesError.value = '';

    try {
      final variant = _resolvedVariant;
      if (variant == null) {
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
      _fileToHexUrl.clear();

      var activetDatasets =
          (variant.tDatasetEcu ?? []).where((t) => t.isActive == true).toList();

      bool usingDDataset = false;
      if (activetDatasets.isEmpty) {
        print("No active T-dataset entries — falling back to D-dataset");
        usingDDataset = true;
        activetDatasets = (variant.dDatasetEcu ?? [])
            .where((d) => d.isActive == true && d.isLatest == true)
            .toList();
      }

      for (final t in activetDatasets) {
        final ecuId = t.ecu;
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

        if (ecuModel == null) continue;

        final dataFileUrl = t.dataFile;
        if (dataFileUrl == null || dataFileUrl.isEmpty) continue;

        final fileName = dataFileUrl.split('/').last;
        print(
            "Flash File : $fileName (${usingDDataset ? 'D' : 'T'}-dataset id=${t.id}, isLatest=${t.isLatest})");

        files.add(fileName);
        _fileToEcuId[fileName] = ecuId;
        _fileToHexUrl[fileName] = dataFileUrl;

        if (ecuModel.datasets != null && ecuModel.datasets!.isNotEmpty) {
          _fileToDtcDatasetId[fileName] = ecuModel.datasets!.first.id!;
        }
        if (ecuModel.pidDatasets != null && ecuModel.pidDatasets!.isNotEmpty) {
          _fileToPidDatasetId[fileName] = ecuModel.pidDatasets!.first.id!;
        }
      }

      availableFlashFiles.assignAll(files);

      if (files.isNotEmpty) {
        selectFlashFile(files.first);
      } else {
        selectedFlashFile.value = null;
        _currentDtcDatasetId = null;
        _currentPidDatasetId = null;
      }

      print("Available Files : $files");
    } catch (e, s) {
      print("loadAvailableFlashFilesFromVariant ERROR : $e");
      print(s);
      flashFilesError.value = e.toString();
    } finally {
      flashFilesLoading.value = false;
    }
  }

  final RxString vehicleDisplayName = ''.obs;

  List<all_ds.SubmodelModelecu> vehicleEcuEntries = [];

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

  int? _esnVehicleModelId;
  int? _esnVehicleSubModelId;
  esn_ds.ProdbudVariant? _resolvedVariant;

  Future<void> _resolveVehicleFromEsn() async {
    final modelId = _esnVehicleModelId;
    final subModelId = _esnVehicleSubModelId;

    void resetVehicleContext() {
      vehicleDisplayName.value = '';
      vehicleEcuEntries = <all_ds.SubmodelModelecu>[];
      canConnectDongle.value = false;
    }

    if (modelId == null || subModelId == null) {
      _log('Vehicle context: ESN model/sub-model IDs not found.');
      resetVehicleContext();
      return;
    }

    try {
      final models = await _ensureModels();

      all_ds.Result? matchedModel;
      all_ds.SubModel? matchedSubModel;

      for (final model in models.results ?? <all_ds.Result>[]) {
        if (model.id != modelId) continue;

        matchedModel = model;

        for (final sub in model.subModels ?? <all_ds.SubModel>[]) {
          if (sub.id == subModelId) {
            matchedSubModel = sub;
            break;
          }
        }

        break;
      }

      if (matchedModel == null || matchedSubModel == null) {
        _log(
            'Vehicle context: Unable to resolve modelId=$modelId, subModelId=$subModelId.');

        vehicleDisplayName.value = 'Not Available';
        resetVehicleContext();
        return;
      }

      vehicleDisplayName.value =
          '${matchedModel.name} - ${matchedSubModel.name}';

      vehicleEcuEntries =
          matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

      _esnVehicleModelId = matchedModel.id;
      _esnVehicleSubModelId = matchedSubModel.id;

      final ecuIds =
          vehicleEcuEntries.map((e) => e.ecu?.id).whereType<int>().toSet();

      _log('----------------------------------------');
      _log('Vehicle Resolved');
      _log('Model     : ${matchedModel.name}');
      _log('Sub Model : ${matchedSubModel.name}');
      _log('Model ID  : $_esnVehicleModelId');
      _log('SubModel ID : $_esnVehicleSubModelId');
      _log('Vehicle ECU IDs : ${ecuIds.join(", ")}');
      _log('----------------------------------------');

      canConnectDongle.value = ecuIds.isNotEmpty;

      if (canConnectDongle.value) {
        _resolveDongleIpFromEcu(ecuIds);
      } else {
        _log('Vehicle has no ECU configured.');
      }
    } catch (e) {
      _log('Vehicle context resolution failed : $e');
      resetVehicleContext();
    }
  }

  bool harnessRequired = true;

  void _resolveDongleIpFromEcu(Set<int> vehicleEcuIds) {
    if (vehicleEcuIds.isEmpty) {
      _log('No ECU IDs found for resolved vehicle.');
      return;
    }

    if (_dongleEntries.isEmpty) {
      _log('No dongles received from login response.');
      return;
    }

    _log('Searching matching dongle...');
    _log('Vehicle ECU IDs : ${vehicleEcuIds.join(", ")}');

    for (final dongle in _dongleEntries) {
      _log(
        'Dongle : ${dongle.macId ?? "Unknown"} | '
        'IP : ${dongle.ip} | '
        'ECU IDs : ${dongle.ecuIds.join(", ")}',
      );
    }

    final matchedDongle = _dongleEntries.firstWhereOrNull(
      (dongle) =>
          dongle.ip != null &&
          dongle.ip!.isNotEmpty &&
          dongle.ecuIds.any(vehicleEcuIds.contains),
    );

    if (matchedDongle == null) {
      _log(
          'No matching dongle found for ECU IDs : ${vehicleEcuIds.join(", ")}');
      canConnectDongle.value = false;
      return;
    }
    _dongleIp = matchedDongle.ip;
    dongleIp.value = matchedDongle.ip!;
    _dongleDbId = matchedDongle.dongleDbId;

    _log('----------------------------------------');
    _log('Matching Dongle Found');
    _log('MAC : ${matchedDongle.macId}');
    _log('IP  : ${matchedDongle.ip}');
    _log('Matched ECU IDs : ${matchedDongle.ecuIds.join(", ")}');
    _log('----------------------------------------');

    _autoConnectDongle();
  }

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
      if (variables.length != iqaControllers.length) {
        final usedCount = variables.length < iqaControllers.length
            ? variables.length
            : iqaControllers.length;
        _log('⚠️ IQA auto-write: PID has ${variables.length} variable(s) but '
            '${iqaControllers.length} value(s) were entered — using the first '
            '$usedCount');
      }

      final int loopCount = variables.length < iqaControllers.length
          ? variables.length
          : iqaControllers.length;

      for (int i = 0; i < loopCount; i++) {
        final variable = variables[i];

        final value = iqaControllers[i].text.trim().toUpperCase();

        final bytes = latin1.encode(value);

        final start = variable.bytePosition! - 1;
        final end = start + bytes.length;

        if (start < 0 || end > writeInput.length) {
          _log('❌ IQA auto-write: byte range [$start,$end) out of bounds for '
              'writeInput length ${writeInput.length} (variable=${variable.shortName}, '
              'bytePosition=${variable.bytePosition})');
          return 'IQA write failed: byte layout mismatch for this ECU — '
              'check PID dataset for ${variable.shortName}';
        }

        writeInput.setRange(
          start,
          end,
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

  final RxMap<int, String> livePlcValues = <int, String>{}.obs;
  final RxBool isReadingPlcValues = false.obs;

  // ── Write ──
  final RxBool isWritingSensor = false.obs;
  final RxSet<int> writeInFlightSensorIds = <int>{}.obs;
  // ── Write All (sequential) ──
  final RxBool isWritingAllSensors = false.obs;
  final Rx<int?> currentWritingSensorId = Rx<int?>(null);
  Future<void> writeSensorValue(list_ds.Receipe sensor, int value) async {
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
      final double engineeringValue =
          _applySensorFormula(sensor.type, rawReadBack);
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

  Future<void> readSensorValue(list_ds.Receipe sensor) async {
    final id = sensor.id;
    final reg = sensor.regAddress;
    if (id == null || reg == null) return;

    if (!plcService.isConnected.value) {
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Read FAILED: PLC not connected');
      return;
    }

    writeInFlightSensorIds
        .add(id); // reused as a generic "busy" marker for this row
    try {
      int raw;
      try {
        raw = await plcService.readRegister(reg);
      } catch (firstError) {
        print(
            '[PLC READ] ${sensor.sensorName} | Reg $reg | first attempt failed ($firstError), retrying once...');
        await Future.delayed(const Duration(milliseconds: 200));
        raw = await plcService.readRegister(reg);
      }

      final double engineeringValue = _applySensorFormula(sensor.type, raw);
      final String formatted = engineeringValue.toStringAsFixed(2);

      livePlcValues[id] = formatted;

      print(
          '[PLC READ] ${sensor.sensorName} | Reg $reg | Raw=$raw | Value=$formatted');

      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Type: ${sensor.type ?? '-'}  |  Value: $formatted ${sensor.unit ?? ''}'
              .trim());
    } catch (e) {
      livePlcValues[id] = 'ERR';
      print(
          '[PLC READ] ${sensor.sensorName} | Reg $reg | FAILED after retry: $e');
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Read FAILED: $e');
    } finally {
      writeInFlightSensorIds.remove(id);
    }
  }

  Future<void> readAllSensorValues() async {
    if (harnessReceipes.isEmpty) return;

    if (!plcService.isConnected.value) {
      _log('PLC not connected — cannot read values');
      return;
    }

    isReadingPlcValues.value = true;
    _log('Reading ${harnessReceipes.length} sensor value(s) from PLC…');

    try {
      for (final sensor in harnessReceipes) {
        await readSensorValue(sensor);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      isReadingPlcValues.value = false;
      _log('PLC read complete for ${harnessReceipes.length} sensor(s)');
    }
  }

  Future<void> writeAllSensorValues() async {
    if (isWritingAllSensors.value) return; // guard against double-tap
    if (harnessReceipes.isEmpty) return;

    isWritingAllSensors.value = true;
    _log(
        'Writing all ${harnessReceipes.length} sensor value(s) sequentially...');

    try {
      for (final sensor in harnessReceipes) {
        if (sensor.value == null) {
          _log('Skipping ${sensor.sensorName ?? '-'} — no value from server');
          continue;
        }

        final int? value = int.tryParse(sensor.value.toString());
        if (value == null) {
          _log('Invalid value for ${sensor.sensorName}');
          continue;
        }

        currentWritingSensorId.value = sensor.id;
        await writeSensorValue(sensor, value);
        // Small gap between writes — most PLCs can't handle overlapping requests.
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } finally {
      currentWritingSensorId.value = null;
      isWritingAllSensors.value = false;
      _log('✅ Sequential write complete');
    }
  }

  Future<void> writeAllSensorValues1() async {
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

  final RxList<list_ds.Receipe> harnessReceipes = <list_ds.Receipe>[].obs;

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
    harnessRequired = true; // ✅ reset to default (require scan) on ESN change
    livePlcValues.clear();
    isReadingPlcValues.value = false;

    _flashStopwatch?.cancel();
    flashInProgress.value = false;
    flashComplete.value = false;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;

      dtcList.clear();
    pidList.clear();
    iqaWriteStatus.value = '';
    dtcReadStatus.value = '';

    availableFlashFiles.clear();
    _fileToDtcDatasetId.clear();
    _fileToPidDatasetId.clear();
    _fileToEcuId.clear();
    _fileToHexUrl.clear();
    _currentDtcDatasetId = null;
    _currentPidDatasetId = null;
    selectedFlashFile.value = null;
    flashFilesError.value = '';

    esnError.value = '';
    listError.value = '';
    _resolvedVariant = null;
    resolvedListNumber.value = '';
    resolvedHarnessName.value = '';
    currentStepIndex.value = 0;
    canConnectDongle.value = false;
    dongleConnected.value = false;
    _dongleIp = null;
    dongleIp.value = '';
    _dongleRetryTimer?.cancel();
    canConnectDongle.value = false;
    dongleConnected.value = false;
    testbedSessionHistory.clear();
    currentEsn.value = '';

    // ✅ Abandon the previous local session draft — a fresh one will be
    // opened the next time an ESN is successfully validated.
    _currentSessionKey = null;
    _draftFlashStatus = null;
    _draftIqaStatus = null;
    _draftDtcStatus = null;
    _resolvedDatasetType = null;
    _resolvedDatasetFileName = null;
    _sessionReportSent = false; // ✅ next session starts with a clean slate
// ✅ reset so this session's flag doesn't leak forward
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

  final Map<String, String> _fileToHexUrl = {};

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
      _fileToHexUrl.clear();
      var activetDatasets =
          (variant.tDatasetEcu ?? []).where((t) => t.isActive == true).toList();

      bool usingDDataset = false;
      if (activetDatasets.isEmpty) {
        print("No active T-dataset entries — falling back to D-dataset");
        usingDDataset = true;
        activetDatasets = (variant.dDatasetEcu ?? [])
            .where((d) => d.isActive == true && d.isLatest == true)
            .toList();

        if (activetDatasets.isEmpty) {
          print("No active+latest D-dataset entries either");
        }
      }

      for (final t in activetDatasets) {
        final ecuId = t.ecu;
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

        final dataFileUrl = t.dataFile;
        if (dataFileUrl == null || dataFileUrl.isEmpty) continue;

        final fileName = dataFileUrl.split('/').last;
        print(
            "Flash File : $fileName (${usingDDataset ? 'D' : 'T'}-dataset id=${t.id}, isLatest=${t.isLatest})");

        files.add(fileName);
        _fileToEcuId[fileName] = ecuId;
        _fileToHexUrl[fileName] = dataFileUrl;

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

  Future<void> submitStep(int index) async {
    if (index == 0 && currentStepIndex.value != 0) {
      _resetForEsnEdit();
    }
    if (index != currentStepIndex.value) return;
    _idleTimers[index]?.cancel();

    final value = stepControllers[index].text.trim();
    if (value.isEmpty) return;

    final step = steps[index];

    if (step.key == 'list' && value.length != 4) {
      return; // wait for the remaining digits
    }

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
        await _resolveInjectorConfigFromVariant();
        await _resolveHarnessRequirementFromVariant();
        await loadAvailableFlashFilesFromVariant();
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        esnError.value = message;
        _log('Failed to validate ESN: $e');
        _showErrorPopup(message, title: 'ESN Validation Failed');
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

  void _onAllStepsComplete() {
    _log('All scan steps complete.');
  }

  final Map<String, int> _fileToEcuId = {};
  void _tryResolveDatasetInfo() {
    final fileName = selectedFlashFile.value;
    final variant = _resolvedVariant;
    if (fileName == null || variant == null) return;
    if (_resolvedDatasetType != null && _resolvedDatasetFileName != null) {
      return;
    }

    final targetEcuId = _fileToEcuId[fileName];
    if (targetEcuId == null) return;

    final variantEcu = (variant.tDatasetEcu ?? []).firstWhereOrNull(
          (t) => t.ecu == targetEcuId && t.isActive == true,
        ) ??
        (variant.dDatasetEcu ?? []).firstWhereOrNull(
          (d) =>
              d.ecu == targetEcuId && d.isActive == true && d.isLatest == true,
        );
    if (variantEcu == null) return;

    final isFromTDataset =
        (variant.tDatasetEcu ?? []).any((t) => t.id == variantEcu.id);
    _resolvedDatasetType = isFromTDataset ? 'T Dataset' : 'D Dataset';
    _resolvedDatasetFileName = variantEcu.dataFile?.split('/').last;

    _log(
        'Dataset resolved early (before flashing): $_resolvedDatasetType — $_resolvedDatasetFileName');
  }

  void selectFlashFile(String? file) {
    selectedFlashFile.value = file;

    _currentDtcDatasetId = file == null ? null : _fileToDtcDatasetId[file];

    _currentPidDatasetId = file == null ? null : _fileToPidDatasetId[file];

    // ✅ Resolve dataset_type/datafile_name as soon as a file is known —
    // don't wait for Start Flashing.
    _tryResolveDatasetInfo();

    print("Selected File : $file");
    print("DTC Dataset : $_currentDtcDatasetId");
    print("PID Dataset : $_currentPidDatasetId");
  }

  Future<void> saveActivityLog() async {
    try {
      if (activityLog.isEmpty) {
        return;
      }

      final String? selectedDirectory = await getDirectoryPath(
        confirmButtonText: 'Select Folder',
      );

      if (selectedDirectory == null) {
        return;
      }

      final String fileName =
          'ActivityLog_${DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}.txt';

      final File file =
          File('$selectedDirectory${Platform.pathSeparator}$fileName');

      await file.writeAsString(activityLog.join('\n'));

      print("Saved at: ${file.path}");
    } catch (e) {
      print("saveActivityLog error: $e");
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

  Future<void> flushPendingSessionOnExit() async {
    final key = _currentSessionKey;
    if (key == null) return; // nothing in progress

    if (_sessionReportSent) {
      print(
          'Skipping exit-flush — report already sent for this session ($key)');
      return;
    }

    if (_resolvedDatasetType == null ||
        _resolvedDatasetType!.isEmpty ||
        _resolvedDatasetFileName == null ||
        _resolvedDatasetFileName!.isEmpty) {
      print(
          'Skipping exit-flush ($key) — dataset_type/datafile_name not resolved, would be rejected by server');
      return;
    }
    _sessionReportSent = true;

    _log('App closing — attempting to send pending session before exit...');

    try {
      await _authService
          .createTestBedSession(
            esnId: _esnRecordId,
            dongleId: _dongleDbId,
            datasetType: _resolvedDatasetType,
            datafileName: _resolvedDatasetFileName,
            startDate: _flashCycleStartTime ?? DateTime.now(),
            endDate: DateTime.now(),
            flashStatus: _draftFlashStatus ?? 'Fail',
            iqaStatus: _draftIqaStatus ?? 'Fail',
            dtcStatus: _draftDtcStatus ?? 'Fail',
            activityLog: activityLog.toList(),
            accessToken: _accessToken,
          )
          .timeout(const Duration(seconds: 8));

      await PendingSessionStorage.removeDraft(key);
      print('✅ Sent pending session on exit ($key)');
    } catch (e) {
      // ✅ Unlock on failure so a later retry path (next-launch resend) can
      // still attempt to send.
      _sessionReportSent = false;
      print(
          '❌ Could not send pending session on exit ($key): $e — will retry next launch');
    }
  }
  final RxString flashStatus = 'Preparing...'.obs;
  final RxDouble postFlashProgress = 0.0.obs;
  final RxString iqaWriteStatus = ''.obs;
  final RxString dtcReadStatus = ''.obs;
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

    flashErrorMessage.value = '';
    flashComplete.value = false;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;
    flashStatus.value = 'Preparing Flash...';
    postFlashProgress.value = 0;

    // ✅ Keep device awake for the entire flashing operation
    await WakelockPlus.enable();

    try {
      await _withDongleBusy(() async {
        flashInProgress.value = true;
        flashStatus.value = 'Preparing Flash...';
// kept for any UI state that reads it

        _log('Flashing started');

        _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
          flashElapsedSeconds.value++;
        });

        Timer? percentTimer;

        String? result;

        try {
          flashStatus.value = 'Validating vehicle...';

          final variant = _resolvedVariant;

          if (variant == null) {
            throw Exception("Variant not resolved — scan ESN again");
          }

          final targetEcuId = _fileToEcuId[fileName];
          if (targetEcuId == null) {
            throw Exception(
                "Could not resolve ECU for selected file \"$fileName\"");
          }
          final variantEcu = (variant.tDatasetEcu ?? []).firstWhereOrNull(
                (t) => t.ecu == targetEcuId && t.isActive == true,
              ) ??
              (variant.dDatasetEcu ?? []).firstWhereOrNull(
                (d) =>
                    d.ecu == targetEcuId &&
                    d.isActive == true &&
                    d.isLatest == true,
              );
          if (variantEcu == null) {
            throw Exception(
                "Active D-dataset ECU entry not found for selected file");
          }
          final isFromTDataset =
              (variant.tDatasetEcu ?? []).any((t) => t.id == variantEcu.id);
          _resolvedDatasetType = isFromTDataset ? 'T Dataset' : 'D Dataset';
          _resolvedDatasetFileName = variantEcu.dataFile?.split('/').last;

          print("🟣 [DatasetTracking] Selected file: $fileName");
          print(
              "🟣 [DatasetTracking] variantEcu.id: ${variantEcu.id}  →  dataset_type sent: $_resolvedDatasetType");
          print(
              "🟣 [DatasetTracking] variantEcu.dataFile: ${variantEcu.dataFile}");
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
            throw Exception("ECU configuration not found");
          }

          if (selectedEcu.flashFile == null) {
            final fallback = vehicleEcuEntries.firstWhereOrNull(
              (e) => e.ecu?.id == targetEcuId,
            );

            if (fallback?.flashFile != null) {
              selectedEcu = fallback;
            }
          }

          if (selectedEcu!.flashFile == null) {
            throw Exception("Flash file missing");
          }

          final flashConfig = selectedEcu.flashFile!;

          flashStatus.value = 'Configuring ECU...';

          await App.dllFunctions!.setDongleProperties(
            selectedEcu.ecu?.protocol?.name ?? '',
            selectedEcu.ecu?.protocol?.autopeepal ?? '',
            selectedEcu.ecu?.txHeader ?? '',
            selectedEcu.ecu?.rxHeader ?? '',
          );

          flashStatus.value = 'Downloading sequence file...';

          final sequenceContent =
              await _downloadAsRawString(flashConfig.sequenceFile!);

          var ecuMapFiles = flashConfig.ecuMapFile ?? <all_ds.EcuMapFile>[];

          if (ecuMapFiles.isEmpty) {
            ecuMapFiles = _parseEcuMapFilesFromSequence(sequenceContent);
          }

          if (ecuMapFiles.isEmpty) {
            throw Exception(
                "ECU MAP FILE missing — cannot generate flash JSON.");
          }

          flashStatus.value = 'Downloading Dataset...';

          final hexUrl = variantEcu.dataFile ?? _fileToHexUrl[fileName];

          if (hexUrl == null || hexUrl.isEmpty) {
            throw Exception(
                "Hex file URL missing for selected D-dataset entry");
          }

          final hexContent = await _downloadAsRawString(hexUrl);

          flashStatus.value = 'Preparing flash data...';

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

          flashProgress.value = 0;

          flashStatus.value = 'Flashing ECU...';

          percentTimer = Timer.periodic(
            const Duration(
                milliseconds:
                    50), // 2 updates/sec — plenty for a UI progress bar
            (_) async {
              try {
                flashProgress.value = await App.dllFunctions!.flashingData();
              } catch (_) {}
            },
          );

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

        if (result == null || result.isEmpty || result != 'NOERROR') {
          flashInProgress.value = false;

          flashComplete.value = false;
          _log('❌ Flashing failed: $result');
          _draftFlashStatus = 'Fail';

          final r = (result ?? '').toLowerCase();
          final looksDisconnected = r.contains('no resp') ||
              r.contains('socket_closed') ||
              r.contains('noresponsefromecu');

          if (looksDisconnected) {
            dongleConnected.value = false;
            _startDongleRetryTimer();
            _showReconnectPopup();
          }

          flashErrorMessage.value = result ?? 'Unknown error';

          unawaited(_sendPartialSessionReport('flashing failed'));
          return;
        }

        flashComplete.value = true;
        _log('Flashing completed successfully (${formattedElapsed})');

              flashStatus.value = 'Writing IQA Values...';
        final iqaWriteResult = await _autoWriteIqaValues();
        iqaWriteStatus.value = iqaWriteResult;
        // ✅ Track IQA status for the local draft as soon as it's known.
        _draftIqaStatus = iqaWriteResult.toLowerCase().contains('successful')
            ? 'Pass'
            : 'Fail';
        _showFlashCompletePopup(iqaWriteResult);

        flashStatus.value = 'Writing PLC Values...';
        if (harnessReceipes.isNotEmpty && plcService.isConnected.value) {
          await writeAllSensorValues();
        } else {
          _log('Skipping PLC value write — PLC not connected or no '
              'recipe sensors available');
        }

        flashStatus.value = 'Loading DTCs...';
        await _loadDtcResults();

        flashStatus.value = 'Loading PIDs...';
        await _loadPidResults();

        flashStatus.value = 'Completed';

        final flashPassed = result == 'NOERROR';
        _draftFlashStatus = flashPassed ? 'Pass' : 'Fail';
        final iqaPassed = iqaWriteStatus.toLowerCase().contains('successful');
        final startTime = _flashCycleStartTime ?? DateTime.now();
        final endTime = DateTime.now();
        final sessionKeyForSend = _currentSessionKey;

        if (_sessionReportSent) {
          _log(
              'Session report already sent earlier this session — skipping final send');
          flashInProgress.value = false;
          return;
        }
        _sessionReportSent = true;

        print(
            "🟣 [DatasetTracking] About to send — esnId=$_esnRecordId dongleId=$_dongleDbId datasetType=$_resolvedDatasetType");
        _log('Sending test-bed session report to server...');

        unawaited(_authService
            .createTestBedSession(
          esnId: _esnRecordId,
          dongleId: _dongleDbId,
          datasetType: _resolvedDatasetType,
          datafileName: _resolvedDatasetFileName,
          startDate: startTime,
          endDate: endTime,
          flashStatus: flashPassed ? 'Pass' : 'Fail',
          iqaStatus: iqaPassed ? 'Pass' : 'Fail',
          dtcStatus: _draftDtcStatus ?? 'Fail',
          activityLog: activityLog.toList(),
          accessToken: _accessToken,
        )
            .then((_) async {
          _log('✅ Test-bed session report sent successfully');
          if (sessionKeyForSend != null) {
            await PendingSessionStorage.removeDraft(sessionKeyForSend);
          }
        }).catchError((e) {
          // Send failed — allow a later event (heartbeat, exit flush, next
          // launch resend) to retry it instead of leaving it stuck locked.
          _sessionReportSent = false;
          _log('❌ Test-bed session report failed to send: $e');
        }));

        flashInProgress.value = false;
      });
    } finally {
      await WakelockPlus.disable();
    }
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
        dynamic readResult;
        const maxAttempts = 2;

        for (var attempt = 1; attempt <= maxAttempts; attempt++) {
          _log(
              'Reading DTCs from ${ecu.ecuName}... (attempt $attempt/$maxAttempts)');
          readResult = await App.dllFunctions!.readDtc(ecu.readDtcIndex!);

          final status = readResult?.status?.toString();
          final looksBad = readResult == null ||
              (status != 'NO_ERROR' &&
                  (status == null ||
                      status == 'No Resp From Dongle' ||
                      status == 'SOCKET_CLOSED' ||
                      status.toLowerCase().contains('no resp')));

          if (!looksBad) break; // good read — stop retrying

          if (attempt < maxAttempts) {
            _log(
                'DTC read attempt $attempt failed (${readResult?.status ?? "no response"}) '
                '— retrying once before giving up...');
            await Future.delayed(const Duration(milliseconds: 300));
          }
        }
        if (readResult == null) {
          _log(
              'DTC read: ECU_COMMUNICATION_ERROR (after $maxAttempts attempts)');
          dtcList.clear();
          _draftDtcStatus = 'Fail';
          unawaited(
              _sendPartialSessionReport('DTC read: no response from ECU'));
          dongleConnected.value = false;
          _startDongleRetryTimer();
          _showReconnectPopup();
          return;
        }
        if (readResult.status != 'NO_ERROR') {
          _log(
              'DTC read failed: ${readResult.status} (after $maxAttempts attempts)');
          dtcList.clear();
          _draftDtcStatus = 'Fail';
          unawaited(_sendPartialSessionReport('DTC read failed'));
          final statusLower = readResult.status.toString().toLowerCase();
          if (readResult.status == 'No Resp From Dongle' ||
              readResult.status == 'SOCKET_CLOSED' ||
              statusLower.contains('no resp')) {
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
          final code = row[0].toString().toUpperCase();
          final status = row[1].toString();
          final match = serverCodes.firstWhereOrNull(
            (c) => (c.code ?? '').toUpperCase() == code,
          );
          final desc = match?.description ?? 'Description not found';

          dummy[code] = '$code - $desc ($status)';
          final register =
              null; // placeholder — becomes match?.regAddress later
          final registerText = register?.toString() ?? '-';

          dummy[code] = '$code - $desc ($status) [REG:$registerText]';
        }

               dtcList.assignAll(dummy.values.toList());
        _draftDtcStatus = 'Pass';
        dtcReadStatus.value = 'DTC read successful';
        _log('DTC (${dtcList.length}) data loaded');
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        _log('Failed to load DTC dataset: $e');
        dtcList.clear();
        _draftDtcStatus = 'Fail';
        unawaited(_sendPartialSessionReport('DTC read exception'));
        _showErrorPopup(message, title: 'Failed to Load DTC');
      }
    });
  }

  Future<void> refreshDtcResults() => _loadDtcResults();

  Future<void> _clearDTCInternal() async {
    final ecu =
        StaticData.ecuInfo.firstWhereOrNull((e) => e.clearDtcIndex != null);

    if (ecu == null) return;

    await App.dllFunctions!.setDongleProperties(
      ecu.protocol?.name ?? '',
      ecu.protocol?.autopeepal ?? '',
      ecu.txHeader ?? '',
      ecu.rxHeader ?? '',
    );

    _log('Clearing DTCs from ${ecu.ecuName}...');

    final response = await App.dllFunctions!.clearDtc(ecu.clearDtcIndex!);

    if (response == 'NOERROR' || response == 'NO_ERROR') {
      _log('✅ DTC cleared successfully');
      dtcList.clear();
      dtcList.refresh();
    } else {
      _log('❌ Clear DTC failed: $response');
    }
  }

  Future<void> clearDTC() {
    return _withDongleBusy(() async {
      await _clearDTCInternal();
      await _loadDtcResults(); // ✅ immediately re-read DTCs after clearing
    });
  }

  void _showReconnectPopup() {
    Get.dialog(
      AlertDialog(
        title: const Text("Communication Error"),
        content: const Text(
          "Please Reconnect Dongle",
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

        // Builds livePidCodes / selection state for the Run/Play PID feature.
        _buildLivePidGroups(pid);

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

    Future<void> logout() async {
    if (flashInProgress.value) {
      Get.snackbar(
        'Flashing in Progress',
        'Logout is disabled until flashing completes.',
      );
      return;
    }

    final key = _currentSessionKey;
    if (key != null && !_sessionReportSent) {
      await PendingSessionStorage.removeDraft(key);
      print(
          'Logout: discarded unsent draft for session ($key) — this was a normal logout, not an interruption');
    }

    _currentSessionKey = null;
    _draftFlashStatus = null;
    _draftIqaStatus = null;
    _draftDtcStatus = null;
    _resolvedDatasetType = null;
    _resolvedDatasetFileName = null;
    _sessionReportSent = false;

    // Release the PLC connection (and its lock register) on logout so
    // the next session can claim it cleanly.
    await plcService.disconnect();

    _log('Logged out');
    await SecureStorageService.clearAll();
    Get.offAllNamed(Routes.LOGIN);
  }

  // ── Live PID (Play/Run) ──
  final RxList<pid_ds.Code> livePidCodes = <pid_ds.Code>[].obs;
  final RxSet<int> selectedPidCodeIds = <int>{}.obs;
  final RxMap<int, String> livePidValues =
      <int, String>{}.obs; // variable.id -> display value
  final RxBool pidPlaying = false.obs;
  bool _stopPidLoop = false;

  bool get allPidsSelected =>
      livePidCodes.isNotEmpty &&
      livePidCodes.every((c) => selectedPidCodeIds.contains(c.id));

  void _buildLivePidGroups(pid_ds.PidDataset pid) {
    final codes = <pid_ds.Code>[];
    for (final result in pid.results ?? <pid_ds.Result>[]) {
      for (final code in result.codes ?? <pid_ds.Code>[]) {
        if (code.read == true) codes.add(code);
      }
    }
    codes.sort((a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0));
    livePidCodes.assignAll(codes);

    // All PIDs are selected by default — no manual "Select All" step needed.
    selectedPidCodeIds
      ..clear()
      ..addAll(codes.map((c) => c.id!));
    livePidValues.clear();
  }

  void toggleSelectAllPids() {
    if (allPidsSelected) {
      selectedPidCodeIds.clear();
    } else {
      selectedPidCodeIds
        ..clear()
        ..addAll(livePidCodes.map((c) => c.id!));
    }
  }

  void togglePidCodeSelection(int codeId) {
    if (selectedPidCodeIds.contains(codeId)) {
      selectedPidCodeIds.remove(codeId);
    } else {
      selectedPidCodeIds.add(codeId);
    }
  }

  Future<void> togglePidPlayback() async {
    if (pidPlaying.value) {
      // Manual stop mid-run still works if the user taps again.
      _stopPidLoop = true;
      pidPlaying.value = false;
      _log('Live PID read stopped');
      return;
    }

    if (selectedPidCodeIds.isEmpty) {
      _showErrorPopup('No parameters available to run',
          title: 'Nothing to Read');
      return;
    }

    _stopPidLoop = false;
    pidPlaying.value = true;
    _log('Live PID read started (${selectedPidCodeIds.length} parameter(s))');

    final selectedCodes =
        livePidCodes.where((c) => selectedPidCodeIds.contains(c.id)).toList();

    final ok = await _readSelectedPidsOnce(selectedCodes);

    if (!_stopPidLoop) {
      // Ran to completion (wasn't manually stopped mid-read) — auto-stop.
      pidPlaying.value = false;
      if (ok) {
        _log('✅ Live PID read complete');
      } else {
        _log('❌ Live PID read finished with errors');
      }
    }
  }

  Future<bool> _readSelectedPidsOnce(List<pid_ds.Code> codes) async {
    return await _withDongleBusy(() async {
      try {
        final responses = await App.dllFunctions!.readPid(codes);

        if (responses == null) {
          _log('❌ Live PID read: no response from ECU');
          dongleConnected.value = false;
          _startDongleRetryTimer();
          _showReconnectPopup();
          unawaited(
              _sendPartialSessionReport('PID read: no response from ECU'));
          return false;
        }

        bool sawDisconnect = false;

        for (final resp in responses) {
          final code = codes.firstWhereOrNull((c) => c.id == resp.pidId);
          if (code == null) continue;

          if (resp.status == 'NOERROR') {
            for (final variable
                in code.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
              final item = resp.variables
                  .firstWhereOrNull((v) => v.pidNumber == variable.id);
              if (variable.id != null) {
                livePidValues[variable.id!] =
                    item?.responseValue ?? 'Not Found';
              }
            }
          } else {
            for (final variable
                in code.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
              if (variable.id != null) {
                livePidValues[variable.id!] = resp.status ?? 'ERROR';
              }
            }

            final statusLower = (resp.status ?? '').toLowerCase();
            if (statusLower.contains('no resp') ||
                statusLower.contains('socket_closed') ||
                statusLower.contains('noresponsefromecu') ||
                statusLower.contains('no response from dongle')) {
              sawDisconnect = true;
            }
          }
        }

        if (sawDisconnect) {
          _log('❌ Live PID read: dongle appears disconnected');
          dongleConnected.value = false;
          _startDongleRetryTimer();
          _showReconnectPopup();
          unawaited(_sendPartialSessionReport('PID read: dongle disconnected'));
          return false;
        }

        return true;
      } catch (e) {
        _log('❌ Live PID read error: $e');
        dongleConnected.value = false;
        _startDongleRetryTimer();
        _showReconnectPopup();
        unawaited(_sendPartialSessionReport('PID read exception'));
        return false;
      }
    });
  }

  Future<bool> checkDongleStatus() async {
    if (!dongleConnected.value) return false;

    if (isDongleBusy.value) return true;

    if (_dongleIp == null || _dongleIp!.isEmpty) return dongleConnected.value;

    try {
      final stillAlive = await _withDongleBusy(() {
        return _connectionWifi
            .checkStillConnected()
            .timeout(const Duration(seconds: 2));
      });

      if (!stillAlive) {
        _log('❌ Dongle status check failed — connection lost (check wiring)');
        dongleConnected.value = false;
        _startDongleRetryTimer();
        unawaited(
            _sendPartialSessionReport('Dongle heartbeat lost connection'));
        return false;
      }

      return true;
    } catch (e) {
      _log('❌ Dongle status check error: $e — connection lost (check wiring)');
      dongleConnected.value = false;
      _startDongleRetryTimer();
      unawaited(_sendPartialSessionReport('Dongle heartbeat check exception'));
      return false;
    }
  }

  void _startDongleHeartbeat() {
    _dongleHeartbeatTimer?.cancel();
    _dongleHeartbeatTimer =
        Timer.periodic(const Duration(seconds: 5), (_) async {
      await checkDongleStatus();
    });
  }

  @override
  void onClose() {
    WidgetsBinding.instance
        .removeObserver(this); // ✅ clean up lifecycle observer

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

  final Rx<String?> activityLogFilter = Rx<String?>(null);

  void setActivityLogFilter(String? tag) {
    if (tag == null) {
      activityLogFilter.value = null;
      return;
    }
    activityLogFilter.value = (activityLogFilter.value == tag) ? null : tag;
  }

  String _inferLogTag(String message) {
    final m = message.toLowerCase();
    if (m.contains('esn')) return 'ESN';
    if (m.contains('dtc')) return 'DTC';
    if (m.contains('iqa')) return 'IQA';
    if (m.contains('pid')) return 'PID';
    if (m.contains('flash')) return 'FLASH';
    if (m.contains('harness')) return 'HARNESS';
    if (m.contains('plc')) return 'PLC';
    if (m.contains('session started')) return 'SESSION';
    if (m.contains('dongle')) return 'DONGLE';
    return 'All';
  }
}

class _DongleEntry {
  final String? macId;
  final String? ip;
  final bool isActive;
  final List<int> ecuIds;
  final int? dongleDbId;
  _DongleEntry({
    this.macId,
    this.ip,
    this.isActive = false,
    this.ecuIds = const [],
    this.dongleDbId,
  });
}
