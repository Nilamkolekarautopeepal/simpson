//Prathmesh Girme
import 'dart:async';
import 'package:simpson/utils/ui_helper.dart/dllFunctions.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
import 'package:simpson/modals/all.models.dart' show SubmodelModelecu;

import 'package:simpson/modals/pidDataset.model.dart'
    show Code, MessageType, PiCodeVariables;

class PsfLane {
  PsfLane(
    this.laneNumber, {
    this.dongleIpFromLogin,
    this.expectedEcuId,
    this.macIdFromLogin,
  }) {
    ever(dongleConnected, (bool connected) {
      logActivity(connected ? 'Dongle connected' : 'Dongle disconnected');
    });
    ever(esn, (String v) {
      if (v.isNotEmpty) logActivity('ESN scanned: $v');
    });
    ever(esnError, (String v) {
      if (v.isNotEmpty) logActivity('ESN error: $v');
    });
    ever(isFlashing, (bool flashing) {
      if (flashing) logActivity('Flashing started');
    });
    ever(flashStatus, (String v) {
      if (v.isNotEmpty) logActivity(v);
    });
    ever(dtcError, (String v) {
      if (v.isNotEmpty) logActivity('DTC error: $v');
    });
    ever(iqaWriteStatus, (String v) {
      if (v.isNotEmpty) logActivity(v);
    });
  }

  final String? dongleIpFromLogin;
  final int? expectedEcuId;
  final String? macIdFromLogin;

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

  final RxList<String> activityLog = <String>[].obs;

  void logActivity(String entry) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 19);
    activityLog.add('[$timestamp] $entry');
    if (activityLog.length > 300) {
      activityLog.removeAt(0);
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
  int? resolvedDatasetId;
  int? dongleDbId;
  DateTime? flashCycleStartTime;
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

    ecuModelName.value = "ECU MODEL NAME";

    matchedEcu = null;
    matchedVehicleModelId = null;
    matchedSubModelId = null;
    esnRecordId = null;
    resolvedDatasetId = null;
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
