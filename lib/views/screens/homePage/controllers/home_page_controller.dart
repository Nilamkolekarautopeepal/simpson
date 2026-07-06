// // import 'dart:async';
// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:simpson/AppPreferences/app_areferences.dart';
// import 'package:simpson/common_widgets/popup.dart';
// import 'package:simpson/modals/all.models.dart'
//     as all_ds; // AllModel, Result, SubModel, SubmodelModelecu, FileElement — prefixed to avoid colliding with flashRecord/pidDataset/dtcDataset/listNumber's own Result/FileElement classes
// import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
// import 'package:simpson/modals/dtcDataset.model.dart' as dtc_ds;
// import 'package:simpson/modals/listNumber.model.dart' as list_ds;
// import 'package:simpson/services/apiServices.dart';

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

//   /// Default IQA field count/labels used until a List number resolves a
//   /// real injector count. Also the fallback if resolution fails.
//   static const _defaultIqaCount = 4;

//   /// Mutable (not const) — rebuilt by _configureIqaFields() once the
//   /// scanned List number is matched to a vehicle's no_of_injectors /
//   /// firing_sequence in models/get-models/.
//   List<String> iqaLabels = List.generate(_defaultIqaCount, (i) => 'IQA ${i + 1}');
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

//   /// Cached variant/list-number lookup so the List field doesn't hit the
//   /// API on every keystroke — fetched once and reused for the session.
//   list_ds.ListNumber? _variantListCache;

//   /// Cached models/get-models/ response — used both to resolve
//   /// no_of_injectors/firing_sequence right after List validates, and later
//   /// to build the flash-file → DTC/PID dataset id maps. Fetched once and
//   /// reused so we don't hit the API twice for the same data.
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

//   /// dataFileName -> the DTC dataset id (submodel_modelecu.datasets[0].id)
//   /// that owns it, read from GET models/get-models/.
//   final Map<String, int> _fileToDtcDatasetId = {};

//   /// dataFileName -> the PID dataset id (submodel_modelecu.pid_datasets[0].id)
//   /// that owns it, read from GET models/get-models/.
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

//   // ── Activity log (newest first) ──
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

//     // Start with the default 4-field IQA layout; _configureIqaFields()
//     // will rebuild these at the real injector count once the List number
//     // resolves, before the operator ever reaches the IQA step.
//     iqaControllers =
//         List.generate(_defaultIqaCount, (_) => TextEditingController());
//     iqaFocusNodes = List.generate(_defaultIqaCount, (_) => FocusNode());
//     _iqaIdleTimers = List.generate(_defaultIqaCount, (_) => null);

//     _log('Session started on "$station"');

//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       stepFocusNodes[0].requestFocus();
//     });

//     // Load the access token up front so it's ready by the time we need it
//     // for models/list/DTC/PID API calls.
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

//   /// Shared error popup — every failure path in this controller (ESN
//   /// mismatch, List mismatch, flash-file load failure, DTC/PID load
//   /// failure) routes through here so the operator always sees a dialog,
//   /// not just inline text they might miss.
//   void _showErrorPopup(String message, {String title = 'Error'}) {
//     if (Get.isDialogOpen == true) {
//       Get.back(); // close any existing dialog first so they don't stack
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

//   Future<String> _fetchEcuEsn(String scannedValue) async {
//     await Future.delayed(const Duration(milliseconds: 150));
//     return scannedValue; // TODO: no real ESN API yet — replace with the
//     // actual ECU-read call once it's available. Currently always "matches"
//     // whatever the operator typed/scanned.
//   }

//   /// Fetches the variant/list-number dataset once and caches it for the
//   /// rest of the session, so the List field's validation doesn't re-hit
//   /// the API on every keystroke.
//   Future<list_ds.ListNumber> _ensureVariantList() async {
//     if (_variantListCache != null) return _variantListCache!;
//     _accessToken ??= await SecureStorageService.getAccessToken();
//     _variantListCache =
//         await _authService.getVariantsList(accessToken: _accessToken);
//     return _variantListCache!;
//   }

//   /// Fetches models/get-models/ once and caches it — reused both for
//   /// resolving injector config right after List validates, and later for
//   /// the flash-file dataset-id maps in _loadAvailableFlashFiles().
//   Future<all_ds.AllModel> _ensureModels() async {
//     if (_modelsCache != null) return _modelsCache!;
//     _accessToken ??= await SecureStorageService.getAccessToken();
//     _modelsCache = await _authService.getModels(accessToken: _accessToken);
//     return _modelsCache!;
//   }

//   /// Checks the scanned List value against every variant's `variant_code`
//   /// in the real getVariantsList() response.
//   /// TODO: confirm listNumber.model.dart's field name for "variant_code" —
//   /// this assumes it deserializes to `variantCode` following this
//   /// codebase's snake_case -> camelCase convention. Adjust if it's named
//   /// differently in the actual model file.
//   Future<bool> _isValidListNumber(String value) async {
//     final list = await _ensureVariantList(); // let exceptions propagate to
//     // the caller, so submitStep can show the *actual* failure (e.g. a
//     // network/auth error) in the popup instead of a generic "not
//     // recognized" message.
//     final scanned = value.trim().toUpperCase();
//     return (list.results ?? []).any(
//       (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
//     );
//   }

//   /// Resolves how many IQA fields to show and how to label them, by
//   /// matching the scanned List number's variant (vehicle_model, sub_model,
//   /// variant_ecu.ecu) against models/get-models/'s
//   /// submodel_modelecu[].no_of_injectors / .firing_sequence.
//   ///
//   /// TODO: field-name assumptions on listNumber.model.dart, same
//   /// snake_case -> camelCase convention as the rest of this codebase:
//   ///   vehicle_model -> vehicleModel (int)
//   ///   sub_model     -> subModel (int)
//   ///   variant_ecu   -> variantEcu (List<...>), each with a plain int `ecu`
//   ///                    field (NOT a nested object — matches the JSON
//   ///                    shown, unlike all.models.dart's Ecu object).
//   /// Adjust the property names below if the real model differs.
//   ///
//   /// If no match is found, silently falls back to the default 4-field IQA
//   /// layout — a failed injector-count lookup should not block the scan
//   /// flow, since IQA can still be scanned generically.
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

//           // Prefer an exact ecu match if one exists, but the variant
//           // list's `ecu` id and the models endpoint's `ecu.id` don't
//           // always agree for the same vehicle+submodel (seen in practice —
//           // e.g. variant says ecu 1, models/get-models/ only has ecu 3 for
//           // that submodel). Since every submodel in this data has exactly
//           // one ECU entry anyway, fall back to "the only/first entry for
//           // this vehicle+submodel" rather than failing the whole lookup.
//           matched = candidates.firstWhereOrNull((sme) => sme.ecu?.id == ecuId) ??
//               candidates.first;

//           if (matched.ecu?.id != ecuId) {
//             _log(
//                 'Injector config: ecu mismatch (variant says $ecuId, models/get-models/ has ${matched.ecu?.id}) — using the submodel\'s entry anyway');
//           }
//         }
//       }

//       if (matched == null) {
//         _log('Injector config: no submodel_modelecu match in models/get-models/');
//         _configureIqaFields(_defaultIqaCount, null);
//         return;
//       }

//       final noOfInjectors = matched.noOfInjectors;
//       final firingSequenceEnum = matched.firingSequence;

//       if (noOfInjectors == null || noOfInjectors <= 0) {
//         _log('Injector config: no_of_injectors missing/invalid — using default');
//         _configureIqaFields(_defaultIqaCount, null);
//         return;
//       }

//       // firing_sequence comes back from the generated model as a
//       // FiringSequence enum (e.g. THE_123, THE_1342), not a raw string —
//       // firingSequenceValues.reverse converts it back to "1,2,3" / "1,3,4,2"
//       // etc. TODO: if models/get-models/ ever returns a firing_sequence
//       // combination not already in firingSequenceValues' map (e.g. a
//       // 6-cylinder "1,5,3,6,2,4"), Ecu.fromJson's non-nullable "!" lookup
//       // will throw before this code even runs — that map may need
//       // extending as new engine configurations are added.
//       final firingSequenceStr = firingSequenceEnum != null
//           ? (all_ds.firingSequenceValues.reverse[firingSequenceEnum] ?? '')
//           : '';

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

//   /// Rebuilds iqaControllers/iqaFocusNodes/_iqaIdleTimers/iqaLabels at the
//   /// given [count] (the resolved no_of_injectors, or the 4-field default
//   /// if resolution failed). Labels are always plain sequential
//   /// "IQA 1".."IQA n" — [firingOrder] is accepted for callers that still
//   /// pass it, but no longer changes the label text.
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
//   }

//   /// If the ESN field is edited after already being confirmed (i.e. the
//   /// user goes back and retypes it), everything that depended on the old
//   /// ESN is no longer valid — reset List, Harness, IQA, Flash, DTC, and
//   /// PID, and restart the flow from ESN.
//   void _resetForEsnEdit() {
//     _log('ESN changed — resetting flow from the start');

//     for (int i = 1; i < stepControllers.length; i++) {
//       stepControllers[i].clear();
//       _idleTimers[i]?.cancel();
//     }

//     // Injector config is tied to the List number about to be re-scanned —
//     // reset IQA back to the generic default until it resolves again.
//     _configureIqaFields(_defaultIqaCount, null);

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
//       final ecuEsn = await _fetchEcuEsn(value);
//       if (value.toUpperCase() != ecuEsn.toUpperCase()) {
//         final message = 'ESN does not match the connected ECU. Please rescan.';
//         esnError.value = message;
//         _log('ESN mismatch: scanned "$value"');
//         _showErrorPopup(message, title: 'ESN Mismatch');
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
//         // Resolve no_of_injectors / firing_sequence now, before the
//         // operator ever reaches the IQA step further down the flow.
//         await _resolveInjectorConfig(value);
//       } catch (e) {
//         // Covers network/auth/parsing failures while validating — shows
//         // the real underlying error rather than a generic mismatch message.
//         final message = e.toString().replaceFirst('Exception: ', '');
//         listError.value = message;
//         _log('Failed to validate list number: $e');
//         _showErrorPopup(message, title: 'List Validation Failed');
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
//     _iqaIdleTimers[subIndex]?.cancel();
//     final value = iqaControllers[subIndex].text.trim();
//     if (value.isEmpty) return;

//     _log('${iqaLabels[subIndex]} scanned: $value');

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

//   /// Real call: GET models/get-models/ → walks
//   /// results[].sub_models[].submodel_modelecu[] and, for every entry that
//   /// has a non-null flash_file with files, records each file's name against
//   /// that entry's DTC dataset id (datasets[0].id) and PID dataset id
//   /// (pid_datasets[0].id). Populates the flash-file dropdown/list from this
//   /// same walk. Reuses the cached models response from
//   /// _resolveInjectorConfig() if the List step already fetched it.
//   Future<void> _loadAvailableFlashFiles() async {
//     flashFilesLoading.value = true;
//     flashFilesError.value = '';
//     try {
//       final all_ds.AllModel models = await _ensureModels();

//       final files = <String>[];
//       _fileToDtcDatasetId.clear();
//       _fileToPidDatasetId.clear();

//       for (final result in models.results ?? <all_ds.Result>[]) {
//         for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
//           for (final sme
//               in subModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[]) {
//             final flashFiles = sme.flashFile?.file ?? <all_ds.FileElement>[];
//             if (flashFiles.isEmpty) continue; // flash_file can be null

//             // TODO: confirm it's always safe to take the first entry —
//             // datasets/pid_datasets are lists but every example seen so far
//             // only ever has exactly one item.
//             final dtcDatasetId =
//                 (sme.datasets ?? []).isNotEmpty ? sme.datasets!.first.id : null;
//             final pidDatasetId = (sme.pidDatasets ?? []).isNotEmpty
//                 ? sme.pidDatasets!.first.id
//                 : null;

//             for (final f in flashFiles) {
//               final name = f.dataFileName ?? f.swPartNo;
//               if (name == null) continue;
//               if (!files.contains(name)) files.add(name);
//               if (dtcDatasetId != null) {
//                 _fileToDtcDatasetId[name] = dtcDatasetId;
//               }
//               if (pidDatasetId != null) {
//                 _fileToPidDatasetId[name] = pidDatasetId;
//               }
//             }
//           }
//         }
//       }

//       availableFlashFiles.assignAll(files);
//       selectedFlashFile.value = null;
//       _log('Loaded ${files.length} flash file(s)');
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

//   Future<void> startFlashing() async {
//     if (!allStepsComplete ||
//         flashInProgress.value ||
//         flashComplete.value ||
//         selectedFlashFile.value == null) {
//       return;
//     }

//     _log('Selected flash file: ${selectedFlashFile.value}');

//     flashInProgress.value = true;
//     flashProgress.value = 0;
//     flashElapsedSeconds.value = 0;
//     _log('Flashing started');

//     _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
//       flashElapsedSeconds.value++;
//     });

//     for (int i = 1; i <= 10; i++) {
//       await Future.delayed(const Duration(milliseconds: 200));
//       flashProgress.value = i / 10;
//     }

//     _flashStopwatch?.cancel();
//     flashInProgress.value = false;
//     flashComplete.value = true;
//     _log('Flashing completed successfully (${formattedElapsed})');

//     // Two fully independent calls — a failure in one has no effect on the
//     // other, and each writes only to its own RxList.
//     await _loadDtcResults();
//     await _loadPidResults();

//     _showFlashCompletePopup();
//   }

//   /// Real call: GET datasets/get-dtc-datasets/?id={datasetId}, using the
//   /// DTC dataset id resolved from the selected flash file via
//   /// _fileToDtcDatasetId. Writes only to dtcList.
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

//   /// Real call: GET datasets/get-pid-datasets?id={datasetId}, using the
//   /// PID dataset id resolved from the selected flash file via
//   /// _fileToPidDatasetId. Writes only to pidList.
//   ///
//   /// NOTE: this dataset only contains PID *definitions* (name, unit,
//   /// min/max, resolution) — not a live reading. TODO: once a real-time PID
//   /// read endpoint exists for the connected ECU, append the live value
//   /// here instead of just the unit, e.g. '$name — $liveValue $unit'.
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
//             // Uses an em dash (' — ') to match what _buildPidCard in the
//             // view splits on. Using '(' ')' here would break that split.
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
//       (i) => '${iqaLabels[i]}: ${iqaControllers[i].text.trim()}',
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
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/all.models.dart'
    as all_ds; // AllModel, Result, SubModel, SubmodelModelecu, FileElement — prefixed to avoid colliding with flashRecord/pidDataset/dtcDataset/listNumber's own Result/FileElement classes
import 'package:simpson/modals/pidDataset.model.dart' as pid_ds;
import 'package:simpson/modals/dtcDataset.model.dart' as dtc_ds;
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/services/apiServices.dart';

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

  /// Default IQA field count/labels used until a List number resolves a
  /// real injector count. Also the fallback if resolution fails.
  static const _defaultIqaCount = 4;

  /// Mutable (not const) — rebuilt by _configureIqaFields(). Always plain
  /// sequential "IQA 1".."IQA n" for on-screen display — this is what the
  /// operator sees and scans against, regardless of firing order.
  List<String> iqaLabels = List.generate(_defaultIqaCount, (i) => 'IQA ${i + 1}');

  /// Separate from iqaLabels: the backend's actual firing order, index-
  /// aligned with iqaControllers/iqaLabels (slot i in the UI corresponds
  /// to cylinder _iqaFiringOrder[i] in the backend's firing_sequence).
  /// Null if no firing sequence was resolved (using the generic default).
  /// This is what "writing"/recording (activity log, flash-complete
  /// summary) uses instead of the flat display label, so a value scanned
  /// into on-screen slot 2 is correctly recorded against whichever
  /// cylinder the backend says actually sits in that firing position —
  /// e.g. firing_sequence "1,3,4,2" means slot 2 records as "Cyl 3", even
  /// though the screen just shows "IQA 2".
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

  /// Cached variant/list-number lookup so the List field doesn't hit the
  /// API on every keystroke — fetched once and reused for the session.
  list_ds.ListNumber? _variantListCache;

  /// Cached models/get-models/ response — used both to resolve
  /// no_of_injectors/firing_sequence right after List validates, and later
  /// to build the flash-file → DTC/PID dataset id maps. Fetched once and
  /// reused so we don't hit the API twice for the same data.
  all_ds.AllModel? _modelsCache;

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

  /// dataFileName -> the DTC dataset id (submodel_modelecu.datasets[0].id)
  /// that owns it, read from GET models/get-models/.
  final Map<String, int> _fileToDtcDatasetId = {};

  /// dataFileName -> the PID dataset id (submodel_modelecu.pid_datasets[0].id)
  /// that owns it, read from GET models/get-models/.
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

  // ── Activity log (newest first) ──
  final RxList<String> activityLog = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    station =
        (Get.arguments is String) ? Get.arguments as String : 'Unknown Station';

    stepControllers =
        List.generate(steps.length, (_) => TextEditingController());
    stepFocusNodes = List.generate(steps.length, (_) => FocusNode());
    _idleTimers = List.generate(steps.length, (_) => null);

    // Start with the default 4-field IQA layout; _configureIqaFields()
    // will rebuild these at the real injector count once the List number
    // resolves, before the operator ever reaches the IQA step.
    iqaControllers =
        List.generate(_defaultIqaCount, (_) => TextEditingController());
    iqaFocusNodes = List.generate(_defaultIqaCount, (_) => FocusNode());
    _iqaIdleTimers = List.generate(_defaultIqaCount, (_) => null);

    _log('Session started on "$station"');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stepFocusNodes[0].requestFocus();
    });

    // Load the access token up front so it's ready by the time we need it
    // for models/list/DTC/PID API calls.
    _loadAccessToken();
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

  /// Shared error popup — every failure path in this controller (ESN
  /// mismatch, List mismatch, flash-file load failure, DTC/PID load
  /// failure) routes through here so the operator always sees a dialog,
  /// not just inline text they might miss.
  void _showErrorPopup(String message, {String title = 'Error'}) {
    if (Get.isDialogOpen == true) {
      Get.back(); // close any existing dialog first so they don't stack
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

  Future<String> _fetchEcuEsn(String scannedValue) async {
    await Future.delayed(const Duration(milliseconds: 150));
    return scannedValue; // TODO: no real ESN API yet — replace with the
    // actual ECU-read call once it's available. Currently always "matches"
    // whatever the operator typed/scanned.
  }

  /// Fetches the variant/list-number dataset once and caches it for the
  /// rest of the session, so the List field's validation doesn't re-hit
  /// the API on every keystroke.
  Future<list_ds.ListNumber> _ensureVariantList() async {
    if (_variantListCache != null) return _variantListCache!;
    _accessToken ??= await SecureStorageService.getAccessToken();
    _variantListCache =
        await _authService.getVariantsList(accessToken: _accessToken);
    return _variantListCache!;
  }

  /// Fetches models/get-models/ once and caches it — reused both for
  /// resolving injector config right after List validates, and later for
  /// the flash-file dataset-id maps in _loadAvailableFlashFiles().
  Future<all_ds.AllModel> _ensureModels() async {
    if (_modelsCache != null) return _modelsCache!;
    _accessToken ??= await SecureStorageService.getAccessToken();
    _modelsCache = await _authService.getModels(accessToken: _accessToken);
    return _modelsCache!;
  }

  /// Checks the scanned List value against every variant's `variant_code`
  /// in the real getVariantsList() response.
  /// TODO: confirm listNumber.model.dart's field name for "variant_code" —
  /// this assumes it deserializes to `variantCode` following this
  /// codebase's snake_case -> camelCase convention. Adjust if it's named
  /// differently in the actual model file.
  Future<bool> _isValidListNumber(String value) async {
    final list = await _ensureVariantList(); // let exceptions propagate to
    // the caller, so submitStep can show the *actual* failure (e.g. a
    // network/auth error) in the popup instead of a generic "not
    // recognized" message.
    final scanned = value.trim().toUpperCase();
    return (list.results ?? []).any(
      (r) => (r.variantCode ?? '').trim().toUpperCase() == scanned,
    );
  }

  /// Resolves how many IQA fields to show and how to label them, by
  /// matching the scanned List number's variant (vehicle_model, sub_model,
  /// variant_ecu.ecu) against models/get-models/'s
  /// submodel_modelecu[].no_of_injectors / .firing_sequence.
  ///
  /// TODO: field-name assumptions on listNumber.model.dart, same
  /// snake_case -> camelCase convention as the rest of this codebase:
  ///   vehicle_model -> vehicleModel (int)
  ///   sub_model     -> subModel (int)
  ///   variant_ecu   -> variantEcu (List<...>), each with a plain int `ecu`
  ///                    field (NOT a nested object — matches the JSON
  ///                    shown, unlike all.models.dart's Ecu object).
  /// Adjust the property names below if the real model differs.
  ///
  /// If no match is found, silently falls back to the default 4-field IQA
  /// layout — a failed injector-count lookup should not block the scan
  /// flow, since IQA can still be scanned generically.
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

          // Prefer an exact ecu match if one exists, but the variant
          // list's `ecu` id and the models endpoint's `ecu.id` don't
          // always agree for the same vehicle+submodel (seen in practice —
          // e.g. variant says ecu 1, models/get-models/ only has ecu 3 for
          // that submodel). Since every submodel in this data has exactly
          // one ECU entry anyway, fall back to "the only/first entry for
          // this vehicle+submodel" rather than failing the whole lookup.
          matched = candidates.firstWhereOrNull((sme) => sme.ecu?.id == ecuId) ??
              candidates.first;

          if (matched.ecu?.id != ecuId) {
            _log(
                'Injector config: ecu mismatch (variant says $ecuId, models/get-models/ has ${matched.ecu?.id}) — using the submodel\'s entry anyway');
          }
        }
      }

      if (matched == null) {
        _log('Injector config: no submodel_modelecu match in models/get-models/');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      final noOfInjectors = matched.noOfInjectors;
      final firingSequenceEnum = matched.firingSequence;

      if (noOfInjectors == null || noOfInjectors <= 0) {
        _log('Injector config: no_of_injectors missing/invalid — using default');
        _configureIqaFields(_defaultIqaCount, null);
        return;
      }

      // firing_sequence comes back from the generated model as a
      // FiringSequence enum (e.g. THE_123, THE_1342), not a raw string —
      // firingSequenceValues.reverse converts it back to "1,2,3" / "1,3,4,2"
      // etc. TODO: if models/get-models/ ever returns a firing_sequence
      // combination not already in firingSequenceValues' map (e.g. a
      // 6-cylinder "1,5,3,6,2,4"), Ecu.fromJson's non-nullable "!" lookup
      // will throw before this code even runs — that map may need
      // extending as new engine configurations are added.
      final firingSequenceStr = firingSequenceEnum != null
          ? (all_ds.firingSequenceValues.reverse[firingSequenceEnum] ?? '')
          : '';

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

  /// Rebuilds iqaControllers/iqaFocusNodes/_iqaIdleTimers/iqaLabels at the
  /// given [count] (the resolved no_of_injectors, or the 4-field default
  /// if resolution failed).
  ///
  /// [firingOrder], if provided, is stored in _iqaFiringOrder for use when
  /// *recording* values (activity log, flash-complete summary) — but
  /// iqaLabels itself stays flat "IQA 1".."IQA n" for on-screen display.
  /// This deliberately separates what the operator sees (simple sequential
  /// numbering) from what gets written/recorded (the backend's real
  /// per-cylinder firing order) — see _iqaFiringOrder's doc comment.
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

  /// The label used when *recording* a scanned IQA value (activity log,
  /// flash-complete summary) — tags it with the real backend cylinder
  /// number from _iqaFiringOrder when available, falling back to the
  /// flat on-screen label (iqaLabels[i]) otherwise.
  String _iqaRecordLabel(int i) {
    final order = _iqaFiringOrder;
    if (order != null && i < order.length) {
      return 'IQA (Cyl ${order[i]})';
    }
    return iqaLabels[i];
  }

  /// If the ESN field is edited after already being confirmed (i.e. the
  /// user goes back and retypes it), everything that depended on the old
  /// ESN is no longer valid — reset List, Harness, IQA, Flash, DTC, and
  /// PID, and restart the flow from ESN.
  void _resetForEsnEdit() {
    _log('ESN changed — resetting flow from the start');

    for (int i = 1; i < stepControllers.length; i++) {
      stepControllers[i].clear();
      _idleTimers[i]?.cancel();
    }

    // Injector config is tied to the List number about to be re-scanned —
    // reset IQA back to the generic default until it resolves again.
    _configureIqaFields(_defaultIqaCount, null);

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
      final ecuEsn = await _fetchEcuEsn(value);
      if (value.toUpperCase() != ecuEsn.toUpperCase()) {
        final message = 'ESN does not match the connected ECU. Please rescan.';
        esnError.value = message;
        _log('ESN mismatch: scanned "$value"');
        _showErrorPopup(message, title: 'ESN Mismatch');
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
        // Resolve no_of_injectors / firing_sequence now, before the
        // operator ever reaches the IQA step further down the flow.
        await _resolveInjectorConfig(value);
      } catch (e) {
        // Covers network/auth/parsing failures while validating — shows
        // the real underlying error rather than a generic mismatch message.
        final message = e.toString().replaceFirst('Exception: ', '');
        listError.value = message;
        _log('Failed to validate list number: $e');
        _showErrorPopup(message, title: 'List Validation Failed');
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

  // ── IQA group (IQA1..IQAn shown together, n = resolved injector count) ──

  void onIqaFieldChanged(int subIndex) {
    _iqaIdleTimers[subIndex]?.cancel();
    _iqaIdleTimers[subIndex] =
        Timer(_idleDuration, () => submitIqaField(subIndex));
  }

  void submitIqaField(int subIndex) {
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

  /// Real call: GET models/get-models/ → walks
  /// results[].sub_models[].submodel_modelecu[] and, for every entry that
  /// has a non-null flash_file with files, records each file's name against
  /// that entry's DTC dataset id (datasets[0].id) and PID dataset id
  /// (pid_datasets[0].id). Populates the flash-file dropdown/list from this
  /// same walk. Reuses the cached models response from
  /// _resolveInjectorConfig() if the List step already fetched it.
  Future<void> _loadAvailableFlashFiles() async {
    flashFilesLoading.value = true;
    flashFilesError.value = '';
    try {
      final all_ds.AllModel models = await _ensureModels();

      final files = <String>[];
      _fileToDtcDatasetId.clear();
      _fileToPidDatasetId.clear();

      for (final result in models.results ?? <all_ds.Result>[]) {
        for (final subModel in result.subModels ?? <all_ds.SubModel>[]) {
          for (final sme
              in subModel.submodelModelecu ?? <all_ds.SubmodelModelecu>[]) {
            final flashFiles = sme.flashFile?.file ?? <all_ds.FileElement>[];
            if (flashFiles.isEmpty) continue; // flash_file can be null

            // TODO: confirm it's always safe to take the first entry —
            // datasets/pid_datasets are lists but every example seen so far
            // only ever has exactly one item.
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
        }
      }

      availableFlashFiles.assignAll(files);
      selectedFlashFile.value = null;
      _log('Loaded ${files.length} flash file(s)');
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

  Future<void> startFlashing() async {
    if (!allStepsComplete ||
        flashInProgress.value ||
        flashComplete.value ||
        selectedFlashFile.value == null) {
      return;
    }

    _log('Selected flash file: ${selectedFlashFile.value}');

    flashInProgress.value = true;
    flashProgress.value = 0;
    flashElapsedSeconds.value = 0;
    _log('Flashing started');

    _flashStopwatch = Timer.periodic(const Duration(seconds: 1), (_) {
      flashElapsedSeconds.value++;
    });

    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      flashProgress.value = i / 10;
    }

    _flashStopwatch?.cancel();
    flashInProgress.value = false;
    flashComplete.value = true;
    _log('Flashing completed successfully (${formattedElapsed})');

    // Two fully independent calls — a failure in one has no effect on the
    // other, and each writes only to its own RxList.
    await _loadDtcResults();
    await _loadPidResults();

    _showFlashCompletePopup();
  }

  /// Real call: GET datasets/get-dtc-datasets/?id={datasetId}, using the
  /// DTC dataset id resolved from the selected flash file via
  /// _fileToDtcDatasetId. Writes only to dtcList.
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

  /// Real call: GET datasets/get-pid-datasets?id={datasetId}, using the
  /// PID dataset id resolved from the selected flash file via
  /// _fileToPidDatasetId. Writes only to pidList.
  ///
  /// NOTE: this dataset only contains PID *definitions* (name, unit,
  /// min/max, resolution) — not a live reading. TODO: once a real-time PID
  /// read endpoint exists for the connected ECU, append the live value
  /// here instead of just the unit, e.g. '$name — $liveValue $unit'.
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
            // Uses an em dash (' — ') to match what _buildPidCard in the
            // view splits on. Using '(' ')' here would break that split.
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
    _flashStopwatch?.cancel();
    super.onClose();
  }
}