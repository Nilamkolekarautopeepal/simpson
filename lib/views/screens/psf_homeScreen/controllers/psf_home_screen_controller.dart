// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:simpson/AppPreferences/app_areferences.dart';
// import 'package:simpson/common_widgets/popup.dart';
// import 'package:simpson/modals/all.models.dart' as all_ds;
// import 'package:simpson/modals/dtcDataset.model.dart' show DtcCode;
// import 'package:simpson/modals/esn.model.dart' as esn_ds;
// import 'package:simpson/modals/listNumber.model.dart' as list_ds;
// import 'package:simpson/modals/liveParameter_model.dart';
// import 'package:simpson/modals/pfsLaneRegister.model.dart';
// import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
// import 'package:simpson/modals/pidDataset.model.dart' show Code;
// import 'package:simpson/services/apiServices.dart';
// import 'package:simpson/services/connectionWifiService.dart';
// import 'package:simpson/services/getJson_service.dart';
// import 'package:simpson/services/plc/plc_service.dart';
// import 'pfs_lane.dart' hide psfLaneRegisterMap;

// String _decodeLatin1Isolate(Uint8List bytes) {
//   return latin1.decode(bytes);
// }

// class PsfHomeScreenController extends GetxController {
//   static final HttpClient _sharedHttpClient = HttpClient()
//     ..maxConnectionsPerHost = 8 // enough for several lanes downloading at once
//     ..connectionTimeout = const Duration(seconds: 15);
//   String? station;
//   final RxList<PsfLane> lanes = <PsfLane>[].obs;
//   final AuthService _authService = AuthService();
//   String? _accessToken;
//   final PlcService plcService = Get.find<PlcService>();
//   all_ds.AllModel? _modelsCache;
//   list_ds.ListNumber? _variantListCache;

//   final ConnectionWifi _connectionWifi = ConnectionWifi();
//   Future<T> _runFlashSerialized<T>(Future<T> Function() action) {
//     final previous = _flashQueue;
//     final completer = Completer<void>();
//     _flashQueue = completer.future;
//     return previous.then((_) async {
//       try {
//         return await action();
//       } finally {
//         completer.complete();
//       }
//     });
//   }

//   Future<void> _flashQueue = Future.value();
//   Future<T?> _withLaneDongleBusy<T>(
//       int laneIndex, Future<T> Function() action) async {
//     final lane = lanes[laneIndex];
//     if (lane.isDongleBusy) {
//       print(
//           '⏭️ [Lane ${lane.laneNumber}] dongle busy with another operation — ignoring this request');
//       return null;
//     }
//     lane.isDongleBusy = true;
//     try {
//       return await action();
//     } finally {
//       lane.isDongleBusy = false;
//     }
//   }

//   bool get isDongleConnectedAnywhere =>
//       lanes.any((l) => l.dongleConnected.value);
//   RxBool get isPlcConnected => plcService.isConnected;
//   RxBool get isPlcConnecting => plcService.isConnecting;
//   RxString get plcStatus => plcService.status;

//   @override
//   void onInit() {
//     super.onInit();
//     station = Get.arguments is String ? Get.arguments : "PFS Station";
//     _loadLanesFromDongleList();
//     _loadAccessToken();
//     _loadPlcConfig().then((_) => _autoConnectPlc());

//     debugPrint(
//       "PFS Controller Loaded",
//     );
//   }

//   Future<void> _loadLanesFromDongleList() async {
//     final raw = await SecureStorageService.getDongleList();
//     if (raw == null || raw.isEmpty) {
//       debugPrint("PFS: no dongle list found from login — no lanes to show.");
//       return;
//     }

//     try {
//       final List<dynamic> decoded = jsonDecode(raw);
//       final built = <PsfLane>[];

//       for (int i = 0; i < decoded.length; i++) {
//         final entry = decoded[i] as Map<String, dynamic>;
//         final ecuIdRaw = entry['ecuId'];
//         final ecuId = ecuIdRaw is int ? ecuIdRaw : int.tryParse('$ecuIdRaw');

//         built.add(PsfLane(
//           i + 1,
//           dongleIpFromLogin: entry['ip'] as String?,
//           expectedEcuId: ecuId,
//           macIdFromLogin: entry['macId'] as String?,
//         ));
//       }

//       lanes.assignAll(built);
//       debugPrint(
//           "PFS Controller Loaded : ${lanes.length} lane(s) from login dongle list");
//     } catch (e) {
//       debugPrint("PFS: failed to parse saved dongle list: $e");
//     }
//   }

//   Future<void> _loadAccessToken() async {
//     _accessToken = await SecureStorageService.getAccessToken();
//   }

//   @override
//   void onClose() {
//     _plcRetryTimer?.cancel();

//     for (final lane in lanes) {
//       lane.dispose();
//     }

//     super.onClose();
//   }

//   String? _plcIp;
//   int _plcPort = 502;
//   Timer? _plcRetryTimer;

//   Future<void> _loadPlcConfig() async {
//     _plcIp = await SecureStorageService.getPlcIp();
//     final portStr = await SecureStorageService.getPlcPort();
//     _plcPort = int.tryParse(portStr ?? '') ?? 502;
//   }

//   Future<void> _autoConnectPlc() async {
//     if (plcService.isConnected.value || plcService.isConnecting.value) return;
//     if (_plcIp == null || _plcIp!.isEmpty) return;
//     try {
//       await plcService.connect(_plcIp!, port: _plcPort);
//       _plcRetryTimer?.cancel();
//     } catch (e) {
//       debugPrint(
//           "PLC connection failed: $e — will keep retrying in the background");
//       _startPlcRetryTimer();
//     }
//   }

//   void _startPlcRetryTimer() {
//     _plcRetryTimer?.cancel();
//     _schedulePlcRetry(const Duration(seconds: 10));
//   }

//   void _schedulePlcRetry(Duration delay) {
//     _plcRetryTimer?.cancel();
//     _plcRetryTimer = Timer(delay, () async {
//       if (plcService.isConnected.value) return;

//       await _autoConnectPlc();

//       if (plcService.isConnected.value) return;

//       final nextDelay = Duration(seconds: (delay.inSeconds * 2).clamp(10, 60));
//       _schedulePlcRetry(nextDelay);
//     });
//   }

//   void onPlcButtonTapped() {
//     if (isPlcConnected.value) return;
//     _autoConnectPlc();
//   }

//   void onEsnFieldChanged(int laneIndex) {
//     final lane = lanes[laneIndex];
//     lane.esnIdleTimer?.cancel();
//     lane.esnIdleTimer = Timer(const Duration(seconds: 2), () {
//       onScanEsnForLane(laneIndex);
//     });
//   }

//   void _showScanFailedPopup(String title, String message) {
//     if (Get.isDialogOpen == true) Get.back();
//     Get.dialog(
//       CustomPopup(title: title, message: message, confirmText: 'OK'),
//       barrierDismissible: true,
//     );
//   }

//   Future<void> onScanEsnForLane(int laneIndex) async {
//     final lane = lanes[laneIndex];
//     lane.esnIdleTimer?.cancel();
//     final esn = lane.esnController.text.trim();

//     print('══════════════════════════════════════════');
//     print('🔹 [Lane ${lane.laneNumber}] ESN SCAN');
//     print('   Entered ESN: "$esn"');

//     if (esn.isEmpty) {
//       print('   ❌ ESN field empty — nothing to scan');
//       lane.esnError.value = "Enter ESN";
//       return;
//     }

//     lane.isLookingUpEsn.value = true;
//     lane.esnError.value = '';

//     try {
//       final result = await identifyModel(esn);
//       final resolvedEcuId = result.ecuEntry.ecu?.id;

//       print(
//           '   Resolved ECU id: $resolvedEcuId  |  Lane expects ECU id: ${lane.expectedEcuId}');
//       if (lane.expectedEcuId != null && resolvedEcuId != lane.expectedEcuId) {
//         print('   ❌ ECU mismatch — this ESN belongs to a different lane');
//         throw Exception(
//           'This ESN is wired for a different lane (resolved ECU id: '
//           '${resolvedEcuId ?? "unknown"}, expected: ${lane.expectedEcuId}).',
//         );
//       }

//       await applyLane(esn, laneIndex, result);
//       print(
//           '   ✅ ESN accepted — model/sub-model/ECU applied to Lane ${lane.laneNumber}');
//       print('══════════════════════════════════════════');

//       // Auto-advance to List Number once ESN resolves successfully.
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         lane.listNumberFocusNode.requestFocus();
//       });
//     } catch (e) {
//       final message = e.toString().replaceFirst('Exception: ', '');
//       print('   ❌ ESN scan failed: $message');
//       print('══════════════════════════════════════════');
//       lane.esnError.value = message;
//       _showScanFailedPopup('ESN Not Recognized', message);
//     } finally {
//       lane.isLookingUpEsn.value = false;
//     }
//   }

//   Future<all_ds.AllModel> _ensureModels() async {
//     if (_modelsCache != null) return _modelsCache!;
//     _accessToken ??= await SecureStorageService.getAccessToken();
//     _modelsCache = await _authService.getModels(accessToken: _accessToken);
//     return _modelsCache!;
//   }

//   Future<_IdentifiedEcu> identifyModel(
//     String esn,
//   ) async {
//     _accessToken ??= await SecureStorageService.getAccessToken();
//     final esnList =
//         await _authService.getEsnList(engSlno: esn, accessToken: _accessToken);

//     final match = (esnList.results ?? <esn_ds.Result>[]).firstWhereOrNull(
//       (r) => (r.engSlno ?? '').trim().toUpperCase() == esn.toUpperCase(),
//     );

//     if (match == null) {
//       throw Exception('ESN not recognized. Please rescan.');
//     }
//     if (match.isActive != true) {
//       throw Exception('ESN is not active.');
//     }

//     final modelName = match.model?.name?.trim();
//     final subModelName = match.subModel?.name?.trim();

//     print('   ESN catalog match → model="$modelName" subModel="$subModelName" '
//         '(model.id=${match.model?.id}, subModel.id=${match.subModel?.id})');

//     if (modelName == null ||
//         modelName.isEmpty ||
//         subModelName == null ||
//         subModelName.isEmpty) {
//       throw Exception('ESN match is missing model/sub-model information.');
//     }
//     final allModel = await _ensureModels();

//     all_ds.Result? matchedModel;
//     all_ds.SubModel? matchedSubModel;

//     for (final result in allModel.results ?? <all_ds.Result>[]) {
//       if ((result.name ?? '').trim().toUpperCase() != modelName.toUpperCase()) {
//         continue;
//       }
//       matchedModel = result;
//       for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
//         if ((subModel.name ?? '').trim().toUpperCase() ==
//             subModelName.toUpperCase()) {
//           matchedSubModel = subModel;
//           break;
//         }
//       }
//       break;
//     }

//     if (matchedModel == null || matchedSubModel == null) {
//       throw Exception(
//           'No matching model/sub-model found in catalog for "$modelName — $subModelName".');
//     }

//     final ecuEntry = matchedSubModel.submodelModelecu?.firstOrNull;
//     if (ecuEntry == null) {
//       throw Exception(
//           'No ECU configuration found for "$modelName — $subModelName".');
//     }

//     print('   Models catalog match → vehicleModel.id=${matchedModel.id} '
//         'subModel.id=${matchedSubModel.id} ecu.id=${ecuEntry.ecu?.id} '
//         'ecu.name=${ecuEntry.ecu?.name}');

//     return _IdentifiedEcu(
//       ecuEntry: ecuEntry,
//       vehicleModelId: matchedModel.id,
//       subModelId: matchedSubModel.id,
//     );
//   }

//   Future<void> applyLane(
//     String esn,
//     int laneIndex,
//     _IdentifiedEcu identified,
//   ) async {
//     final ecuEntry = identified.ecuEntry;
//     final lane = lanes[laneIndex];

//     lane.harnessTimer?.cancel();

//     lane.isTargetLane.value = true;
//     lane.isLocked.value = false;
//     lane.isLedOn.value = true;
//     lane.isHarnessConnected.value = false;
//     lane.esn.value = esn;

//     lane.matchedEcu = ecuEntry;
//     lane.matchedVehicleModelId = identified.vehicleModelId;
//     lane.matchedSubModelId = identified.subModelId;
//     lane.ecuModelName.value = ecuEntry.ecu?.name ?? 'Unknown Model';
//     lane.dtcDatasetId.value = ecuEntry.datasets?.firstOrNull?.id;
//     lane.pidDatasetId.value = ecuEntry.pidDatasets?.firstOrNull?.id;

//     final injectorCount = ecuEntry.noOfInjectors ?? 4;
//     final firingOrder = (ecuEntry.firingSequence ?? '')
//         .split(',')
//         .map((s) => s.trim())
//         .where((s) => s.isNotEmpty)
//         .toList();
//     lane.configureIqaFields(
//       injectorCount.clamp(1, 8),
//       firingSequence: firingOrder.length == injectorCount ? firingOrder : null,
//     );

//     print(
//         '   Lane ${lane.laneNumber} configured: ecuModelName="${lane.ecuModelName.value}" '
//         'dtcDatasetId=${lane.dtcDatasetId.value} pidDatasetId=${lane.pidDatasetId.value} '
//         'injectorCount=$injectorCount firingOrder=$firingOrder');
//     print(
//         '   Lane ${lane.laneNumber}: triggering dongle auto-connect at ${lane.dongleIpFromLogin}');
//     unawaited(connectDongleForLane(laneIndex));

//     if (plcService.isConnected.value && laneIndex < psfLaneRegisterMap.length) {
//       try {
//         await plcService.writeRegister(
//           psfLaneRegisterMap[laneIndex].ledOutputRegister,
//           1,
//         );
//       } catch (e) {
//         debugPrint(
//           "LED Error : $e",
//         );
//       }
//     }

//     if (laneIndex < psfLaneRegisterMap.length) {
//       lane.harnessTimer = Timer.periodic(
//         const Duration(
//           milliseconds: 800,
//         ),
//         (timer) {
//           checkHarness(
//             laneIndex,
//           );
//         },
//       );
//     }
//   }

//   Future<list_ds.ListNumber> _ensureVariantList(
//       {bool forceRefresh = false}) async {
//     if (!forceRefresh && _variantListCache != null) return _variantListCache!;
//     _accessToken ??= await SecureStorageService.getAccessToken();
//     _variantListCache =
//         await _authService.getVariantsList(accessToken: _accessToken);
//     return _variantListCache!;
//   }

//   void onListNumberFieldChanged(int laneIndex) {
//     final lane = lanes[laneIndex];
//     lane.listNumberIdleTimer?.cancel();
//     lane.listNumberIdleTimer = Timer(const Duration(seconds: 2), () {
//       onScanListNumberForLane(laneIndex);
//     });
//   }

//   Future<void> onScanListNumberForLane(int laneIndex) async {
//     final lane = lanes[laneIndex];
//     lane.listNumberIdleTimer?.cancel();
//     final scanned = lane.listNumberController.text.trim();

//     print('══════════════════════════════════════════');
//     print('🔹 [Lane ${lane.laneNumber}] LIST NUMBER SCAN');
//     print('   Entered List Number: "$scanned"');

//     if (scanned.isEmpty) {
//       print('   ❌ List Number field empty — nothing to scan');
//       print('══════════════════════════════════════════');
//       lane.listNumberError.value = "Enter List Number";
//       return;
//     }

//     if (lane.matchedEcu == null) {
//       print(
//           '   ❌ ESN not scanned yet for this lane — cannot resolve List Number');
//       print('══════════════════════════════════════════');
//       lane.listNumberError.value = "Scan ESN first";
//       return;
//     }

//     lane.isLookingUpListNumber.value = true;
//     lane.listNumberError.value = '';
//     lane.flashFilesError.value = '';

//     try {
//       final expectedEcuId = lane.matchedEcu!.ecu?.id;
//       final expectedVehicleModelId = lane.matchedVehicleModelId;
//       final expectedSubModelId = lane.matchedSubModelId;

//       print('🔍 [ListNumber] scanned="$scanned" '
//           'expectedEcuId=$expectedEcuId '
//           'expectedVehicleModelId=$expectedVehicleModelId '
//           'expectedSubModelId=$expectedSubModelId');

//       bool tryResolve(list_ds.ListNumber list) {
//         String leadingToken(String raw) {
//           final match = RegExp(r'^[A-Za-z0-9.]+').firstMatch(raw.trim());
//           return (match?.group(0) ?? raw.trim()).toUpperCase();
//         }

//         final scannedToken = leadingToken(scanned);

//         final variant = (list.results ?? []).firstWhereOrNull(
//           (r) => leadingToken(r.variantCode ?? '') == scannedToken,
//         );

//         if (variant == null) {
//           print('🔴 [ListNumber] no variant_code matched token "$scannedToken" '
//               'among: ${(list.results ?? []).map((r) => r.variantCode).join(', ')}');
//           return false;
//         }

//         print('🟢 [ListNumber] variant_code matched: id=${variant.id} '
//             'vehicleModel=${variant.vehicleModel} subModel=${variant.subModel} '
//             'dDatasetEcu=${variant.dDatasetEcu?.map((e) => 'ecu=${e.ecu}/active=${e.isActive}').join(',')}');

//         // Cross-check: the List Number must belong to the SAME
//         // vehicle model/sub-model the ESN actually resolved to — a
//         // variant_code match alone isn't enough, since a code could
//         // coincidentally match a variant for a different vehicle.
//         if (expectedVehicleModelId != null &&
//             variant.vehicleModel != expectedVehicleModelId) {
//           print('🔴 [ListNumber] vehicleModel mismatch: variant has '
//               '${variant.vehicleModel}, expected $expectedVehicleModelId');
//           return false;
//         }
//         if (expectedSubModelId != null &&
//             variant.subModel != expectedSubModelId) {
//           print('🔴 [ListNumber] subModel mismatch: variant has '
//               '${variant.subModel}, expected $expectedSubModelId');
//           return false;
//         }

//         // Resolve the flash file URL, trying every shape this
//         // endpoint has been confirmed to return: d_dataset_ecu and
//         // t_dataset_ecu (plain string data_file) first, falling back
//         // to the older variant_ecu shape (nested data_file object) if
//         // neither is present.
//         String? fileUrl;

//         final dMatch = (variant.dDatasetEcu ?? [])
//             .firstWhereOrNull((e) => e.ecu == expectedEcuId);
//         fileUrl = dMatch?.dataFile;

//         if (fileUrl == null || fileUrl.isEmpty) {
//           final tMatch = (variant.tDatasetEcu ?? [])
//               .firstWhereOrNull((e) => e.ecu == expectedEcuId);
//           fileUrl = tMatch?.dataFile;
//         }

//         if (fileUrl == null || fileUrl.isEmpty) {
//           final vMatch = (variant.variantEcu ?? [])
//               .firstWhereOrNull((e) => e.ecu == expectedEcuId);
//           fileUrl = vMatch?.dataFile?.dataFile;
//         }

//         if (fileUrl == null || fileUrl.isEmpty) {
//           print('🔴 [ListNumber] variant matched model/submodel but no ECU '
//               'entry (d/t/variant) has ecu=$expectedEcuId with a data_file');
//           return false;
//         }

//         print('🟢 [ListNumber] resolved fileUrl=$fileUrl');

//         lane.listNumber.value = scanned;
//         lane.resolvedFlashFileUrl.value = fileUrl;
//         lane.resolvedFlashFileName.value = fileUrl.split('/').last;

//         // Auto-advance to the first IQA field once List Number
//         // resolves successfully.
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           if (lane.iqaFocusNodes.isNotEmpty) {
//             lane.iqaFocusNodes.first.requestFocus();
//           }
//         });
//         return true;
//       }

//       final cached = await _ensureVariantList();
//       if (tryResolve(cached)) {
//         print(
//             '   ✅ List Number accepted — flash file resolved for Lane ${lane.laneNumber}');
//         print('══════════════════════════════════════════');
//         return;
//       }

//       // Refetch once to rule out a stale cache before giving up.
//       final fresh = await _ensureVariantList(forceRefresh: true);
//       if (tryResolve(fresh)) {
//         print(
//             '   ✅ List Number accepted (after refresh) — flash file resolved for Lane ${lane.laneNumber}');
//         print('══════════════════════════════════════════');
//         return;
//       }

//       throw Exception(
//         'No flash file found for List Number "$scanned" matching this '
//         'lane\'s vehicle model/sub-model and ECU.',
//       );
//     } catch (e) {
//       final message = e.toString().replaceFirst('Exception: ', '');
//       print('   ❌ List Number scan failed: $message');
//       print('══════════════════════════════════════════');
//       lane.listNumberError.value = message;
//       _showScanFailedPopup('List Number Not Found', message);
//     } finally {
//       lane.isLookingUpListNumber.value = false;
//     }
//   }

//   // ===================================================
//   // DONGLE — each lane gets its own independent connection via
//   // ConnectionWifi().connectDongleForLane(), so multiple lanes can be
//   // connected and flashing simultaneously.
//   // ===================================================

//   Future<void> connectDongleForLane(int laneIndex) async {
//     final lane = lanes[laneIndex];

//     print('══════════════════════════════════════════');
//     print(
//         '🔹 [Lane ${lane.laneNumber}] DONGLE CONNECT (independent connection)');
//     print(
//         '   IP: ${lane.dongleIpFromLogin}  ecu.id: ${lane.matchedEcu?.ecu?.id}');

//     if (lane.dongleConnected.value || lane.dongleConnecting.value) {
//       print('   ⏭️ already connected/connecting — skipping');
//       print('══════════════════════════════════════════');
//       return;
//     }

//     if (lane.isDongleBusy) {
//       print(
//           '   ⏭️ dongle busy with another operation — skipping this connect attempt');
//       print('══════════════════════════════════════════');
//       return;
//     }

//     final ip = lane.dongleIpFromLogin;
//     if (ip == null || ip.isEmpty) {
//       print('   ❌ no dongle IP on record from login');
//       print('══════════════════════════════════════════');
//       lane.dongleError.value =
//           'No dongle IP on record for this lane from login.';
//       return;
//     }

//     final ecu = lane.matchedEcu;
//     if (ecu == null) {
//       print('   ❌ no ECU resolved yet — scan ESN first');
//       print('══════════════════════════════════════════');
//       lane.dongleError.value = 'Scan ESN first — no ECU config resolved yet.';
//       return;
//     }

//     lane.dongleConnecting.value = true;
//     lane.dongleError.value = '';

//     try {
//       final channelParts = ecu.ecu?.channel?.split('-');
//       final channelId = (channelParts != null && channelParts.length > 1)
//           ? '0${channelParts[1]}'
//           : '00';

//       print(
//           '   Connecting to $ip (channelId=$channelId) — own independent socket…');
//       final connected =
//           await _connectionWifi.connectDongleForLane(ip, channelId: channelId);

//       if (connected == null) {
//         print('   ❌ connectDongleForLane returned null — connect failed');
//         print('══════════════════════════════════════════');
//         lane.dongleError.value = 'Failed to connect to dongle at $ip.';
//         lane.dongleConnected.value = false;
//         _startDongleRetryTimer(laneIndex);
//         return;
//       }

//       print('   ✅ Connected. MAC: ${connected.macId}');
//       lane.dllFunctions = connected.dll;

//       // Explicit-params version — takes THIS lane's ECU protocol/tx/rx
//       // directly, unlike setDongleProperties1() which reads the
//       // global StaticData.ecuInfo (a race if another lane's connect
//       // overwrites it in between).
//       await lane.dllFunctions!.setDongleProperties(
//         ecu.ecu?.protocol?.name ?? '',
//         ecu.ecu?.protocol?.autopeepal ?? '',
//         ecu.ecu?.txHeader ?? '',
//         ecu.ecu?.rxHeader ?? '',
//       );

//       print('   ✅ Dongle ready — configured for ${ecu.ecu?.name}');
//       print('══════════════════════════════════════════');
//       lane.dongleConnected.value = true;
//       lane.dongleRetryTimer?.cancel();
//     } catch (e) {
//       print('   ❌ Dongle connect exception: $e');
//       print('══════════════════════════════════════════');
//       lane.dongleError.value = e.toString().replaceFirst('Exception: ', '');
//       lane.dongleConnected.value = false;
//       lane.dllFunctions = null;
//       _startDongleRetryTimer(laneIndex);
//     } finally {
//       lane.dongleConnecting.value = false;
//     }
//   }

//   /// Tracks consecutive failed reconnect attempts per lane. Reset to
//   /// zero the moment a connect attempt succeeds.
//   final Map<int, int> _dongleRetryAttempts = {};

//   void _startDongleRetryTimer(int laneIndex) {
//     final lane = lanes[laneIndex];
//     lane.dongleRetryTimer?.cancel();
//     _dongleRetryAttempts[laneIndex] = 0;
//     _scheduleDongleRetry(laneIndex, const Duration(seconds: 10));
//   }

//   /// Schedules exactly ONE retry attempt after [delay], then — if it
//   /// still isn't connected — schedules the NEXT one with a longer
//   /// delay (10s → 20s → 40s → capped at 60s). This is deliberately NOT
//   /// a Timer.periodic: a periodic timer fires on a fixed clock
//   /// regardless of whether the previous attempt actually finished, and
//   /// a failing connect attempt (e.g. the underlying dongle module
//   /// needing time to recover, producing "semaphore timeout" errors)
//   /// can easily take longer than the retry interval — so the periodic
//   /// timer's next tick fires into a still-in-flight attempt and just
//   /// no-ops ("already connected/connecting — skipping") without ever
//   /// giving the dongle a genuine, clean second try. Chaining attempts
//   /// one at a time guarantees they never overlap.
//   ///
//   /// After 5 CONSECUTIVE failures with the identical low-level error
//   /// (Windows "semaphore timeout period has expired" — meaning the OS
//   /// couldn't even open a new TCP connection, not a logic error on our
//   /// side), the dongle is almost certainly hung/crashed and needs a
//   /// physical power cycle. Retrying forever in that state just hides
//   /// the real problem — so we stop and say so clearly instead.
//   void _scheduleDongleRetry(int laneIndex, Duration delay) {
//     final lane = lanes[laneIndex];
//     lane.dongleRetryTimer?.cancel();
//     lane.dongleRetryTimer = Timer(delay, () async {
//       if (lane.dongleConnected.value) return;

//       await connectDongleForLane(laneIndex);

//       if (lane.dongleConnected.value) {
//         _dongleRetryAttempts[laneIndex] = 0;
//         return;
//       }

//       final attempts = (_dongleRetryAttempts[laneIndex] ?? 0) + 1;
//       _dongleRetryAttempts[laneIndex] = attempts;

//       if (attempts >= 5) {
//         print(
//             '   🛑 [Lane ${lane.laneNumber}] Giving up after $attempts failed reconnect attempts.');
//         print(
//             '   🛑 This looks like a hung/crashed dongle, not a software issue —');
//         print(
//             '   🛑 the OS could not even open a new TCP connection to it. Please');
//         print(
//             '   🛑 physically power-cycle Lane ${lane.laneNumber}\'s dongle, then tap the reconnect button.');
//         try {
//           Get.snackbar(
//             'Lane ${lane.laneNumber} dongle unresponsive',
//             'Power-cycle the dongle, then tap reconnect. Auto-retry stopped after $attempts failed attempts.',
//             duration: const Duration(seconds: 8),
//           );
//         } catch (_) {}
//         return; // stop scheduling further retries
//       }

//       final nextDelay = Duration(seconds: (delay.inSeconds * 2).clamp(10, 60));
//       _scheduleDongleRetry(laneIndex, nextDelay);
//     });
//   }

//   /// Releases this lane's own dongle connection. Since each lane has
//   /// its own independent DLLFunctions instance now, this doesn't
//   /// affect any other lane.
//   void releaseDongleForLane(int laneIndex) {
//     lanes[laneIndex].dongleConnected.value = false;
//     lanes[laneIndex].dongleRetryTimer?.cancel();
//     lanes[laneIndex].dllFunctions = null;
//   }

//   // ===================================================
//   // IQA field changes
//   // ===================================================

//   void onIqaFieldChanged(int laneIndex, int iqaIndex) {
//     final lane = lanes[laneIndex];

//     // Keep the live "N / 4 scanned" counter updating immediately as you
//     // type, but debounce the actual auto-advance check so it only
//     // fires after a short pause — otherwise focus would jump to the
//     // next field after the very first keystroke.
//     lane.refreshIqaAllFilled();

//     lane.iqaIdleTimers[iqaIndex]?.cancel();
//     lane.iqaIdleTimers[iqaIndex] = Timer(const Duration(milliseconds: 500), () {
//       _submitIqaField(laneIndex, iqaIndex);
//     });
//   }

//   void _submitIqaField(int laneIndex, int iqaIndex) {
//     final lane = lanes[laneIndex];
//     final value = lane.iqaControllers[iqaIndex].text.trim();
//     if (value.isEmpty) return;

//     print('🔹 [Lane ${lane.laneNumber}] IQA ${iqaIndex + 1} entered: "$value"  '
//         '(${lane.filledIqaCount.value}/${lane.iqaControllers.length} filled)');

//     // Auto-advance to the next IQA field, same as scanning through the
//     // Test Station's IQA group.
//     if (iqaIndex < lane.iqaFocusNodes.length - 1) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         lane.iqaFocusNodes[iqaIndex + 1].requestFocus();
//       });
//     } else if (lane.iqaAllFilled.value) {
//       print(
//           '   ✅ All IQA fields filled for Lane ${lane.laneNumber} — ready for flash file box');
//     }
//   }

//   // ===================================================
//   // HARNESS CHECK
//   // ===================================================

//   Future<void> checkHarness(
//     int index,
//   ) async {
//     if (!plcService.isConnected.value) return;
//     if (index >= psfLaneRegisterMap.length) return;

//     final register = psfLaneRegisterMap[index];

//     try {
//       final result = await plcService.readRegister(
//         register.harnessConnectedInputRegister,
//       );

//       lanes[index].isHarnessConnected.value = result == 1;
//     } catch (e) {
//       debugPrint(
//         "Harness Error : $e",
//       );
//     }
//   }

//   // ===================================================
//   // RESET — resets just this one lane, independent of the others.
//   // ===================================================

//   void resetLane(int laneIndex) {
//     lanes[laneIndex].resetToUnlockedIdle();
//   }

//   Future<void> onStartFlash(
//     int index,
//   ) async {
//     final lane = lanes[index];

//     print('══════════════════════════════════════════');
//     print('🔹 [Lane ${lane.laneNumber}] START FLASH');
//     print('   Flash file URL: ${lane.resolvedFlashFileUrl.value}');
//     print(
//         '   Dongle connected: ${lane.dongleConnected.value}  has own dllFunctions: ${lane.dllFunctions != null}');

//     if (lane.isFlashing.value) {
//       print('   ⏭️ already flashing — ignoring tap');
//       print('══════════════════════════════════════════');
//       return;
//     }

//     if (lane.resolvedFlashFileUrl.value == null) {
//       print('   ❌ no flash file resolved — scan List Number first');
//       print('══════════════════════════════════════════');
//       Get.snackbar(
//           'Flash', 'Scan a List Number first to resolve the flash file.');
//       return;
//     }

//     if (!lane.dongleConnected.value || lane.dllFunctions == null) {
//       print('   ❌ this lane\'s dongle isn\'t connected — cannot flash');
//       print('══════════════════════════════════════════');
//       Get.snackbar('Flash', 'Connect the dongle for this lane first.');
//       return;
//     }

//     if (lane.isDongleBusy) {
//       print(
//           '   ⏭️ this lane\'s dongle is busy with another operation (Live Parameter read, DTC read, etc) — cannot flash yet');
//       print('══════════════════════════════════════════');
//       Get.snackbar('Flash',
//           'This lane\'s dongle is busy — wait for the current operation to finish.');
//       return;
//     }
//     lane.isDongleBusy = true;

//     final dll = lane.dllFunctions!;

//     lane.isFlashing.value = true;
//     lane.flashStatus.value = "Flashing Started";
//     lane.flashProgress.value = 0;
//     lane.flashElapsedSeconds.value = 0;
//     lane.flashStopwatch?.cancel();
//     lane.flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
//       lane.flashElapsedSeconds.value++;
//     });

//     Timer? percentTimer;
//     String? result;

//     try {
//       final hexUrl = lane.resolvedFlashFileUrl.value!;
//       final ecuEntry = lane.matchedEcu;

//       if (ecuEntry == null || ecuEntry.flashFile == null) {
//         throw Exception("Flash file configuration missing");
//       }

//       final flashConfig = ecuEntry.flashFile!;

//       print(
//           '   ECU: ${ecuEntry.ecu?.name}  protocol: ${ecuEntry.ecu?.protocol?.name}');
//       print('   Downloading sequence file + firmware hex in parallel…');
//       final results = await Future.wait([
//         _downloadAsRawStringFast(flashConfig.sequenceFile!),
//         _downloadAsRawStringFast(hexUrl),
//       ]);
//       final sequenceContent = results[0];
//       final hexContent = results[1];

//       var ecuMapFiles = flashConfig.ecuMapFile ?? <all_ds.EcuMapFile>[];
//       if (ecuMapFiles.isEmpty) {
//         ecuMapFiles = _parseEcuMapFilesFromSequence(sequenceContent);
//       }
//       if (ecuMapFiles.isEmpty) {
//         throw Exception("ECU MAP FILE missing — cannot generate flash JSON.");
//       }
//       print('   ECU map file entries: ${ecuMapFiles.length}');

//       final flashJson = await _readJson(
//         ecuMapFiles,
//         flashConfig.flashCheckSumType?.toString() ?? '',
//         Uint8List.fromList(hexContent.codeUnits),
//       );

//       if (flashJson.isEmpty) {
//         throw Exception("Flash JSON generation failed");
//       }
//       print(
//           '   Flash JSON generated (${flashJson.length} chars) — waiting for turn to flash…');
//       result = await _runFlashSerialized(() async {
//         print(
//             '   ▶️ [Lane ${lane.laneNumber}] starting ECU flash now (own turn)');

//         await dll.setDongleProperties(
//           ecuEntry.ecu?.protocol?.name ?? '',
//           ecuEntry.ecu?.protocol?.autopeepal ?? '',
//           ecuEntry.ecu?.txHeader ?? '',
//           ecuEntry.ecu?.rxHeader ?? '',
//         );

//         percentTimer =
//             Timer.periodic(const Duration(milliseconds: 500), (_) async {
//           try {
//             lane.flashProgress.value = await dll.flashingData();
//           } catch (_) {}
//         });

//         return dll.startECUFlashing(
//           flashJson,
//           sequenceContent,
//           ecuEntry.ecu!,
//           ecuEntry.ecu?.seedkeyalgoFnIndex?.value ?? '',
//         );
//       });
//       print('   startECUFlashing() result: $result');
//     } catch (e) {
//       print('   ❌ Flash exception: $e');
//       result = e.toString();
//     }

//     percentTimer?.cancel();
//     lane.flashStopwatch?.cancel();
//     lane.isFlashing.value = false;

//     if (result == null || result.isEmpty || result != 'NOERROR') {
//       print('   ❌ Flash FAILED: $result  (elapsed ${lane.formattedElapsed})');
//       final r = result?.toLowerCase() ?? '';
//       final looksDisconnected = r.contains('no resp') ||
//           r.contains('socket_closed') ||
//           r.contains('noresponsefromecu');

//       if (looksDisconnected) {
//         print(
//             '   ⚠️ Failure looks like a dead connection — marking Lane ${lane.laneNumber}\'s dongle disconnected');
//         lane.dongleConnected.value = false;
//         lane.dllFunctions = null;
//         _startDongleRetryTimer(index);
//       }

//       print('══════════════════════════════════════════');
//       lane.flashStatus.value = "Flash Failed: $result";
//       lane.isDongleBusy = false;
//       return;
//     }

//     print(
//         '   ✅ Flash COMPLETED in ${lane.formattedElapsed} — reading DTC/PID, writing IQA…');
//     print('══════════════════════════════════════════');
//     lane.flashProgress.value = 1;
//     lane.flashStatus.value = "Flash Completed";

//     await Future.delayed(const Duration(milliseconds: 500));
//     await readLiveDtcForLane(index);

//     await Future.delayed(const Duration(milliseconds: 300));
//     await loadPidForLane(index);

//     lane.iqaWriteStatus.value = await autoWriteIqaValuesForLane(index);
//     lane.isDongleBusy = false;
//   }

//   Future<String> _downloadAsRawStringFast(String url) async {
//     final request = await _sharedHttpClient.getUrl(Uri.parse(url));
//     final response = await request.close();

//     final builder = BytesBuilder(copy: false);
//     await for (final chunk in response) {
//       builder.add(chunk);
//     }
//     final bytes = builder.takeBytes();

//     return await compute(_decodeLatin1Isolate, bytes);
//   }

//   List<all_ds.EcuMapFile> _parseEcuMapFilesFromSequence(
//       String sequenceContent) {
//     final result = <all_ds.EcuMapFile>[];

//     for (final rawLine in sequenceContent.split('\n')) {
//       final line = rawLine.replaceAll('\r', '').trim();
//       if (!line.startsWith('EcuMapFile')) continue;

//       final colonIdx = line.indexOf(':');
//       if (colonIdx == -1) continue;
//       final info = line.substring(colonIdx + 1);

//       String? startAddress;
//       String? endAddress;

//       for (final item in info.split('+')) {
//         final trimmed = item.trim();
//         if (!trimmed.startsWith('<')) continue;
//         final endIdx = trimmed.indexOf('>');
//         if (endIdx == -1) continue;

//         final bracket = trimmed.substring(1, endIdx);
//         final values = bracket.split(',');
//         if (values.length < 2) continue;

//         final reference = values[0].trim();
//         final value = values[1].trim();

//         if (reference.contains('start_address')) {
//           startAddress = value;
//         } else if (reference.contains('end_address')) {
//           endAddress = value;
//         }
//       }

//       if (startAddress != null && endAddress != null) {
//         result.add(all_ds.EcuMapFile(
//           startAddress: startAddress,
//           startAddr: int.tryParse(startAddress, radix: 16),
//           endAddress: endAddress,
//           endAddr: int.tryParse(endAddress, radix: 16),
//         ));
//       }
//     }

//     return result;
//   }

//   Future<String> _readJson(
//     List<all_ds.EcuMapFile> ecuMapFiles,
//     String checksumAlgo,
//     Uint8List hexBytes,
//   ) async {
//     try {
//       return await compute(
//         convertHexToJsonIsolate,
//         HexToJsonArgs(
//             streamBytes: hexBytes,
//             ecuMapFiles: ecuMapFiles,
//             checksumAlgo: checksumAlgo),
//       );
//     } catch (e) {
//       return "";
//     }
//   }

//   Future<void> loadDtcForLane(
//     int index,
//   ) async {
//     final lane = lanes[index];

//     if (lane.dtcDatasetId.value == null) {
//       lane.dtcError.value = "DTC dataset not available";

//       return;
//     }

//     try {
//       lane.isLoadingDtc.value = true;
//       lane.dtcError.value = '';

//       _accessToken ??= await SecureStorageService.getAccessToken();
//       final result = await _authService.getDtcDataset(
//         id: lane.dtcDatasetId.value!,
//         accessToken: _accessToken,
//       );

//       final List<DtcCode> codes = (result.results ?? [])
//           .expand<DtcCode>((item) => item.dtcCode ?? [])
//           .toList();

//       lane.dtcCodes.assignAll(
//         codes,
//       );
//     } catch (e) {
//       lane.dtcError.value = e.toString().replaceFirst('Exception: ', '');
//     } finally {
//       lane.isLoadingDtc.value = false;
//     }
//   }

//   Future<void> onOpenDtc(
//     int index,
//   ) async {
//     await loadDtcForLane(
//       index,
//     );
//   }

//   /// the shared App.dllFunctions.
//   Future<void> readLiveDtcForLane(int laneIndex) async {
//     final lane = lanes[laneIndex];

//     print('══════════════════════════════════════════');
//     print('🔹 [Lane ${lane.laneNumber}] DTC READ (live ECU)');

//     if (lane.dllFunctions == null || lane.matchedEcu == null) {
//       print('   ❌ dongle not connected for this lane — cannot read DTCs');
//       print('══════════════════════════════════════════');
//       lane.dtcError.value = 'Connect the dongle for this lane first.';
//       return;
//     }

//     final ecu = lane.matchedEcu!.ecu;
//     if (ecu?.readDtcFnIndex?.value == null) {
//       print('   ❌ no read_dtc_index configured for this ECU');
//       print('══════════════════════════════════════════');
//       lane.dtcError.value = 'No DTC read function configured for this ECU.';
//       return;
//     }

//     lane.isReadingDtc.value = true;
//     lane.dtcError.value = '';

//     try {
//       // Make sure the dataset catalog (for descriptions) is loaded.
//       if (lane.dtcCodes.isEmpty) {
//         await loadDtcForLane(laneIndex);
//       }

//       await lane.dllFunctions!.setDongleProperties(
//         ecu?.protocol?.name ?? '',
//         ecu?.protocol?.autopeepal ?? '',
//         ecu?.txHeader ?? '',
//         ecu?.rxHeader ?? '',
//       );

//       print('   Reading DTCs from ${ecu?.name}...');
//       final readResult =
//           await lane.dllFunctions!.readDtc(ecu!.readDtcFnIndex!.value!);

//       if (readResult == null) {
//         print('   ❌ DTC read: ECU_COMMUNICATION_ERROR');
//         print('══════════════════════════════════════════');
//         lane.dtcReadResults.clear();
//         lane.dongleConnected.value = false;
//         lane.dllFunctions = null;
//         _startDongleRetryTimer(laneIndex);
//         return;
//       }

//       if (readResult.status != 'NO_ERROR') {
//         print('   ❌ DTC read failed: ${readResult.status}');
//         print('══════════════════════════════════════════');
//         lane.dtcReadResults.clear();
//         final statusText = readResult.status.toString().toLowerCase();
//         if (statusText.contains('no resp') ||
//             statusText.contains('socket_closed')) {
//           lane.dongleConnected.value = false;
//           lane.dllFunctions = null;
//           _startDongleRetryTimer(laneIndex);
//         }
//         lane.dtcError.value = readResult.status ?? 'DTC read failed';
//         return;
//       }

//       final rows = readResult.dtcs ?? [];
//       final merged = <String, String>{};

//       for (final row in rows) {
//         if (row.length < 2) continue;
//         final code = row[0];
//         final status = row[1];

//         final match = lane.dtcCodes.firstWhereOrNull((c) => c.code == code);
//         final desc = match?.description ?? 'Description not found';

//         merged[code] = '$code - $desc ($status)';
//       }

//       lane.dtcReadResults.assignAll(merged.values.toList());
//       print('   ✅ DTC read complete (${lane.dtcReadResults.length} code(s))');
//       print('══════════════════════════════════════════');
//     } catch (e) {
//       print('   ❌ DTC read exception: $e');
//       print('══════════════════════════════════════════');
//       lane.dtcError.value = e.toString().replaceFirst('Exception: ', '');
//       lane.dtcReadResults.clear();
//     } finally {
//       lane.isReadingDtc.value = false;
//     }
//   }

//   Future<String> autoWriteIqaValuesForLane(int laneIndex) async {
//     final lane = lanes[laneIndex];

//     print('══════════════════════════════════════════');
//     print('🔹 [Lane ${lane.laneNumber}] IQA WRITE');

//     try {
//       // Make sure the PID dataset (which carries the IQA code) is loaded.
//       if (lane.iqaParameterCodes.isEmpty) {
//         await loadPidForLane(laneIndex);
//       }

//       final iqaPid = lane.iqaParameterCodes.firstOrNull;
//       if (iqaPid == null) {
//         print('   ⏭️ IQA PID not found — skipping write');
//         print('══════════════════════════════════════════');
//         return 'IQA write skipped: IQA PID not found';
//       }

//       for (int i = 0; i < lane.iqaControllers.length; i++) {
//         final value = lane.iqaControllers[i].text.trim();
//         if (value.length != 7) {
//           print(
//               '   ⏭️ ${lane.iqaLabelFor(i)} is not 7 characters — skipping write');
//           print('══════════════════════════════════════════');
//           return 'IQA write skipped: enter a valid 7-character value for each cylinder';
//         }
//       }

//       List<pid_ds.PiCodeVariables> variables =
//           List<pid_ds.PiCodeVariables>.from(iqaPid.piCodeVariable ?? []);
//       variables.sort((a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0));

//       final order = lane.firingOrder;
//       if (order != null && order.length == variables.length) {
//         variables = order.map((e) => variables[int.parse(e) - 1]).toList();
//       }

//       final writeInput = Uint8List(iqaPid.totalLen ?? 0);
//       final List<VariantDataLists> variantList = [];

//       final int loopCount = variables.length < lane.iqaControllers.length
//           ? variables.length
//           : lane.iqaControllers.length;

//       for (int i = 0; i < loopCount; i++) {
//         final variable = variables[i];
//         final value = lane.iqaControllers[i].text.trim().toUpperCase();
//         final bytes = latin1.encode(value);

//         final start = variable.bytePosition! - 1;
//         final end = start + bytes.length;

//         if (start < 0 || end > writeInput.length) {
//           print('   ❌ byte range [$start,$end) out of bounds for writeInput '
//               'length ${writeInput.length} (variable=${variable.shortName})');
//           print('══════════════════════════════════════════');
//           return 'IQA write failed: byte layout mismatch for this ECU — '
//               'check PID dataset for ${variable.shortName}';
//         }

//         writeInput.setRange(start, end, bytes);

//         variantList.add(VariantDataLists(
//           pidId: variable.id,
//           pidName: variable.shortName,
//           startByte: variable.bytePosition,
//           noOfBytes: variable.length,
//           datatype: variable.messageType.toString(),
//           resolution: variable.resolution,
//           offset: variable.offset,
//           unit: variable.unit,
//           isBitcoded: variable.bitcoded,
//           startBit: variable.startBitPosition ?? 0,
//           noofBits: 0,
//         ));
//       }

//       final int startByte =
//           variantList.map((e) => e.startByte!).reduce((a, b) => a < b ? a : b);

//       final ecu = lane.matchedEcu?.ecu;
//       if (ecu?.writeDataFnIndex?.value == null) {
//         print('   ⏭️ ECU write function not configured — skipping');
//         print('══════════════════════════════════════════');
//         return 'IQA write skipped: ECU configuration not found';
//       }

//       final dll = lane.dllFunctions;
//       if (dll == null) {
//         print('   ❌ dongle not connected for this lane — cannot write IQA');
//         print('══════════════════════════════════════════');
//         return 'IQA write failed: dongle not connected';
//       }

//       final pid = WriteParameterPid(
//         writePamIndex: ecu?.writeDataFnIndex?.value,
//         seedKeyIndex: ecu?.seedkeyalgoFnIndex?.value,
//         writePid: iqaPid.writePid,
//         writeParaDataSize: iqaPid.totalLen,
//         writeInput: writeInput,
//         pid: iqaPid.code,
//         totalLen: iqaPid.totalLen,
//         totalBytes: iqaPid.totalLen,
//         startByte: startByte,
//         variantList: variantList,
//       );

//       const maxRetries = 4;
//       const initialDelay = Duration(seconds: 2);
//       var delay = initialDelay;

//       for (var attempt = 1; attempt <= maxRetries; attempt++) {
//         print('   Writing IQA values to ECU... (attempt $attempt/$maxRetries)');

//         final response =
//             await dll.writePid(ecu!.writeDataFnIndex!.value!, [pid]);
//         final status = response?.first.status?.toUpperCase();

//         if (response != null && response.isNotEmpty && status == "NOERROR") {
//           print('   ✅ IQA write successful');
//           print('══════════════════════════════════════════');
//           return 'IQA write: Successful';
//         }

//         if (status != null && status.contains('REQUIREDTIMEDELAYNOTEXPIRED')) {
//           print(
//               '   ⏳ ECU not ready yet — waiting ${delay.inSeconds}s before retry '
//               '${attempt + 1}/$maxRetries');
//           await Future.delayed(delay);
//           delay *= 2;
//           continue;
//         }

//         final failMsg = (response == null || response.isEmpty)
//             ? "No response from ECU"
//             : (response.first.status ?? "Write Failed");
//         print('   ❌ IQA write failed: $failMsg');
//         print('══════════════════════════════════════════');
//         return 'IQA write failed: $failMsg';
//       }

//       print('   ❌ IQA write failed: ECU still busy after $maxRetries attempts');
//       print('══════════════════════════════════════════');
//       return 'IQA write failed: requiredTimeDelayNotExpired (gave up after retries)';
//     } catch (e) {
//       print('   ❌ IQA auto-write exception: $e');
//       print('══════════════════════════════════════════');
//       return 'IQA write failed: $e';
//     }
//   }

//   Future<void> loadPidForLane(
//     int index,
//   ) async {
//     final lane = lanes[index];

//     if (lane.pidDatasetId.value == null) {
//       lane.pidError.value = "PID dataset not available";
//       return;
//     }

//     try {
//       lane.isLoadingPid.value = true;
//       lane.pidError.value = '';

//       _accessToken ??= await SecureStorageService.getAccessToken();
//       final result = await _authService.getPidDataset(
//         id: lane.pidDatasetId.value!,
//         accessToken: _accessToken,
//       );

//       final List<Code> codes = (result.results ?? [])
//           .expand<Code>((item) => item.codes ?? [])
//           .toList();

//       lane.applyPidCodes(
//         codes,
//       );
//     } catch (e) {
//       lane.pidError.value = e.toString().replaceFirst('Exception: ', '');
//     } finally {
//       lane.isLoadingPid.value = false;
//     }
//   }

//   Future<void> onOpenLiveParameter(
//     int index,
//   ) async {
//     await loadPidForLane(
//       index,
//     );
//   }

//   Future<void> togglePidPlaybackForLane(int laneIndex) async {
//     final lane = lanes[laneIndex];

//     if (lane.pidPlaying.value) {
//       lane.stopPidLoop = true;
//       lane.pidPlaying.value = false;
//       print('🔹 [Lane ${lane.laneNumber}] Live PID read stopped');
//       return;
//     }

//     if (lane.dllFunctions == null) {
//       Get.snackbar('Live Parameter', 'Connect the dongle for this lane first.');
//       return;
//     }

//     if (lane.liveParameterCodes.isEmpty) {
//       Get.snackbar('Live Parameter', 'No parameters available to run.');
//       return;
//     }

//     if (lane.isDongleBusy) {
//       Get.snackbar('Live Parameter',
//           'This lane\'s dongle is busy with another operation — try again shortly.');
//       return;
//     }

//     lane.stopPidLoop = false;
//     lane.pidPlaying.value = true;
//     lane.isDongleBusy = true;

//     print('══════════════════════════════════════════');
//     print('🔹 [Lane ${lane.laneNumber}] LIVE PID READ');
//     print('   Parameters: ${lane.liveParameterCodes.length}');

//     final ok = await _readLivePidOnceForLane(
//         laneIndex, lane.liveParameterCodes.toList());
//     lane.isDongleBusy = false;

//     if (!lane.stopPidLoop) {
//       lane.pidPlaying.value = false;
//       print(ok
//           ? '   ✅ Live PID read complete'
//           : '   ❌ Live PID read finished with errors');
//       print('══════════════════════════════════════════');
//     }
//   }

//   Future<bool> _readLivePidOnceForLane(
//       int laneIndex, List<pid_ds.Code> codes) async {
//     final lane = lanes[laneIndex];
//     final dll = lane.dllFunctions;
//     if (dll == null) return false;

//     try {
//       final responses = await dll.readPid(codes);

//       if (responses == null) {
//         print('   ❌ Live PID read: no response from ECU');
//         return false;
//       }

//       for (final resp in responses) {
//         final code = codes.firstWhereOrNull((c) => c.id == resp.pidId);
//         if (code == null) continue;

//         if (resp.status == 'NOERROR') {
//           for (final variable
//               in code.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
//             final item = resp.variables
//                 .firstWhereOrNull((v) => v.pidNumber == variable.id);
//             if (variable.id != null) {
//               lane.livePidValues[variable.id!] =
//                   item?.responseValue ?? 'Not Found';
//             }
//           }
//         } else {
//           for (final variable
//               in code.piCodeVariable ?? <pid_ds.PiCodeVariables>[]) {
//             if (variable.id != null) {
//               lane.livePidValues[variable.id!] = resp.status ?? 'ERROR';
//             }
//           }
//         }
//       }

//       return true;
//     } catch (e) {
//       print('   ❌ Live PID read error: $e');
//       return false;
//     }
//   }

//   // ===================================================
//   // INJECTOR STATUS — kept for the existing toggle grid;
//   // superseded by the real IQA text fields for actual codes.
//   // ===================================================

//   void onToggleInjector(
//     int laneIndex,
//     int injectorIndex,
//   ) {
//     final lane = lanes[laneIndex];

//     if (lane.isLocked.value) return;

//     if (injectorIndex < lane.injectorStatus.length) {
//       lane.injectorStatus[injectorIndex] = !lane.injectorStatus[injectorIndex];

//       lane.injectorStatus.refresh();
//     }
//   }

//   void onToggleIqa(
//     int laneIndex,
//     int iqaIndex,
//   ) {
//     final lane = lanes[laneIndex];

//     if (lane.isLocked.value) return;

//     if (iqaIndex < lane.iqaStatus.length) {
//       lane.iqaStatus[iqaIndex] = !lane.iqaStatus[iqaIndex];

//       lane.iqaStatus.refresh();
//     }
//   }

//   // ===================================================
//   // REFRESH LANE
//   // ===================================================

//   void onRefreshLane(
//     int index,
//   ) {
//     if (index >= lanes.length) return;

//     lanes[index].isLedOn.toggle();
//   }

//   void logout() {
//     Get.offAllNamed(
//       "/login",
//     );
//   }
// }

// class _IdentifiedEcu {
//   final all_ds.SubmodelModelecu ecuEntry;
//   final int? vehicleModelId;
//   final int? subModelId;

//   _IdentifiedEcu({
//     required this.ecuEntry,
//     required this.vehicleModelId,
//     required this.subModelId,
//   });
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
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
import 'package:simpson/services/plc/plc_service.dart';
import 'package:simpson/services/pfs_isolate_flash.dart';
import 'pfs_lane.dart' hide psfLaneRegisterMap;

String _decodeLatin1Isolate(Uint8List bytes) {
  return latin1.decode(bytes);
}

class PsfHomeScreenController extends GetxController {
  static final HttpClient _sharedHttpClient = HttpClient()
    ..maxConnectionsPerHost = 8 // enough for several lanes downloading at once
    ..connectionTimeout = const Duration(seconds: 15);
  String? station;
  final RxList<PsfLane> lanes = <PsfLane>[].obs;
  final AuthService _authService = AuthService();
  String? _accessToken;
  final PlcService plcService = Get.find<PlcService>();
  all_ds.AllModel? _modelsCache;
  list_ds.ListNumber? _variantListCache;

  final ConnectionWifi _connectionWifi = ConnectionWifi();

  /// Guarantees no two lanes' flash isolates spawn within 8 seconds of
  /// each other — matching the reference project's proven timing.
  /// Pure simultaneous start (even with full isolate-level separation)
  /// triggered an intermittent failure in the second-starting ECU in
  /// the reference project too — pointing to something at the
  /// dongle/hardware level that briefly chokes if two connections
  /// initialize at the exact same instant. This is chained one at a
  /// time (never a periodic/fixed-clock timer), so it's always
  /// exactly 8s after the PREVIOUS spawn, regardless of how many lanes
  /// are queuing up.
  DateTime? _lastIsolateFlashStart;

  Future<void> _staggerIsolateFlashStart() async {
    const minGap = Duration(seconds: 8);
    final last = _lastIsolateFlashStart;
    if (last != null) {
      final elapsed = DateTime.now().difference(last);
      if (elapsed < minGap) {
        final wait = minGap - elapsed;
        print('   ⏳ Staggering flash isolate start by ${wait.inMilliseconds}ms');
        await Future.delayed(wait);
      }
    }
    _lastIsolateFlashStart = DateTime.now();
  }

  /// Spawns a real Dart isolate to run one lane's entire flash —
  /// connect, configure, and transfer — completely independently of
  /// every other lane. This is genuine OS-scheduled parallelism, not
  /// cooperative async/await sharing the main isolate — which is what
  /// the earlier same-isolate serialization queue had to work around
  /// (running two flashes on the shared main isolate at once produced
  /// ECUERROR_WRONGBLOCKSEQCOUNTER, since the block-counter tracking
  /// inside the ap_dongle_comm/ap_diagnostic packages isn't safe for
  /// concurrent use on one isolate). A fresh connection is created
  /// entirely INSIDE the spawned isolate — never handed off from the
  /// main isolate — since a live Socket can't cross isolate boundaries.
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
    await _staggerIsolateFlashStart();

    final receivePort = ReceivePort();
    Isolate? isolate;
    final completer = Completer<String?>();

    final sub = receivePort.listen((message) {
      if (message is PfsFlashMessage) {
        if (message.type == 'progress' && message.percent != null) {
          onProgress(message.percent!);
        } else if (message.type == 'done') {
          if (!completer.isCompleted) completer.complete(message.result);
        } else if (message.type == 'error') {
          if (!completer.isCompleted) {
            completer.complete(message.result ?? 'ERROR');
          }
        }
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

      final result = await completer.future;
      return result;
    } catch (e) {
      print('   ❌ [Lane $laneNumber] isolate spawn/run failed: $e');
      return e.toString();
    } finally {
      await sub.cancel();
      receivePort.close();
      isolate?.kill(priority: Isolate.immediate);
    }
  }

  Future<T?> _withLaneDongleBusy<T>(
      int laneIndex, Future<T> Function() action) async {
    final lane = lanes[laneIndex];
    if (lane.isDongleBusy) {
      print(
          '⏭️ [Lane ${lane.laneNumber}] dongle busy with another operation — ignoring this request');
      return null;
    }
    lane.isDongleBusy = true;
    try {
      return await action();
    } finally {
      lane.isDongleBusy = false;
    }
  }

  bool get isDongleConnectedAnywhere => lanes
      .any((l) => l.dongleConnected.value || l.isFlashing.value);
  RxBool get isPlcConnected => plcService.isConnected;
  RxBool get isPlcConnecting => plcService.isConnecting;
  RxString get plcStatus => plcService.status;

  @override
  void onInit() {
    super.onInit();
    station = Get.arguments is String ? Get.arguments : "PFS Station";
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
      print(
          '   ✅ ESN accepted — model/sub-model/ECU applied to Lane ${lane.laneNumber}');
      print('══════════════════════════════════════════');

      // Auto-advance to List Number once ESN resolves successfully.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        lane.listNumberFocusNode.requestFocus();
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

    final modelName = match.model?.name?.trim();
    final subModelName = match.subModel?.name?.trim();

    print('   ESN catalog match → model="$modelName" subModel="$subModelName" '
        '(model.id=${match.model?.id}, subModel.id=${match.subModel?.id})');

    if (modelName == null ||
        modelName.isEmpty ||
        subModelName == null ||
        subModelName.isEmpty) {
      throw Exception('ESN match is missing model/sub-model information.');
    }
    final allModel = await _ensureModels();

    all_ds.Result? matchedModel;
    all_ds.SubModel? matchedSubModel;

    for (final result in allModel.results ?? <all_ds.Result>[]) {
      if ((result.name ?? '').trim().toUpperCase() != modelName.toUpperCase()) {
        continue;
      }
      matchedModel = result;
      for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
        if ((subModel.name ?? '').trim().toUpperCase() ==
            subModelName.toUpperCase()) {
          matchedSubModel = subModel;
          break;
        }
      }
      break;
    }

    if (matchedModel == null || matchedSubModel == null) {
      throw Exception(
          'No matching model/sub-model found in catalog for "$modelName — $subModelName".');
    }

    final ecuEntry = matchedSubModel.submodelModelecu?.firstOrNull;
    if (ecuEntry == null) {
      throw Exception(
          'No ECU configuration found for "$modelName — $subModelName".');
    }

    print('   Models catalog match → vehicleModel.id=${matchedModel.id} '
        'subModel.id=${matchedSubModel.id} ecu.id=${ecuEntry.ecu?.id} '
        'ecu.name=${ecuEntry.ecu?.name}');

    return _IdentifiedEcu(
      ecuEntry: ecuEntry,
      vehicleModelId: matchedModel.id,
      subModelId: matchedSubModel.id,
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
    lane.ecuModelName.value = ecuEntry.ecu?.name ?? 'Unknown Model';
    lane.dtcDatasetId.value = ecuEntry.datasets?.firstOrNull?.id;
    lane.pidDatasetId.value = ecuEntry.pidDatasets?.firstOrNull?.id;

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

        // Cross-check: the List Number must belong to the SAME
        // vehicle model/sub-model the ESN actually resolved to — a
        // variant_code match alone isn't enough, since a code could
        // coincidentally match a variant for a different vehicle.
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

        // Resolve the flash file URL, trying every shape this
        // endpoint has been confirmed to return: d_dataset_ecu and
        // t_dataset_ecu (plain string data_file) first, falling back
        // to the older variant_ecu shape (nested data_file object) if
        // neither is present.
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
      if (tryResolve(cached)) {
        print(
            '   ✅ List Number accepted — flash file resolved for Lane ${lane.laneNumber}');
        print('══════════════════════════════════════════');
        return;
      }

      // Refetch once to rule out a stale cache before giving up.
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

  // ===================================================
  // DONGLE — each lane gets its own independent connection via
  // ConnectionWifi().connectDongleForLane(), so multiple lanes can be
  // connected and flashing simultaneously.
  // ===================================================

  Future<void> connectDongleForLane(int laneIndex) async {
    final lane = lanes[laneIndex];

    print('══════════════════════════════════════════');
    print(
        '🔹 [Lane ${lane.laneNumber}] DONGLE CONNECT (independent connection)');
    print(
        '   IP: ${lane.dongleIpFromLogin}  ecu.id: ${lane.matchedEcu?.ecu?.id}');

    if (lane.dongleConnected.value || lane.dongleConnecting.value) {
      print('   ⏭️ already connected/connecting — skipping');
      print('══════════════════════════════════════════');
      return;
    }

    if (lane.isDongleBusy) {
      print(
          '   ⏭️ dongle busy with another operation — skipping this connect attempt');
      print('══════════════════════════════════════════');
      return;
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
      lane.dongleError.value = 'Scan ESN first — no ECU config resolved yet.';
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

      // Explicit-params version — takes THIS lane's ECU protocol/tx/rx
      // directly, unlike setDongleProperties1() which reads the
      // global StaticData.ecuInfo (a race if another lane's connect
      // overwrites it in between).
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

  /// Tracks consecutive failed reconnect attempts per lane. Reset to
  /// zero the moment a connect attempt succeeds.
  final Map<int, int> _dongleRetryAttempts = {};

  void _startDongleRetryTimer(int laneIndex) {
    final lane = lanes[laneIndex];
    lane.dongleRetryTimer?.cancel();
    _dongleRetryAttempts[laneIndex] = 0;
    _scheduleDongleRetry(laneIndex, const Duration(seconds: 10));
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
          Get.snackbar(
            'Lane ${lane.laneNumber} dongle unresponsive',
            'Power-cycle the dongle, then tap reconnect. Auto-retry stopped after $attempts failed attempts.',
            duration: const Duration(seconds: 8),
          );
        } catch (_) {}
        return; // stop scheduling further retries
      }

      final nextDelay = Duration(seconds: (delay.inSeconds * 2).clamp(10, 60));
      _scheduleDongleRetry(laneIndex, nextDelay);
    });
  }

  /// Releases this lane's own dongle connection. Since each lane has
  /// its own independent DLLFunctions instance now, this doesn't
  /// affect any other lane.
  void releaseDongleForLane(int laneIndex) {
    lanes[laneIndex].dongleConnected.value = false;
    lanes[laneIndex].dongleRetryTimer?.cancel();
    lanes[laneIndex].dllFunctions = null;
  }

  // ===================================================
  // IQA field changes
  // ===================================================

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
    lanes[laneIndex].resetToUnlockedIdle();
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
      Get.snackbar(
          'Flash', 'Scan a List Number first to resolve the flash file.');
      return;
    }

    if (!lane.dongleConnected.value || lane.dllFunctions == null) {
      print('   ❌ this lane\'s dongle isn\'t connected — cannot flash');
      print('══════════════════════════════════════════');
      Get.snackbar('Flash', 'Connect the dongle for this lane first.');
      return;
    }

    if (lane.isDongleBusy) {
      print(
          '   ⏭️ this lane\'s dongle is busy with another operation (Live Parameter read, DTC read, etc) — cannot flash yet');
      print('══════════════════════════════════════════');
      Get.snackbar('Flash',
          'This lane\'s dongle is busy — wait for the current operation to finish.');
      return;
    }
    lane.isDongleBusy = true;

    final dll = lane.dllFunctions!;

    lane.isFlashing.value = true;
    lane.flashStatus.value = "Flashing Started";
    lane.flashProgress.value = 0;
    lane.flashElapsedSeconds.value = 0;
    lane.flashStopwatch?.cancel();
    lane.flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
      lane.flashElapsedSeconds.value++;
    });

    // Progress now comes from the isolate via onProgress callback.
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
          '   Flash JSON generated (${flashJson.length} chars) — releasing main-isolate connection, starting ECU flash in its own isolate…');

      // Confirmed root cause: this dongle only supports ONE active
      // connection at a time. The main isolate's connection (used for
      // ESN scan / security access / MAC ID / setDongleProperties —
      // all of which worked fine) was never being closed before the
      // flash isolate opened its OWN fresh connection to the same IP.
      // The dongle kept "talking" to the first (main isolate) session
      // and never responded to the second — exactly the
      // "connects fine, then zero response forever" symptom seen,
      // even with just one lane flashing alone. Explicitly disconnect
      // here so the dongle is free for the isolate's connection.
      try {
        await dll.disconnectVCI1();
      } catch (e) {
        print('   ⚠️ pre-flash disconnect warning (non-fatal): $e');
      }
      lane.dongleConnected.value = false;
      lane.dllFunctions = null;

      result = await _runFlashInIsolate(
        laneNumber: lane.laneNumber,
        host: lane.dongleIpFromLogin ?? '',
        port: 6888,
        protocolName: ecuEntry.ecu?.protocol?.name ?? '',
        protocolHex: ecuEntry.ecu?.protocol?.autopeepal ?? '',
        txHeader: ecuEntry.ecu?.txHeader ?? '',
        rxHeader: ecuEntry.ecu?.rxHeader ?? '',
        flashJson: flashJson,
        interpreter: sequenceContent,
        seedKeyAlgo: ecuEntry.ecu?.seedkeyalgoFnIndex?.value ?? '',
        onProgress: (pct) => lane.flashProgress.value = pct,
      );
      print('   startECUFlashing() result: $result');
    } catch (e) {
      print('   ❌ Flash exception: $e');
      result = e.toString();
    }

    lane.flashStopwatch?.cancel();
    lane.isFlashing.value = false;

    if (result == null || result.isEmpty || result != 'NOERROR') {
      print('   ❌ Flash FAILED: $result  (elapsed ${lane.formattedElapsed})');
      final r = result?.toLowerCase() ?? '';
      final looksDisconnected = r.contains('no resp') ||
          r.contains('socket_closed') ||
          r.contains('noresponsefromecu');

      if (looksDisconnected) {
        print(
            '   ⚠️ Failure looks like a dead connection — marking Lane ${lane.laneNumber}\'s dongle disconnected');
        lane.dongleConnected.value = false;
        lane.dllFunctions = null;
        _startDongleRetryTimer(index);
      }

      print('══════════════════════════════════════════');
      lane.flashStatus.value = "Flash Failed: $result";
      lane.isDongleBusy = false;
      return;
    }

    print(
        '   ✅ Flash COMPLETED in ${lane.formattedElapsed} — reconnecting to read DTC/PID, write IQA…');
    print('══════════════════════════════════════════');
    lane.flashProgress.value = 1;
    lane.flashStatus.value = "Flash Completed";

    // The flash isolate's connection is gone now that it finished —
    // the dongle is free again, so reconnect the main isolate's
    // connection (same as connectDongleForLane) before doing anything
    // that needs lane.dllFunctions.
    // The ECU has just been reset by the flash and is rebooting into
    // its newly-flashed application firmware. Reading DTCs or writing
    // IQA too soon — while it's still mid-boot or stuck in a
    // programming/bootloader session — produces exactly
    // ECUERROR_SERVICENOTSUPPORTED, since those services only exist
    // once it's back in normal application mode. Rather than guessing
    // a fixed delay (which will be wrong for some ECUs/some boot
    // times), actively poll with a lightweight status check until it
    // actually responds, up to a reasonable timeout.
    await Future.delayed(const Duration(milliseconds: 1000));
    lane.isDongleBusy = false; // connectDongleForLane refuses while busy
    await connectDongleForLane(index);
    lane.isDongleBusy = true; // restore — DTC/PID/IQA below still need the guard

    if (lane.dllFunctions == null) {
      print(
          '   ❌ [Lane ${lane.laneNumber}] could not reconnect after flash — skipping DTC/PID/IQA');
      lane.isDongleBusy = false;
      return;
    }

    print('   ⏳ [Lane ${lane.laneNumber}] waiting for ECU to finish booting post-flash...');
    const maxBootWait = Duration(seconds: 15);
    final bootDeadline = DateTime.now().add(maxBootWait);
    bool ecuReady = false;
    while (DateTime.now().isBefore(bootDeadline)) {
      try {
        final status = await lane.dllFunctions!.checkEcuStatus();
        if (status == 'NOERROR') {
          ecuReady = true;
          break;
        }
        print('   ⏳ ECU not ready yet (status: "$status") — retrying...');
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 500));
    }
    print(ecuReady
        ? '   ✅ [Lane ${lane.laneNumber}] ECU responding — proceeding with DTC/PID/IQA'
        : '   ⚠️ [Lane ${lane.laneNumber}] ECU still not confirmed ready after ${maxBootWait.inSeconds}s — proceeding anyway');

    await readLiveDtcForLane(index);

    await Future.delayed(const Duration(milliseconds: 300));
    await loadPidForLane(index);

    lane.iqaWriteStatus.value = await autoWriteIqaValuesForLane(index);
    lane.isDongleBusy = false;
  }

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

  /// the shared App.dllFunctions.
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

    lane.isReadingDtc.value = true;
    lane.dtcError.value = '';

    try {
      // Make sure the dataset catalog (for descriptions) is loaded.
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
        final code = row[0];
        final status = row[1];

        final match = lane.dtcCodes.firstWhereOrNull((c) => c.code == code);
        final desc = match?.description ?? 'Description not found';

        merged[code] = '$code - $desc ($status)';
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

  /// Clears DTCs on the live ECU via DLLFunctions.clearDtc(), then
  /// re-reads so the dialog immediately reflects whether it actually
  /// worked — a "NOERROR" clear response doesn't guarantee the codes
  /// are gone if the underlying fault condition is still active, so
  /// re-reading is the only way to show the real resulting state
  /// rather than just trusting the clear command's own response.
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
      final status = await lane.dllFunctions!.clearDtc(ecu!.clearDtcFnIndex!.value!);

      print('   Clear DTC status: $status');

      if (status == null) {
        print('   ❌ Clear DTC: no response from ECU');
        print('══════════════════════════════════════════');
        lane.dtcError.value = 'Clear DTC failed: no response from ECU.';
        lane.isReadingDtc.value = false;
        return;
      }

      final statusText = status.toLowerCase();
      if (statusText.contains('no resp') || statusText.contains('socket_closed')) {
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

    // Re-read to show the real resulting state, same as after a flash.
    await readLiveDtcForLane(laneIndex);
  }

  Future<String> autoWriteIqaValuesForLane(int laneIndex) async {
    final lane = lanes[laneIndex];

    print('══════════════════════════════════════════');
    print('🔹 [Lane ${lane.laneNumber}] IQA WRITE');

    try {
      // Make sure the PID dataset (which carries the IQA code) is loaded.
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
      Get.snackbar('Live Parameter', 'Connect the dongle for this lane first.');
      return;
    }

    if (lane.liveParameterCodes.isEmpty) {
      Get.snackbar('Live Parameter', 'No parameters available to run.');
      return;
    }

    if (lane.isDongleBusy) {
      Get.snackbar('Live Parameter',
          'This lane\'s dongle is busy with another operation — try again shortly.');
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
    final flashingLanes = lanes.where((l) => l.isFlashing.value).toList();
    if (flashingLanes.isNotEmpty) {
      final laneNumbers = flashingLanes.map((l) => l.laneNumber).join(', ');
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
    Get.offAllNamed(
      "/login",
    );
  }
}

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