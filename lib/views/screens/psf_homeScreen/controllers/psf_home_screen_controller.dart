import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
import 'package:simpson/modals/pfsLaneRegister.model.dart';
import 'package:simpson/modals/pidDataset.model.dart' show Code;
import 'package:simpson/services/apiServices.dart';
import 'package:simpson/services/plc/plc_service.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';


/// Controller for the PFS Station home screen: 6 lanes (4 visible,
/// 2 reached via horizontal scroll), each mirroring one physical
/// harness/ECU slot at the station.
/// Workflow per MOM "Steps for PFS Station":
///  1. Scan ESN                -> esnController + onScanEsn()
///  2. System Identifies Model -> _identifyModelForEsn() (AuthService)
///  3. LED Indication          -> PlcService.writeRegister(ledOutputRegister)
///  4. Connect Harness         -> polls harnessConnectedInputRegister
///  5. Run Diagnostics         -> flash / DTC / live parameter per lane
class PsfHomeScreenController extends GetxController {
  late final String station;

  static const int laneCount = 6;
  late final List<PsfLane> lanes;

  final AuthService _authService = AuthService();
  final PlcService plcService = Get.find<PlcService>();

  final TextEditingController esnController = TextEditingController();
  final RxBool isLookingUpEsn = false.obs;
  final RxString esnError = ''.obs;
  final RxnInt currentTargetLane = RxnInt();
  Timer? _harnessPollTimer;

  // ── PLC connect (top-right app bar button) ──
  final TextEditingController plcIpController = TextEditingController();
  final TextEditingController plcPortController = TextEditingController(text: '502');

  RxBool get isPlcConnected => plcService.isConnected;
  RxBool get isPlcConnecting => plcService.isConnecting;
  RxString get plcStatus => plcService.status;

  @override
  void onInit() {
    super.onInit();
    station = (Get.arguments is String) ? Get.arguments as String : 'PFS Station';
    lanes = List.generate(laneCount, (i) => PsfLane(i + 1));
  }

  @override
  void onClose() {
    _harnessPollTimer?.cancel();
    esnController.dispose();
    plcIpController.dispose();
    plcPortController.dispose();
    super.onClose();
  }

  // ================= PLC connect dialog =================

  void openPlcConnectDialog() {
    plcIpController.text = plcService.savedIp;
    plcPortController.text = plcService.savedPort;

    const Color primary = Color(0xFF003874);

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: 420,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header ──
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_ethernet, color: primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Connect to PLC',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                    onPressed: () => Get.back(),
                    splashRadius: 18,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Enter the PLC\'s network address to establish a connection.',
                style: TextStyle(fontSize: 12.5, color: Colors.grey),
              ),
              const SizedBox(height: 22),

              // ── IP field ──
              const Text('PLC IP ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black54, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              TextField(
                controller: plcIpController,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'e.g. 192.168.1.10',
                  prefixIcon: const Icon(Icons.lan_outlined, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Port field ──
              const Text('PORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black54, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              TextField(
                controller: plcPortController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 14),
                decoration: InputDecoration(
                  hintText: '502',
                  prefixIcon: const Icon(Icons.numbers, size: 20, color: Colors.grey),
                  filled: true,
                  fillColor: const Color(0xFFF5F7FA),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: primary, width: 1.6),
                  ),
                ),
              ),
              const SizedBox(height: 26),

              // ── Actions ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: BorderSide(color: Colors.grey.shade300),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Obx(
                      () => ElevatedButton(
                        onPressed: isPlcConnecting.value ? null : _connectPlcFromDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: primary.withOpacity(0.5),
                          disabledForegroundColor: Colors.white70,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: isPlcConnecting.value
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Icon(Icons.link, size: 17, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text('Connect', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
      barrierDismissible: !isPlcConnecting.value,
    );
  }

  Future<void> _connectPlcFromDialog() async {
    final ip = plcIpController.text.trim();
    if (ip.isEmpty) {
      Get.snackbar('PLC', 'Enter a PLC IP address first.', backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    final port = int.tryParse(plcPortController.text.trim()) ?? 502;
    try {
      await plcService.connect(ip, port: port);
      Get.back();
    } catch (e) {
      Get.snackbar('PLC Connection Failed', e.toString(), backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  void onPlcButtonTapped() {
    if (isPlcConnected.value) {
      Get.dialog(
        CustomPopup(
          title: 'Disconnect PLC?',
          message: 'Currently connected to ${plcService.lastIp.value}.',
          confirmText: 'Disconnect',
          showCancel: true,
          onConfirm: () {
            plcService.disconnect();
            Get.back();
          },
        ),
      );
      return;
    }
    openPlcConnectDialog();
  }

  // ================= STEP 1 + 2: Scan ESN -> identify model =================

  Future<void> onScanEsn() async {
    final esn = esnController.text.trim();
    if (esn.isEmpty) {
      esnError.value = 'Enter or scan an ESN first.';
      return;
    }

    isLookingUpEsn.value = true;
    esnError.value = '';

    try {
      final int targetLane = await _identifyModelForEsn(esn);
      await _applyLookupResult(esn, targetLane);
    } catch (e) {
      esnError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      isLookingUpEsn.value = false;
    }
  }

  /// TODO: There isn't yet a dedicated "look up model by ESN" endpoint —
  /// this calls the existing getModels() catalog and picks a
  /// model/lane deterministically from the ESN so the UI/PLC flow is
  /// testable end-to-end. Replace once the real matching logic exists.
  Future<int> _identifyModelForEsn(String esn) async {
    final allModel = await _authService.getModels();
    if (allModel.results == null || allModel.results!.isEmpty) {
      throw Exception('No models returned from server.');
    }

    final int targetLane = esn.hashCode.abs() % laneCount;
    final lane = lanes[targetLane];

    final model = allModel.results!.first;
    lane.ecuModelName.value = model.name ?? 'Unknown Model';

    final subModel = model.subModels?.isNotEmpty == true ? model.subModels!.first : null;
    final ecuInfo = subModel?.submodelModelecu?.isNotEmpty == true ? subModel!.submodelModelecu!.first : null;

    final injectorCount = ecuInfo?.noOfInjectors ?? 4;
    lane.injectorStatus.assignAll(List.generate(injectorCount.clamp(1, 8), (_) => false));
    lane.iqaStatus.assignAll(List.generate(injectorCount.clamp(1, 8), (_) => false));

    // TODO: confirm which dataset in these lists is the "active" one to
    // use for DTC — currently left null since ivnDtcDatasets is untyped
    // in AllModel; wire this up once the real shape is confirmed.
    final pidDatasetId = ecuInfo?.pidDatasets?.isNotEmpty == true ? ecuInfo!.pidDatasets!.first.id : null;
    lane.pidDatasetId.value = pidDatasetId;

    if (ecuInfo?.flashFile?.sequenceFile != null) {
      lane.flashFileName.value = ecuInfo!.flashFile!.sequenceFile!;
    }

    return targetLane;
  }

  // ================= STEP 3: LED indication (lock the rest) =================

  Future<void> _applyLookupResult(String esn, int targetLaneIndex) async {
    currentTargetLane.value = targetLaneIndex;
    _harnessPollTimer?.cancel();

    for (int i = 0; i < lanes.length; i++) {
      final bool isTarget = i == targetLaneIndex;
      lanes[i].isTargetLane.value = isTarget;
      lanes[i].isLocked.value = !isTarget;
      lanes[i].isLedOn.value = isTarget;
      lanes[i].isHarnessConnected.value = false;
      if (isTarget) lanes[i].esn.value = esn;
    }

    for (final reg in psfLaneRegisterMap) {
      final bool shouldBeOn = reg.laneIndex == targetLaneIndex;
      try {
        if (plcService.isConnected.value) {
          await plcService.writeRegister(reg.ledOutputRegister, shouldBeOn ? 1 : 0);
        }
      } catch (_) {
        // TODO: surface LED write failures (e.g. PLC unreachable) to the UI.
      }
    }

    _harnessPollTimer = Timer.periodic(const Duration(milliseconds: 800), (_) => _pollHarness(targetLaneIndex));
  }

  Future<void> _pollHarness(int laneIndex) async {
    if (currentTargetLane.value != laneIndex) return;
    if (!plcService.isConnected.value) return;

    final reg = psfLaneRegisterMap[laneIndex];
    try {
      final raw = await plcService.readRegister(reg.harnessConnectedInputRegister);
      lanes[laneIndex].isHarnessConnected.value = raw == 1;
    } catch (_) {
      // TODO: surface harness-sensor read failures (e.g. PLC disconnected).
    }
  }

  void resetForNextEsn() {
    _harnessPollTimer?.cancel();
    currentTargetLane.value = null;
    esnController.clear();
    for (final lane in lanes) {
      lane.resetToUnlockedIdle();
    }
  }

  // ================= Injector / IQA grid =================

  /// Manual override / re-check of ECU presence for this lane.
  /// TODO: wire to a real ECU-presence check via the PLC/OBD service.
  void onRefreshLane(int index) {
    lanes[index].isLedOn.toggle();
  }

  /// Tapping an INJECTOR cell toggles it — stand-in for a real scan/probe
  /// result until wired to the PLC/OBD service.
  void onToggleInjector(int laneIndex, int injectorIndex) {
    final lane = lanes[laneIndex];
    if (lane.isLocked.value) return;
    lane.injectorStatus[injectorIndex] = !lane.injectorStatus[injectorIndex];
  }

  /// Tapping an IQA cell toggles it. Once all IQA cells for a lane are
  /// confirmed, PsfLane.iqaStatusText reflects "N / N confirmed".
  void onToggleIqa(int laneIndex, int iqaIndex) {
    final lane = lanes[laneIndex];
    if (lane.isLocked.value) return;
    lane.iqaStatus[iqaIndex] = !lane.iqaStatus[iqaIndex];
  }

  // ================= STEP 5a: Flash =================

  Future<void> onStartFlash(int index) async {
    final lane = lanes[index];
    if (!lane.isHarnessConnected.value || lane.isFlashing.value) return;

    lane.isFlashing.value = true;
    lane.flashProgress.value = 0;
    lane.flashStatus.value = 'Flashing…';

    // TODO: replace with the real flash sequence — write the matched
    // model's FlashFile (see SubmodelModelecu.flashFile in AllModel) via
    // PlcService / the ECU flashing service, instead of this simulated delay.
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      lane.flashProgress.value = i / 10;
    }

    lane.isFlashing.value = false;
    lane.flashStatus.value = 'Completed';

    // Matches the original wizard's behavior: once flashing finishes,
    // automatically pull DTC + live parameter data for this lane.
    unawaited(loadDtcForLane(index));
    unawaited(loadPidForLane(index));
  }

  // ================= STEP 5b: DTC =================

  Future<void> loadDtcForLane(int index) async {
    final lane = lanes[index];
    final id = lane.dtcDatasetId.value;
    if (id == null) {
      lane.dtcError.value = 'No DTC dataset linked to this lane yet.';
      return;
    }

    lane.isLoadingDtc.value = true;
    lane.dtcError.value = '';
    try {
      final dataset = await _authService.getDtcDataset(id: id);
      final results = dataset.results ?? const [];
      final List<DtcCode> codes = results.expand<DtcCode>((r) => r.dtcCode ?? const <DtcCode>[]).toList();
      lane.dtcCodes.assignAll(codes);
    } catch (e) {
      lane.dtcError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      lane.isLoadingDtc.value = false;
    }
  }

  Future<void> onOpenDtc(int index) async {
    final lane = lanes[index];
    if (lane.dtcCodes.isEmpty && !lane.isLoadingDtc.value) {
      await loadDtcForLane(index);
    }
  }

  // ================= STEP 5c: Live Parameter / IQA =================

  Future<void> loadPidForLane(int index) async {
    final lane = lanes[index];
    final id = lane.pidDatasetId.value;
    if (id == null) {
      lane.pidError.value = 'No PID dataset linked to this lane yet.';
      return;
    }

    lane.isLoadingPid.value = true;
    lane.pidError.value = '';
    try {
      final dataset = await _authService.getPidDataset(id: id);
      final results = dataset.results ?? const [];
      final List<Code> codes = results.expand<Code>((r) => r.codes ?? const <Code>[]).toList();
      lane.applyPidCodes(codes);
    } catch (e) {
      lane.pidError.value = e.toString().replaceFirst('Exception: ', '');
    } finally {
      lane.isLoadingPid.value = false;
    }
  }

  Future<void> onOpenLiveParameter(int index) async {
    final lane = lanes[index];
    if (lane.liveParameterCodes.isEmpty && lane.iqaParameterCodes.isEmpty && !lane.isLoadingPid.value) {
      await loadPidForLane(index);
    }
  }

  void logout() {
    Get.offAllNamed('/login');
  }
}
