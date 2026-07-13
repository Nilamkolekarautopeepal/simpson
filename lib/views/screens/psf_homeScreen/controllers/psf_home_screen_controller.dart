import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
import 'package:simpson/modals/pfsLaneRegister.model.dart';
import 'package:simpson/modals/pidDataset.model.dart' show Code;

import 'package:simpson/services/apiServices.dart';
import 'package:simpson/services/plc/plc_service.dart';

import 'pfs_lane.dart' hide psfLaneRegisterMap;

class PsfHomeScreenController extends GetxController {
  // ===============================
  // Station
  // ===============================

  late String station;

  // Total physical lanes

  static const int laneCount = 6;

  late List<PsfLane> lanes;

  final AuthService _authService = AuthService();

  final PlcService plcService = Get.find<PlcService>();

  // ===============================
  // ESN
  // ===============================

  final TextEditingController esnController = TextEditingController();

  final RxBool isLookingUpEsn = false.obs;

  final RxString esnError = "".obs;

  final RxnInt currentTargetLane = RxnInt();

  Timer? harnessTimer;

  // ===============================
  // PLC
  // ===============================

  final TextEditingController plcIpController = TextEditingController();

  final TextEditingController plcPortController = TextEditingController(
    text: "502",
  );

  RxBool get isPlcConnected => plcService.isConnected;

  RxBool get isPlcConnecting => plcService.isConnecting;

  RxString get plcStatus => plcService.status;

  @override
  void onInit() {
    super.onInit();

    station = Get.arguments is String ? Get.arguments : "PFS Station";

    lanes = List.generate(
      laneCount,
      (index) => PsfLane(index + 1),
    );

    debugPrint(
      "PFS Controller Loaded : ${lanes.length} lanes",
    );
  }

  @override
  void onClose() {
    harnessTimer?.cancel();

    esnController.dispose();

    plcIpController.dispose();

    plcPortController.dispose();

    super.onClose();
  }

  // ===================================================
  // PLC CONNECTION
  // ===================================================

  void onPlcButtonTapped() {
    if (isPlcConnected.value) {
      Get.dialog(
        CustomPopup(
          title: "Disconnect PLC?",
          message: "PLC is connected",
          confirmText: "Disconnect",
          showCancel: true,
          onConfirm: () {
            plcService.disconnect();

            Get.back();
          },
        ),
      );
    } else {
      connectPLCDialog();
    }
  }

  void connectPLCDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text(
          "Connect PLC",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: plcIpController,
              decoration: const InputDecoration(
                labelText: "PLC IP",
              ),
            ),
            TextField(
              controller: plcPortController,
              decoration: const InputDecoration(
                labelText: "PORT",
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: connectPLC,
            child: const Text(
              "CONNECT",
            ),
          ),
        ],
      ),
    );
  }

  Future<void> connectPLC() async {
    final ip = plcIpController.text.trim();

    if (ip.isEmpty) {
      Get.snackbar(
        "PLC",
        "Enter IP Address",
      );

      return;
    }

    final port = int.tryParse(
          plcPortController.text,
        ) ??
        502;

    try {
      await plcService.connect(
        ip,
        port: port,
      );

      Get.back();
    } catch (e) {
      Get.snackbar(
        "PLC ERROR",
        e.toString(),
      );
    }
  }

  // ===================================================
  // ESN SCAN
  // ===================================================

  Future<void> onScanEsn() async {
    final esn = esnController.text.trim();

    if (esn.isEmpty) {
      esnError.value = "Enter ESN";

      return;
    }

    isLookingUpEsn.value = true;

    try {
      final laneIndex = await identifyModel(esn);

      await applyLane(esn, laneIndex);
    } catch (e) {
      esnError.value = e.toString();
    } finally {
      isLookingUpEsn.value = false;
    }
  }

  Future<int> identifyModel(
    String esn,
  ) async {
    final data = await _authService.getModels();

    if (data.results == null || data.results!.isEmpty) {
      throw Exception(
        "Model not found",
      );
    }

    final laneIndex = esn.hashCode.abs() % laneCount;

    final lane = lanes[laneIndex];

    final model = data.results!.first;

    lane.ecuModelName.value = model.name ?? "Unknown Model";

    return laneIndex;
  }

  // ===================================================
  // APPLY ESN RESULT TO LANE
  // ===================================================

  Future<void> applyLane(
    String esn,
    int laneIndex,
  ) async {
    currentTargetLane.value = laneIndex;

    harnessTimer?.cancel();

    for (int i = 0; i < lanes.length; i++) {
      final lane = lanes[i];

      final active = i == laneIndex;

      lane.isTargetLane.value = active;

      lane.isLocked.value = !active;

      lane.isLedOn.value = active;

      lane.isHarnessConnected.value = false;

      if (active) {
        lane.esn.value = esn;
      }
    }

    // PLC LED OUTPUT

    if (plcService.isConnected.value) {
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

    // Start harness checking

    harnessTimer = Timer.periodic(
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

  // ===================================================
  // HARNESS CHECK
  // ===================================================

  Future<void> checkHarness(
    int index,
  ) async {
    if (!plcService.isConnected.value) return;

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

  // ===================================================
  // RESET
  // ===================================================

  void resetForNextEsn() {
    harnessTimer?.cancel();

    currentTargetLane.value = null;

    esnController.clear();

    for (final lane in lanes) {
      lane.resetToUnlockedIdle();
    }
  }

  // ===================================================
  // FLASH ECU
  // ===================================================

  Future<void> onStartFlash(
    int index,
  ) async {
    final lane = lanes[index];

    if (!lane.isHarnessConnected.value) return;

    if (lane.isFlashing.value) return;

    lane.isFlashing.value = true;

    lane.flashStatus.value = "Flashing Started";

    lane.flashProgress.value = 0;

    // Replace this part with real UDS Flashing

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      lane.flashProgress.value = i / 10;
    }

    lane.isFlashing.value = false;

    lane.flashStatus.value = "Flash Completed";

    await loadDtcForLane(index);

    await loadPidForLane(index);
  }

  // ===================================================
  // DTC
  // ===================================================

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

      final result = await _authService.getDtcDataset(
        id: lane.dtcDatasetId.value!,
      );

      final List<DtcCode> codes = result.results!
          .expand<DtcCode>((item) => item.dtcCode ?? [])
          .toList();

      lane.dtcCodes.assignAll(
        codes,
      );
    } catch (e) {
      lane.dtcError.value = e.toString();
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

  // ===================================================
  // PID / LIVE PARAMETER
  // ===================================================

  Future<void> loadPidForLane(
    int index,
  ) async {
    final lane = lanes[index];

    if (lane.pidDatasetId.value == null) return;

    try {
      lane.isLoadingPid.value = true;

      final result = await _authService.getPidDataset(
        id: lane.pidDatasetId.value!,
      );

      final List<Code> codes =
          result.results!.expand<Code>((item) => item.codes ?? []).toList();

      lane.applyPidCodes(
        codes,
      );
    } catch (e) {
      lane.pidError.value = e.toString();
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
  // ===================================================
  // INJECTOR STATUS
  // ===================================================

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

  // ===================================================
  // IQA STATUS
  // ===================================================

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
  // ===================================================
  // REFRESH LANE
  // ===================================================

  void onRefreshLane(
    int index,
  ) {
    if (index >= lanes.length) return;

    lanes[index].isLedOn.toggle();
  }

  void logout() {
    Get.offAllNamed(
      "/login",
    );
  }
}
