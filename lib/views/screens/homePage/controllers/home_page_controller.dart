// import 'dart:async';
// import 'dart:convert';
// import 'dart:io';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:simpson/AppPreferences/app_areferences.dart';
// import 'package:simpson/app.dart';
// import 'package:simpson/common_widgets/popup.dart';
// import 'package:simpson/modals/all.models.dart' as all_ds;
// import 'package:simpson/modals/all.models.dart';
// import 'package:simpson/modals/dtcDataset.model.dart' as dtc_ds;
// import 'package:simpson/modals/listNumber.model.dart' as list_ds;
// import 'package:simpson/modals/harness.model.dart' as harness_ds;
// import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
// import 'package:simpson/modals/staticData.dart';
// import 'package:simpson/services/apiServices.dart';
// import 'package:simpson/services/connectionWifiService.dart';
// import 'package:simpson/services/getJson_service.dart';

// enum StepType { single, iqaGroup }

// class ScanStep {
//   final String key;
//   final String label;
//   final StepType type;
//   ScanStep(this.key, this.label, {this.type = StepType.single});
// }

// class HomePageController extends GetxController {
//   late final String station;

//   final List<ScanStep> steps = [
//     ScanStep('esn', 'ESN'),
//     ScanStep('list', 'List'),
//     ScanStep('harness', 'Harness'),
//     ScanStep('iqa', 'IQA', type: StepType.iqaGroup),
//   ];

//   late final List<TextEditingController> stepControllers;
//   late final List<FocusNode> stepFocusNodes;
//   late final List<Timer?> _idleTimers;
//   static const _defaultIqaCount = 4;
//   List<String> iqaLabels =
//       List.generate(_defaultIqaCount, (i) => 'IQA ${i + 1}');
//   List<String>? _iqaFiringOrder;

//   late List<TextEditingController> iqaControllers;
//   late List<FocusNode> iqaFocusNodes;
//   late List<Timer?> _iqaIdleTimers;

//   static const _idleDuration = Duration(milliseconds: 400);

//   final RxInt currentStepIndex = 0.obs;
//   bool get allStepsComplete => currentStepIndex.value >= steps.length;

//   final RxString esnError = ''.obs;
//   final RxString listError = ''.obs;

//   // ── API ──
//   final AuthService _authService = AuthService();
//   String? _accessToken;
//   list_ds.ListNumber? _variantListCache;
//   all_ds.AllModel? _modelsCache;

//   // ── Flash File ──
//   final RxBool flashInProgress = false.obs;
//   final RxBool flashComplete = false.obs;
//   final RxDouble flashProgress = 0.0.obs;
//   final RxInt flashElapsedSeconds = 0.obs;
//   final RxBool flashExpanded = true.obs;
//   Timer? _flashStopwatch;

//   void toggleFlash() => flashExpanded.toggle();

//   final RxBool flashFilesLoading = false.obs;
//   final RxString flashFilesError = ''.obs;
//   final RxList<String> availableFlashFiles = <String>[].obs;
//   final Rx<String?> selectedFlashFile = Rx<String?>(null);
//   final Map<String, int> _fileToDtcDatasetId = {};
//   final Map<String, int> _fileToPidDatasetId = {};

//   int? _currentDtcDatasetId;
//   int? _currentPidDatasetId;

//   String get formattedElapsed {
//     final s = flashElapsedSeconds.value;
//     final m = s ~/ 60;
//     final sec = s % 60;
//     return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
//   }

//   // ── DTC ──
//   final RxBool dtcExpanded = true.obs;
//   final RxList<String> dtcList = <String>[].obs;
//   int get dtcCount => dtcList.length;

//   // ── PID ──
//   final RxBool pidExpanded = true.obs;
//   final RxList<String> pidList = <String>[].obs;
//   final RxList<String> activityLog = <String>[].obs;

//   @override
//   void onInit() {
//     super.onInit();
//     station =
//         (Get.arguments is String) ? Get.arguments as String : 'Unknown Station';

//     stepControllers =
//         List.generate(steps.length, (_) => TextEditingController());
//     stepFocusNodes = List.generate(steps.length, (_) => FocusNode());
//     _idleTimers = List.generate(steps.length, (_) => null);

//     iqaControllers =
//         List.generate(_defaultIqaCount, (_) => TextEditingController());
//     iqaFocusNodes = List.generate(_defaultIqaCount, (_) => FocusNode());
//     _iqaIdleTimers = List.generate(_defaultIqaCount, (_) => null);

//     _log('Session started on "$station"');

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       stepFocusNodes[0].requestFocus();
//     });

//     _loadAccessToken();
//   }

//   Future<void> _loadAccessToken() async {
//     _accessToken = await SecureStorageService.getAccessToken();
//   }

//   String _timestamp() {
//     final t = DateTime.now();
//     String two(int n) => n.toString().padLeft(2, '0');
//     return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
//   }

//   void _log(String message) {
//     activityLog.insert(0, '[${_timestamp()}] $message');
//   }

//   void _showErrorPopup(String message, {String title = 'Error'}) {
//     if (Get.isDialogOpen == true) {
//       Get.back();
//     }
//     Get.dialog(
//       CustomPopup(
//         title: title,
//         message: message,
//         confirmText: 'OK',
//       ),
//       barrierDismissible: true,
//     );
//   }

//   Future<bool> _isValidEsn(String value) async {
//     final scanned = value.trim();
//     final esnList = await _authService.getEsnList(
//       engSlno: scanned,
//       accessToken: _accessToken,
//     );

//     final match = (esnList.results ?? []).firstWhereOrNull(
//       (r) => (r.engSlno ?? '').trim().toUpperCase() == scanned.toUpperCase(),
//     );

//     if (match == null) return false;
//     if (match.isActive != true) return false;

//     _esnVehicleModelName = match.model?.name;
//     _esnVehicleSubModelName = match.subModel?.name;
//     return true;
//   }

//   final RxString vehicleDisplayName = ''.obs;
//   String? _esnVehicleModelName;
//   String? _esnVehicleSubModelName;
//   List<all_ds.SubmodelModelecu> vehicleEcuEntries = [];

//   Future<void> _resolveVehicleFromEsn() async {
//     final modelName = _esnVehicleModelName?.trim();
//     final subModelName = _esnVehicleSubModelName?.trim();

//     if (modelName == null ||
//         modelName.isEmpty ||
//         subModelName == null ||
//         subModelName.isEmpty) {
//       _log('Vehicle context: ESN match missing model/sub_model name');
//       vehicleDisplayName.value = '';
//       vehicleEcuEntries = [];
//       return;
//     }

//     try {
//       final models = await _ensureModels();

//       all_ds.Result? matchedModel;
//       all_ds.SubModel? matchedSubModel;

//       for (final result in models.results ?? <all_ds.Result>[]) {
//         if ((result.name ?? '').trim().toUpperCase() !=
//             modelName.toUpperCase()) {
//           continue;
//         }
//         matchedModel = result;
//         for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
//           if ((subModel.name ?? '').trim().toUpperCase() ==
//               subModelName.toUpperCase()) {
//             matchedSubModel = subModel;
//             break;
//           }
//         }
//         break;
//       }

//       if (matchedModel == null || matchedSubModel == null) {
//         _log(
//             'Vehicle context: no match for model="$modelName", sub_model="$subModelName" in models/get-models/');
//         vehicleDisplayName.value =
//             '$modelName — $subModelName (unrecognized combination)';
//         vehicleEcuEntries = [];
//         return;
//       }

//       vehicleDisplayName.value =
//           '${matchedModel.name} — ${matchedSubModel.name}';
//       vehicleEcuEntries =
//           matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

//       _log('Vehicle resolved from ESN: ${vehicleDisplayName.value} '
//           '(${vehicleEcuEntries.length} ECU entr${vehicleEcuEntries.length == 1 ? 'y' : 'ies'})');
//     } catch (e) {
//       _log('Vehicle context resolution failed: $e');
//       vehicleDisplayName.value = '';
//       vehicleEcuEntries = [];
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

//   Future<all_ds.AllModel> _ensureModels() async {
//     if (_modelsCache != null) return _modelsCache!;
//     _accessToken ??= await SecureStorageService.getAccessToken();
//     _modelsCache = await _authService.getModels(accessToken: _accessToken);
//     return _modelsCache!;
//   }

//   Future<bool> _isValidListNumber(String value) async {
//     final scanned = value.trim().toUpperCase();

//     bool checkAgainst(list_ds.ListNumber list) {
//       return (list.results ?? []).any(
//         (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
//       );
//     }

//     final cached = await _ensureVariantList();
//     if (checkAgainst(cached)) return true;

//     // Cache may be stale (backend data can change between scans within the
//     // same session) — retry once against a forced-fresh fetch before
//     // reporting a genuine mismatch.
//     _log(
//         'List validation: no match in cached list — refetching to rule out stale cache');
//     final fresh = await _ensureVariantList(forceRefresh: true);
//     return checkAgainst(fresh);
//   }

//   Future<void> _resolveInjectorConfig(String scannedListValue) async {
//     try {
//       final list = await _ensureVariantList();
//       final scanned = scannedListValue.trim().toUpperCase();

//       final variant = (list.results ?? []).firstWhereOrNull(
//         (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
//       );
//       if (variant == null) {
//         _log('Injector config: no matching variant for "$scannedListValue"');
//         _configureIqaFields(_defaultIqaCount, null);
//         return;
//       }

//       final vehicleModelId = variant.vehicleModel;
//       final subModelId = variant.subModel;
//       final ecuId = (variant.variantEcu ?? [])
//           .map((ve) => ve.ecu)
//           .whereType<int>()
//           .firstOrNull;

//       if (vehicleModelId == null || subModelId == null || ecuId == null) {
//         _log('Injector config: variant missing model/submodel/ecu ids');
//         _configureIqaFields(_defaultIqaCount, null);
//         return;
//       }

//       final models = await _ensureModels();
//       all_ds.SubmodelModelecu? matched;

//       for (final result in models.results ?? <all_ds.Result>[]) {
//         if (result.id != vehicleModelId) continue;
//         for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
//           if (subModel.id != subModelId) continue;

//           final candidates =
//               subModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];
//           if (candidates.isEmpty) continue;
//           matched =
//               candidates.firstWhereOrNull((sme) => sme.ecu?.id == ecuId) ??
//                   candidates.first;

//           if (matched.ecu?.id != ecuId) {
//             _log(
//                 'Injector config: ecu mismatch (variant says $ecuId, models/get-models/ has ${matched.ecu?.id}) — using the submodel\'s entry anyway');
//           }
//         }
//       }

//       if (matched == null) {
//         _log(
//             'Injector config: no submodel_modelecu match in models/get-models/');
//         _configureIqaFields(_defaultIqaCount, null);
//         return;
//       }

//       final noOfInjectors = matched.noOfInjectors;
//       final firingSequenceStr = matched.firingSequence ?? '';

//       if (noOfInjectors == null || noOfInjectors <= 0) {
//         _log(
//             'Injector config: no_of_injectors missing/invalid — using default');
//         _configureIqaFields(_defaultIqaCount, null);
//         return;
//       }

//       final firingOrder = firingSequenceStr
//           .split(',')
//           .map((s) => s.trim())
//           .where((s) => s.isNotEmpty)
//           .toList();

//       _log(
//           'Injector config resolved: $noOfInjectors injector(s), firing sequence [${firingOrder.join(',')}]');
//       _configureIqaFields(
//         noOfInjectors,
//         firingOrder.length == noOfInjectors ? firingOrder : null,
//       );
//     } catch (e) {
//       _log('Injector config resolution failed: $e — using default');
//       _configureIqaFields(_defaultIqaCount, null);
//     }
//   }

//   final RxList<harness_ds.Receipe> harnessReceipes = <harness_ds.Receipe>[].obs;

//   Future<bool> _isValidHarness(String value) async {
//     final scanned = value.trim();
//     final harnessList = await _authService.getHarnessList(
//       harnessName: scanned,
//       accessToken: _accessToken,
//     );

//     final match = (harnessList.results ?? []).firstWhereOrNull(
//       (r) => (r.name ?? '').trim().toUpperCase() == scanned.toUpperCase(),
//     );

//     if (match == null) return false;
//     if (match.isActive != true) return false;

//     harnessReceipes.assignAll(match.receipes ?? []);
//     _log(
//         'Harness matched: "${match.name}" (${harnessReceipes.length} recipe sensor(s))');

//     // Log each sensor individually too, right under the match line.
//     // Logged in reverse so they read top-to-bottom in natural order
//     // (Sensor 1, 2, 3…) since _log() inserts newest-first.
//     for (final sensor in harnessReceipes.reversed) {
//       _log(
//           '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: ${sensor.regAddress ?? '-'}  |  Type: ${sensor.type ?? '-'}  |  Value: ${sensor.value ?? '-'} ${sensor.unit ?? ''}'
//               .trim());
//     }

//     return true;
//   }

//   void _configureIqaFields(int count, List<String>? firingOrder) {
//     for (final c in iqaControllers) {
//       c.dispose();
//     }
//     for (final f in iqaFocusNodes) {
//       f.dispose();
//     }
//     for (final t in _iqaIdleTimers) {
//       t?.cancel();
//     }

//     iqaControllers = List.generate(count, (_) => TextEditingController());
//     iqaFocusNodes = List.generate(count, (_) => FocusNode());
//     _iqaIdleTimers = List.generate(count, (_) => null);

//     iqaLabels = List.generate(count, (i) => 'IQA ${i + 1}');
//     _iqaFiringOrder = firingOrder;
//   }

//   String _iqaRecordLabel(int i) {
//     final order = _iqaFiringOrder;
//     if (order != null && i < order.length) {
//       return 'IQA (Cyl ${order[i]})';
//     }
//     return iqaLabels[i];
//   }

//   void _resetForEsnEdit() {
//     _log('ESN changed — resetting flow from the start');

//     for (int i = 1; i < stepControllers.length; i++) {
//       stepControllers[i].clear();
//       _idleTimers[i]?.cancel();
//     }
//     _configureIqaFields(_defaultIqaCount, null);

//     harnessReceipes.clear();

//     _flashStopwatch?.cancel();
//     flashInProgress.value = false;
//     flashComplete.value = false;
//     flashProgress.value = 0;
//     flashElapsedSeconds.value = 0;

//     dtcList.clear();
//     pidList.clear();

//     availableFlashFiles.clear();
//     _fileToDtcDatasetId.clear();
//     _fileToPidDatasetId.clear();
//     _currentDtcDatasetId = null;
//     _currentPidDatasetId = null;
//     selectedFlashFile.value = null;
//     flashFilesError.value = '';

//     esnError.value = '';
//     listError.value = '';
//     currentStepIndex.value = 0;
//   }

//   // ── Single-field steps (ESN, List, Harness) ──

//   void onFieldChanged(int index) {
//     if (index == 0 && currentStepIndex.value != 0) {
//       _resetForEsnEdit();
//     }
//     if (index != currentStepIndex.value) return;
//     _idleTimers[index]?.cancel();
//     _idleTimers[index] = Timer(_idleDuration, () => submitStep(index));
//   }

//   Future<void> submitStep(int index) async {
//     if (index == 0 && currentStepIndex.value != 0) {
//       _resetForEsnEdit();
//     }
//     if (index != currentStepIndex.value) return;
//     _idleTimers[index]?.cancel();

//     final value = stepControllers[index].text.trim();
//     if (value.isEmpty) return;

//     final step = steps[index];

//     if (step.key == 'esn') {
//       esnError.value = '';
//       try {
//         final isValid = await _isValidEsn(value);
//         if (!isValid) {
//           final message = 'ESN not recognized. Please rescan.';
//           esnError.value = message;
//           _log('ESN mismatch: scanned "$value"');
//           _showErrorPopup(message, title: 'ESN Mismatch');
//           return;
//         }
//         await _resolveVehicleFromEsn();
//       } catch (e) {
//         final message = e.toString().replaceFirst('Exception: ', '');
//         esnError.value = message;
//         _log('Failed to validate ESN: $e');
//         _showErrorPopup(message, title: 'ESN Validation Failed');
//         return;
//       }
//     }

//     if (step.key == 'list') {
//       listError.value = '';
//       try {
//         final isValid = await _isValidListNumber(value);
//         if (!isValid) {
//           final message = 'List number not recognized. Please rescan.';
//           listError.value = message;
//           _log('List number mismatch: scanned "$value"');
//           _showErrorPopup(message, title: 'List Number Mismatch');
//           return;
//         }
//         await _resolveInjectorConfig(value);
//       } catch (e) {
//         final message = e.toString().replaceFirst('Exception: ', '');
//         listError.value = message;
//         _log('Failed to validate list number: $e');
//         _showErrorPopup(message, title: 'List Validation Failed');
//         return;
//       }
//     }

//     if (step.key == 'harness') {
//       try {
//         final isValid = await _isValidHarness(value);
//         if (!isValid) {
//           final message = 'Harness not recognized. Please rescan.';
//           _log('Harness mismatch: scanned "$value"');
//           _showErrorPopup(message, title: 'Harness Mismatch');
//           return;
//         }
//       } catch (e) {
//         final message = e.toString().replaceFirst('Exception: ', '');
//         _log('Failed to validate harness: $e');
//         _showErrorPopup(message, title: 'Harness Validation Failed');
//         return;
//       }
//     }

//     _log('${step.label} scanned: $value');
//     currentStepIndex.value = index + 1;

//     if (allStepsComplete) {
//       _log('All scan steps complete. Ready to flash.');
//       _onAllStepsComplete();
//       return;
//     }

//     final nextStep = steps[currentStepIndex.value];
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (nextStep.type == StepType.single) {
//         stepFocusNodes[currentStepIndex.value].requestFocus();
//       } else {
//         iqaFocusNodes[0].requestFocus();
//       }
//     });
//   }

//   // ── IQA group (IQA1..IQAn shown together, n = resolved injector count) ──

//   void onIqaFieldChanged(int subIndex) {
//     _iqaIdleTimers[subIndex]?.cancel();
//     _iqaIdleTimers[subIndex] =
//         Timer(_idleDuration, () => submitIqaField(subIndex));
//   }

//   void submitIqaField(int subIndex) {
//     if (allStepsComplete) return;

//     _iqaIdleTimers[subIndex]?.cancel();
//     final value = iqaControllers[subIndex].text.trim();
//     if (value.isEmpty) return;

//     _log('${_iqaRecordLabel(subIndex)} scanned: $value');

//     if (subIndex < iqaLabels.length - 1) {
//       WidgetsBinding.instance.addPostFrameCallback((_) {
//         iqaFocusNodes[subIndex + 1].requestFocus();
//       });
//       return;
//     }

//     final allFilled = iqaControllers.every((c) => c.text.trim().isNotEmpty);
//     if (!allFilled) return;

//     _log('IQA group complete');
//     currentStepIndex.value = currentStepIndex.value + 1;

//     if (allStepsComplete) {
//       _log('All scan steps complete. Ready to flash.');
//       _onAllStepsComplete();
//     }
//   }

//   void _onAllStepsComplete() {
//     _loadAvailableFlashFiles();
//   }

//   Future<void> _loadAvailableFlashFiles() async {
//     flashFilesLoading.value = true;
//     flashFilesError.value = '';
//     try {
//       final modelName = _esnVehicleModelName?.trim();
//       final subModelName = _esnVehicleSubModelName?.trim();

//       if (modelName == null ||
//           modelName.isEmpty ||
//           subModelName == null ||
//           subModelName.isEmpty) {
//         _log('Flash files: no ESN-resolved model/sub_model name to filter by');
//         availableFlashFiles.assignAll(<String>[]);
//         selectedFlashFile.value = null;
//         return;
//       }

//       final all_ds.AllModel models = await _ensureModels();

//       all_ds.Result? matchedModel;
//       all_ds.SubModel? matchedSubModel;

//       for (final result in models.results ?? <all_ds.Result>[]) {
//         if ((result.name ?? '').trim().toUpperCase() !=
//             modelName.toUpperCase()) {
//           continue;
//         }
//         matchedModel = result;
//         for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
//           if ((subModel.name ?? '').trim().toUpperCase() ==
//               subModelName.toUpperCase()) {
//             matchedSubModel = subModel;
//             break;
//           }
//         }
//         break;
//       }

//       if (matchedModel == null || matchedSubModel == null) {
//         _log(
//             'Flash files: no match for model="$modelName", sub_model="$subModelName" in models/get-models/');
//         availableFlashFiles.assignAll(<String>[]);
//         selectedFlashFile.value = null;
//         return;
//       }

//       final ecuEntries =
//           matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

//       final files = <String>[];
//       _fileToDtcDatasetId.clear();
//       _fileToPidDatasetId.clear();

//       for (final sme in ecuEntries) {
//         final flashFiles = sme.flashFile?.file ?? <all_ds.FileElement>[];
//         if (flashFiles.isEmpty) continue; // flash_file can be null

//         final dtcDatasetId =
//             (sme.datasets ?? []).isNotEmpty ? sme.datasets!.first.id : null;
//         final pidDatasetId = (sme.pidDatasets ?? []).isNotEmpty
//             ? sme.pidDatasets!.first.id
//             : null;

//         for (final f in flashFiles) {
//           final name = f.dataFileName ?? f.swPartNo;
//           if (name == null) continue;
//           if (!files.contains(name)) files.add(name);
//           if (dtcDatasetId != null) {
//             _fileToDtcDatasetId[name] = dtcDatasetId;
//           }
//           if (pidDatasetId != null) {
//             _fileToPidDatasetId[name] = pidDatasetId;
//           }
//         }
//       }

//       availableFlashFiles.assignAll(files);
//       selectedFlashFile.value = null;
//       _log(
//           'Loaded ${files.length} flash file(s) for $modelName — $subModelName');
//     } catch (e) {
//       final message = e.toString().replaceFirst('Exception: ', '');
//       flashFilesError.value = message;
//       _log('Failed to load flash files: $e');
//       _showErrorPopup(message, title: 'Failed to Load Flash Files');
//     } finally {
//       flashFilesLoading.value = false;
//     }
//   }

//   void selectFlashFile(String? file) {
//     selectedFlashFile.value = file;
//     _currentDtcDatasetId = file != null ? _fileToDtcDatasetId[file] : null;
//     _currentPidDatasetId = file != null ? _fileToPidDatasetId[file] : null;
//   }

//   // Future<void> startFlashing() async {
//   //   if (!allStepsComplete ||
//   //       flashInProgress.value ||
//   //       flashComplete.value ||
//   //       selectedFlashFile.value == null) {
//   //     return;
//   //   }

//   //   _log('Selected flash file: ${selectedFlashFile.value}');

//   //   flashInProgress.value = true;
//   //   flashProgress.value = 0;
//   //   flashElapsedSeconds.value = 0;
//   //   _log('Flashing started');

//   //   _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
//   //     flashElapsedSeconds.value++;
//   //   });

//   //   for (int i = 1; i <= 10; i++) {
//   //     await Future.delayed(const Duration(milliseconds: 200));
//   //     flashProgress.value = i / 10;
//   //   }

//   //   _flashStopwatch?.cancel();
//   //   flashInProgress.value = false;
//   //   flashComplete.value = true;
//   //   _log('Flashing completed successfully (${formattedElapsed})');

//   //   await _loadDtcResults();
//   //   await _loadPidResults();

//   //   _showFlashCompletePopup();
//   // }

//   Future<void> _loadDtcResults() async {
//     final datasetId = _currentDtcDatasetId;
//     if (datasetId == null) {
//       _log('No DTC dataset id available — skipping');
//       return;
//     }

//     _accessToken ??= await SecureStorageService.getAccessToken();

//     try {
//       final dtc_ds.DtcDataset dtc = await _authService.getDtcDataset(
//         id: datasetId,
//         accessToken: _accessToken,
//       );

//       final dtcStrings = <String>[];
//       for (final result in dtc.results ?? <dtc_ds.Result>[]) {
//         for (final code in result.dtcCode ?? <dtc_ds.DtcCode>[]) {
//           final c = code.code ?? '';
//           final desc = code.description ?? '';
//           final line = desc.isNotEmpty ? '$c - $desc' : c;
//           if (line.trim().isNotEmpty) dtcStrings.add(line);
//         }
//       }
//       dtcList.assignAll(dtcStrings);
//       _log('DTC (${dtcList.length}) data loaded');
//     } catch (e) {
//       final message = e.toString().replaceFirst('Exception: ', '');
//       _log('Failed to load DTC dataset: $e');
//       dtcList.clear();
//       _showErrorPopup(message, title: 'Failed to Load DTC');
//     }
//   }

//   Future<void> _loadPidResults() async {
//     final datasetId = _currentPidDatasetId;
//     if (datasetId == null) {
//       _log('No PID dataset id available — skipping');
//       return;
//     }

//     _accessToken ??= await SecureStorageService.getAccessToken();

//     try {
//       final pid_ds.PidDataset pid = await _authService.getPidDataset(
//         id: datasetId,
//         accessToken: _accessToken,
//       );

//       final pidStrings = <String>[];
//       for (final result in pid.results ?? <pid_ds.Result>[]) {
//         for (final code in result.codes ?? <pid_ds.Code>[]) {
//           for (final v in code.piCodeVariable ?? <pid_ds.PiCodeVariable>[]) {
//             final name = v.longName ??
//                 v.shortName ??
//                 code.shortName ??
//                 code.code ??
//                 'PID';
//             final unit = v.unit ?? '';
//             pidStrings.add(unit.isNotEmpty ? '$name — $unit' : name);
//           }
//         }
//       }
//       pidList.assignAll(pidStrings);
//       _log('PID (${pidList.length}) data loaded');
//     } catch (e) {
//       final message = e.toString().replaceFirst('Exception: ', '');
//       _log('Failed to load PID dataset: $e');
//       pidList.clear();
//       _showErrorPopup(message, title: 'Failed to Load PID');
//     }
//   }

//   void _showFlashCompletePopup() {
//     final iqaSummary = List.generate(
//       iqaLabels.length,
//       (i) => '${_iqaRecordLabel(i)}: ${iqaControllers[i].text.trim()}',
//     ).join('\n');

//     final message = 'File: ${selectedFlashFile.value ?? '-'}\n\n$iqaSummary';

//     Get.dialog(
//       CustomPopup(
//         title: 'Flashing Complete',
//         message: message,
//         confirmText: 'OK',
//       ),
//       barrierDismissible: true,
//     );
//   }

//   void toggleDtc() => dtcExpanded.toggle();
//   void togglePid() => pidExpanded.toggle();

//   void logout() {
//     _log('Logged out');
//     Get.offAllNamed('/login');
//   }

//   final RxBool dongleConnecting = false.obs;
//   final RxBool dongleConnected = false.obs;
//   final RxString dongleIp = ''.obs;
//   final ConnectionWifi _connectionWifi = ConnectionWifi();
//   Map<String, int> _fileToEcuIndex = {};

//   /// Call this after the user types an IP and taps "Connect".
//   /// Must be called AFTER _resolveVehicleFromEsn() has populated
//   /// vehicleEcuEntries (i.e. after step 0 / ESN is scanned).
//   Future<void> connectDongle(String ip) async {
//     if (ip.trim().isEmpty) {
//       _log('Connect: no IP entered');
//       return;
//     }
//     if (vehicleEcuEntries.isEmpty) {
//       _log('Connect: no ECU data resolved yet — scan ESN first');
//       _showErrorPopup('Scan ESN first so vehicle/ECU info is known',
//           title: 'Not Ready');
//       return;
//     }

//     dongleConnecting.value = true;
//     dongleIp.value = ip.trim();
//     try {
//       // 1️⃣ Populate StaticData.ecuInfo from the already-resolved vehicle ECUs
//       _fileToEcuIndex.clear();
//       StaticData.ecuInfo = <EcuDataSet>[];

//       for (final sme in vehicleEcuEntries) {
//         StaticData.ecuInfo.add(EcuDataSet(
//           ecuID: sme.ecu?.id,
//           ecuName: sme.ecu?.name,
//           txHeader: sme.ecu?.txHeader,
//           rxHeader: sme.ecu?.rxHeader,
//           protocol: sme.ecu?.protocol,
//           channelId: sme.ecu?.channel,
//           seedKeyIndex: sme.ecu?.seedkeyalgoFnIndex?.value,
//           readDtcIndex: sme.ecu?.readDtcFnIndex?.value,
//           clearDtcIndex: sme.ecu?.clearDtcFnIndex?.value,
//           writePidIndex: sme.ecu?.writeDataFnIndex?.value,
//           iorTestFnIndex: sme.ecu?.iorTestFnIndex?.value,
//           firingSequence: sme.firingSequence,
//           noOfInjectors: sme.noOfInjectors,
//         ));
//       }

//       if (StaticData.ecuInfo.isEmpty) {
//         _log('Connect: no ECU entries to configure');
//         _showErrorPopup('No ECU configuration found for this vehicle',
//             title: 'Connect Failed');
//         return;
//       }

//       // 2️⃣ Connect over WiFi — channel id comes from the first ECU
//       final channelParts = StaticData.ecuInfo.first.channelId?.split('-');
//       final channelId = (channelParts != null && channelParts.length > 1)
//           ? '0${channelParts[1]}'
//           : '00';

//       _log('Connecting to dongle at $ip...');
//       final macId =
//           await _connectionWifi.getDongleMacID(ip.trim(), channelId: channelId);

//       if (macId.isEmpty) {
//         _log('❌ Failed to connect to dongle at $ip');
//         _showErrorPopup('Could not connect to dongle at $ip',
//             title: 'Connect Failed');
//         dongleConnected.value = false;
//         return;
//       }
//       _log('✅ Connected. MAC: $macId');

//       // 3️⃣ Apply protocol/tx/rx headers and confirm via firmware read
//       final firmware = await App.dllFunctions?.setDongleProperties1() ?? '';
//       if (firmware.isEmpty) {
//         _log('❌ Failed to configure dongle properties / read firmware');
//         _showErrorPopup('Connected, but failed to configure dongle',
//             title: 'Connect Failed');
//         dongleConnected.value = false;
//         return;
//       }

//       _log('✅ Dongle ready — firmware $firmware');
//       dongleConnected.value = true;
//     } catch (e) {
//       _log('❌ Connect exception: $e');
//       _showErrorPopup(e.toString(), title: 'Connect Failed');
//       dongleConnected.value = false;
//     } finally {
//       dongleConnecting.value = false;
//     }
//   }

//   Future<void> startFlashing() async {
//     if (!allStepsComplete ||
//         flashInProgress.value ||
//         flashComplete.value ||
//         selectedFlashFile.value == null) {
//       return;
//     }

//     if (!dongleConnected.value || App.dllFunctions == null) {
//       _log('❌ Cannot flash — dongle not connected');
//       _showErrorPopup('Connect to the dongle before flashing',
//           title: 'Not Connected');
//       return;
//     }

//     final fileName = selectedFlashFile.value!;
//     _log('Selected flash file: $fileName');

//     // Find which SubmodelModelecu + FileElement this filename belongs to
//     all_ds.SubmodelModelecu? sme;
//     all_ds.FileElement? fileEntry;
//     for (final entry in vehicleEcuEntries) {
//       final files = entry.flashFile?.file ?? <all_ds.FileElement>[];
//       final match = files.firstWhereOrNull(
//         (f) => (f.dataFileName ?? f.swPartNo) == fileName,
//       );
//       if (match != null) {
//         sme = entry;
//         fileEntry = match;
//         break;
//       }
//     }

//     if (sme == null || fileEntry == null) {
//       _log('❌ Could not resolve ECU/file entry for "$fileName"');
//       _showErrorPopup('Internal error: file not resolved',
//           title: 'Flashing Failed');
//       return;
//     }

//     flashInProgress.value = true;
//     flashProgress.value = 0;
//     flashElapsedSeconds.value = 0;
//     _log('Flashing started');

//     _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
//       flashElapsedSeconds.value++;
//     });

//     Timer? percentTimer =
//         Timer.periodic(const Duration(milliseconds: 500), (_) async {
//       try {
//         flashProgress.value = await App.dllFunctions!.flashingData();
//       } catch (_) {}
//     });

//     String? result;
//     try {
//       // Set protocol/tx/rx for this specific ECU (may differ from the one
//       // used during connect, if the vehicle has multiple ECUs)
//       await App.dllFunctions!.setDongleProperties(
//         sme.ecu?.protocol?.autopeepal ?? '',
//         sme.ecu?.txHeader ?? '',
//         sme.ecu?.rxHeader ?? '',
//       );

//       _log('Downloading sequence file...');
//       final sequenceContent =
//           await _downloadAsRawString(sme.flashFile!.sequenceFile!);
//       _log('Downloading firmware file: $fileName');
//       final hexContent = await _downloadAsRawString(fileEntry.dataFile!);

//       // NOTE: readJson()/GetJson conversion (from Ecuflashingcontroller) must
//       // be available here to convert hexContent -> flashJson. Port that logic
//       // in, or call it via a shared service, before this line.
//       final flashJson = await readJson(
//           sequenceContent, Uint8List.fromList(hexContent.codeUnits));

//       if (flashJson.isEmpty) {
//         throw Exception('Failed to convert firmware file to flash JSON');
//       }

//       result = await App.dllFunctions!.startECUFlashing(
//         flashJson,
//         sequenceContent,
//         sme.ecu!,
//         sme.ecu?.seedkeyalgoFnIndex?.value ?? '',
//       );
//     } catch (e) {
//       _log('❌ Flashing exception: $e');
//       result = e.toString();
//     }

//     _flashStopwatch?.cancel();
//     percentTimer.cancel();
//     flashInProgress.value = false;

//     if (result == null || result.isEmpty || result != 'NOERROR') {
//       flashComplete.value = false;
//       _log('❌ Flashing failed: $result');
//       _showErrorPopup(result ?? 'Unknown error', title: 'Flashing Failed');
//       return;
//     }

//     flashComplete.value = true;
//     _log('Flashing completed successfully (${formattedElapsed})');

//     await _loadDtcResults();
//     await _loadPidResults();
//     _showFlashCompletePopup();
//   }

//   Future<String> _downloadAsRawString(String url) async {
//     final client = HttpClient();
//     final request = await client.getUrl(Uri.parse(url));
//     final response = await request.close();
//     final bytes =
//         await response.fold<List<int>>(<int>[], (p, c) => p..addAll(c));
//     client.close();
//     return latin1.decode(bytes);
//   }

//   List<EcuMapFile>? parsedEcuMapFiles;
//   RxBool isBusy = false.obs;
//   RxString loaderText = ''.obs;
//   Future<String> readJson(
//       String interpreterData, Uint8List flashFileBytes) async {
//     try {
//       isBusy.value = true;
//       loaderText.value = "Processing Dataset...";
//       print("[FLASH] 🔹 Started readJson");

//       await Future.delayed(const Duration(milliseconds: 100));

//       List<EcuMapFile> ecuMapFiles = [];
//       String checksumAlgo = "";

//       if (interpreterData.isNotEmpty &&
//           interpreterData.contains("EcuMapFile")) {
//         final lines = interpreterData.split('\n');
//         print("[FLASH] 🔹 Interpreter data lines: ${lines.length}");

//         for (var line in lines) {
//           final formatted = line.replaceAll("\r", "").trim();
//           if (formatted.isEmpty || formatted.startsWith("//")) continue;

//           String command = "";
//           String info = "";

//           if (formatted.contains(":")) {
//             final parts = formatted.split(":");
//             command = parts[0];
//             info = parts.length > 1 ? parts[1] : "";
//           } else {
//             command = formatted;
//           }

//           print("[FLASH] 🔹 Parsed line -> command: '$command', info: '$info'");

//           if (command == "EcuMapFile") {
//             final ecuMap = EcuMapFile();
//             final splitData = info.split('+');

//             for (var item in splitData) {
//               int endIndex = item.indexOf('>');
//               if (endIndex == -1) continue;

//               String bracketStr = item.substring(1, endIndex);
//               final values = bracketStr.split(',');

//               String reference = values[0];
//               if (reference.contains("start_address")) {
//                 ecuMap.startAddress = values[1];
//                 ecuMap.startAddr = int.parse(values[1], radix: 16);
//                 print(
//                     "[FLASH] 🔹 EcuMap startAddress: ${ecuMap.startAddress}, startAddr: ${ecuMap.startAddr}");
//               } else if (reference.contains("end_address")) {
//                 ecuMap.endAddress = values[1];
//                 ecuMap.endAddr = int.parse(values[1], radix: 16);
//                 print(
//                     "[FLASH] 🔹 EcuMap endAddress: ${ecuMap.endAddress}, endAddr: ${ecuMap.endAddr}");
//               }
//             }

//             ecuMapFiles.add(ecuMap);
//             print(
//                 "[FLASH] 🔹 Added EcuMapFile, total count: ${ecuMapFiles.length}");
//           } else if (command.toLowerCase().contains("chksum")) {
//             checksumAlgo = info.trim();
//             print("[FLASH] 🔹 Checksum algorithm found: $checksumAlgo");
//           }
//         }
//       } else {
//         print("[FLASH] ⚠️ No valid interpreter data or missing EcuMapFile");
//       }
//       print("[FLASH] 🔹 Converting flash file to JSON...");
//       final getJson = GetJson();
//       final flashJson = await getJson.convertToJson(
//           flashFileBytes, ecuMapFiles, checksumAlgo);
//       parsedEcuMapFiles = ecuMapFiles;
//       print("[FLASH] 🔹 Conversion done, JSON length: ${flashJson.length}");

//       _resetLoader();

//       return flashJson;
//     } catch (e) {
//       print("[FLASH][readJson error] $e");
//       _resetLoader();
//       return '';
//     }
//   }

//   void _setBusy(bool busy, String text) {
//     isBusy.value = busy;
//     loaderText.value = text;
//   }

//   void _resetLoader() => _setBusy(false, "");

//   @override
//   void onClose() {
//     for (final c in stepControllers) {
//       c.dispose();
//     }
//     for (final f in stepFocusNodes) {
//       f.dispose();
//     }
//     for (final t in _idleTimers) {
//       t?.cancel();
//     }
//     for (final c in iqaControllers) {
//       c.dispose();
//     }
//     for (final f in iqaFocusNodes) {
//       f.dispose();
//     }
//     for (final t in _iqaIdleTimers) {
//       t?.cancel();
//     }
//     _flashStopwatch?.cancel();
//     super.onClose();
//   }
// }

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/app.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/all.models.dart' as all_ds;
import 'package:simpson/modals/staticData.dart';
import 'package:simpson/modals/dtcDataset.model.dart' as dtc_ds;
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/modals/harness.model.dart' as harness_ds;
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/services/apiServices.dart';
import 'package:simpson/services/plc/plc_service.dart';
import 'package:simpson/services/connectionWifiService.dart';
import 'package:simpson/services/getJson_service.dart';

enum StepType { single, iqaGroup }

class ScanStep {
  final String key;
  final String label;
  final StepType type;
  ScanStep(this.key, this.label, {this.type = StepType.single});
}

class HomePageController extends GetxController {
  late final String station;

  final List<ScanStep> steps = [
    ScanStep('esn', 'ESN'),
    ScanStep('list', 'List'),
    ScanStep('harness', 'Harness'),
    ScanStep('iqa', 'IQA', type: StepType.iqaGroup),
  ];

  late final List<TextEditingController> stepControllers;
  late final List<FocusNode> stepFocusNodes;
  late final List<Timer?> _idleTimers;
  static const _defaultIqaCount = 4;
  List<String> iqaLabels =
      List.generate(_defaultIqaCount, (i) => 'IQA ${i + 1}');
  List<String>? _iqaFiringOrder;

  late List<TextEditingController> iqaControllers;
  late List<FocusNode> iqaFocusNodes;
  late List<Timer?> _iqaIdleTimers;

  static const _idleDuration = Duration(milliseconds: 400);

  final RxInt currentStepIndex = 0.obs;
  bool get allStepsComplete => currentStepIndex.value >= steps.length;

  final RxString esnError = ''.obs;
  final RxString listError = ''.obs;

  // ── API ──
  final AuthService _authService = AuthService();
  String? _accessToken;
  list_ds.ListNumber? _variantListCache;
  all_ds.AllModel? _modelsCache;

  // ── PLC connection (auto-connects, no manual IP/port entry) ──
  // TODO: 192.168.1.10 is a PLACEHOLDER — replace with the real PLC/
  // dongle IP and port for this station. This is the ONLY line that
  // needs to change once you have the real address.
  static const String _plcIp = '192.168.137.20';
  static const int _plcPort = 502;

  final PlcService plcService = Get.find<PlcService>();
  RxBool get isPlcConnected => plcService.isConnected;
  RxBool get isPlcConnecting => plcService.isConnecting;
  RxString get plcStatus => plcService.status;

  Timer? _plcRetryTimer;

  Future<void> _autoConnectPlc() async {
    if (plcService.isConnected.value || plcService.isConnecting.value) return;
    _log('Connecting to PLC at $_plcIp:$_plcPort…');
    try {
      await plcService.connect(_plcIp, port: _plcPort);
      _log('PLC connected ($_plcIp:$_plcPort)');
      _plcRetryTimer?.cancel();
    } catch (e) {
      _log('PLC connection failed: $e — will keep retrying in the background');
      _startPlcRetryTimer();
    }
  }

  /// Keeps trying every 10s in the background, so if the PLC comes
  /// online later (or the IP gets corrected) it connects automatically
  /// without needing an app restart or manual retry.
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

  /// Tap the status indicator to retry immediately instead of waiting
  /// for the next background retry tick.
  void retryPlcConnection() {
    if (isPlcConnected.value) return;
    _autoConnectPlc();
  }

  // ── Flash File ──
  final RxBool flashInProgress = false.obs;
  final RxBool flashComplete = false.obs;
  final RxDouble flashProgress = 0.0.obs;
  final RxInt flashElapsedSeconds = 0.obs;
  final RxBool flashExpanded = true.obs;
  Timer? _flashStopwatch;

  void toggleFlash() => flashExpanded.toggle();

  final RxBool flashFilesLoading = false.obs;
  final RxString flashFilesError = ''.obs;
  final RxList<String> availableFlashFiles = <String>[].obs;
  final Rx<String?> selectedFlashFile = Rx<String?>(null);
  final Map<String, int> _fileToDtcDatasetId = {};
  final Map<String, int> _fileToPidDatasetId = {};

  int? _currentDtcDatasetId;
  int? _currentPidDatasetId;

  String get formattedElapsed {
    final s = flashElapsedSeconds.value;
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── DTC ──
  final RxBool dtcExpanded = true.obs;
  final RxList<String> dtcList = <String>[].obs;
  int get dtcCount => dtcList.length;

  // ── PID ──
  final RxBool pidExpanded = true.obs;
  final RxList<String> pidList = <String>[].obs;
  final RxList<String> activityLog = <String>[].obs;

  // ── Dongle connection ──
  final TextEditingController dongleIpController = TextEditingController();
  final RxBool canConnectDongle = false.obs; // true once ESN/vehicle resolved
  final RxBool dongleConnecting = false.obs;
  final RxBool dongleConnected = false.obs;
  final RxString dongleIp = ''.obs;
  final ConnectionWifi _connectionWifi = ConnectionWifi();

  @override
  void onInit() {
    super.onInit();
    station =
        (Get.arguments is String) ? Get.arguments as String : 'Unknown Station';

    stepControllers =
        List.generate(steps.length, (_) => TextEditingController());
    stepFocusNodes = List.generate(steps.length, (_) => FocusNode());
    _idleTimers = List.generate(steps.length, (_) => null);

    iqaControllers =
        List.generate(_defaultIqaCount, (_) => TextEditingController());
    iqaFocusNodes = List.generate(_defaultIqaCount, (_) => FocusNode());
    _iqaIdleTimers = List.generate(_defaultIqaCount, (_) => null);

    _log('Session started on "$station"');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stepFocusNodes[0].requestFocus();
    });

    _loadAccessToken();
    _autoConnectPlc();
  }

  Future<void> _loadAccessToken() async {
    _accessToken = await SecureStorageService.getAccessToken();
  }

  String _timestamp() {
    final t = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
  }

  void _log(String message) {
    activityLog.insert(0, '[${_timestamp()}] $message');
  }

  void _showErrorPopup(String message, {String title = 'Error'}) {
    if (Get.isDialogOpen == true) {
      Get.back();
    }
    Get.dialog(
      CustomPopup(
        title: title,
        message: message,
        confirmText: 'OK',
      ),
      barrierDismissible: true,
    );
  }

  Future<bool> _isValidEsn(String value) async {
    final scanned = value.trim();
    final esnList = await _authService.getEsnList(
      engSlno: scanned,
      accessToken: _accessToken,
    );

    final match = (esnList.results ?? []).firstWhereOrNull(
      (r) => (r.engSlno ?? '').trim().toUpperCase() == scanned.toUpperCase(),
    );

    if (match == null) return false;
    if (match.isActive != true) return false;

    _esnVehicleModelName = match.model?.name;
    _esnVehicleSubModelName = match.subModel?.name;
    return true;
  }

  final RxString vehicleDisplayName = ''.obs;
  String? _esnVehicleModelName;
  String? _esnVehicleSubModelName;
  List<all_ds.SubmodelModelecu> vehicleEcuEntries = [];

  Future<void> _resolveVehicleFromEsn() async {
    final modelName = _esnVehicleModelName?.trim();
    final subModelName = _esnVehicleSubModelName?.trim();

    if (modelName == null ||
        modelName.isEmpty ||
        subModelName == null ||
        subModelName.isEmpty) {
      _log('Vehicle context: ESN match missing model/sub_model name');
      vehicleDisplayName.value = '';
      vehicleEcuEntries = [];
      canConnectDongle.value = false;
      return;
    }

    try {
      final models = await _ensureModels();

      all_ds.Result? matchedModel;
      all_ds.SubModel? matchedSubModel;

      for (final result in models.results ?? <all_ds.Result>[]) {
        if ((result.name ?? '').trim().toUpperCase() !=
            modelName.toUpperCase()) {
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
        _log(
            'Vehicle context: no match for model="$modelName", sub_model="$subModelName" in models/get-models/');
        vehicleDisplayName.value =
            '$modelName — $subModelName (unrecognized combination)';
        vehicleEcuEntries = [];
        canConnectDongle.value = false;
        return;
      }

      vehicleDisplayName.value =
          '${matchedModel.name} — ${matchedSubModel.name}';
      vehicleEcuEntries =
          matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

      _log('Vehicle resolved from ESN: ${vehicleDisplayName.value} '
          '(${vehicleEcuEntries.length} ECU entr${vehicleEcuEntries.length == 1 ? 'y' : 'ies'})');

      // Vehicle/ECU info is now known — dongle can be connected any time
      // from here on, independent of the remaining scan steps.
      canConnectDongle.value = vehicleEcuEntries.isNotEmpty;
    } catch (e) {
      _log('Vehicle context resolution failed: $e');
      vehicleDisplayName.value = '';
      vehicleEcuEntries = [];
      canConnectDongle.value = false;
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

  Future<all_ds.AllModel> _ensureModels() async {
    if (_modelsCache != null) return _modelsCache!;
    _accessToken ??= await SecureStorageService.getAccessToken();
    _modelsCache = await _authService.getModels(accessToken: _accessToken);
    return _modelsCache!;
  }

  Future<bool> _isValidListNumber(String value) async {
    final scanned = value.trim().toUpperCase();

    bool checkAgainst(list_ds.ListNumber list) {
      return (list.results ?? []).any(
        (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
      );
    }

    final cached = await _ensureVariantList();
    if (checkAgainst(cached)) return true;

    _log(
        'List validation: no match in cached list — refetching to rule out stale cache');
    final fresh = await _ensureVariantList(forceRefresh: true);
    return checkAgainst(fresh);
  }

  Future<void> _resolveInjectorConfig(String scannedListValue) async {
    try {
      final list = await _ensureVariantList();
      final scanned = scannedListValue.trim().toUpperCase();

      final variant = (list.results ?? []).firstWhereOrNull(
        (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
      );
      if (variant == null) {
        _log('Injector config: no matching variant for "$scannedListValue"');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final vehicleModelId = variant.vehicleModel;
      final subModelId = variant.subModel;
      final ecuId = (variant.variantEcu ?? [])
          .map((ve) => ve.ecu)
          .whereType<int>()
          .firstOrNull;

      if (vehicleModelId == null || subModelId == null || ecuId == null) {
        _log('Injector config: variant missing model/submodel/ecu ids');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final models = await _ensureModels();
      all_ds.SubmodelModelecu? matched;

      for (final result in models.results ?? <all_ds.Result>[]) {
        if (result.id != vehicleModelId) continue;
        for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
          if (subModel.id != subModelId) continue;

          final candidates =
              subModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];
          if (candidates.isEmpty) continue;
          matched =
              candidates.firstWhereOrNull((sme) => sme.ecu?.id == ecuId) ??
                  candidates.first;

          if (matched.ecu?.id != ecuId) {
            _log(
                'Injector config: ecu mismatch (variant says $ecuId, models/get-models/ has ${matched.ecu?.id}) — using the submodel\'s entry anyway');
          }
        }
      }

      if (matched == null) {
        _log(
            'Injector config: no submodel_modelecu match in models/get-models/');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final noOfInjectors = matched.noOfInjectors;
      final firingSequenceStr = matched.firingSequence ?? '';

      if (noOfInjectors == null || noOfInjectors <= 0) {
        _log(
            'Injector config: no_of_injectors missing/invalid — using default');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final firingOrder = firingSequenceStr
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      _log(
          'Injector config resolved: $noOfInjectors injector(s), firing sequence [${firingOrder.join(',')}]');
      _configureIqaFields(
        noOfInjectors,
        firingOrder.length == noOfInjectors ? firingOrder : null,
      );
    } catch (e) {
      _log('Injector config resolution failed: $e — using default');
      _configureIqaFields(_defaultIqaCount, null);
    }
  }

  final RxList<harness_ds.Receipe> harnessReceipes = <harness_ds.Receipe>[].obs;

  // ── Live PLC values for the current harness's recipe sensors ──
  // Keyed by sensor id. Populated by reading each sensor's register
  // address from the connected PLC, right after the harness API
  final RxMap<int, String> livePlcValues = <int, String>{}.obs;
  final RxBool isReadingPlcValues = false.obs;

  Future<void> _readLivePlcValuesForHarness() async {
    if (harnessReceipes.isEmpty) return;

    if (!plcService.isConnected.value) {
      _log('PLC not connected — showing recipe reference values only (no live read)');
      return;
    }

    isReadingPlcValues.value = true;
    livePlcValues.clear();
    _log('Reading ${harnessReceipes.length} sensor value(s) from PLC…');

    // NOTE: reads are sequential, not parallel. Most real Modbus TCP
    // slave devices only handle one request at a time per connection —
    // firing all reads at once (even with transaction-ID matching on
    // our end) causes the slave to silently drop everything after the
    // first request, which shows up as timeouts on every sensor after
    // the first. One at a time is the reliable approach.
    for (final sensor in harnessReceipes) {
      await _readOneSensor(sensor);
      // Small gap between requests — some PLCs/gateways need a brief
      // settling time between transactions, even when sent sequentially.
      await Future.delayed(const Duration(milliseconds: 50));
    }

    isReadingPlcValues.value = false;
    _log('PLC Write complete for ${harnessReceipes.length} sensor(s)');
  }

  Future<void> _readOneSensor(harness_ds.Receipe sensor) async {
    final id = sensor.id;
    final reg = sensor.regAddress;
    if (id == null || reg == null) return;

    try {
      final int raw = await plcService.readRegister(reg);
      final double engineeringValue = _applySensorFormula(sensor.type, raw);
      final String formatted = engineeringValue.toStringAsFixed(2);

      livePlcValues[id] = formatted;

      // Verbose debug info — console/VS Code only, not shown in the UI.
      print(
          '[PLC WRITE] ${sensor.sensorName} | Reg $reg | Raw=$raw | Converted=$formatted ${sensor.unit ?? ''}');

      // Clean, UI-facing Activity line — Sensor / Reg Address / Type / Value,
      // with Value coming from the live PLC read (not the API's static value).
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Type: ${sensor.type ?? '-'}  |  Value: $formatted ${sensor.unit ?? ''}'
              .trim());
    } catch (e) {
      livePlcValues[id] = 'ERR';
      print('[PLC WRITE] ${sensor.sensorName} | Reg $reg | FAILED: $e');
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Type: ${sensor.type ?? '-'}  |  Value: ERR');
    }
  }

  // ── Write ──
  final RxBool isWritingSensor = false.obs;
  final RxSet<int> writeInFlightSensorIds = <int>{}.obs;

  /// Writes [value] to [sensor]'s register on the PLC and confirms the
  /// write actually took (PlcService.writeRegister checks the PLC echoed
  /// back the same address+value, not just that bytes went out).
  /// Same dual-logging pattern as reads: clean line in the UI Activity
  /// box, verbose raw detail to the console only.
  Future<void> writeSensorValue(harness_ds.Receipe sensor, int value) async {
    final id = sensor.id;
    final reg = sensor.regAddress;
    if (id == null || reg == null) return;

    if (!plcService.isConnected.value) {
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Write FAILED: PLC not connected');
      return;
    }

    writeInFlightSensorIds.add(id);
    try {
      final bool confirmed = await plcService.writeRegister(reg, value);

      // Verbose debug info — console/VS Code only.
      print(
          '[PLC WRITE] ${sensor.sensorName} | Reg $reg | Value=$value | Confirmed=$confirmed');

      if (confirmed) {
        // Re-read immediately so the UI/Recipe dialog shows the
        // just-written value confirmed back from the PLC, not just
        // what we asked to write.
        livePlcValues[id] = value.toStringAsFixed(2);
        _log(
            '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Type: ${sensor.type ?? '-'}  |  Written: $value ${sensor.unit ?? ''}'
                .trim());
      } else {
        _log(
            '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Write NOT CONFIRMED (PLC did not echo the value back)');
      }
    } catch (e) {
      print('[PLC WRITE] ${sensor.sensorName} | Reg $reg | FAILED: $e');
      _log('  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: $reg  |  Write FAILED: $e');
    } finally {
      writeInFlightSensorIds.remove(id);
    }
  }

  /// TODO: this only handles "Linear" directly (raw value as-is, since
  /// the recipe API doesn't currently give us multiplier/offset — the
  /// register is assumed to already be PLC-scaled). Extend the other
  /// branches once the real formulas/constants for Resistance/Current
  /// sensors are confirmed for this API (see the older ESNController's
  /// handlePlcData for the fuller reference formulas: current sensor
  /// uses (Vout-2.5)/0.185, resistance uses R1*Vout/(Vin-Vout), etc.).
  double _applySensorFormula(String? type, int raw) {
    final t = (type ?? '').toLowerCase();
    if (t.contains('resistance')) {
      // TODO: needs real R1/Vin constants for this sensor — placeholder
      // treats raw as already representing the resistance directly.
      return raw.toDouble();
    }
    if (t.contains('current')) {
      // TODO: needs the real current-sensor scaling — placeholder
      // treats raw as already representing the current directly.
      return raw.toDouble();
    }
    // Linear (default): raw value as-is.
    return raw.toDouble();
  }

  Future<bool> _isValidHarness(String value) async {
    final scanned = value.trim();
    final harnessList = await _authService.getHarnessList(
      harnessName: scanned,
      accessToken: _accessToken,
    );

    final match = (harnessList.results ?? []).firstWhereOrNull(
      (r) => (r.name ?? '').trim().toUpperCase() == scanned.toUpperCase(),
    );

    if (match == null) return false;
    if (match.isActive != true) return false;

    harnessReceipes.assignAll(match.receipes ?? []);
    _log(
        'Harness matched: "${match.name}" (${harnessReceipes.length} recipe sensor(s))');

    // Read live values from the PLC right away — fast/parallel, and
    // each sensor's result gets logged to Activity as it comes in
    // (see _readLivePlcValuesForHarness / _readOneSensor).
    unawaited(_readLivePlcValuesForHarness());
    for (final sensor in harnessReceipes.reversed) {
      _log(
          '  • Sensor: ${sensor.sensorName ?? '-'}  |  Reg Address: ${sensor.regAddress ?? '-'}  |  Type: ${sensor.type ?? '-'}  |  Value: ${sensor.value ?? '-'} ${sensor.unit ?? ''}'
              .trim());
    }

    return true;
  }

  void _configureIqaFields(int count, List<String>? firingOrder) {
    for (final c in iqaControllers) {
      c.dispose();
    }
    for (final f in iqaFocusNodes) {
      f.dispose();
    }
    for (final t in _iqaIdleTimers) {
      t?.cancel();
    }

    iqaControllers = List.generate(count, (_) => TextEditingController());
    iqaFocusNodes = List.generate(count, (_) => FocusNode());
    _iqaIdleTimers = List.generate(count, (_) => null);

    iqaLabels = List.generate(count, (i) => 'IQA ${i + 1}');
    _iqaFiringOrder = firingOrder;
  }

  String _iqaRecordLabel(int i) {
    final order = _iqaFiringOrder;
    if (order != null && i < order.length) {
      return 'IQA (Cyl ${order[i]})';
    }
    return iqaLabels[i];
  }

  void _resetForEsnEdit() {
    _log('ESN changed — resetting flow from the start');

    for (int i = 1; i < stepControllers.length; i++) {
      stepControllers[i].clear();
      _idleTimers[i]?.cancel();
    }
    _configureIqaFields(_defaultIqaCount, null);

    harnessReceipes.clear();
    livePlcValues.clear();
    isReadingPlcValues.value = false;

    _flashStopwatch?.cancel();
    flashInProgress.value = false;
    flashComplete.value = false;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;

    dtcList.clear();
    pidList.clear();

    availableFlashFiles.clear();
    _fileToDtcDatasetId.clear();
    _fileToPidDatasetId.clear();
    _currentDtcDatasetId = null;
    _currentPidDatasetId = null;
    selectedFlashFile.value = null;
    flashFilesError.value = '';

    esnError.value = '';
    listError.value = '';
    currentStepIndex.value = 0;

    // Dongle connection is tied to a specific vehicle's ECU config —
    // reset it too when ESN changes.
    canConnectDongle.value = false;
    dongleConnected.value = false;
    dongleIp.value = '';
    dongleIpController.clear();
  }

  // ── Single-field steps (ESN, List, Harness) ──

  void onFieldChanged(int index) {
    if (index == 0 && currentStepIndex.value != 0) {
      _resetForEsnEdit();
    }
    if (index != currentStepIndex.value) return;
    _idleTimers[index]?.cancel();
    _idleTimers[index] = Timer(_idleDuration, () => submitStep(index));
  }

  Future<void> submitStep(int index) async {
    if (index == 0 && currentStepIndex.value != 0) {
      _resetForEsnEdit();
    }
    if (index != currentStepIndex.value) return;
    _idleTimers[index]?.cancel();

    final value = stepControllers[index].text.trim();
    if (value.isEmpty) return;

    final step = steps[index];

    if (step.key == 'esn') {
      esnError.value = '';
      try {
        final isValid = await _isValidEsn(value);
        if (!isValid) {
          final message = 'ESN not recognized. Please rescan.';
          esnError.value = message;
          _log('ESN mismatch: scanned "$value"');
          _showErrorPopup(message, title: 'ESN Mismatch');
          return;
        }
        await _resolveVehicleFromEsn();
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        esnError.value = message;
        _log('Failed to validate ESN: $e');
        _showErrorPopup(message, title: 'ESN Validation Failed');
        return;
      }
    }

    if (step.key == 'list') {
      listError.value = '';
      try {
        final isValid = await _isValidListNumber(value);
        if (!isValid) {
          final message = 'List number not recognized. Please rescan.';
          listError.value = message;
          _log('List number mismatch: scanned "$value"');
          _showErrorPopup(message, title: 'List Number Mismatch');
          return;
        }
        await _resolveInjectorConfig(value);
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        listError.value = message;
        _log('Failed to validate list number: $e');
        _showErrorPopup(message, title: 'List Validation Failed');
        return;
      }
    }

    if (step.key == 'harness') {
      try {
        final isValid = await _isValidHarness(value);
        if (!isValid) {
          final message = 'Harness not recognized. Please rescan.';
          _log('Harness mismatch: scanned "$value"');
          _showErrorPopup(message, title: 'Harness Mismatch');
          return;
        }
      } catch (e) {
        final message = e.toString().replaceFirst('Exception: ', '');
        _log('Failed to validate harness: $e');
        _showErrorPopup(message, title: 'Harness Validation Failed');
        return;
      }
    }

    _log('${step.label} scanned: $value');
    currentStepIndex.value = index + 1;

    if (allStepsComplete) {
      _log('All scan steps complete. Ready to flash.');
      _onAllStepsComplete();
      return;
    }

    final nextStep = steps[currentStepIndex.value];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (nextStep.type == StepType.single) {
        stepFocusNodes[currentStepIndex.value].requestFocus();
      } else {
        iqaFocusNodes[0].requestFocus();
      }
    });
  }

  // ── IQA group ──

  void onIqaFieldChanged(int subIndex) {
    _iqaIdleTimers[subIndex]?.cancel();
    _iqaIdleTimers[subIndex] =
        Timer(_idleDuration, () => submitIqaField(subIndex));
  }

  void submitIqaField(int subIndex) {
    if (allStepsComplete) return;

    _iqaIdleTimers[subIndex]?.cancel();
    final value = iqaControllers[subIndex].text.trim();
    if (value.isEmpty) return;

    _log('${_iqaRecordLabel(subIndex)} scanned: $value');

    if (subIndex < iqaLabels.length - 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        iqaFocusNodes[subIndex + 1].requestFocus();
      });
      return;
    }

    final allFilled = iqaControllers.every((c) => c.text.trim().isNotEmpty);
    if (!allFilled) return;

    _log('IQA group complete');
    currentStepIndex.value = currentStepIndex.value + 1;

    if (allStepsComplete) {
      _log('All scan steps complete. Ready to flash.');
      _onAllStepsComplete();
    }
  }

  void _onAllStepsComplete() {
    _loadAvailableFlashFiles();
  }

  Future<void> _loadAvailableFlashFiles() async {
    flashFilesLoading.value = true;
    flashFilesError.value = '';
    try {
      final modelName = _esnVehicleModelName?.trim();
      final subModelName = _esnVehicleSubModelName?.trim();

      if (modelName == null ||
          modelName.isEmpty ||
          subModelName == null ||
          subModelName.isEmpty) {
        _log('Flash files: no ESN-resolved model/sub_model name to filter by');
        availableFlashFiles.assignAll(<String>[]);
        selectedFlashFile.value = null;
        return;
      }

      final all_ds.AllModel models = await _ensureModels();

      all_ds.Result? matchedModel;
      all_ds.SubModel? matchedSubModel;

      for (final result in models.results ?? <all_ds.Result>[]) {
        if ((result.name ?? '').trim().toUpperCase() !=
            modelName.toUpperCase()) {
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
        _log(
            'Flash files: no match for model="$modelName", sub_model="$subModelName" in models/get-models/');
        availableFlashFiles.assignAll(<String>[]);
        selectedFlashFile.value = null;
        return;
      }

      final ecuEntries =
          matchedSubModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[];

      final files = <String>[];
      _fileToDtcDatasetId.clear();
      _fileToPidDatasetId.clear();

      for (final sme in ecuEntries) {
        final flashFiles = sme.flashFile?.file ?? <all_ds.FileElement>[];
        if (flashFiles.isEmpty) continue;

        final dtcDatasetId =
            (sme.datasets ?? []).isNotEmpty ? sme.datasets!.first.id : null;
        final pidDatasetId = (sme.pidDatasets ?? []).isNotEmpty
            ? sme.pidDatasets!.first.id
            : null;

        for (final f in flashFiles) {
          final name = f.dataFileName ?? f.swPartNo;
          if (name == null) continue;
          if (!files.contains(name)) files.add(name);
          if (dtcDatasetId != null) {
            _fileToDtcDatasetId[name] = dtcDatasetId;
          }
          if (pidDatasetId != null) {
            _fileToPidDatasetId[name] = pidDatasetId;
          }
        }
      }

      availableFlashFiles.assignAll(files);
      selectedFlashFile.value = null;
      _log(
          'Loaded ${files.length} flash file(s) for $modelName — $subModelName');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      flashFilesError.value = message;
      _log('Failed to load flash files: $e');
      _showErrorPopup(message, title: 'Failed to Load Flash Files');
    } finally {
      flashFilesLoading.value = false;
    }
  }

  void selectFlashFile(String? file) {
    selectedFlashFile.value = file;
    _currentDtcDatasetId = file != null ? _fileToDtcDatasetId[file] : null;
    _currentPidDatasetId = file != null ? _fileToPidDatasetId[file] : null;
  }

  // ── Dongle connect — call this from a "Connect" button once ESN is
  // resolved (canConnectDongle.value == true). Independent of the
  // sequential List/Harness/IQA steps, so the technician can connect
  // whenever the dongle is physically plugged in. ──
  Future<void> connectDongle() async {
    final ip = dongleIpController.text.trim();
    if (ip.isEmpty) {
      _log('Connect: no IP entered');
      _showErrorPopup('Enter the dongle IP address', title: 'Missing IP');
      return;
    }
    if (vehicleEcuEntries.isEmpty) {
      _log('Connect: no ECU data resolved yet — scan ESN first');
      _showErrorPopup('Scan ESN first so vehicle/ECU info is known',
          title: 'Not Ready');
      return;
    }

    dongleConnecting.value = true;
    dongleIp.value = ip;
    try {
      // 1️⃣ Populate StaticData.ecuInfo from the already-resolved vehicle ECUs
      StaticData.ecuInfo = <EcuDataSet>[];

      for (final sme in vehicleEcuEntries) {
        StaticData.ecuInfo.add(EcuDataSet(
          ecuID: sme.ecu?.id,
          ecuName: sme.ecu?.name,
          txHeader: sme.ecu?.txHeader,
          rxHeader: sme.ecu?.rxHeader,
          protocol: sme.ecu?.protocol,
          channelId: sme.ecu?.channel,
          seedKeyIndex: sme.ecu?.seedkeyalgoFnIndex?.value,
          readDtcIndex: sme.ecu?.readDtcFnIndex?.value,
          clearDtcIndex: sme.ecu?.clearDtcFnIndex?.value,
          writePidIndex: sme.ecu?.writeDataFnIndex?.value,
          iorTestFnIndex: sme.ecu?.iorTestFnIndex?.value,
          firingSequence: sme.firingSequence,
          noOfInjectors: sme.noOfInjectors,
        ));
      }

      if (StaticData.ecuInfo.isEmpty) {
        _log('Connect: no ECU entries to configure');
        _showErrorPopup('No ECU configuration found for this vehicle',
            title: 'Connect Failed');
        dongleConnected.value = false;
        return;
      }

      // 2️⃣ Connect over WiFi — channel id comes from the first ECU
      final channelParts = StaticData.ecuInfo.first.channelId?.split('-');
      final channelId = (channelParts != null && channelParts.length > 1)
          ? '0${channelParts[1]}'
          : '00';

      _log('Connecting to dongle at $ip...');
      final macId =
          await _connectionWifi.getDongleMacID(ip, channelId: channelId);

      if (macId.isEmpty) {
        _log('❌ Failed to connect to dongle at $ip');
        _showErrorPopup('Could not connect to dongle at $ip',
            title: 'Connect Failed');
        dongleConnected.value = false;
        return;
      }
      _log('✅ Connected. MAC: $macId');

      // 3️⃣ Apply protocol/tx/rx headers and confirm via firmware read
      final firmware = await App.dllFunctions?.setDongleProperties1() ?? '';
      if (firmware.isEmpty) {
        _log('❌ Failed to configure dongle properties / read firmware');
        _showErrorPopup('Connected, but failed to configure dongle',
            title: 'Connect Failed');
        dongleConnected.value = false;
        return;
      }

      _log('✅ Dongle ready — firmware $firmware');
      dongleConnected.value = true;
    } catch (e) {
      _log('❌ Connect exception: $e');
      _showErrorPopup(e.toString(), title: 'Connect Failed');
      dongleConnected.value = false;
    } finally {
      dongleConnecting.value = false;
    }
  }

  Future<void> startFlashing() async {
    if (!allStepsComplete ||
        flashInProgress.value ||
        flashComplete.value ||
        selectedFlashFile.value == null) {
      return;
    }

    if (!dongleConnected.value || App.dllFunctions == null) {
      _log('❌ Cannot flash — dongle not connected');
      _showErrorPopup('Connect to the dongle before flashing',
          title: 'Not Connected');
      return;
    }

    final fileName = selectedFlashFile.value!;
    _log('Selected flash file: $fileName');

    all_ds.SubmodelModelecu? sme;
    all_ds.FileElement? fileEntry;
    for (final entry in vehicleEcuEntries) {
      final files = entry.flashFile?.file ?? <all_ds.FileElement>[];
      final match = files.firstWhereOrNull(
        (f) => (f.dataFileName ?? f.swPartNo) == fileName,
      );
      if (match != null) {
        sme = entry;
        fileEntry = match;
        break;
      }
    }

    if (sme == null || fileEntry == null) {
      _log('❌ Could not resolve ECU/file entry for "$fileName"');
      _showErrorPopup('Internal error: file not resolved',
          title: 'Flashing Failed');
      return;
    }

    flashInProgress.value = true;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;
    _log('Flashing started');

    _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
      flashElapsedSeconds.value++;
    });

    Timer? percentTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        flashProgress.value = await App.dllFunctions!.flashingData();
      } catch (_) {}
    });

    String? result;
    try {
      await App.dllFunctions!.setDongleProperties(
        sme.ecu?.protocol?.autopeepal ?? '',
        sme.ecu?.txHeader ?? '',
        sme.ecu?.rxHeader ?? '',
      );

      _log('Downloading sequence file...');
      final sequenceContent =
          await _downloadAsRawString(sme.flashFile!.sequenceFile!);
      _log('Downloading firmware file: $fileName');
      final hexContent = await _downloadAsRawString(fileEntry.dataFile!);

      // EcuMapFile entries + checksum come straight from the API model —
      // no more parsing them out of the .fsq sequence-file text.
      final ecuMapFiles = sme.flashFile!.ecuMapFile ?? <all_ds.EcuMapFile>[];
      final checksumAlgo = sme.flashFile!.flashCheckSumType?.toString() ?? '';

      final flashJson = await readJson(
        ecuMapFiles,
        checksumAlgo,
        Uint8List.fromList(hexContent.codeUnits),
      );

      if (flashJson.isEmpty) {
        throw Exception('Failed to convert firmware file to flash JSON');
      }

      result = await App.dllFunctions!.startECUFlashing(
        flashJson,
        sequenceContent,
        sme.ecu!,
        sme.ecu?.seedkeyalgoFnIndex?.value ?? '',
      );
    } catch (e) {
      _log('❌ Flashing exception: $e');
      result = e.toString();
    }

    _flashStopwatch?.cancel();
    percentTimer.cancel();
    flashInProgress.value = false;

    if (result == null || result.isEmpty || result != 'NOERROR') {
      flashComplete.value = false;
      _log('❌ Flashing failed: $result');
      _showErrorPopup(result ?? 'Unknown error', title: 'Flashing Failed');
      return;
    }

    flashComplete.value = true;
    _log('Flashing completed successfully (${formattedElapsed})');

    await _loadDtcResults();
    await _loadPidResults();
    _showFlashCompletePopup();
  }

  Future<String> _downloadAsRawString(String url) async {
    final client = HttpClient();
    final request = await client.getUrl(Uri.parse(url));
    final response = await request.close();
    final bytes =
        await response.fold<List<int>>(<int>[], (p, c) => p..addAll(c));
    client.close();
    return latin1.decode(bytes);
  }

  // ── Flash JSON conversion — uses EcuMapFile data straight from the API ──
  List<all_ds.EcuMapFile>? parsedEcuMapFiles;
  RxBool isBusy = false.obs;
  RxString loaderText = ''.obs;

  Future<String> readJson(
    List<all_ds.EcuMapFile> ecuMapFiles,
    String checksumAlgo,
    Uint8List flashFileBytes,
  ) async {
    try {
      isBusy.value = true;
      loaderText.value = "Processing Dataset...";
      _log('Converting flash file to JSON '
          '(${ecuMapFiles.length} EcuMapFile entries, checksum: '
          '${checksumAlgo.isEmpty ? '-' : checksumAlgo})...');

      final getJson = GetJson();
      final flashJson = await getJson.convertToJson(
        flashFileBytes,
        ecuMapFiles,
        checksumAlgo,
      );
      parsedEcuMapFiles = ecuMapFiles;
      _log('Conversion done, JSON length: ${flashJson.length}');

      return flashJson;
    } catch (e) {
      _log('❌ readJson error: $e');
      return '';
    } finally {
      _resetLoader();
    }
  }

  void _setBusy(bool busy, String text) {
    isBusy.value = busy;
    loaderText.value = text;
  }

  void _resetLoader() => _setBusy(false, "");

  Future<void> _loadDtcResults() async {
    final datasetId = _currentDtcDatasetId;
    if (datasetId == null) {
      _log('No DTC dataset id available — skipping');
      return;
    }

    _accessToken ??= await SecureStorageService.getAccessToken();

    try {
      final dtc_ds.DtcDataset dtc = await _authService.getDtcDataset(
        id: datasetId,
        accessToken: _accessToken,
      );

      final dtcStrings = <String>[];
      for (final result in dtc.results ?? <dtc_ds.Result>[]) {
        for (final code in result.dtcCode ?? <dtc_ds.DtcCode>[]) {
          final c = code.code ?? '';
          final desc = code.description ?? '';
          final line = desc.isNotEmpty ? '$c - $desc' : c;
          if (line.trim().isNotEmpty) dtcStrings.add(line);
        }
      }
      dtcList.assignAll(dtcStrings);
      _log('DTC (${dtcList.length}) data loaded');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _log('Failed to load DTC dataset: $e');
      dtcList.clear();
      _showErrorPopup(message, title: 'Failed to Load DTC');
    }
  }

  Future<void> _loadPidResults() async {
    final datasetId = _currentPidDatasetId;
    if (datasetId == null) {
      _log('No PID dataset id available — skipping');
      return;
    }

    _accessToken ??= await SecureStorageService.getAccessToken();

    try {
      final pid_ds.PidDataset pid = await _authService.getPidDataset(
        id: datasetId,
        accessToken: _accessToken,
      );

      final pidStrings = <String>[];
      for (final result in pid.results ?? <pid_ds.Result>[]) {
        for (final code in result.codes ?? <pid_ds.Code>[]) {
          for (final v in code.piCodeVariable ?? <pid_ds.PiCodeVariable>[]) {
            final name = v.longName ??
                v.shortName ??
                code.shortName ??
                code.code ??
                'PID';
            final unit = v.unit ?? '';
            pidStrings.add(unit.isNotEmpty ? '$name — $unit' : name);
          }
        }
      }
      pidList.assignAll(pidStrings);
      _log('PID (${pidList.length}) data loaded');
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _log('Failed to load PID dataset: $e');
      pidList.clear();
      _showErrorPopup(message, title: 'Failed to Load PID');
    }
  }

  void _showFlashCompletePopup() {
    final iqaSummary = List.generate(
      iqaLabels.length,
      (i) => '${_iqaRecordLabel(i)}: ${iqaControllers[i].text.trim()}',
    ).join('\n');

    final message = 'File: ${selectedFlashFile.value ?? '-'}\n\n$iqaSummary';

    Get.dialog(
      CustomPopup(
        title: 'Flashing Complete',
        message: message,
        confirmText: 'OK',
      ),
      barrierDismissible: true,
    );
  }

  void toggleDtc() => dtcExpanded.toggle();
  void togglePid() => pidExpanded.toggle();

  void logout() {
    _log('Logged out');
    Get.offAllNamed('/login');
  }

  @override
  void onClose() {
    for (final c in stepControllers) {
      c.dispose();
    }
    for (final f in stepFocusNodes) {
      f.dispose();
    }
    for (final t in _idleTimers) {
      t?.cancel();
    }
    for (final c in iqaControllers) {
      c.dispose();
    }
    for (final f in iqaFocusNodes) {
      f.dispose();
    }
    for (final t in _iqaIdleTimers) {
      t?.cancel();
    }
    dongleIpController.dispose();
    _flashStopwatch?.cancel();
    super.onClose();
  }
}
