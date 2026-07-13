import 'package:get/get.dart';

import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;

import 'package:simpson/modals/pidDataset.model.dart'
    show Code, MessageType, PiCodeVariables;

class PsfLane {
  PsfLane(this.laneNumber);

  // ===============================
  // LANE NUMBER
  // ===============================

  final int laneNumber;

  // ===============================
  // ECU INFORMATION
  // ===============================

  final RxString ecuModelName = "ECU MODEL NAME".obs;

  final RxString esn = "".obs;

  final Rxn<int> dtcDatasetId = Rxn<int>();

  final Rxn<int> pidDatasetId = Rxn<int>();

  // ===============================
  // PLC / HARNESS STATUS
  // ===============================

  final RxBool isLedOn = false.obs;

  final RxBool isLocked = false.obs;

  final RxBool isTargetLane = false.obs;

  final RxBool isHarnessConnected = false.obs;

  // ===============================
  // INJECTOR / IQA
  // ===============================

  final RxList<bool> injectorStatus = <bool>[
    false,
    false,
    false,
    false,
  ].obs;

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

  // ===============================
  // FLASH
  // ===============================

  final RxString flashFileName = "".obs;

  final RxString flashStatus = "".obs;

  final RxBool isFlashing = false.obs;

  final RxDouble flashProgress = 0.0.obs;

  // ===============================
  // DTC
  // ===============================

  final RxBool isLoadingDtc = false.obs;

  final RxString dtcError = "".obs;

  final RxList<DtcCode> dtcCodes = <DtcCode>[].obs;

  // ===============================
  // LIVE PARAMETER
  // ===============================

  final RxBool isLoadingPid = false.obs;

  final RxString pidError = "".obs;

  final RxList<Code> liveParameterCodes = <Code>[].obs;

  final RxList<Code> iqaParameterCodes = <Code>[].obs;

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
    isTargetLane.value = false;

    isLocked.value = false;

    isLedOn.value = false;

    isHarnessConnected.value = false;

    esn.value = "";

    ecuModelName.value = "ECU MODEL NAME";

    dtcDatasetId.value = null;

    pidDatasetId.value = null;

    flashFileName.value = "";

    flashStatus.value = "";

    flashProgress.value = 0;

    dtcCodes.clear();

    liveParameterCodes.clear();

    iqaParameterCodes.clear();

    for (int i = 0; i < injectorStatus.length; i++) {
      injectorStatus[i] = false;
    }

    for (int i = 0; i < iqaStatus.length; i++) {
      iqaStatus[i] = false;
    }

    injectorStatus.refresh();

    iqaStatus.refresh();
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
