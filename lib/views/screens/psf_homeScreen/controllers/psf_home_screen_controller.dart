//Prathmesh Girme
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:ap_dongle_comm/utils/comm_controller_isolate_safe.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/all.models.dart' as all_ds;
import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
import 'package:simpson/modals/esn.model.dart' as esn_ds;
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/modals/liveParameter_model.dart';
import 'package:simpson/modals/pfsLaneRegister.model.dart';
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/modals/pidDataset.model.dart' show Code;
import 'package:simpson/services/apiServices.dart';
import 'package:simpson/services/connectionWifiService.dart';
import 'package:simpson/services/getJson_service.dart';
import 'package:simpson/services/pending_session_storage.dart';
import 'package:simpson/services/plc/plc_service.dart';
import 'package:simpson/services/pfs_isolate_flash.dart';
import 'pfs_lane.dart' hide psfLaneRegisterMap;

String _decodeLatin1Isolate(Uint8List bytes) {
  return latin1.decode(bytes);
}

class PsfHomeScreenController extends GetxController {
  static final HttpClient _sharedHttpClient = HttpClient()
    ..maxConnectionsPerHost = 8
    ..connectionTimeout = const Duration(seconds: 15)
    ..badCertificateCallback = (cert, host, port) =>
        true; // TEMPORARY: same expired-cert bypass as login, until the server's TLS cert is renewed

  Future<String> _downloadAsRawStringFast(String url) async {
    final request = await _sharedHttpClient.getUrl(Uri.parse(url));
    final response = await request.close();

    final builder = BytesBuilder(copy: false);
    await for (final chunk in response) {
      builder.add(chunk);
    }
    final bytes = builder.takeBytes();

    return await compute(_decodeLatin1Isolate, bytes);
  }

  static const int _dongleFlashPort = 6888;
  bool get _anyOtherLaneFlashing =>
      lanes.any((PsfLane l) => l.isFlashing.value);

  final RxnInt expandedLaneIndex = RxnInt(0);

  void expandLane(int index) {
    expandedLaneIndex.value = index;
  }

  void collapseLane() {
    expandedLaneIndex.value = null;
  }

  void logActivity(String entry, dynamic activityLog) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    activityLog.add('[$timestamp] $entry');
    if (activityLog.length > 300) {
      activityLog.removeAt(0);
    }
  }

  Future<void> _resendPendingSessions() async {
    final drafts = PendingSessionStorage.getAllDrafts();
    final pfsDrafts = drafts
        .where((d) => (d['sessionKey'] as String? ?? '').startsWith('pfs_'))
        .toList();
    if (pfsDrafts.isEmpty) return;

    print(
        'Found ${pfsDrafts.length} unsent PFS session report(s) from a previous run — resending...');

    const validStatuses = {'Pass', 'Fail'};
    String sanitizeStatus(dynamic raw) {
      final value = raw as String?;
      return validStatuses.contains(value) ? value! : 'Fail';
    }

    for (final draft in pfsDrafts) {
      final key = draft['sessionKey'] as String?;
      if (key == null) continue;

      final datasetType = draft['datasetType'] as String?;
      final datafileName = draft['datafileName'] as String?;
      if (datasetType == null ||
          datasetType.isEmpty ||
          datafileName == null ||
          datafileName.isEmpty) {
        await PendingSessionStorage.removeDraft(key);
        continue;
      }

      try {
        await _authService.createEolSession(
          esnId: draft['esnId'] as int?,
          dongleId: draft['dongleId'] as int?,
          datasetType: datasetType,
          datafileName: datafileName,
          startDate: DateTime.tryParse(draft['startDate'] as String? ?? '') ??
              DateTime.now(),
          endDate: DateTime.tryParse(draft['endDate'] as String? ?? '') ??
              DateTime.now(),
          continutyStatus: sanitizeStatus(draft['continutyStatus']),
          flashStatus: sanitizeStatus(draft['flashStatus']),
          iqaStatus: sanitizeStatus(draft['iqaStatus']),
          dtcStatus: sanitizeStatus(draft['dtcStatus']),
          activityLog: List<String>.from(draft['activityLog'] as List? ?? []),
          accessToken: _accessToken,
        );
        await PendingSessionStorage.removeDraft(key);
        print('✅ Resent previously unsent PFS session report ($key)');
      } catch (e) {
        print(
            '❌ Failed to resend PFS session report ($key): $e — will retry next launch');
      }
    }
  }

  Future<void> _persistSessionDraft(int laneIndex) async {
    final lane = lanes[laneIndex];
    final key = lane.currentSessionKey;
    if (key == null) return;
    if (lane.sessionReportSent) return;
    if (lane.resolvedDatasetType == null ||
        lane.resolvedDatasetFileName == null) return;

    await PendingSessionStorage.saveDraft(key, {
      'sessionKey': key,
      'esnId': lane.esnRecordId,
      'dongleId': lane.dongleDbId,
      'datasetType': lane.resolvedDatasetType,
      'datafileName': lane.resolvedDatasetFileName,
      'startDate':
          (lane.flashCycleStartTime ?? DateTime.now()).toIso8601String(),
      'endDate': DateTime.now().toIso8601String(),
      'continutyStatus': lane.isHarnessConnected.value ? 'Pass' : 'Fail',
      'flashStatus': lane.draftFlashStatus ?? 'Fail',
      'iqaStatus': lane.draftIqaStatus ?? 'Fail',
      'dtcStatus': lane.draftDtcStatus ?? 'Fail',
      'activityLog': lane.activityLog.toList(),
    });
  }

  Future<void> _sendPartialSessionReport(int laneIndex, String reason) async {
    final lane = lanes[laneIndex];
    final key = lane.currentSessionKey;
    if (key == null) return;
    if (lane.sessionReportSent) return;

    if (lane.resolvedDatasetType == null ||
        lane.resolvedDatasetType!.isEmpty ||
        lane.resolvedDatasetFileName == null ||
        lane.resolvedDatasetFileName!.isEmpty) {
      return;
    }
    lane.sessionReportSent = true;

    lane.logActivity('Sending session report to server ($reason)...');

    try {
      await _authService.createEolSession(
        esnId: lane.esnRecordId,
        dongleId: lane.dongleDbId,
        datasetType: lane.resolvedDatasetType,
        datafileName: lane.resolvedDatasetFileName,
        startDate: lane.flashCycleStartTime ?? DateTime.now(),
        endDate: DateTime.now(),
        continutyStatus: lane.isHarnessConnected.value ? 'Pass' : 'Fail',
        flashStatus: lane.draftFlashStatus ?? 'Fail',
        iqaStatus: lane.draftIqaStatus ?? 'Fail',
        dtcStatus: lane.draftDtcStatus ?? 'Fail',
        activityLog: lane.activityLog.toList(),
        accessToken: _accessToken,
      );
      lane.logActivity('✅ Session report sent successfully ($reason)');
      await PendingSessionStorage.removeDraft(key);
    } catch (e) {
      lane.sessionReportSent = false;
      lane.logActivity(
          '❌ Failed to send session report ($reason): $e — will retry later');
    }
  }

  String? station;
  final RxList<PsfLane> lanes = <PsfLane>[].obs;
  final AuthService _authService = AuthService();
  String? _accessToken;
  final PlcService plcService = Get.find<PlcService>();
  all_ds.AllModel? _modelsCache;
  list_ds.ListNumber? _variantListCache;

  final ConnectionWifi _connectionWifi = ConnectionWifi();

  DateTime? _lastIsolateFlashStart;

  final Set<String> _activeFlashProtocols = {};

  // SendPort each finished-but-not-yet-closed flash isolate gave us, so we
  // can tell it "safe to disconnect now" once no OTHER lane is mid-flash.
  final Map<int, SendPort> _pendingLaneCloseSignal = {};

  // Resolves once THIS lane's flash isolate has confirmed its socket is
  // actually closed. onStartFlash awaits this (not "all lanes done")
  // before reconnecting — so a lane that finishes while nothing else is
  // flashing proceeds immediately, and one that finishes mid-way through
  // another lane's flash only waits for that lane, never longer.
  final Map<int, Completer<void>> _laneFlashTeardownCompleters = {};

  // Call any time a lane's isFlashing flips false, or a controlPort
  // registers. Cheap and idempotent — safe to call liberally.
    void _trySendProceedSignals() {
    if (_pendingLaneCloseSignal.isEmpty) return;
    final ready = <int>[];
    for (final laneNum in _pendingLaneCloseSignal.keys) {
      final lane =
          lanes.firstWhereOrNull((PsfLane l) => l.laneNumber == laneNum);
      if (lane == null) {
        print(
            '   🔸 [proceed-check] Lane $laneNum: no matching PsfLane found — skipping');
        continue;
      }
      if (lane.isFlashing.value) {
        print(
            '   🔸 [proceed-check] Lane $laneNum: still flashing itself — not ready');
        continue;
      }
      // Proceed as soon as THIS lane's own flash is done — no longer
      // waiting for any other lane to finish. Each lane's IQA/DTC now
      // runs immediately after its own flash, independent of others.
      print('   🔸 [proceed-check] Lane $laneNum: its own flash is done — proceeding immediately');
      ready.add(laneNum);
    }
    for (final laneNum in ready) {
      final port = _pendingLaneCloseSignal.remove(laneNum);
      if (port != null) {
        port.send('proceed');
        print('   ✅ [proceed-check] sent proceed signal to Lane $laneNum');
      }
    }
  }

  Future<String?> _runFlashInIsolate({
    required int laneNumber,
    required String host,
    required int port,
    required String protocolName,
    required String protocolHex,
    required String txHeader,
    required String rxHeader,
    required String flashJson,
    required String interpreter,
    required String seedKeyAlgo,
    required void Function(double percent) onProgress,
  }) async {
    final signature = '$protocolHex|$txHeader|$rxHeader';
    while (_activeFlashProtocols.isNotEmpty &&
        !_activeFlashProtocols.contains(signature)) {
      print(
          '   ⏳ [Lane $laneNumber] waiting — a different protocol config is actively flashing on another lane');
      await Future.delayed(const Duration(seconds: 1));
    }
    _activeFlashProtocols.add(signature);

    final receivePort = ReceivePort();
    Isolate? isolate;
    final completer = Completer<String?>();
    final teardownCompleter = Completer<void>();
    _laneFlashTeardownCompleters[laneNumber] = teardownCompleter;

    final sub = receivePort.listen((message) {
      if (message is! PfsFlashMessage) return;
      switch (message.type) {
        case 'progress':
          if (message.percent != null) onProgress(message.percent!);
          break;
        case 'controlPort':
          if (message.controlPort != null) {
            _pendingLaneCloseSignal[laneNumber] = message.controlPort!;
            print(
                '   🔹 [Lane $laneNumber] registered control port — checking if already safe to proceed');
            _trySendProceedSignals();
          }
          break;
        case 'done':
          if (!completer.isCompleted) completer.complete(message.result);
          break;
        case 'error':
          if (!completer.isCompleted) {
            completer.complete(message.result ?? 'ERROR');
          }
          break;
        case 'closed':
          if (!teardownCompleter.isCompleted) teardownCompleter.complete();
          break;
      }
    });

    try {
      final args = PfsFlashArgs(
        host: host,
        port: port,
        protocolName: protocolName,
        protocolHex: protocolHex,
        txHeader: txHeader,
        rxHeader: rxHeader,
        flashJson: flashJson,
        interpreter: interpreter,
        seedKeyAlgo: seedKeyAlgo,
        laneNumber: laneNumber,
      );

      isolate = await Isolate.spawn(
        pfsFlashIsolateEntry,
        [receivePort.sendPort, args],
      );

      return await completer.future;
    } catch (e) {
      print('   ❌ [Lane $laneNumber] isolate spawn/run failed: $e');
      if (!teardownCompleter.isCompleted) teardownCompleter.complete();
      return e.toString();
    } finally {
      final isolateRef = isolate;
      unawaited(() async {
        try {
          await teardownCompleter.future.timeout(const Duration(minutes: 10));
        } catch (_) {
          print(
              '   ⚠️ [Lane $laneNumber] isolate did not confirm socket close in time — killing anyway');
          if (!teardownCompleter.isCompleted) teardownCompleter.complete();
        }
        await sub.cancel();
        receivePort.close();
        isolateRef?.kill(priority: Isolate.beforeNextEvent);
        _activeFlashProtocols.remove(signature);
        _pendingLaneCloseSignal.remove(laneNumber);
        _laneFlashTeardownCompleters.remove(laneNumber);
      }());
    }
  }

  bool get isDongleConnectedAnywhere =>
      lanes.any((PsfLane l) => l.dongleConnected.value || l.isFlashing.value);
  RxBool get isPlcConnected => plcService.isConnected;
  RxBool get isPlcConnecting => plcService.isConnecting;
  RxString get plcStatus => plcService.status;

  final RxList<list_ds.Receipe> harnessReceipes = <list_ds.Receipe>[].obs;
  final RxMap<int, String> livePlcValues = <int, String>{}.obs;
  final RxBool isReadingPlcValues = false.obs;
  final RxBool isWritingAllSensors = false.obs;
  final Rx<int?> currentWritingSensorId = Rx<int?>(null);
  final RxSet<int> writeInFlightSensorIds = <int>{}.obs;

  @override
  void onInit() {
    super.onInit();
    station = Get.arguments is String ? Get.arguments : "PFS Station";
    _loadLanesFromDongleList();
    _loadAccessToken();
    _loadPlcConfig().then((_) => _autoConnectPlc());
    PendingSessionStorage.init().then((_) => _resendPendingSessions());

    debugPrint("PFS Controller Loaded");
  }

  Future<void> _loadLanesFromDongleList() async {
    final raw = await SecureStorageService.getDongleList();
    if (raw == null || raw.isEmpty) {
      debugPrint("PFS: no dongle list found from login — no lanes to show.");
      return;
    }

    try {
      final List<dynamic> decoded = jsonDecode(raw);
      final built = <PsfLane>[];

      for (int i = 0; i < decoded.length; i++) {
        final entry = decoded[i] as Map<String, dynamic>;
        final ecuIdRaw = entry['ecuId'];
        final ecuId = ecuIdRaw is int ? ecuIdRaw : int.tryParse('$ecuIdRaw');

        final lane = PsfLane(
          i + 1,
          dongleIpFromLogin: entry['ip'] as String?,
          expectedEcuId: ecuId,
          macIdFromLogin: entry['macId'] as String?,
        );
        lane.dongleDbId = entry['dongleDbId'] as int?;

        final ecuNameFromLogin = entry['ecuName'] as String?;
        if (ecuNameFromLogin != null && ecuNameFromLogin.isNotEmpty) {
          lane.ecuModelName.value = ecuNameFromLogin;
        }

        built.add(lane);
      }
      lanes.assignAll(built);
      debugPrint(
          "PFS Controller Loaded : ${lanes.length} lane(s) from login dongle list");
    } catch (e) {
      debugPrint("PFS: failed to parse saved dongle list: $e");
    }
  }

  Future<void> _loadAccessToken() async {
    _accessToken = await SecureStorageService.getAccessToken();
  }

  @override
  void onClose() {
    _plcRetryTimer?.cancel();

    for (final comm in _laneCommControllers.values) {
      unawaited(comm.disconnect());
    }
    _laneCommControllers.clear();

    for (final lane in lanes) {
      lane.dispose();
    }

    super.onClose();
  }

  String? _plcIp;
  int _plcPort = 502;
  Timer? _plcRetryTimer;

  Future<void> _loadPlcConfig() async {
    _plcIp = await SecureStorageService.getPlcIp();
    final portStr = await SecureStorageService.getPlcPort();
    _plcPort = int.tryParse(portStr ?? '') ?? 502;
  }

  Future<void> _autoConnectPlc() async {
    if (plcService.isConnected.value || plcService.isConnecting.value) return;
    if (_plcIp == null || _plcIp!.isEmpty) return;
    try {
      await plcService.connect(_plcIp!, port: _plcPort);
      _plcRetryTimer?.cancel();
    } catch (e) {
      debugPrint(
          "PLC connection failed: $e — will keep retrying in the background");
      _startPlcRetryTimer();
    }
  }

  void _startPlcRetryTimer() {
    _plcRetryTimer?.cancel();
    _schedulePlcRetry(const Duration(seconds: 10));
  }

  void _schedulePlcRetry(Duration delay) {
    _plcRetryTimer?.cancel();
    _plcRetryTimer = Timer(delay, () async {
      if (plcService.isConnected.value) return;

      await _autoConnectPlc();

      if (plcService.isConnected.value) return;

      final nextDelay = Duration(seconds: (delay.inSeconds * 2).clamp(10, 60));
      _schedulePlcRetry(nextDelay);
    });
  }

  void onPlcButtonTapped() {
    if (isPlcConnected.value) return;
    _autoConnectPlc();
  }

  void onEsnFieldChanged(int laneIndex) {
    final lane = lanes[laneIndex];
    lane.esnIdleTimer?.cancel();
    lane.esnIdleTimer = Timer(const Duration(seconds: 2), () {
      onScanEsnForLane(laneIndex);
    });
  }

  void _showScanFailedPopup(String title, String message) {
    if (Get.isDialogOpen == true) Get.back();
    Get.dialog(
      CustomPopup(title: title, message: message, confirmText: 'OK'),
      barrierDismissible: true,
    );
  }

  Future<void> onScanEsnForLane(int laneIndex) async {
    final lane = lanes[laneIndex];
    lane.esnIdleTimer?.cancel();
    final esn = lane.esnController.text.trim();

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] ESN SCAN');
    print('   Entered ESN: "$esn"');

    if (esn.isEmpty) {
      print('   ❌ ESN field empty — nothing to scan');
      lane.esnError.value = "Enter ESN";
      return;
    }

    lane.isLookingUpEsn.value = true;
    lane.esnError.value = '';

    try {
      final result = await identifyModel(esn);
      final resolvedEcuId = result.ecuEntry.ecu?.id;

      print(
          '   Resolved ECU id: $resolvedEcuId  |  Lane expects ECU id: ${lane.expectedEcuId}');
      if (lane.expectedEcuId != null && resolvedEcuId != lane.expectedEcuId) {
        print('   ❌ ECU mismatch — this ESN belongs to a different lane');
        throw Exception(
          'This ESN is wired for a different lane (resolved ECU id: '
          '${resolvedEcuId ?? "unknown"}, expected: ${lane.expectedEcuId}).',
        );
      }

      await applyLane(esn, laneIndex, result);

      unawaited(_authService
          .getSessionHistory(esn: esn, accessToken: _accessToken)
          .then((history) {
        final eol = (history['eol_sessions'] as List?) ?? [];
        final testbed = (history['testbed_sessions'] as List?) ?? [];
        print(
            '   History for ESN $esn → ${eol.length} EOL session(s), ${testbed.length} testbed session(s)');

        lane.eolSessionHistory.assignAll(eol.whereType<Map<String, dynamic>>());
        lane.testbedSessionHistory
            .assignAll(testbed.whereType<Map<String, dynamic>>());

        if (eol.isNotEmpty || testbed.isNotEmpty) {
          lane.logActivity(
              'Previous history: ${eol.length} EOL, ${testbed.length} testbed session(s) found');
        }
      }));
      print(
          '   ✅ ESN accepted — model/sub-model/ECU applied to Lane ${lane.laneNumber}');
      print('══════════════════════════════════════════');

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (lane.iqaFocusNodes.isNotEmpty) {
          lane.iqaFocusNodes.first.requestFocus();
        }
      });
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('   ❌ ESN scan failed: $message');
      print('══════════════════════════════════════════');
      lane.esnError.value = message;
      _showScanFailedPopup('ESN Not Recognized', message);
    } finally {
      lane.isLookingUpEsn.value = false;
    }

    if (esn.isNotEmpty) {
      logActivity('ESN scanned: $esn', lane.activityLog);
    }
  }

  Future<all_ds.AllModel> _ensureModels() async {
    if (_modelsCache != null) return _modelsCache!;
    _accessToken ??= await SecureStorageService.getAccessToken();
    _modelsCache = await _authService.getModels(accessToken: _accessToken);
    return _modelsCache!;
  }

  Future<_IdentifiedEcu> identifyModel(
    String esn,
  ) async {
    _accessToken ??= await SecureStorageService.getAccessToken();
    final esnList =
        await _authService.getEsnList(engSlno: esn, accessToken: _accessToken);

    final match = (esnList.results ?? <esn_ds.Result>[]).firstWhereOrNull(
      (r) => (r.engSlno ?? '').trim().toUpperCase() == esn.toUpperCase(),
    );

    if (match == null) {
      throw Exception('ESN not recognized. Please rescan.');
    }
    if (match.isActive != true) {
      throw Exception('ESN is not active.');
    }

    final variant = match.prodbudVariant;
    if (variant == null) {
      throw Exception('This ESN has no vehicle variant assigned.');
    }

    final vehicleModelId = variant.vehicleModel;
    final subModelId = variant.subModel;

    print('   ESN catalog match → vehicleModelId=$vehicleModelId '
        'subModelId=$subModelId variantId=${variant.id}');

    if (vehicleModelId == null || subModelId == null) {
      throw Exception('ESN variant is missing vehicle model/sub-model.');
    }

    final allModel = await _ensureModels();

    all_ds.Result? matchedModel;
    all_ds.SubModel? matchedSubModel;

    for (final result in allModel.results ?? <all_ds.Result>[]) {
      if (result.id != vehicleModelId) continue;
      matchedModel = result;
      for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
        if (subModel.id == subModelId) {
          matchedSubModel = subModel;
          break;
        }
      }
      break;
    }

    if (matchedModel == null || matchedSubModel == null) {
      throw Exception('No matching model/sub-model found in catalog '
          '(vehicleModelId=$vehicleModelId, subModelId=$subModelId).');
    }

    final ecuEntry = matchedSubModel.submodelModelecu?.firstOrNull;
    if (ecuEntry == null) {
      throw Exception('No ECU configuration found for this model/sub-model.');
    }

    print('   Models catalog match → vehicleModel.id=${matchedModel.id} '
        'subModel.id=${matchedSubModel.id} ecu.id=${ecuEntry.ecu?.id} '
        'ecu.name=${ecuEntry.ecu?.name}');
    String? flashFileUrl;
    String? resolvedDatasetType;
    final expectedEcuId = ecuEntry.ecu?.id;

    final dMatches = (variant.dDatasetEcu ?? [])
        .where((e) => e.ecu == expectedEcuId)
        .toList();
    if (dMatches.isNotEmpty) {
      final chosen = dMatches.firstWhereOrNull((e) => e.isLatest == true) ??
          dMatches.first;
      flashFileUrl = chosen.dataFile;
      resolvedDatasetType = 'D Dataset';
    }

    if (flashFileUrl == null || flashFileUrl.isEmpty) {
      final tMatches = (variant.tDatasetEcu ?? [])
          .where((e) => e.ecu == expectedEcuId)
          .toList();
      if (tMatches.isNotEmpty) {
        final chosen = tMatches.firstWhereOrNull((e) => e.isLatest == true) ??
            tMatches.first;
        flashFileUrl = chosen.dataFile;
        resolvedDatasetType = 'T Dataset';
      }
    }

    print(
        '   Flash file resolved → $flashFileUrl (datasetType=$resolvedDatasetType)');

    return _IdentifiedEcu(
      ecuEntry: ecuEntry,
      vehicleModelId: matchedModel.id,
      subModelId: matchedSubModel.id,
      flashFileUrl: flashFileUrl,
      resolvedDatasetType: resolvedDatasetType,
      esnRecordId: match.id,
      variantCode: variant.variantCode,
      harnesses: variant.prodbudVariantHarness,
    );
  }

  Future<void> applyLane(
    String esn,
    int laneIndex,
    _IdentifiedEcu identified,
  ) async {
    final ecuEntry = identified.ecuEntry;
    final lane = lanes[laneIndex];

    lane.harnessTimer?.cancel();

    lane.isTargetLane.value = true;
    lane.isLocked.value = false;
    lane.isLedOn.value = true;
    lane.isHarnessConnected.value = false;
    lane.esn.value = esn;

    lane.matchedEcu = ecuEntry;
    lane.matchedVehicleModelId = identified.vehicleModelId;
    lane.matchedSubModelId = identified.subModelId;
    lane.esnRecordId = identified.esnRecordId;
    lane.resolvedDatasetType = identified.resolvedDatasetType;
    lane.listNumber.value = identified.variantCode ?? '';

    final activeHarness = (identified.harnesses ?? []).firstWhereOrNull(
      (h) =>
          h.isActive == true &&
          (h.stationType ?? '').trim().toLowerCase() == 'pfs',
    );
    harnessReceipes.assignAll(activeHarness?.receipes ?? []);
    if (activeHarness != null) {
      lane.logActivity(
          'Harness resolved: "${activeHarness.name}" (${harnessReceipes.length} recipe sensor(s))');
    }

    lane.resolvedFlashFileUrl.value = identified.flashFileUrl;
    lane.resolvedFlashFileName.value = identified.flashFileUrl?.split('/').last;
    lane.resolvedDatasetFileName = identified.flashFileUrl?.split('/').last;
    lane.flashCycleStartTime = DateTime.now();
       lane.currentSessionKey =
        'pfs_lane${lane.laneNumber}_esn${identified.esnRecordId}_${lane.flashCycleStartTime!.millisecondsSinceEpoch}';
    lane.sessionReportSent = false;
    lane.logActivity('Session started for ESN $esn (key: ${lane.currentSessionKey})');
    lane.ecuModelName.value = ecuEntry.ecu?.name ?? 'Unknown Model';
    lane.dtcDatasetId.value = ecuEntry.datasets?.firstOrNull?.id;
    lane.pidDatasetId.value = ecuEntry.pidDatasets?.firstOrNull?.id;
    lane.resolvedFlashFileUrl.value = identified.flashFileUrl;
    lane.resolvedFlashFileName.value = identified.flashFileUrl?.split('/').last;

    final injectorCount = ecuEntry.noOfInjectors ?? 4;
    final firingOrder = (ecuEntry.firingSequence ?? '')
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
    lane.configureIqaFields(
      injectorCount.clamp(1, 8),
      firingSequence: firingOrder.length == injectorCount ? firingOrder : null,
    );

    print(
        '   Lane ${lane.laneNumber} configured: ecuModelName="${lane.ecuModelName.value}" '
        'dtcDatasetId=${lane.dtcDatasetId.value} pidDatasetId=${lane.pidDatasetId.value} '
        'injectorCount=$injectorCount firingOrder=$firingOrder');
    print(
        '   Lane ${lane.laneNumber}: triggering dongle auto-connect at ${lane.dongleIpFromLogin}');
    unawaited(connectDongleForLane(laneIndex));

    if (plcService.isConnected.value && laneIndex < psfLaneRegisterMap.length) {
      try {
        await plcService.writeRegister(
          psfLaneRegisterMap[laneIndex].ledOutputRegister,
          1,
        );
      } catch (e) {
        debugPrint(
          "LED Error : $e",
        );
      }
    }

    if (laneIndex < psfLaneRegisterMap.length) {
      lane.harnessTimer = Timer.periodic(
        const Duration(
          milliseconds: 800,
        ),
        (timer) {
          checkHarness(
            laneIndex,
          );
        },
      );
    }
  }

  double _applySensorFormula(String? type, int raw) => raw.toDouble();

  Future<void> writeSensorValue(list_ds.Receipe sensor, int value) async {
    final id = sensor.id;
    final reg = sensor.regAddress;
    if (id == null || reg == null) return;
    if (!plcService.isConnected.value) return;

    writeInFlightSensorIds.add(id);
    try {
      final confirmed = await plcService.writeRegister(reg, value);
      if (!confirmed) return;
      final raw = await plcService.readRegister(reg);
      livePlcValues[id] =
          _applySensorFormula(sensor.type, raw).toStringAsFixed(2);
    } catch (_) {
      // leave as-is on failure; UI shows last-known value
    } finally {
      writeInFlightSensorIds.remove(id);
    }
  }

  Future<void> readSensorValue(list_ds.Receipe sensor) async {
    final id = sensor.id;
    final reg = sensor.regAddress;
    if (id == null || reg == null) return;
    if (!plcService.isConnected.value) return;

    writeInFlightSensorIds.add(id);
    try {
      int raw;
      try {
        raw = await plcService.readRegister(reg);
      } catch (_) {
        await Future.delayed(const Duration(milliseconds: 200));
        raw = await plcService.readRegister(reg);
      }
      livePlcValues[id] =
          _applySensorFormula(sensor.type, raw).toStringAsFixed(2);
    } catch (_) {
      livePlcValues[id] = 'ERR';
    } finally {
      writeInFlightSensorIds.remove(id);
    }
  }

  Future<void> readAllSensorValues() async {
    if (harnessReceipes.isEmpty || !plcService.isConnected.value) return;
    isReadingPlcValues.value = true;
    try {
      for (final sensor in harnessReceipes) {
        await readSensorValue(sensor);
        await Future.delayed(const Duration(milliseconds: 50));
      }
    } finally {
      isReadingPlcValues.value = false;
    }
  }

  Future<void> writeAllSensorValues() async {
    if (isWritingAllSensors.value || harnessReceipes.isEmpty) return;
    isWritingAllSensors.value = true;
    try {
      for (final sensor in harnessReceipes) {
        if (sensor.value == null) continue;
        final value = int.tryParse(sensor.value.toString());
        if (value == null) continue;
        currentWritingSensorId.value = sensor.id;
        await writeSensorValue(sensor, value);
        await Future.delayed(const Duration(milliseconds: 150));
      }
    } finally {
      currentWritingSensorId.value = null;
      isWritingAllSensors.value = false;
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

  void onListNumberFieldChanged(int laneIndex) {
    final lane = lanes[laneIndex];
    lane.listNumberIdleTimer?.cancel();
    lane.listNumberIdleTimer = Timer(const Duration(seconds: 2), () {
      onScanListNumberForLane(laneIndex);
    });
  }

  Future<void> onScanListNumberForLane(int laneIndex) async {
    final lane = lanes[laneIndex];
    lane.listNumberIdleTimer?.cancel();
    final scanned = lane.listNumberController.text.trim();

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] LIST NUMBER SCAN');
    print('   Entered List Number: "$scanned"');

    if (scanned.isEmpty) {
      print('   ❌ List Number field empty — nothing to scan');
      print('══════════════════════════════════════════');
      lane.listNumberError.value = "Enter List Number";
      return;
    }

    if (lane.matchedEcu == null) {
      print(
          '   ❌ ESN not scanned yet for this lane — cannot resolve List Number');
      print('══════════════════════════════════════════');
      lane.listNumberError.value = "Scan ESN first";
      return;
    }

    lane.isLookingUpListNumber.value = true;
    lane.listNumberError.value = '';
    lane.flashFilesError.value = '';

    try {
      final expectedEcuId = lane.matchedEcu!.ecu?.id;
      final expectedVehicleModelId = lane.matchedVehicleModelId;
      final expectedSubModelId = lane.matchedSubModelId;

      print('🔍 [ListNumber] scanned="$scanned" '
          'expectedEcuId=$expectedEcuId '
          'expectedVehicleModelId=$expectedVehicleModelId '
          'expectedSubModelId=$expectedSubModelId');

      bool tryResolve(list_ds.ListNumber list) {
        String leadingToken(String raw) {
          final match = RegExp(r'^[A-Za-z0-9.]+').firstMatch(raw.trim());
          return (match?.group(0) ?? raw.trim()).toUpperCase();
        }

        final scannedToken = leadingToken(scanned);

        final variant = (list.results ?? []).firstWhereOrNull(
          (r) => leadingToken(r.variantCode ?? '') == scannedToken,
        );

        if (variant == null) {
          print('🔴 [ListNumber] no variant_code matched token "$scannedToken" '
              'among: ${(list.results ?? []).map((r) => r.variantCode).join(', ')}');
          return false;
        }

        print('🟢 [ListNumber] variant_code matched: id=${variant.id} '
            'vehicleModel=${variant.vehicleModel} subModel=${variant.subModel} '
            'dDatasetEcu=${variant.dDatasetEcu?.map((e) => 'ecu=${e.ecu}/active=${e.isActive}').join(',')}');
        if (expectedVehicleModelId != null &&
            variant.vehicleModel != expectedVehicleModelId) {
          print('🔴 [ListNumber] vehicleModel mismatch: variant has '
              '${variant.vehicleModel}, expected $expectedVehicleModelId');
          return false;
        }
        if (expectedSubModelId != null &&
            variant.subModel != expectedSubModelId) {
          print('🔴 [ListNumber] subModel mismatch: variant has '
              '${variant.subModel}, expected $expectedSubModelId');
          return false;
        }
        String? fileUrl;

        final dMatch = (variant.dDatasetEcu ?? [])
            .firstWhereOrNull((e) => e.ecu == expectedEcuId);
        fileUrl = dMatch?.dataFile;

        if (fileUrl == null || fileUrl.isEmpty) {
          final tMatch = (variant.tDatasetEcu ?? [])
              .firstWhereOrNull((e) => e.ecu == expectedEcuId);
          fileUrl = tMatch?.dataFile;
        }

        if (fileUrl == null || fileUrl.isEmpty) {
          final vMatch = (variant.variantEcu ?? [])
              .firstWhereOrNull((e) => e.ecu == expectedEcuId);
          fileUrl = vMatch?.dataFile?.dataFile;
        }

        if (fileUrl == null || fileUrl.isEmpty) {
          print('🔴 [ListNumber] variant matched model/submodel but no ECU '
              'entry (d/t/variant) has ecu=$expectedEcuId with a data_file');
          return false;
        }

        print('🟢 [ListNumber] resolved fileUrl=$fileUrl');

        lane.listNumber.value = scanned;
        lane.resolvedFlashFileUrl.value = fileUrl;
        lane.resolvedFlashFileName.value = fileUrl.split('/').last;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (lane.iqaFocusNodes.isNotEmpty) {
            lane.iqaFocusNodes.first.requestFocus();
          }
        });
        return true;
      }

      final cached = await _ensureVariantList();
      if (tryResolve(cached)) {
        print(
            '   ✅ List Number accepted — flash file resolved for Lane ${lane.laneNumber}');
        print('══════════════════════════════════════════');
        return;
      }

      final fresh = await _ensureVariantList(forceRefresh: true);
      if (tryResolve(fresh)) {
        print(
            '   ✅ List Number accepted (after refresh) — flash file resolved for Lane ${lane.laneNumber}');
        print('══════════════════════════════════════════');
        return;
      }

      throw Exception(
        'No flash file found for List Number "$scanned" matching this '
        'lane\'s vehicle model/sub-model and ECU.',
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      print('   ❌ List Number scan failed: $message');
      print('══════════════════════════════════════════');
      lane.listNumberError.value = message;
      _showScanFailedPopup('List Number Not Found', message);
    } finally {
      lane.isLookingUpListNumber.value = false;
    }
  }

  Future<void> connectDongleForLane(int laneIndex) async {
    final lane = lanes[laneIndex];
    _dongleRetryAttempts[laneIndex] = 0;

    print('══════════════════════════════════════════');
    print(
        '🔹 [Lane ${lane.laneNumber}] DONGLE CONNECT (independent connection)');
    print(
        '   IP: ${lane.dongleIpFromLogin}  ecu.id: ${lane.matchedEcu?.ecu?.id}');

    if (lane.dongleConnected.value) {
      print('   ⏭️ already connected — skipping');
      print('══════════════════════════════════════════');
      return;
    }

    if (lane.dongleConnecting.value || lane.isDongleBusy) {
      print(
          '   ⚠️ dongle marked busy/connecting — forcing a clean retry anyway');
      lane.dongleConnecting.value = false;
      lane.isDongleBusy = false;
    }

    final ip = lane.dongleIpFromLogin;
    if (ip == null || ip.isEmpty) {
      print('   ❌ no dongle IP on record from login');
      print('══════════════════════════════════════════');
      lane.dongleError.value =
          'No dongle IP on record for this lane from login.';
      return;
    }

    final ecu = lane.matchedEcu;
    if (ecu == null) {
      print('   ❌ no ECU resolved yet — scan ESN first');
      print('══════════════════════════════════════════');
      lane.dongleError.value = 'Scan ESN first —.';
      return;
    }

    lane.dongleConnecting.value = true;
    lane.dongleError.value = '';

    try {
      final channelParts = ecu.ecu?.channel?.split('-');
      final channelId = (channelParts != null && channelParts.length > 1)
          ? '0${channelParts[1]}'
          : '00';

      print(
          '   Connecting to $ip (channelId=$channelId) — own independent socket…');
      final connected =
          await _connectionWifi.connectDongleForLane(ip, channelId: channelId);

      if (connected == null) {
        print('   ❌ connectDongleForLane returned null — connect failed');
        print('══════════════════════════════════════════');
        lane.dongleError.value = 'Failed to connect to dongle at $ip.';
        lane.dongleConnected.value = false;
        _startDongleRetryTimer(laneIndex);
        return;
      }

      print('   ✅ Connected. MAC: ${connected.macId}');
      lane.dllFunctions = connected.dll;
      _laneCommControllers[laneIndex] = connected.comm;

      await lane.dllFunctions!.setDongleProperties(
        ecu.ecu?.protocol?.name ?? '',
        ecu.ecu?.protocol?.autopeepal ?? '',
        ecu.ecu?.txHeader ?? '',
        ecu.ecu?.rxHeader ?? '',
      );

      print('   ✅ Dongle ready — configured for ${ecu.ecu?.name}');
      print('══════════════════════════════════════════');
      lane.dongleConnected.value = true;
      lane.dongleRetryTimer?.cancel();
    } catch (e) {
      print('   ❌ Dongle connect exception: $e');
      print('══════════════════════════════════════════');
      lane.dongleError.value = e.toString().replaceFirst('Exception: ', '');
      lane.dongleConnected.value = false;
      lane.dllFunctions = null;
      _startDongleRetryTimer(laneIndex);
    } finally {
      lane.dongleConnecting.value = false;
    }
  }

  final Map<int, CommControllerIsolateSafe> _laneCommControllers = {};

  final Map<int, int> _dongleRetryAttempts = {};

  void _startDongleRetryTimer(int laneIndex) {
    final lane = lanes[laneIndex];
    lane.dongleRetryTimer?.cancel();
    _dongleRetryAttempts[laneIndex] = 0;
    _scheduleDongleRetry(laneIndex, const Duration(seconds: 3));
  }

  void _scheduleDongleRetry(int laneIndex, Duration delay) {
    final lane = lanes[laneIndex];
    lane.dongleRetryTimer?.cancel();
    lane.dongleRetryTimer = Timer(delay, () async {
      if (lane.dongleConnected.value) return;

      await connectDongleForLane(laneIndex);

      if (lane.dongleConnected.value) {
        _dongleRetryAttempts[laneIndex] = 0;
        return;
      }

      final attempts = (_dongleRetryAttempts[laneIndex] ?? 0) + 1;
      _dongleRetryAttempts[laneIndex] = attempts;

      if (attempts >= 5) {
        print(
            '   🛑 [Lane ${lane.laneNumber}] Giving up after $attempts failed reconnect attempts.');
        print(
            '   🛑 This looks like a hung/crashed dongle, not a software issue —');
        print(
            '   🛑 the OS could not even open a new TCP connection to it. Please');
        print(
            '   🛑 physically power-cycle Lane ${lane.laneNumber}\'s dongle, then tap the reconnect button.');
        try {
          if (Get.isDialogOpen == true) Get.back();
          Get.dialog(
            CustomPopup(
              title: 'Lane ${lane.laneNumber} dongle unresponsive',
              message:
                  'Power-cycle the dongle, then tap reconnect. Auto-retry stopped after $attempts failed attempts.',
              confirmText: 'OK',
            ),
            barrierDismissible: true,
          );
        } catch (_) {}
        return;
      }

      final nextDelay = Duration(seconds: (delay.inSeconds * 2).clamp(10, 60));
      _scheduleDongleRetry(laneIndex, nextDelay);
    });
  }

  // Future<void> releaseDongleForLane(int laneIndex) async {
  //   lanes[laneIndex].dongleConnected.value = false;
  //   lanes[laneIndex].dongleRetryTimer?.cancel();
  //   lanes[laneIndex].dllFunctions = null;

  //   final comm = _laneCommControllers.remove(laneIndex);
  //   if (comm != null) {
  //     try {
  //       await comm.disconnect();
  //     } catch (e) {
  //       debugPrint('releaseDongleForLane: disconnect error: $e');
  //     }
  //   }
  // }

Future<void> releaseDongleForLane(int laneIndex) async {
  final lane = lanes[laneIndex];

  print(
    '🔌 [Lane ${lane.laneNumber}] '
    'Releasing normal dongle connection',
  );

  // ONLY this lane
  lane.dongleConnected.value = false;

  // ONLY this lane's retry timer
  lane.dongleRetryTimer?.cancel();
  lane.dongleRetryTimer = null;

  // ONLY this lane's DLL
  lane.dllFunctions = null;

  // ONLY this lane's communication controller
  final comm = _laneCommControllers.remove(laneIndex);

  if (comm == null) {
    print(
      'ℹ️ [Lane ${lane.laneNumber}] '
      'No normal communication controller found',
    );
    return;
  }

  try {
    print(
      '🔌 [Lane ${lane.laneNumber}] '
      'Disconnecting normal connection...',
    );

    await comm.disconnect();

    print(
      '✅ [Lane ${lane.laneNumber}] '
      'Normal connection released',
    );
  } catch (e, stackTrace) {
    print(
      '⚠️ [Lane ${lane.laneNumber}] '
      'Disconnect error: $e',
    );

    print(stackTrace);
  }
}
//===================================================================================

  Future<void> reconnectDongleWithFeedback(int laneIndex) async {
    final lane = lanes[laneIndex];

    if (lane.dongleConnected.value) return;

    await connectDongleForLane(laneIndex);

    if (Get.isDialogOpen == true) Get.back();

    if (!lane.dongleConnected.value) {
      _showScanFailedPopup(
        'Reconnect Failed',
        'Could not reconnect to Lane ${lane.laneNumber}\'s dongle at ${lane.dongleIpFromLogin}. '
            'If this keeps happening, try power-cycling the dongle.',
      );
    }
  }

  void onIqaFieldChanged(int laneIndex, int iqaIndex) {
    final lane = lanes[laneIndex];

    lane.refreshIqaAllFilled();

    lane.iqaIdleTimers[iqaIndex]?.cancel();
    lane.iqaIdleTimers[iqaIndex] = Timer(const Duration(milliseconds: 500), () {
      _submitIqaField(laneIndex, iqaIndex);
    });
  }

  void _submitIqaField(int laneIndex, int iqaIndex) {
    final lane = lanes[laneIndex];
    final value = lane.iqaControllers[iqaIndex].text.trim();
    if (value.isEmpty) return;

    print('🔹 [Lane ${lane.laneNumber}] IQA ${iqaIndex + 1} entered: "$value"  '
        '(${lane.filledIqaCount.value}/${lane.iqaControllers.length} filled)');

    if (iqaIndex < lane.iqaFocusNodes.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lane.iqaFocusNodes[iqaIndex + 1].requestFocus();
      });
    } else if (lane.iqaAllFilled.value) {
      print(
          '   ✅ All IQA fields filled for Lane ${lane.laneNumber} — ready for flash file box');
    }
  }

  Future<void> checkHarness(
    int index,
  ) async {
    if (!plcService.isConnected.value) return;
    if (index >= psfLaneRegisterMap.length) return;

    final register = psfLaneRegisterMap[index];

    try {
      final result = await plcService.readRegister(
        register.harnessConnectedInputRegister,
      );

      lanes[index].isHarnessConnected.value = result == 1;
    } catch (e) {
      debugPrint(
        "Harness Error : $e",
      );
    }
  }

  void resetLane(int laneIndex) async {
    final lane = lanes[laneIndex];
    lane.resetToUnlockedIdle();

    await releaseDongleForLane(laneIndex);
    await Future.delayed(const Duration(seconds: 2));
    unawaited(connectDongleForLane(laneIndex));
  }

  Future<void> onStartFlash(
    int index,
  ) async {
    final lane = lanes[index];

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] START FLASH');
    print('   Flash file URL: ${lane.resolvedFlashFileUrl.value}');
    print(
        '   Dongle connected: ${lane.dongleConnected.value}  has own dllFunctions: ${lane.dllFunctions != null}');

    if (lane.isFlashing.value) {
      print('   ⏭️ already flashing — ignoring tap');
      print('══════════════════════════════════════════');
      return;
    }

    if (lane.resolvedFlashFileUrl.value == null) {
      print('   ❌ no flash file resolved — scan List Number first');
      print('══════════════════════════════════════════');
      if (Get.isDialogOpen == true) Get.back();
      Get.dialog(
        CustomPopup(
          title: 'Flash',
          message: 'Scan a List Number first to resolve the flash file.',
          confirmText: 'OK',
        ),
        barrierDismissible: true,
      );
      return;
    }

    if (!lane.dongleConnected.value || lane.dllFunctions == null) {
      print('   ❌ this lane\'s dongle isn\'t connected — cannot flash');
      print('══════════════════════════════════════════');
      if (Get.isDialogOpen == true) Get.back();
      Get.dialog(
        CustomPopup(
          title: 'Flash',
          message: 'Connect the dongle for this lane first.',
          confirmText: 'OK',
        ),
        barrierDismissible: true,
      );
      return;
    }

    if (lane.isDongleBusy) {
      print(
          '   ⏭️ this lane\'s dongle is busy with another operation (Live Parameter read, DTC read, etc) — cannot flash yet');
      print('══════════════════════════════════════════');
      if (Get.isDialogOpen == true) Get.back();
      Get.dialog(
        CustomPopup(
          title: 'Flash',
          message:
              'This lane\'s dongle is busy — wait for the current operation to finish.',
          confirmText: 'OK',
        ),
        barrierDismissible: true,
      );
      return;
    }

    lane.isDongleBusy = true;

    final ip = lane.dongleIpFromLogin;
    if (ip == null || ip.isEmpty) {
      print('   ❌ no dongle IP on record for this lane — cannot flash');
      print('══════════════════════════════════════════');
      lane.flashStatus.value = "Flash Failed: no dongle IP on record";
      lane.isDongleBusy = false;
      return;
    }

    lane.isFlashing.value = true;
    lane.flashStatus.value = "Flashing Started";
    lane.flashProgress.value = 0;
    lane.flashElapsedSeconds.value = 0;
    lane.flashStopwatch?.cancel();
    lane.flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
      lane.flashElapsedSeconds.value++;
    });

    String? result;

    try {
      final hexUrl = lane.resolvedFlashFileUrl.value!;
      final ecuEntry = lane.matchedEcu;

      if (ecuEntry == null || ecuEntry.flashFile == null) {
        throw Exception("Flash file configuration missing");
      }

      final flashConfig = ecuEntry.flashFile!;

      print(
          '   ECU: ${ecuEntry.ecu?.name}  protocol: ${ecuEntry.ecu?.protocol?.name}');
      print('   Downloading sequence file + firmware hex in parallel…');
      final results = await Future.wait([
        _downloadAsRawStringFast(flashConfig.sequenceFile!),
        _downloadAsRawStringFast(hexUrl),
      ]);
      final sequenceContent = results[0];
      final hexContent = results[1];

      var ecuMapFiles = flashConfig.ecuMapFile ?? <all_ds.EcuMapFile>[];
      if (ecuMapFiles.isEmpty) {
        ecuMapFiles = _parseEcuMapFilesFromSequence(sequenceContent);
      }
      if (ecuMapFiles.isEmpty) {
        throw Exception("ECU MAP FILE missing — cannot generate flash JSON.");
      }
      print('   ECU map file entries: ${ecuMapFiles.length}');

      final flashJson = await _readJson(
        ecuMapFiles,
        flashConfig.flashCheckSumType?.toString() ?? '',
        Uint8List.fromList(hexContent.codeUnits),
      );

      if (flashJson.isEmpty) {
        throw Exception("Flash JSON generation failed");
      }
      print(
          '   Flash JSON generated (${flashJson.length} chars) — starting flash on its own isolate…');

      print('   Releasing main-isolate connection before handoff to isolate…');
      await releaseDongleForLane(index);
      await Future.delayed(const Duration(seconds: 2));

      result = await _runFlashInIsolate(
        laneNumber: lane.laneNumber,
        host: ip,
        port: _dongleFlashPort,
        protocolName: ecuEntry.ecu?.protocol?.name ?? '',
        protocolHex: ecuEntry.ecu?.protocol?.autopeepal ?? '',
        txHeader: ecuEntry.ecu?.txHeader ?? '',
        rxHeader: ecuEntry.ecu?.rxHeader ?? '',
        flashJson: flashJson,
        interpreter: sequenceContent,
        seedKeyAlgo: ecuEntry.ecu?.seedkeyalgoFnIndex?.value ?? '',
        onProgress: (percent) {
          lane.flashProgress.value = percent;
        },
      );
      print('   [Lane ${lane.laneNumber}] isolate flash result: $result');
    } catch (e) {
      print('   ❌ Flash exception: $e');
      result = e.toString();
    }

    lane.flashStopwatch?.cancel();
    lane.isFlashing.value = false;
    print(
        '   🔹 [Lane ${lane.laneNumber}] isFlashing set false — checking pending close signals');
    _trySendProceedSignals();

    if (result == null || result.isEmpty || result != 'NOERROR') {
      print('   ❌ Flash FAILED: $result  (elapsed ${lane.formattedElapsed})');
      print(
          '   ⚠️ Lane ${lane.laneNumber}\'s dongle was released before flashing — reconnecting');
      lane.dongleConnected.value = false;
      lane.dllFunctions = null;
      _startDongleRetryTimer(index);

      print('══════════════════════════════════════════');
      lane.flashStatus.value = "Flash Failed: $result";
      lane.logActivity(
          'SESSION SUMMARY — Flash: Fail ($result)  |  IQA: Fail  |  DTC: Fail');

      lane.draftFlashStatus = 'Fail';
      lane.draftIqaStatus = 'Fail';
      lane.draftDtcStatus = 'Fail';
      await _persistSessionDraft(index);
      await _sendPartialSessionReport(index, 'flash failed: $result');

      lane.isDongleBusy = false;
      return;
    }

    print(
        '   ✅ Flash COMPLETED in ${lane.formattedElapsed} — letting dongle settle before reconnecting…');
    print('══════════════════════════════════════════');
    lane.flashProgress.value = 1;
    lane.flashStatus.value = "Flash Completed";

    lane.isPostFlashProcessing.value = true;
    lane.isReconnectingAfterFlash.value = true;

    final teardown = _laneFlashTeardownCompleters[lane.laneNumber];
    if (teardown != null && !teardown.isCompleted) {
      print(
          '   ⏳ [Lane ${lane.laneNumber}] waiting for its own flash socket to close gracefully before reconnecting...');
      final waitStart = DateTime.now();
      await teardown.future;
      final waited = DateTime.now().difference(waitStart).inSeconds;
      if (waited > 0) {
        print(
            '   ⏳ [Lane ${lane.laneNumber}] waited ${waited}s for its flash socket to close');
      }
    }

    await Future.delayed(const Duration(seconds: 2));

    lane.isDongleBusy = false;

    int attempt = 0;
    final reconnectDeadline = DateTime.now().add(const Duration(minutes: 3));
    while (DateTime.now().isBefore(reconnectDeadline)) {
      attempt++;
      await connectDongleForLane(index);
      if (lane.dongleConnected.value && lane.dllFunctions != null) {
        print(
            '   ✅ [Lane ${lane.laneNumber}] reconnected after flash on attempt $attempt');
        break;
      }
      print(
          '   ⚠️ [Lane ${lane.laneNumber}] reconnect attempt $attempt failed — retrying in 5s...');
      await Future.delayed(const Duration(seconds: 5));
    }

    lane.isDongleBusy = true;
    lane.isReconnectingAfterFlash.value = false;

    if (!lane.dongleConnected.value || lane.dllFunctions == null) {
      print(
          '   ⚠️ [Lane ${lane.laneNumber}] could not reconnect after flash — skipping DTC/PID/IQA steps');
      lane.flashStatus.value = "Flash Completed (reconnect failed)";
      lane.isPostFlashProcessing.value = false;
      lane.isDongleBusy = false;
      return;
    }

       lane.iqaWriteStatus.value = await autoWriteIqaValuesForLane(index);

    await Future.delayed(const Duration(milliseconds: 500));
    await readLiveDtcForLane(index);

    await Future.delayed(const Duration(milliseconds: 300));
    await loadPidForLane(index);

    lane.isPostFlashProcessing.value = false;
    final flashPassed = result == 'NOERROR';
    final iqaPassed =
        lane.iqaWriteStatus.value.toLowerCase().contains('successful');
    final dtcPassed = lane.dtcError.value.isEmpty;
    final continutyPassed = lane.isHarnessConnected.value;

    final startTime = lane.flashCycleStartTime ?? DateTime.now();
    final endTime = DateTime.now();
    String fmtTime(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:${t.second.toString().padLeft(2, '0')}';

    lane.logActivity(
      'SESSION SUMMARY — Start ${fmtTime(startTime)}  End ${fmtTime(endTime)}  |  '
      'Flash: ${flashPassed ? "Pass" : "Fail"}  '
      'IQA: ${iqaPassed ? "Pass" : "Fail"}  '
      'DTC: ${dtcPassed ? "Pass" : "Fail"}  '
      'Continuity: ${continutyPassed ? "Pass" : "Fail"}',
    );

    lane.draftFlashStatus = flashPassed ? 'Pass' : 'Fail';
    lane.draftIqaStatus = iqaPassed ? 'Pass' : 'Fail';
    lane.draftDtcStatus = dtcPassed ? 'Pass' : 'Fail';
    await _persistSessionDraft(index);

    await _sendPartialSessionReport(index, 'flash cycle completed');

    lane.isDongleBusy = false;
  }

  Future<String> _downloadAsRawString(String url) async {
    final client = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes =
        await response.fold<List<int>>(<int>[], (p, c) => p..addAll(c));
    client.close();
    return latin1.decode(bytes);
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

  Future<String> _readJson(
    List<all_ds.EcuMapFile> ecuMapFiles,
    String checksumAlgo,
    Uint8List hexBytes,
  ) async {
    try {
      return await compute(
        convertHexToJsonIsolate,
        HexToJsonArgs(
            streamBytes: hexBytes,
            ecuMapFiles: ecuMapFiles,
            checksumAlgo: checksumAlgo),
      );
    } catch (e) {
      return "";
    }
  }

  Future<void> loadDtcForLane(
    int index,
  ) async {
    final lane = lanes[index];

    if (lane.dtcDatasetId.value == null) {
      lane.dtcError.value = "DTC dataset not available";

      return;
    }

    try {
      lane.isLoadingDtc.value = true;
      lane.dtcError.value = '';

      _accessToken ??= await SecureStorageService.getAccessToken();
      final result = await _authService.getDtcDataset(
        id: lane.dtcDatasetId.value!,
        accessToken: _accessToken,
      );

      final List<DtcCode> codes = (result.results ?? [])
          .expand<DtcCode>((item) => item.dtcCode ?? [])
          .toList();

      lane.dtcCodes.assignAll(
        codes,
      );
    } catch (e) {
      lane.dtcError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      lane.isLoadingDtc.value = false;
    }
  }

  Future<void> onOpenDtc(
    int index,
  ) async {
    await loadDtcForLane(
      index,
    );
  }

  Future<void> readLiveDtcForLane(int laneIndex) async {
    final lane = lanes[laneIndex];

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] DTC READ (live ECU)');

    if (lane.dllFunctions == null || lane.matchedEcu == null) {
      print('   ❌ dongle not connected for this lane — cannot read DTCs');
      print('══════════════════════════════════════════');
      lane.dtcError.value = 'Connect the dongle for this lane first.';
      return;
    }

    final ecu = lane.matchedEcu!.ecu;
    if (ecu?.readDtcFnIndex?.value == null) {
      print('   ❌ no read_dtc_index configured for this ECU');
      print('══════════════════════════════════════════');
      lane.dtcError.value = 'No DTC read function configured for this ECU.';
      return;
    }

    lane.isClearingDtc.value = true;
    lane.dtcError.value = '';
    try {
      if (lane.dtcCodes.isEmpty) {
        await loadDtcForLane(laneIndex);
      }

      await lane.dllFunctions!.setDongleProperties(
        ecu?.protocol?.name ?? '',
        ecu?.protocol?.autopeepal ?? '',
        ecu?.txHeader ?? '',
        ecu?.rxHeader ?? '',
      );

      print('   Reading DTCs from ${ecu?.name}...');
      final readResult =
          await lane.dllFunctions!.readDtc(ecu!.readDtcFnIndex!.value!);

      if (readResult == null) {
        print('   ❌ DTC read: ECU_COMMUNICATION_ERROR');
        print('══════════════════════════════════════════');
        lane.dtcReadResults.clear();
        lane.dongleConnected.value = false;
        lane.dllFunctions = null;
        _startDongleRetryTimer(laneIndex);
        return;
      }

      if (readResult.status != 'NO_ERROR') {
        print('   ❌ DTC read failed: ${readResult.status}');
        print('══════════════════════════════════════════');
        lane.dtcReadResults.clear();
        final statusText = readResult.status.toString().toLowerCase();
        if (statusText.contains('no resp') ||
            statusText.contains('socket_closed')) {
          lane.dongleConnected.value = false;
          lane.dllFunctions = null;
          _startDongleRetryTimer(laneIndex);
        }
        lane.dtcError.value = readResult.status ?? 'DTC read failed';
        return;
      }

      final rows = readResult.dtcs ?? [];
      final merged = <String, String>{};

      for (final row in rows) {
        if (row.length < 2) continue;
        final code = row[0].toString().toUpperCase();
        final status = row[1].toString();

                final match = lane.dtcCodes.firstWhereOrNull(
          (c) => (c.code ?? '').toUpperCase() == code,
        );
        final desc = match?.description ?? 'Description not found';
        final relatedSensor = match?.relatedSensor;
        final sensorTag = (relatedSensor != null && relatedSensor.isNotEmpty)
            ? ' [SENSOR:$relatedSensor]'
            : '';

        merged[code] = '$code - $desc ($status)$sensorTag';
      }

      lane.dtcReadResults.assignAll(merged.values.toList());
      print('   ✅ DTC read complete (${lane.dtcReadResults.length} code(s))');
      print('══════════════════════════════════════════');
    } catch (e) {
      print('   ❌ DTC read exception: $e');
      print('══════════════════════════════════════════');
      lane.dtcError.value = e.toString().replaceFirst('Exception: ', '');
      lane.dtcReadResults.clear();
    } finally {
      lane.isReadingDtc.value = false;
    }
  }

  Future<void> clearDtcForLane(int laneIndex) async {
    final lane = lanes[laneIndex];

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] CLEAR DTC');

    if (lane.dllFunctions == null || lane.matchedEcu == null) {
      print('   ❌ dongle not connected for this lane — cannot clear DTCs');
      print('══════════════════════════════════════════');
      lane.dtcError.value = 'Connect the dongle for this lane first.';
      return;
    }

    final ecu = lane.matchedEcu!.ecu;
    if (ecu?.clearDtcFnIndex?.value == null) {
      print('   ❌ no clear_dtc_fn_index configured for this ECU');
      print('══════════════════════════════════════════');
      lane.dtcError.value = 'No Clear DTC function configured for this ECU.';
      return;
    }

    lane.isReadingDtc.value = true;
    lane.dtcError.value = '';

    try {
      await lane.dllFunctions!.setDongleProperties(
        ecu?.protocol?.name ?? '',
        ecu?.protocol?.autopeepal ?? '',
        ecu?.txHeader ?? '',
        ecu?.rxHeader ?? '',
      );

      print('   Clearing DTCs on ${ecu?.name}...');
      final status =
          await lane.dllFunctions!.clearDtc(ecu!.clearDtcFnIndex!.value!);

      print('   Clear DTC status: $status');

      if (status == null) {
        print('   ❌ Clear DTC: no response from ECU');
        print('══════════════════════════════════════════');
        lane.dtcError.value = 'Clear DTC failed: no response from ECU.';
        lane.isReadingDtc.value = false;
        return;
      }

      final statusText = status.toLowerCase();
      if (statusText.contains('no resp') ||
          statusText.contains('socket_closed')) {
        print('   ⚠️ Clear DTC failure looks like a dead connection');
        lane.dongleConnected.value = false;
        lane.dllFunctions = null;
        lane.isReadingDtc.value = false;
        _startDongleRetryTimer(laneIndex);
        lane.dtcError.value = 'Dongle disconnected during Clear DTC.';
        print('══════════════════════════════════════════');
        return;
      }

      if (status != 'NOERROR') {
        print('   ❌ Clear DTC failed: $status');
        print('══════════════════════════════════════════');
        lane.dtcError.value = 'Clear DTC failed: $status';
        lane.isReadingDtc.value = false;
        return;
      }

      print('   ✅ Clear DTC succeeded — re-reading to confirm...');
      print('══════════════════════════════════════════');
    } catch (e) {
      print('   ❌ Clear DTC exception: $e');
      print('══════════════════════════════════════════');
      lane.dtcError.value = e.toString().replaceFirst('Exception: ', '');
      lane.isReadingDtc.value = false;
      return;
    }

    await readLiveDtcForLane(laneIndex);
  }

  Future<String> autoWriteIqaValuesForLane(int laneIndex) async {
    final lane = lanes[laneIndex];

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] IQA WRITE');

    try {
      if (lane.iqaParameterCodes.isEmpty) {
        await loadPidForLane(laneIndex);
      }

      final iqaPid = lane.iqaParameterCodes.firstOrNull;
      if (iqaPid == null) {
        print('   ⏭️ IQA PID not found — skipping write');
        print('══════════════════════════════════════════');
        return 'IQA write skipped: IQA PID not found';
      }

      for (int i = 0; i < lane.iqaControllers.length; i++) {
        final value = lane.iqaControllers[i].text.trim();
        if (value.length != 7) {
          print(
              '   ⏭️ ${lane.iqaLabelFor(i)} is not 7 characters — skipping write');
          print('══════════════════════════════════════════');
          return 'IQA write skipped: enter a valid 7-character value for each cylinder';
        }
      }

      List<pid_ds.PiCodeVariables> variables =
          List<pid_ds.PiCodeVariables>.from(iqaPid.piCodeVariable ?? []);
      variables.sort((a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0));

      final order = lane.firingOrder;
      if (order != null && order.length == variables.length) {
        variables = order.map((e) => variables[int.parse(e) - 1]).toList();
      }

      final writeInput = Uint8List(iqaPid.totalLen ?? 0);
      final List<VariantDataLists> variantList = [];

      final int loopCount = variables.length < lane.iqaControllers.length
          ? variables.length
          : lane.iqaControllers.length;

      for (int i = 0; i < loopCount; i++) {
        final variable = variables[i];
        final value = lane.iqaControllers[i].text.trim().toUpperCase();
        final bytes = latin1.encode(value);

        final start = variable.bytePosition! - 1;
        final end = start + bytes.length;

        if (start < 0 || end > writeInput.length) {
          print('   ❌ byte range [$start,$end) out of bounds for writeInput '
              'length ${writeInput.length} (variable=${variable.shortName})');
          print('══════════════════════════════════════════');
          return 'IQA write failed: byte layout mismatch for this ECU — '
              'check PID dataset for ${variable.shortName}';
        }

        writeInput.setRange(start, end, bytes);

        variantList.add(VariantDataLists(
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
        ));
      }

      final int startByte =
          variantList.map((e) => e.startByte!).reduce((a, b) => a < b ? a : b);

      final ecu = lane.matchedEcu?.ecu;
      if (ecu?.writeDataFnIndex?.value == null) {
        print('   ⏭️ ECU write function not configured — skipping');
        print('══════════════════════════════════════════');
        return 'IQA write skipped: ECU configuration not found';
      }

      final dll = lane.dllFunctions;
      if (dll == null) {
        print('   ❌ dongle not connected for this lane — cannot write IQA');
        print('══════════════════════════════════════════');
        return 'IQA write failed: dongle not connected';
      }

      final pid = WriteParameterPid(
        writePamIndex: ecu?.writeDataFnIndex?.value,
        seedKeyIndex: ecu?.seedkeyalgoFnIndex?.value,
        writePid: iqaPid.writePid,
        writeParaDataSize: iqaPid.totalLen,
        writeInput: writeInput,
        pid: iqaPid.code,
        totalLen: iqaPid.totalLen,
        totalBytes: iqaPid.totalLen,
        startByte: startByte,
        variantList: variantList,
      );

      const maxRetries = 4;
      const initialDelay = Duration(seconds: 2);
      var delay = initialDelay;

      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        print('   Writing IQA values to ECU... (attempt $attempt/$maxRetries)');

        final response =
            await dll.writePid(ecu!.writeDataFnIndex!.value!, [pid]);
        final status = response?.first.status?.toUpperCase();

        if (response != null && response.isNotEmpty && status == "NOERROR") {
          print('   ✅ IQA write successful');
          print('══════════════════════════════════════════');
          return 'IQA write: Successful';
        }

        if (status != null && status.contains('REQUIREDTIMEDELAYNOTEXPIRED')) {
          print(
              '   ⏳ ECU not ready yet — waiting ${delay.inSeconds}s before retry '
              '${attempt + 1}/$maxRetries');
          await Future.delayed(delay);
          delay *= 2;
          continue;
        }

        final failMsg = (response == null || response.isEmpty)
            ? "No response from ECU"
            : (response.first.status ?? "Write Failed");
        print('   ❌ IQA write failed: $failMsg');
        print('══════════════════════════════════════════');
        return 'IQA write failed: $failMsg';
      }

      print('   ❌ IQA write failed: ECU still busy after $maxRetries attempts');
      print('══════════════════════════════════════════');
      return 'IQA write failed: requiredTimeDelayNotExpired (gave up after retries)';
    } catch (e) {
      print('   ❌ IQA auto-write exception: $e');
      print('══════════════════════════════════════════');
      return 'IQA write failed: $e';
    }
  }

  Future<void> loadPidForLane(
    int index,
  ) async {
    final lane = lanes[index];

    if (lane.pidDatasetId.value == null) {
      lane.pidError.value = "PID dataset not available";
      return;
    }

    try {
      lane.isLoadingPid.value = true;
      lane.pidError.value = '';

      _accessToken ??= await SecureStorageService.getAccessToken();
      final result = await _authService.getPidDataset(
        id: lane.pidDatasetId.value!,
        accessToken: _accessToken,
      );

      final List<Code> codes = (result.results ?? [])
          .expand<Code>((item) => item.codes ?? [])
          .toList();

      lane.applyPidCodes(
        codes,
      );
    } catch (e) {
      lane.pidError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      lane.isLoadingPid.value = false;
    }
  }

  Future<void> onOpenLiveParameter(
    int index,
  ) async {
    await loadPidForLane(
      index,
    );
  }

  Future<void> togglePidPlaybackForLane(int laneIndex) async {
    final lane = lanes[laneIndex];

    if (lane.pidPlaying.value) {
      lane.stopPidLoop = true;
      lane.pidPlaying.value = false;
      print('🔹 [Lane ${lane.laneNumber}] Live PID read stopped');
      return;
    }

    if (lane.dllFunctions == null) {
      if (Get.isDialogOpen == true) Get.back();
      Get.dialog(
        CustomPopup(
          title: 'Live Parameter',
          message: 'Connect the dongle for this lane first.',
          confirmText: 'OK',
        ),
        barrierDismissible: true,
      );
      return;
    }

    if (lane.liveParameterCodes.isEmpty) {
      if (Get.isDialogOpen == true) Get.back();
      Get.dialog(
        CustomPopup(
          title: 'Live Parameter',
          message: 'No parameters available to run.',
          confirmText: 'OK',
        ),
        barrierDismissible: true,
      );
      return;
    }

    if (lane.isDongleBusy) {
      if (Get.isDialogOpen == true) Get.back();
      Get.dialog(
        CustomPopup(
          title: 'Live Parameter',
          message:
              'This lane\'s dongle is busy with another operation — try again shortly.',
          confirmText: 'OK',
        ),
        barrierDismissible: true,
      );
      return;
    }

    lane.stopPidLoop = false;
    lane.pidPlaying.value = true;
    lane.isDongleBusy = true;

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] LIVE PID READ');
    print('   Parameters: ${lane.liveParameterCodes.length}');

    final ok = await _readLivePidOnceForLane(
        laneIndex, lane.liveParameterCodes.toList());
    lane.isDongleBusy = false;

    if (!lane.stopPidLoop) {
      lane.pidPlaying.value = false;
      print(ok
          ? '   ✅ Live PID read complete'
          : '   ❌ Live PID read finished with errors');
      print('══════════════════════════════════════════');
    }
  }

  Future<bool> _readLivePidOnceForLane(
      int laneIndex, List<pid_ds.Code> codes) async {
    final lane = lanes[laneIndex];
    final dll = lane.dllFunctions;
    if (dll == null) return false;

    try {
      final responses = await dll.readPid(codes);

      if (responses == null) {
        print('   ❌ Live PID read: no response from ECU');
        return false;
      }

      for (final resp in responses) {
        final code = codes.firstWhereOrNull((c) => c.id == resp.pidId);
        if (code == null) continue;

        if (resp.status == 'NOERROR') {
          for (final variable
              in code.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
            final item = resp.variables
                .firstWhereOrNull((v) => v.pidNumber == variable.id);
            if (variable.id != null) {
              lane.livePidValues[variable.id!] =
                  item?.responseValue ?? 'Not Found';
            }
          }
        } else {
          for (final variable
              in code.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
            if (variable.id != null) {
              lane.livePidValues[variable.id!] = resp.status ?? 'ERROR';
            }
          }
        }
      }

      return true;
    } catch (e) {
      print('   ❌ Live PID read error: $e');
      return false;
    }
  }

  void onToggleInjector(
    int laneIndex,
    int injectorIndex,
  ) {
    final lane = lanes[laneIndex];

    if (lane.isLocked.value) return;

    if (injectorIndex < lane.injectorStatus.length) {
      lane.injectorStatus[injectorIndex] = !lane.injectorStatus[injectorIndex];

      lane.injectorStatus.refresh();
    }
  }

  void onToggleIqa(
    int laneIndex,
    int iqaIndex,
  ) {
    final lane = lanes[laneIndex];

    if (lane.isLocked.value) return;

    if (iqaIndex < lane.iqaStatus.length) {
      lane.iqaStatus[iqaIndex] = !lane.iqaStatus[iqaIndex];

      lane.iqaStatus.refresh();
    }
  }

  void onRefreshLane(
    int index,
  ) {
    if (index >= lanes.length) return;

    lanes[index].isLedOn.toggle();
  }

  void logout() {
    final flashingLanes =
        lanes.where((PsfLane l) => l.isFlashing.value).toList();
    if (flashingLanes.isNotEmpty) {
      final laneNumbers =
          flashingLanes.map((PsfLane l) => l.laneNumber).join(', ');
      final label = flashingLanes.length == 1 ? 'Lane' : 'Lanes';
      if (Get.isDialogOpen == true) Get.back();
      Get.dialog(
        CustomPopup(
          title: 'Flashing in Progress',
          message:
              '$label $laneNumbers ${flashingLanes.length == 1 ? 'is' : 'are'} still flashing. '
              'Please wait for it to finish before logging out — logging out now '
              'could interrupt the flash and leave the ECU in a bad state.',
          confirmText: 'OK',
        ),
        barrierDismissible: true,
      );
      return;
    }

    // Release the PLC connection (and its lock register) so the next
    // station/session can claim it cleanly, instead of leaving this
    // session's ownership token sitting in the lock register.
    unawaited(plcService.disconnect());

    Get.offAllNamed("/login");

    Get.delete<PsfHomeScreenController>(force: true);
  }
}

class _IdentifiedEcu {
  final all_ds.SubmodelModelecu ecuEntry;
  final int? vehicleModelId;
  final int? subModelId;
  final String? flashFileUrl;
  final String? resolvedDatasetType;
  final int? esnRecordId;
  final String? variantCode;
  final List<esn_ds.ProdbudVariantHarness>? harnesses;

  _IdentifiedEcu({
    required this.ecuEntry,
    required this.vehicleModelId,
    required this.subModelId,
    this.flashFileUrl,
    this.resolvedDatasetType,
    this.esnRecordId,
    this.variantCode,
    this.harnesses,
  });
}
