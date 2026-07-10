import 'package:get/get.dart';
import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
import 'package:simpson/modals/pidDataset.model.dart' show Code, MessageType, PiCodeVariables;

/// One lane in the PFS Station's 6-lane grid. Uses individual Rx fields
/// (rather than one big Rx<PsfLane>) so updating one field only rebuilds
/// the widgets that actually read that field.
class PsfLane {
  PsfLane(this.laneNumber);

  final int laneNumber;

  final RxString ecuModelName = 'ECU MODEL NAME'.obs;
  final RxString esn = ''.obs;

  /// Dataset ids for this lane's matched model — filled in once the ESN
  /// lookup resolves a model (see PsfHomeScreenController._identifyModelForEsn).
  /// TODO: confirm these come from SubmodelModelecu.datasets / .pidDatasets
  /// once the real ESN->model matching endpoint exists.
  final Rxn<int> dtcDatasetId = Rxn<int>();
  final Rxn<int> pidDatasetId = Rxn<int>();

  /// Mirrors the PLC's LED output register for this lane — green dot
  /// when true (this lane is the one matched to the current ESN).
  final RxBool isLedOn = false.obs;

  /// True for the lanes NOT matched to the current ESN — dimmed/disabled.
  final RxBool isLocked = false.obs;

  /// True for the one lane currently matched to the scanned ESN.
  final RxBool isTargetLane = false.obs;

  /// Mirrors the PLC's harness-connected sensor input for this lane.
  final RxBool isHarnessConnected = false.obs;

  final RxList<bool> injectorStatus = <bool>[false, false, false, false].obs;
  final RxList<bool> iqaStatus = <bool>[false, false, false, false].obs;

  /// Number of injector/IQA pairs confirmed out of the total — drives the
  /// "IQA STATUS :" line under the flash controls.
  String get iqaStatusText {
    final total = iqaStatus.length;
    final done = iqaStatus.where((v) => v).length;
    if (total == 0) return '';
    return '$done / $total confirmed';
  }

  final RxString flashFileName = ''.obs;
  final RxString flashStatus = ''.obs;
  final RxBool isFlashing = false.obs;
  final RxDouble flashProgress = 0.0.obs;

  // ── DTC ──
  final RxBool isLoadingDtc = false.obs;
  final RxString dtcError = ''.obs;
  final RxList<DtcCode> dtcCodes = <DtcCode>[].obs;

  // ── Live parameter / IQA (from PidDataset) ──
  final RxBool isLoadingPid = false.obs;
  final RxString pidError = ''.obs;
  final RxList<Code> liveParameterCodes = <Code>[].obs; // messageType != IQA
  final RxList<Code> iqaParameterCodes = <Code>[].obs; // messageType == IQA

  /// Splits a freshly-fetched PID code list into "live parameter" vs "IQA"
  /// buckets. `messageType` lives on each Code's nested [PiCodeVariable]
  /// entries, not on Code itself — a Code counts as "IQA" if any of its
  /// piCodeVariable entries are tagged MessageType.IQA.
  void applyPidCodes(List<Code> codes) {
    bool isIqa(Code c) => (c.piCodeVariable ?? const <PiCodeVariables>[])
        .any((v) => v.messageType == MessageType.IQA);

    iqaParameterCodes.assignAll(codes.where(isIqa));
    liveParameterCodes.assignAll(codes.where((c) => !isIqa(c)));
  }

  void resetToLocked() {
    isTargetLane.value = false;
    isLocked.value = true;
    isLedOn.value = false;
    isHarnessConnected.value = false;
  }

  void resetToUnlockedIdle() {
    isTargetLane.value = false;
    isLocked.value = false;
    isLedOn.value = false;
    isHarnessConnected.value = false;
    esn.value = '';
    ecuModelName.value = 'ECU MODEL NAME';
    dtcDatasetId.value = null;
    pidDatasetId.value = null;
    flashFileName.value = '';
    flashStatus.value = '';
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
  }
}
