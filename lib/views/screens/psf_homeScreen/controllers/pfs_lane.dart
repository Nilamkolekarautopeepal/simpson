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
  });

  /// This lane's dongle IP and pre-wired ECU id, straight from the
  /// login response's station_data[0].prodbud_dongles[i] — this is
  /// what a scanned ESN's resolved ECU id gets matched against to
  /// decide which physical lane lights up.
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

  /// ESN is scanned per-lane — validated against THIS lane's
  /// pre-wired expectedEcuId (from login's ecu_station data), so
  /// scanning the wrong engine into the wrong physical bay is caught
  /// immediately rather than silently accepted.
  final RxString esn = "".obs;
  final TextEditingController esnController = TextEditingController();
  final FocusNode esnFocusNode = FocusNode();
  final RxBool isLookingUpEsn = false.obs;

  final RxString esnError = "".obs;

  /// Auto-scan debounce — no SCAN button anymore; typing pauses for
  /// 2s then submits automatically.
  Timer? esnIdleTimer;
  Timer? listNumberIdleTimer;

  /// List Number — scanned right after ESN, resolves to exactly one
  /// flash file via the real API's d_dataset_ecu/t_dataset_ecu arrays
  /// (matched against this lane's ECU id). Only shown/usable once
  /// ESN has matched.
  final TextEditingController listNumberController = TextEditingController();
  final FocusNode listNumberFocusNode = FocusNode();
  final RxBool isLookingUpListNumber = false.obs;
  final RxString listNumberError = "".obs;
  final RxString listNumber = "".obs;

  /// The single resolved flash file URL + display name for this lane,
  /// found via the List Number lookup — there's exactly one, not a
  /// list to choose from.
  final Rx<String?> resolvedFlashFileUrl = Rx<String?>(null);
  final Rx<String?> resolvedFlashFileName = Rx<String?>(null);

  /// Own harness-poll timer per lane, since lanes now run independently.
  Timer? harnessTimer;

  /// Ticks flashElapsedSeconds up once per second while flashing.
  Timer? flashStopwatch;

  final Rxn<int> dtcDatasetId = Rxn<int>();

  final Rxn<int> pidDatasetId = Rxn<int>();

  /// The real matched ECU entry for this lane's vehicle, once ESN
  /// resolution succeeds — needed for flash file resolution and (once
  /// dongle connectivity exists for PFS) real flashing/IQA write.
  SubmodelModelecu? matchedEcu;

  /// The vehicle model / sub-model ids resolved from the scanned ESN
  /// — the List Number scan cross-checks its own vehicle_model /
  /// sub_model fields against these, so a List Number that matches by
  /// code but belongs to a different vehicle gets rejected.
  int? matchedVehicleModelId;
  int? matchedSubModelId;

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

  /// NOTE: App.dllFunctions / ConnectionWifi's internal comm objects
  /// are GLOBAL SINGLETONS (see connectionWifiService.dart) — only
  /// ONE lane can safely hold the dongle connection at a time right
  /// now. The controller enforces this (see dongleOwnerLaneIndex);
  /// these fields just reflect THIS lane's view of that shared state.
  final RxBool dongleConnected = false.obs;

  /// This lane's OWN independent dongle connection object — not the
  /// shared `App.dllFunctions` single global. Set once
  /// ConnectionWifi.connectDongleForLane() succeeds; every dongle
  /// call for this lane (setDongleProperties, startECUFlashing,
  /// flashingData, readDtc, readPid, writePid) must go through THIS
  /// field so multiple lanes can be connected and flashing at the
  /// same time.
  DLLFunctions? dllFunctions;
  final RxBool dongleConnecting = false.obs;

  /// True whenever ANYTHING is actively using this lane's dongle
  /// connection — Live Parameter read, DTC read, IQA write, or
  /// flashing. All of those share the exact same socket
  /// (lane.dllFunctions), so two of them running at once desyncs the
  /// response stream (a flash command's response can get consumed by
  /// a still-running PID read loop, or vice versa) — this flag is the
  /// guard that stops that from happening.
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

  /// Real scannable IQA codes — one TextEditingController per injector,
  /// dynamic count resolved from the matched ECU's noOfInjectors, same
  /// pattern as the Test Station's IQA fields.
  List<TextEditingController> iqaControllers =
      List.generate(4, (_) => TextEditingController());
  List<FocusNode> iqaFocusNodes = List.generate(4, (_) => FocusNode());
  List<Timer?> iqaIdleTimers = List.generate(4, (_) => null);
  final RxBool iqaAllFilled = false.obs;

  /// Proper reactive counter — TextEditingController.text changes are
  /// NOT observable on their own, so refreshIqaAllFilled() below
  /// updates this alongside iqaAllFilled, giving the UI something
  /// genuinely reactive to display without needing a nested Obx.
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
    for (final c in iqaControllers) {
      c.dispose();
    }
    for (final f in iqaFocusNodes) {
      f.dispose();
    }
    for (final t in iqaIdleTimers) {
      t?.cancel();
    }
    iqaControllers = List.generate(count, (_) => TextEditingController());
    iqaFocusNodes = List.generate(count, (_) => FocusNode());
    iqaIdleTimers = List.generate(count, (_) => null);
    firingOrder = firingSequence;
    iqaAllFilled.value = false;
    filledIqaCount.value = 0;
    injectorStatus.assignAll(List.generate(count, (_) => false));
    iqaStatus.assignAll(List.generate(count, (_) => false));
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

  /// Result message from writing the IQA values to the ECU right
  /// after a successful flash (mirrors the Test Station's
  /// _autoWriteIqaValues status string).
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
