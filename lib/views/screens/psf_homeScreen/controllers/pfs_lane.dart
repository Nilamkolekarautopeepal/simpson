//Prathmesh Girme
import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:simpson/utils/ui_helper.dart/dllFunctions.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
import 'package:simpson/modals/all.models.dart' show SubmodelModelecu;

import 'package:simpson/modals/pidDataset.model.dart'
    show Code, MessageType, PiCodeVariables;
import 'package:simpson/views/screens/psf_homeScreen/views/activity_log_tag.dart';

    //   String? indicatorRegAddr;
    // dynamic ecuRegAddr;

 class PsfLane {
  PsfLane(
    this.laneNumber, {
    this.dongleIpFromLogin,
    this.expectedEcuId,
    this.macIdFromLogin,
  }) {
    // ── Dongle ──
        // ══════════════════ DONGLE ══════════════════
    ever(dongleConnected, (bool connected) {
      final ip = dongleIpFromLogin ?? 'unknown IP';
      logActivity(connected ? 'Dongle connected ($ip)' : 'Dongle disconnected ($ip)');
    });
    ever(dongleConnecting, (bool connecting) {
      if (connecting) logActivity('Connecting to dongle at ${dongleIpFromLogin ?? "unknown IP"}...');
    });
    ever(dongleError, (String v) {
      if (v.isNotEmpty) logActivity('Dongle error: $v');
    });
    ever(isReconnectingAfterFlash, (bool reconnecting) {
      if (reconnecting) logActivity('Reconnecting to dongle after flash...');
    });

    // ══════════════════ ESN ══════════════════
    ever(esn, (String v) {
      if (v.isNotEmpty) logActivity('ESN scanned: $v');
    });
    ever(esnError, (String v) {
      if (v.isNotEmpty) logActivity('ESN error: $v');
    });
    ever(listNumber, (String v) {
      if (v.isNotEmpty) logActivity('List Number: $v');
    });
    ever(ecuModelName, (String v) {
      if (v.isNotEmpty && v != 'ECU MODEL NAME') logActivity('Model resolved: $v');
    });
    ever(resolvedFlashFileName, (String? v) {
      if (v != null && v.isNotEmpty) logActivity('Flash file resolved: $v');
    });

    // ══════════════════ HARNESS ══════════════════
    ever(isHarnessConnected, (bool connected) {
      logActivity(connected ? 'Harness connected — continuity OK' : 'Harness disconnected — continuity lost');
    });

    // ══════════════════ IQA ══════════════════
    for (int i = 0; i < iqaControllers.length; i++) {
      final index = i;
      iqaControllers[index].addListener(() {
        final value = iqaControllers[index].text.trim();
        if (value.length == 7) {
          logActivity('${iqaLabelFor(index)} entered: $value');
        }
      });
    }
    ever(filledIqaCount, (int count) {
      if (count == iqaControllers.length && count > 0) {
        logActivity('All $count IQA value(s) entered');
      }
    });
    ever(iqaWriteStatus, (String v) {
      if (v.isNotEmpty) logActivity(v);
    });

    // ══════════════════ FLASH ══════════════════
    ever(isFlashing, (bool flashing) {
      logActivity(flashing ? 'Flashing started' : 'Flashing stopped');
    });
    ever(flashStatus, (String v) {
      if (v.isNotEmpty) logActivity(v);
    });
    ever(isPostFlashProcessing, (bool processing) {
      if (processing) logActivity('Post-flash processing started (IQA write + DTC read)');
    });

    // ══════════════════ DTC ══════════════════
    ever(isReadingDtc, (bool reading) {
      if (reading) logActivity('Reading DTCs...');
    });
    ever(isClearingDtc, (bool clearing) {
      if (clearing) logActivity('Clearing DTCs...');
    });
    ever(dtcError, (String v) {
      if (v.isNotEmpty) logActivity('DTC error: $v');
    });
    ever(dtcReadResults, (List<String> results) {
      logActivity('DTC read complete: ${results.length} code(s) found');
    });

    // ══════════════════ PID (Live Parameter) ══════════════════
    ever(pidPlaying, (bool playing) {
      logActivity(playing ? 'Live Parameter read started' : 'Live Parameter read stopped');
    });
    ever(pidError, (String v) {
      if (v.isNotEmpty) logActivity('PID error: $v');
    });
  }
  final RxList<Map<String, dynamic>> eolSessionHistory =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> testbedSessionHistory =
      <Map<String, dynamic>>[].obs;
  final String? dongleIpFromLogin;
  final int? expectedEcuId;
  final String? macIdFromLogin;

  String? currentSessionKey;
  bool sessionReportSent = false;
  String? draftFlashStatus;
  String? draftIqaStatus;
  String? draftDtcStatus;

  // ===============================
  // LANE NUMBER
  // ===============================

  final int laneNumber;

  // ===============================
  // ECU INFORMATION
  // ===============================

  final RxString ecuModelName = "ECU MODEL NAME".obs;

  final RxString esn = "".obs;
  final TextEditingController esnController = TextEditingController();
  final FocusNode esnFocusNode = FocusNode();
  final RxBool isLookingUpEsn = false.obs;

  final RxString esnError = "".obs;
  final RxBool isClearingDtc = false.obs;

  final RxList<String> activityLog = <String>[].obs;

  // void logActivity(String entry) {
  //   final timestamp = DateTime.now().toIso8601String().substring(11, 19);
  //   activityLog.add('[$timestamp] $entry');
  //   if (activityLog.length > 300) {
  //     activityLog.removeAt(0);
  //   }
  // }

  void logActivity(String entry) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    final tag = ActivityLogTag.infer(entry);
    activityLog.add('[$timestamp] [$tag] $entry');
    if (activityLog.length > 300) {
      activityLog.removeAt(0);
    }
  }

Future<bool> saveActivityLog() async {
    try {
      if (activityLog.isEmpty) return false;

      final documentsDir = await getApplicationDocumentsDirectory();
      final activityDir = Directory('${documentsDir.path}/ActivityLog');

      if (!await activityDir.exists()) {
        await activityDir.create(recursive: true);
      }

      final fileName =
          'Lane${laneNumber}_ActivityLog_${DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}.txt';

      final file = File('${activityDir.path}/$fileName');
      await file.writeAsString(activityLog.join('\n'));

      print('Activity log saved: ${file.path}');
      return true;
    } catch (e) {
      print('Failed to save activity log: $e');
      return false;
    }
  }
  /// Auto-scan debounce — no SCAN button anymore; typing pauses for
  /// 2s then submits automatically.
  Timer? esnIdleTimer;
  Timer? listNumberIdleTimer;

  final TextEditingController listNumberController = TextEditingController();
  final FocusNode listNumberFocusNode = FocusNode();
  final RxBool isLookingUpListNumber = false.obs;
  final RxString listNumberError = "".obs;
  final RxString listNumber = "".obs;

  final Rx<String?> resolvedFlashFileUrl = Rx<String?>(null);
  final Rx<String?> resolvedFlashFileName = Rx<String?>(null);

  /// Own harness-poll timer per lane, since lanes now run independently.
  Timer? harnessTimer;

  /// Ticks flashElapsedSeconds up once per second while flashing.
  Timer? flashStopwatch;

  final Rxn<int> dtcDatasetId = Rxn<int>();

  final Rxn<int> pidDatasetId = Rxn<int>();

  SubmodelModelecu? matchedEcu;

  int? matchedVehicleModelId;
  int? matchedSubModelId;

  // For EOL session reporting
  int? esnRecordId;
  String?
      resolvedDatasetType; // "D Dataset" or "T Dataset" — the actual label the server now expects
  String? resolvedDatasetFileName;
    int? dongleDbId;
  dynamic indicatorRegAddr;
  dynamic ecuRegAddr;
  DateTime? flashCycleStartTime;


    int? get indicatorRegAddrNum => indicatorRegAddr is int
      ? indicatorRegAddr as int
      : int.tryParse(indicatorRegAddr?.toString() ?? '');

  int? get ecuRegAddrNum => ecuRegAddr is int
      ? ecuRegAddr as int
      : int.tryParse(ecuRegAddr?.toString() ?? '');
  // ===============================
  // PLC / HARNESS STATUS
  // ===============================

  final RxBool isLedOn = false.obs;

  final RxBool isLocked = false.obs;

  final RxBool isTargetLane = false.obs;

  final RxBool isHarnessConnected = false.obs;

  // ===============================
  // DONGLE
  // ===============================

  final RxBool dongleConnected = false.obs;
  DLLFunctions? dllFunctions;
  final RxBool dongleConnecting = false.obs;
  bool isDongleBusy = false;
  final RxString dongleError = "".obs;
  Timer? dongleRetryTimer;

  // ===============================
  // INJECTOR / IQA
  // ===============================

  final RxList<bool> injectorStatus = <bool>[
    false,
    false,
    false,
    false,
  ].obs;

  List<TextEditingController> iqaControllers =
      List.generate(4, (_) => TextEditingController());
  List<FocusNode> iqaFocusNodes = List.generate(4, (_) => FocusNode());
  List<Timer?> iqaIdleTimers = List.generate(4, (_) => null);
  final RxBool iqaAllFilled = false.obs;

  final RxInt filledIqaCount = 0.obs;
  List<String>? firingOrder;

  final RxList<bool> iqaStatus = <bool>[
    false,
    false,
    false,
    false,
  ].obs;

  String get iqaStatusText {
    final total = iqaStatus.length;

    final completed = iqaStatus
        .where(
          (value) => value,
        )
        .length;

    return "$completed / $total confirmed";
  }

  void configureIqaFields(int count, {List<String>? firingSequence}) {
    firingOrder = firingSequence;

    // If the injector count hasn't actually changed (e.g. re-scanning
    // the same ESN on an already-configured lane — completely normal
    // in real use), there's nothing to rebuild. Disposing and
    // recreating FocusNodes unconditionally on every scan was racing
    // against currently-mounted TextFields still attached to them,
    // since GetX's Obx rebuild happens on the next frame, not
    // synchronously — that race is exactly what crashes here.
    if (count == iqaControllers.length) {
      for (final c in iqaControllers) {
        c.clear();
      }
      for (final t in iqaIdleTimers) {
        t?.cancel();
      }
      iqaIdleTimers = List.generate(count, (_) => null);
      iqaAllFilled.value = false;
      filledIqaCount.value = 0;
      injectorStatus.assignAll(List.generate(count, (_) => false));
      iqaStatus.assignAll(List.generate(count, (_) => false));
      return;
    }

    // Count genuinely changed — swap in new lists first so the next
    // rebuild has valid nodes to bind to, then dispose the OLD ones a
    // frame later, once Flutter has actually detached every widget
    // from them.
    final oldControllers = iqaControllers;
    final oldFocusNodes = iqaFocusNodes;
    final oldTimers = iqaIdleTimers;

    iqaControllers = List.generate(count, (_) => TextEditingController());
    iqaFocusNodes = List.generate(count, (_) => FocusNode());
    iqaIdleTimers = List.generate(count, (_) => null);
    iqaAllFilled.value = false;
    filledIqaCount.value = 0;
    injectorStatus.assignAll(List.generate(count, (_) => false));
    iqaStatus.assignAll(List.generate(count, (_) => false));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      for (final t in oldTimers) {
        t?.cancel();
      }
      for (final c in oldControllers) {
        c.dispose();
      }
      for (final f in oldFocusNodes) {
        f.dispose();
      }
    });
  }

  String iqaLabelFor(int i) {
    final order = firingOrder;
    if (order != null && i < order.length) {
      return 'IQA (Cyl ${order[i]})';
    }
    return 'IQA ${i + 1}';
  }

  void refreshIqaAllFilled() {
    iqaAllFilled.value = iqaControllers.every((c) => c.text.trim().isNotEmpty);
    filledIqaCount.value =
        iqaControllers.where((c) => c.text.trim().isNotEmpty).length;
  }

  // ===============================
  // FLASH
  // ===============================

  

  final RxBool flashFilesLoading = false.obs;
  final RxString flashFilesError = "".obs;

  final RxString flashFileName = "".obs;

  final RxString flashStatus = "".obs;

  final RxBool isFlashing = false.obs;
  final RxBool isPostFlashProcessing = false.obs;

  final RxBool isReconnectingAfterFlash = false.obs;

  final RxDouble flashProgress = 0.0.obs;

  final RxInt flashElapsedSeconds = 0.obs;

  String get formattedElapsed {
    final s = flashElapsedSeconds.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ===============================
  // DTC
  // ===============================

  final RxBool isLoadingDtc = false.obs;

  final RxString dtcError = "".obs;

  final RxList<DtcCode> dtcCodes = <DtcCode>[].obs;

  /// Real ECU read results (not just the dataset catalog above) —
  /// "CODE - description (status)" strings, same shape as the Test
  /// Station's dtcList.
  final RxBool isReadingDtc = false.obs;
  final RxList<String> dtcReadResults = <String>[].obs;

  // ===============================
  // LIVE PARAMETER
  // ===============================

  final RxBool isLoadingPid = false.obs;

  final RxString pidError = "".obs;

  final RxList<Code> liveParameterCodes = <Code>[].obs;

  final RxList<Code> iqaParameterCodes = <Code>[].obs;

  /// Real-time values read from the ECU during Live Parameter
  /// playback — keyed by variable.id, same as the Test Station.
  final RxMap<int, String> livePidValues = <int, String>{}.obs;
  final RxBool pidPlaying = false.obs;
  bool stopPidLoop = false;

  final RxString iqaWriteStatus = "".obs;

  // ===============================
  // PID FILTER
  // ===============================

  void applyPidCodes(
    List<Code> codes,
  ) {
    bool isIqa(Code code) {
      return (code.piCodeVariable ?? const <PiCodeVariables>[]).any(
        (item) => item.messageType == MessageType.IQA,
      );
    }

    iqaParameterCodes.assignAll(
      codes.where(
        (code) => isIqa(code),
      ),
    );

    liveParameterCodes.assignAll(
      codes.where(
        (code) => !isIqa(code),
      ),
    );
  }

  // ===============================
  // RESET LOCK
  // ===============================

  void resetToLocked() {
    isTargetLane.value = false;

    isLocked.value = true;

    isLedOn.value = false;

    isHarnessConnected.value = false;
  }

  // ===============================
  // RESET IDLE
  // ===============================

  void resetToUnlockedIdle() {
    harnessTimer?.cancel();
    flashStopwatch?.cancel();

    isTargetLane.value = false;

    isLocked.value = false;

    isLedOn.value = false;

    isHarnessConnected.value = false;

    esnController.clear();
    esn.value = "";
    esnError.value = "";
    isLookingUpEsn.value = false;
    esnIdleTimer?.cancel();

    listNumberController.clear();
    listNumber.value = "";
    listNumberError.value = "";
    isLookingUpListNumber.value = false;
    listNumberIdleTimer?.cancel();

    dongleConnected.value = false;
    dongleConnecting.value = false;
    dongleError.value = "";
    dongleRetryTimer?.cancel();
    dllFunctions = null;
    isDongleBusy = false;

    currentSessionKey = null;
    sessionReportSent = false;
    draftFlashStatus = null;
    draftIqaStatus = null;
    draftDtcStatus = null;

    //ecuModelName.value = "ECU MODEL NAME";

    matchedEcu = null;
    matchedVehicleModelId = null;
    matchedSubModelId = null;
    esnRecordId = null;
    resolvedDatasetType = null;
    resolvedDatasetFileName = null;
    flashCycleStartTime = null;
    // dongleDbId is intentionally NOT cleared — it's tied to the
    // physical dongle wired to this lane, not to whichever engine
    // is currently being flashed.

    dtcDatasetId.value = null;

    pidDatasetId.value = null;

    configureIqaFields(4);

    flashFileName.value = "";

    flashFilesError.value = '';
    resolvedFlashFileUrl.value = null;
    resolvedFlashFileName.value = null;

    flashStatus.value = "";

    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;

    dtcCodes.clear();
    dtcReadResults.clear();
    activityLog.clear();
    isReadingDtc.value = false;

    liveParameterCodes.clear();

    iqaParameterCodes.clear();

    livePidValues.clear();
    pidPlaying.value = false;
    stopPidLoop = false;
    iqaWriteStatus.value = "";

    for (int i = 0; i < injectorStatus.length; i++) {
      injectorStatus[i] = false;
    }

    for (int i = 0; i < iqaStatus.length; i++) {
      iqaStatus[i] = false;
    }

    injectorStatus.refresh();

    iqaStatus.refresh();
  }

  void dispose() {
    harnessTimer?.cancel();
    flashStopwatch?.cancel();
    dongleRetryTimer?.cancel();
    esnIdleTimer?.cancel();
    listNumberIdleTimer?.cancel();
    esnController.dispose();
    esnFocusNode.dispose();
    listNumberController.dispose();
    listNumberFocusNode.dispose();
    for (final c in iqaControllers) {
      c.dispose();
    }
    for (final f in iqaFocusNodes) {
      f.dispose();
    }
    for (final t in iqaIdleTimers) {
      t?.cancel();
    }
  }
}
Future<bool> saveActivityLog(dynamic activityLog) async {
    try {
      if (activityLog.isEmpty) return false;

      final documentsDir = await getApplicationDocumentsDirectory();
      final activityDir = Directory('${documentsDir.path}/ActivityLog');

      if (!await activityDir.exists()) {
        await activityDir.create(recursive: true);
      }

      var laneNumber;
      final fileName =
          'Lane${laneNumber}_ActivityLog_${DateTime.now().toIso8601String().replaceAll(':', '-').replaceAll('.', '-')}.txt';

      final file = File('${activityDir.path}/$fileName');
      await file.writeAsString(activityLog.join('\n'));

      print('Activity log saved: ${file.path}');
      return true;
    } catch (e) {
      print('Failed to save activity log: $e');
      return false;
    }
  }

// =====================================================
// PLC REGISTER MODEL
// =====================================================

class PsfLaneRegister {
  final int laneIndex;

  final int ledOutputRegister;

  final int harnessConnectedInputRegister;

  const PsfLaneRegister({
    required this.laneIndex,
    required this.ledOutputRegister,
    required this.harnessConnectedInputRegister,
  });
}

// =====================================================
// PLC ADDRESS MAP
// =====================================================

final List<PsfLaneRegister> psfLaneRegisterMap = [
  PsfLaneRegister(
    laneIndex: 0,
    ledOutputRegister: 100,
    harnessConnectedInputRegister: 200,
  ),
  PsfLaneRegister(
    laneIndex: 1,
    ledOutputRegister: 101,
    harnessConnectedInputRegister: 201,
  ),
  PsfLaneRegister(
    laneIndex: 2,
    ledOutputRegister: 102,
    harnessConnectedInputRegister: 202,
  ),
  PsfLaneRegister(
    laneIndex: 3,
    ledOutputRegister: 103,
    harnessConnectedInputRegister: 203,
  ),
  PsfLaneRegister(
    laneIndex: 4,
    ledOutputRegister: 104,
    harnessConnectedInputRegister: 204,
  ),
  PsfLaneRegister(
    laneIndex: 5,
    ledOutputRegister: 105,
    harnessConnectedInputRegister: 205,
  ),
];
