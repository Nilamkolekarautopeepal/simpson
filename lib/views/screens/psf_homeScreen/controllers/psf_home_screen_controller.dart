import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/app.dart';
import 'package:simpson/modals/all.models.dart' as all_ds;
import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
import 'package:simpson/modals/esn.model.dart' as esn_ds;
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/modals/pfsLaneRegister.model.dart';
import 'package:simpson/modals/pidDataset.model.dart' show Code;
import 'package:simpson/modals/staticData.dart';

import 'package:simpson/services/apiServices.dart';
import 'package:simpson/services/connectionWifiService.dart';
import 'package:simpson/services/getJson_service.dart';
import 'package:simpson/services/plc/plc_service.dart';

import 'pfs_lane.dart' hide psfLaneRegisterMap;

class PsfHomeScreenController extends GetxController {
  // ===============================
  // Station
  // ===============================

  late String station;

  final RxList<PsfLane> lanes = <PsfLane>[].obs;

  final AuthService _authService = AuthService();

  // Access token — without this, every API call below fails with
  // "Authentication credentials were not provided." (401).
  String? _accessToken;

  final PlcService plcService = Get.find<PlcService>();

  // Cached so we don't re-fetch the whole model catalog for every ESN.
  all_ds.AllModel? _modelsCache;

  // Cached so we don't re-fetch the whole variant/list catalog for
  // every List Number scan.
  list_ds.ListNumber? _variantListCache;

  final ConnectionWifi _connectionWifi = ConnectionWifi();
  final RxnInt dongleOwnerLaneIndex = RxnInt();

  /// True whenever any lane currently holds the (single, shared)
  /// dongle connection — used for the app bar's Dongle status dot.
  bool get isDongleConnectedAnywhere =>
      dongleOwnerLaneIndex.value != null && lanes[dongleOwnerLaneIndex.value!].dongleConnected.value;

  // ===============================
  // PLC
  // ===============================

  RxBool get isPlcConnected => plcService.isConnected;

  RxBool get isPlcConnecting => plcService.isConnecting;

  RxString get plcStatus => plcService.status;

  @override
  void onInit() {
    super.onInit();

    station = Get.arguments is String ? Get.arguments : "PFS Station";

    // Lanes are built dynamically — one per dongle in the login
    // response's station_data[0].prodbud_dongles list, each pre-wired
    // to a specific ECU id via ecu_station. Loaded here since it's
    // async; the view should handle an initially-empty lanes list
    // gracefully for one frame.
    _loadLanesFromDongleList();

    _loadAccessToken();
    _loadPlcConfig().then((_) => _autoConnectPlc());

    debugPrint(
      "PFS Controller Loaded",
    );
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

        built.add(PsfLane(
          i + 1,
          dongleIpFromLogin: entry['ip'] as String?,
          expectedEcuId: ecuId,
          macIdFromLogin: entry['macId'] as String?,
        ));
      }

      lanes.assignAll(built);
      debugPrint("PFS Controller Loaded : ${lanes.length} lane(s) from login dongle list");
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

    for (final lane in lanes) {
      lane.dispose();
    }

    super.onClose();
  }

  // ===================================================
  // PLC CONNECTION — auto-connects using the IP/port from the
  // login response (station_data[0].plc_ip / .plc_port), same as
  // the Test Station. No manual IP entry needed; tapping the
  // status indicator just retries immediately.
  // ===================================================

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
      debugPrint("PLC connection failed: $e — will keep retrying in the background");
      _startPlcRetryTimer();
    }
  }

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

  /// Tap the PLC status indicator to retry immediately instead of
  /// waiting for the next background retry tick.
  void onPlcButtonTapped() {
    if (isPlcConnected.value) return;
    _autoConnectPlc();
  }

  // ===================================================
  // ESN SCAN — per lane, auto-triggered after a 2s pause in typing
  // (no SCAN button). Validated against THIS lane's pre-wired
  // expectedEcuId (from login's ecu_station data), so scanning the
  // wrong engine into the wrong physical bay is caught immediately.
  // ===================================================

  void onEsnFieldChanged(int laneIndex) {
    final lane = lanes[laneIndex];
    lane.esnIdleTimer?.cancel();
    lane.esnIdleTimer = Timer(const Duration(seconds: 1), () {
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

    if (esn.isEmpty) {
      lane.esnError.value = "Enter ESN";
      return;
    }

    lane.isLookingUpEsn.value = true;
    lane.esnError.value = '';

    try {
      final result = await identifyModel(esn);
      final resolvedEcuId = result.ecuEntry.ecu?.id;

      // This lane already knows which ECU it's wired for (from the
      // login dongle list) — no need to search all lanes, just
      // confirm the scanned engine actually belongs here.
      if (lane.expectedEcuId != null && resolvedEcuId != lane.expectedEcuId) {
        throw Exception(
          'This ESN is wired for a different lane (resolved ECU id: '
          '${resolvedEcuId ?? "unknown"}, expected: ${lane.expectedEcuId}).',
        );
      }

      await applyLane(esn, laneIndex, result);

      // Auto-advance to List Number once ESN resolves successfully.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lane.listNumberFocusNode.requestFocus();
      });
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      lane.esnError.value = message;
      _showScanFailedPopup('ESN Not Recognized', message);
    } finally {
      lane.isLookingUpEsn.value = false;
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
    // 1) Validate the ESN itself against the real ESN list — same
    // check the Test Station does (must exist AND be active).
    _accessToken ??= await SecureStorageService.getAccessToken();
    final esnList = await _authService.getEsnList(engSlno: esn, accessToken: _accessToken);

    final match = (esnList.results ?? <esn_ds.Result>[]).firstWhereOrNull(
      (r) => (r.engSlno ?? '').trim().toUpperCase() == esn.toUpperCase(),
    );

    if (match == null) {
      throw Exception('ESN not recognized. Please rescan.');
    }
    if (match.isActive != true) {
      throw Exception('ESN is not active.');
    }

    final modelName = match.model?.name?.trim();
    final subModelName = match.subModel?.name?.trim();

    if (modelName == null || modelName.isEmpty || subModelName == null || subModelName.isEmpty) {
      throw Exception('ESN match is missing model/sub-model information.');
    }

    // 2) Resolve the REAL model/sub-model/ECU entry from the catalog —
    // matching by name, not just taking the first result.
    final allModel = await _ensureModels();

    all_ds.Result? matchedModel;
    all_ds.SubModel? matchedSubModel;

    for (final result in allModel.results ?? <all_ds.Result>[]) {
      if ((result.name ?? '').trim().toUpperCase() != modelName.toUpperCase()) {
        continue;
      }
      matchedModel = result;
      for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
        if ((subModel.name ?? '').trim().toUpperCase() == subModelName.toUpperCase()) {
          matchedSubModel = subModel;
          break;
        }
      }
      break;
    }

    if (matchedModel == null || matchedSubModel == null) {
      throw Exception('No matching model/sub-model found in catalog for "$modelName — $subModelName".');
    }

    final ecuEntry = matchedSubModel.submodelModelecu?.firstOrNull;
    if (ecuEntry == null) {
      throw Exception('No ECU configuration found for "$modelName — $subModelName".');
    }

    return _IdentifiedEcu(
      ecuEntry: ecuEntry,
      vehicleModelId: matchedModel.id,
      subModelId: matchedSubModel.id,
    );
  }

  // ===================================================
  // APPLY ESN RESULT TO ITS OWN LANE — no other lane is
  // touched or locked.
  // ===================================================

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
    lane.ecuModelName.value = ecuEntry.ecu?.name ?? 'Unknown Model';

    // Real dataset ids — this is the fix for DTC/Live Parameter always
    // being empty before: these were never actually being set.
    lane.dtcDatasetId.value = ecuEntry.datasets?.firstOrNull?.id;
    lane.pidDatasetId.value = ecuEntry.pidDatasets?.firstOrNull?.id;

    // Real IQA field count + firing order, same as the Test Station.
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

    // Flash file now comes from the List Number scan (see
    // onScanListNumberForLane) — no longer loaded automatically here.

    // Dongle auto-connects now too, using the login-sourced IP — no
    // manual entry, same trigger point as the Test Station's
    // _autoConnectDongle() (right after ESN/vehicle info resolves).
    unawaited(connectDongleForLane(laneIndex));

    // PLC LED OUTPUT — this lane's LED only, doesn't touch the others.
    // Guarded since the register map is a fixed list but lanes are now
    // dynamic (one per dongle from login) — skip if there's no
    // register entry for this lane index rather than crashing.

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

    // Start harness checking for THIS lane only — independent of
    // whatever other lanes are doing.

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

  // ===================================================
  // LIST NUMBER — real API (analyze_prodbud/variant/list/), matched
  // by variant_code. Resolves to exactly ONE flash file via the
  // matching d_dataset_ecu / t_dataset_ecu entry for this lane's
  // ECU id — not a list to choose from, unlike the models-catalog
  // flashFile.file list used elsewhere.
  // ===================================================

  Future<list_ds.ListNumber> _ensureVariantList({bool forceRefresh = false}) async {
    if (!forceRefresh && _variantListCache != null) return _variantListCache!;
    _accessToken ??= await SecureStorageService.getAccessToken();
    // NOTE: analyze_prodbud/variant/list/ returned 404 — that guess
    // was wrong. This endpoint (plain /variant/list/) is confirmed
    // working and its variant_ecu entries already carry the real hex
    // file (as a nested data_file object) matched by ECU id, model,
    // and sub-model — exactly what's needed here.
    _variantListCache = await _authService.getVariantsList(accessToken: _accessToken);
    return _variantListCache!;
  }

  void onListNumberFieldChanged(int laneIndex) {
    final lane = lanes[laneIndex];
    lane.listNumberIdleTimer?.cancel();
    lane.listNumberIdleTimer = Timer(const Duration(seconds: 1), () {
      onScanListNumberForLane(laneIndex);
    });
  }

  Future<void> onScanListNumberForLane(int laneIndex) async {
    final lane = lanes[laneIndex];
    lane.listNumberIdleTimer?.cancel();
    final scanned = lane.listNumberController.text.trim();

    if (scanned.isEmpty) {
      lane.listNumberError.value = "Enter List Number";
      return;
    }

    if (lane.matchedEcu == null) {
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

      bool tryResolve(list_ds.ListNumber list) {
        // variant_code is often "3293 _ 82.5 kVA" (a leading number
        // plus a free-text description tacked on) rather than a
        // clean code — match against just the leading token before
        // the first space/underscore, which is what actually gets
        // scanned/typed.
        String leadingToken(String raw) {
          final match = RegExp(r'^[A-Za-z0-9.]+').firstMatch(raw.trim());
          return (match?.group(0) ?? raw.trim()).toUpperCase();
        }

        final scannedToken = leadingToken(scanned);

        final variant = (list.results ?? []).firstWhereOrNull(
          (r) => leadingToken(r.variantCode ?? '') == scannedToken,
        );
        if (variant == null) return false;

        // Cross-check: the List Number must belong to the SAME
        // vehicle model/sub-model the ESN actually resolved to — a
        // variant_code match alone isn't enough, since a code could
        // coincidentally match a variant for a different vehicle.
        if (expectedVehicleModelId != null && variant.vehicleModel != expectedVehicleModelId) {
          return false;
        }
        if (expectedSubModelId != null && variant.subModel != expectedSubModelId) {
          return false;
        }

        // Match by ECU id within variant_ecu — the confirmed-working
        // field on the real /variant/list/ response. Its data_file is
        // a nested object (not a plain string like d_dataset_ecu was
        // expected to be), so pull the actual URL out of it.
        final match = (variant.variantEcu ?? []).firstWhereOrNull((e) => e.ecu == expectedEcuId);
        final fileUrl = match?.dataFile?.dataFile;

        if (match == null || fileUrl == null || fileUrl.isEmpty) {
          return false;
        }

        lane.listNumber.value = scanned;
        lane.resolvedFlashFileUrl.value = fileUrl;
        lane.resolvedFlashFileName.value = fileUrl.split('/').last;

        // Auto-advance to the first IQA field once List Number
        // resolves successfully.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (lane.iqaFocusNodes.isNotEmpty) {
            lane.iqaFocusNodes.first.requestFocus();
          }
        });
        return true;
      }

      final cached = await _ensureVariantList();
      if (tryResolve(cached)) return;

      // Refetch once to rule out a stale cache before giving up.
      final fresh = await _ensureVariantList(forceRefresh: true);
      if (tryResolve(fresh)) return;

      throw Exception(
        'No flash file found for List Number "$scanned" matching this '
        'lane\'s vehicle model/sub-model and ECU.',
      );
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      lane.listNumberError.value = message;
      _showScanFailedPopup('List Number Not Found', message);
    } finally {
      lane.isLookingUpListNumber.value = false;
    }
  }

  // ===================================================
  // DONGLE — real connection, same underlying call as the
  // Test Station (ConnectionWifi().getDongleMacID()). Guarded so
  // only one lane can hold it at a time (see dongleOwnerLaneIndex).
  // ===================================================

  Future<void> connectDongleForLane(int laneIndex) async {
    final lane = lanes[laneIndex];

    if (lane.dongleConnected.value || lane.dongleConnecting.value) return;

    if (dongleOwnerLaneIndex.value != null && dongleOwnerLaneIndex.value != laneIndex) {
      final ownerLaneNumber = lanes[dongleOwnerLaneIndex.value!].laneNumber;
      lane.dongleError.value =
          'Dongle is currently in use by Lane $ownerLaneNumber. Reset that lane first.';
      return;
    }

    final ip = lane.dongleIpFromLogin;
    if (ip == null || ip.isEmpty) {
      lane.dongleError.value = 'No dongle IP on record for this lane from login.';
      return;
    }

    if (lane.matchedEcu == null) {
      lane.dongleError.value = 'Scan ESN first — no ECU config resolved yet.';
      return;
    }

    lane.dongleConnecting.value = true;
    lane.dongleError.value = '';

    try {
      // Populate StaticData.ecuInfo from THIS lane's matched ECU —
      // same pattern as the Test Station's _autoConnectDongle(), just
      // scoped to a single-entry list for this one lane's ECU.
      final ecu = lane.matchedEcu!;
      StaticData.ecuInfo = <EcuDataSet>[
        EcuDataSet(
          ecuID: ecu.ecu?.id,
          ecuName: ecu.ecu?.name,
          txHeader: ecu.ecu?.txHeader,
          rxHeader: ecu.ecu?.rxHeader,
          protocol: ecu.ecu?.protocol,
          channelId: ecu.ecu?.channel,
          seedKeyIndex: ecu.ecu?.seedkeyalgoFnIndex?.value,
          readDtcIndex: ecu.ecu?.readDtcFnIndex?.value,
          clearDtcIndex: ecu.ecu?.clearDtcFnIndex?.value,
          writePidIndex: ecu.ecu?.writeDataFnIndex?.value,
          iorTestFnIndex: ecu.ecu?.iorTestFnIndex?.value,
          firingSequence: ecu.firingSequence,
          noOfInjectors: ecu.noOfInjectors,
        ),
      ];

      final channelParts = StaticData.ecuInfo.first.channelId?.split('-');
      final channelId = (channelParts != null && channelParts.length > 1) ? '0${channelParts[1]}' : '00';

      final macId = await _connectionWifi.getDongleMacID(ip, channelId: channelId);
      if (macId.isEmpty) {
        lane.dongleError.value = 'Failed to connect to dongle at $ip.';
        lane.dongleConnected.value = false;
        _startDongleRetryTimer(laneIndex);
        return;
      }

      final firmware = await App.dllFunctions?.setDongleProperties1() ?? '';
      if (firmware.isEmpty) {
        lane.dongleError.value = 'Connected, but dongle did not respond to configuration.';
        lane.dongleConnected.value = false;
        _startDongleRetryTimer(laneIndex);
        return;
      }

      dongleOwnerLaneIndex.value = laneIndex;
      lane.dongleConnected.value = true;
      lane.dongleRetryTimer?.cancel();
    } catch (e) {
      lane.dongleError.value = e.toString().replaceFirst('Exception: ', '');
      lane.dongleConnected.value = false;
      _startDongleRetryTimer(laneIndex);
    } finally {
      lane.dongleConnecting.value = false;
    }
  }

  void _startDongleRetryTimer(int laneIndex) {
    final lane = lanes[laneIndex];
    lane.dongleRetryTimer?.cancel();
    lane.dongleRetryTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (lane.dongleConnected.value) {
        lane.dongleRetryTimer?.cancel();
        return;
      }
      connectDongleForLane(laneIndex);
    });
  }

  /// Releases this lane's claim on the shared dongle connection so
  /// another lane can use it. There's no real "disconnect" call
  /// available in ConnectionWifi/DLLFunctions currently — this only
  /// clears the app-side bookkeeping.
  void releaseDongleForLane(int laneIndex) {
    if (dongleOwnerLaneIndex.value == laneIndex) {
      dongleOwnerLaneIndex.value = null;
    }
    lanes[laneIndex].dongleConnected.value = false;
    lanes[laneIndex].dongleRetryTimer?.cancel();
  }

  // ===================================================
  // IQA field changes
  // ===================================================

  void onIqaFieldChanged(int laneIndex, int iqaIndex) {
    final lane = lanes[laneIndex];

    // Keep the live "N / 4 scanned" counter updating immediately as you
    // type, but debounce the actual auto-advance check so it only
    // fires after a short pause — otherwise focus would jump to the
    // next field after the very first keystroke.
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

    // Auto-advance to the next IQA field, same as scanning through the
    // Test Station's IQA group.
    if (iqaIndex < lane.iqaFocusNodes.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lane.iqaFocusNodes[iqaIndex + 1].requestFocus();
      });
    }
  }

  // ===================================================
  // HARNESS CHECK
  // ===================================================

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

  // ===================================================
  // RESET — resets just this one lane, independent of the others.
  // ===================================================

  void resetLane(int laneIndex) {
    if (dongleOwnerLaneIndex.value == laneIndex) {
      dongleOwnerLaneIndex.value = null;
    }
    lanes[laneIndex].resetToUnlockedIdle();
  }

  // ===================================================
  // FLASH ECU — real sequence, using the single flash file resolved
  // by the List Number scan.
  // ===================================================

  Future<void> onStartFlash(
    int index,
  ) async {
    final lane = lanes[index];

    if (lane.isFlashing.value) return;

    if (lane.resolvedFlashFileUrl.value == null) {
      Get.snackbar('Flash', 'Scan a List Number first to resolve the flash file.');
      return;
    }

    if (!lane.dongleConnected.value || dongleOwnerLaneIndex.value != index || App.dllFunctions == null) {
      Get.snackbar('Flash', 'Connect the dongle for this lane first.');
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

    Timer? percentTimer;
    String? result;

    try {
      final hexUrl = lane.resolvedFlashFileUrl.value!;
      final ecuEntry = lane.matchedEcu;

      if (ecuEntry == null || ecuEntry.flashFile == null) {
        throw Exception("Flash file configuration missing");
      }

      final flashConfig = ecuEntry.flashFile!;

      await App.dllFunctions!.setDongleProperties(
        ecuEntry.ecu?.protocol?.name ?? '',
        ecuEntry.ecu?.protocol?.autopeepal ?? '',
        ecuEntry.ecu?.txHeader ?? '',
        ecuEntry.ecu?.rxHeader ?? '',
      );

      final sequenceContent = await _downloadAsRawString(flashConfig.sequenceFile!);

      var ecuMapFiles = flashConfig.ecuMapFile ?? <all_ds.EcuMapFile>[];
      if (ecuMapFiles.isEmpty) {
        ecuMapFiles = _parseEcuMapFilesFromSequence(sequenceContent);
      }
      if (ecuMapFiles.isEmpty) {
        throw Exception("ECU MAP FILE missing — cannot generate flash JSON.");
      }

      final hexContent = await _downloadAsRawString(hexUrl);

      final flashJson = await _readJson(
        ecuMapFiles,
        flashConfig.flashCheckSumType?.toString() ?? '',
        Uint8List.fromList(hexContent.codeUnits),
      );

      if (flashJson.isEmpty) {
        throw Exception("Flash JSON generation failed");
      }

      percentTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
        try {
          lane.flashProgress.value = await App.dllFunctions!.flashingData();
        } catch (_) {}
      });

      result = await App.dllFunctions!.startECUFlashing(
        flashJson,
        sequenceContent,
        ecuEntry.ecu!,
        ecuEntry.ecu?.seedkeyalgoFnIndex?.value ?? '',
      );
    } catch (e) {
      result = e.toString();
    }

    percentTimer?.cancel();
    lane.flashStopwatch?.cancel();
    lane.isFlashing.value = false;

    if (result == null || result.isEmpty || result != 'NOERROR') {
      lane.flashStatus.value = "Flash Failed: $result";
      return;
    }

    lane.flashProgress.value = 1;
    lane.flashStatus.value = "Flash Completed";

    await loadDtcForLane(index);

    await loadPidForLane(index);
  }

  Future<String> _downloadAsRawString(String url) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes = await response.fold<List<int>>(<int>[], (p, c) => p..addAll(c));
    client.close();
    return latin1.decode(bytes);
  }

  List<all_ds.EcuMapFile> _parseEcuMapFilesFromSequence(String sequenceContent) {
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
      return await GetJson().convertToJson(hexBytes, ecuMapFiles, checksumAlgo);
    } catch (e) {
      return "";
    }
  }

  // ===================================================
  // DTC — real API, now actually has a dataset id to call with.
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

  // ===================================================
  // PID / LIVE PARAMETER — real API, now actually has a
  // dataset id to call with.
  // ===================================================

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

      final List<Code> codes =
          (result.results ?? []).expand<Code>((item) => item.codes ?? []).toList();

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

  // ===================================================
  // INJECTOR STATUS — kept for the existing toggle grid;
  // superseded by the real IQA text fields for actual codes.
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

/// Bundles the resolved ECU entry together with the vehicle model /
/// sub-model ids it came from — the List Number scan needs those ids
/// to cross-check that a scanned List Number actually belongs to the
/// same vehicle the ESN resolved to, not just a coincidental code match.
class _IdentifiedEcu {
  final all_ds.SubmodelModelecu ecuEntry;
  final int? vehicleModelId;
  final int? subModelId;

  _IdentifiedEcu({
    required this.ecuEntry,
    required this.vehicleModelId,
    required this.subModelId,
  });
}
