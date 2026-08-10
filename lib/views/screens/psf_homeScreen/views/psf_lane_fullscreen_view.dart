// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
// import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';

// class _StationColors {
//   static const teal = Color(0xFF0E6E6E);
//   static const tealLight = Color(0xFF1B9494);
//   static const tealBg = Color(0xFFE8F5F5);
//   static const charcoal = Color(0xFF1E2A32);
//   static const green = Color(0xFF2ECC71);
//   static const greenDark = Color(0xFF1B7A3E);
//   static const greenBg = Color(0xFFEAFAF1);
//   static const amber = Color(0xFFB9770E);
//   static const amberBg = Color(0xFFFEF6E7);
//   static const red = Color(0xFFD64545);
//   static const redBg = Color(0xFFFDEDED);
//   static const slate = Color(0xFF7C8698);
//   static const slateBorder = Color(0xFFDDE1E9);
//   static const slateBg = Color(0xFFF7F8FA);
// }

// class PsfLaneFullScreenView extends StatefulWidget {
//   const PsfLaneFullScreenView({
//     super.key,
//     required this.laneIndex,
//     required this.lane,
//     required this.controller,
//   });

//   final int laneIndex;
//   final PsfLane lane;
//   final PsfHomeScreenController controller;

//   @override
//   State<PsfLaneFullScreenView> createState() => _PsfLaneFullScreenViewState();
// }

// class _PsfLaneFullScreenViewState extends State<PsfLaneFullScreenView> {
//   late final TextEditingController _esnController;
//   late final FocusNode _esnFocusNode;
//   late final TextEditingController _listNumberController;
//   late final FocusNode _listNumberFocusNode;
//   late final List<TextEditingController> _iqaControllers;
//   late final List<FocusNode> _iqaFocusNodes;

//   int get laneIndex => widget.laneIndex;
//   PsfLane get lane => widget.lane;
//   PsfHomeScreenController get controller => widget.controller;

//   @override
//   void initState() {
//     super.initState();

//     _esnController = TextEditingController(text: lane.esnController.text);
//     _esnFocusNode = FocusNode();
//     _esnController.addListener(() {
//       if (lane.esnController.text != _esnController.text) {
//         lane.esnController.text = _esnController.text;
//         controller.onEsnFieldChanged(laneIndex);
//       }
//     });

//     _listNumberController = TextEditingController(text: lane.listNumberController.text);
//     _listNumberFocusNode = FocusNode();
//     _listNumberController.addListener(() {
//       if (lane.listNumberController.text != _listNumberController.text) {
//         lane.listNumberController.text = _listNumberController.text;
//         controller.onListNumberFieldChanged(laneIndex);
//       }
//     });

//     _iqaControllers = List.generate(
//       lane.iqaControllers.length,
//       (i) => TextEditingController(text: lane.iqaControllers[i].text),
//     );
//     _iqaFocusNodes = List.generate(lane.iqaControllers.length, (_) => FocusNode());
//     for (int i = 0; i < _iqaControllers.length; i++) {
//       _iqaControllers[i].addListener(() {
//         if (lane.iqaControllers[i].text != _iqaControllers[i].text) {
//           lane.iqaControllers[i].text = _iqaControllers[i].text;
//           controller.onIqaFieldChanged(laneIndex, i);
//         }
//       });
//     }
//     // Reset (and anything else that clears the lane's real
//     // controllers directly) needs to reflect back into these local
//     // ones too — the earlier listeners only sync local → lane.
//     lane.esnController.addListener(() {
//       if (_esnController.text != lane.esnController.text) {
//         _esnController.text = lane.esnController.text;
//       }
//     });

//     lane.listNumberController.addListener(() {
//       if (_listNumberController.text != lane.listNumberController.text) {
//         _listNumberController.text = lane.listNumberController.text;
//       }
//     });

//     for (int i = 0; i < _iqaControllers.length; i++) {
//       lane.iqaControllers[i].addListener(() {
//         if (_iqaControllers[i].text != lane.iqaControllers[i].text) {
//           _iqaControllers[i].text = lane.iqaControllers[i].text;
//         }
//       });
//     }
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       controller.onOpenLiveParameter(laneIndex);
//       controller.onOpenDtc(laneIndex);
//     });
//   }

//   @override
//   void dispose() {
//     _esnController.dispose();
//     _esnFocusNode.dispose();
//     _listNumberController.dispose();
//     _listNumberFocusNode.dispose();
//     for (final c in _iqaControllers) {
//       c.dispose();
//     }
//     for (final f in _iqaFocusNodes) {
//       f.dispose();
//     }
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: _StationColors.slateBg,
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           _topBar(),
//           Expanded(
//             child: Row(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 SizedBox(width: 320, child: _leftSidebar()),
//                 const VerticalDivider(width: 1, thickness: 1, color: _StationColors.slateBorder),
//                 Expanded(child: _mainArea()),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _topBar() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
//       child: Row(
//         children: [
//           IconButton(
//             icon: const Icon(Icons.arrow_back, color: _StationColors.teal),
//             onPressed: controller.collapseLane,
//             tooltip: 'Back to all lanes',
//           ),
//           const SizedBox(width: 4),
//           Obx(
//             () => Text(
//               'Lane ${lane.laneNumber} — ${lane.ecuModelName.value.isEmpty ? "ECU MODEL NAME" : lane.ecuModelName.value}',
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _StationColors.charcoal),
//             ),
//           ),
//           const Spacer(),
//           IconButton(
//             icon: const Icon(Icons.refresh, color: _StationColors.teal),
//             onPressed: () => controller.resetLane(laneIndex),
//             tooltip: 'Reset lane for next engine',
//           ),
//         ],
//       ),
//     );
//   }

//   // ── LEFT: ESN / List Number / IQA ──────────────────────────────

//   Widget _leftSidebar() {
//     return Container(
//       color: Colors.white,
//       padding: const EdgeInsets.all(20),
//       child: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _scanField(
//               label: 'ESN NUMBER',
//               textController: _esnController,
//               focusNode: _esnFocusNode,
//               isLoading: lane.isLookingUpEsn,
//               isResolved: lane.esn,
//               error: lane.esnError,
//               hint: 'e.g. 111111111111111',
//               onSubmit: () => controller.onScanEsnForLane(laneIndex),
//             ),
//             const SizedBox(height: 18),
//             Obx(() => lane.esn.value.isEmpty
//                 ? const SizedBox.shrink()
//                 : _scanField(
//                     label: 'LIST NUMBER',
//                     textController: _listNumberController,
//                     focusNode: _listNumberFocusNode,
//                     isLoading: lane.isLookingUpListNumber,
//                     isResolved: lane.listNumber,
//                     error: lane.listNumberError,
//                     hint: 'e.g. 3293',
//                     onSubmit: () => controller.onScanListNumberForLane(laneIndex),
//                   )),
//             const SizedBox(height: 22),
//             const Text('IQA NUMBERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _StationColors.slate, letterSpacing: 0.5)),
//             const SizedBox(height: 8),
//             Column(
//               children: List.generate(_iqaControllers.length, (i) {
//                 return Padding(
//                   padding: const EdgeInsets.only(bottom: 10),
//                   child: ValueListenableBuilder<TextEditingValue>(
//                     valueListenable: _iqaControllers[i],
//                     builder: (context, value, _) {
//                       final filled = value.text.trim().length == 7;
//                       return Row(
//                         children: [
//                           SizedBox(
//                             width: 90,
//                             child: Container(
//                               height: 36,
//                               alignment: Alignment.center,
//                               decoration: BoxDecoration(
//                                 color: filled ? _StationColors.greenBg : _StationColors.slateBg,
//                                 border: Border.all(color: filled ? _StationColors.green : _StationColors.slateBorder),
//                                 borderRadius: BorderRadius.circular(6),
//                               ),
//                               child: Row(
//                                 mainAxisAlignment: MainAxisAlignment.center,
//                                 children: [
//                                   if (filled) ...[
//                                     const Icon(Icons.check_circle, size: 12, color: _StationColors.greenDark),
//                                     const SizedBox(width: 4),
//                                   ],
//                                   Text(
//                                     'INJ ${i + 1}',
//                                     style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: filled ? _StationColors.greenDark : _StationColors.charcoal),
//                                   ),
//                                 ],
//                               ),
//                             ),
//                           ),
//                           const SizedBox(width: 10),
//                           Expanded(
//                             child: SizedBox(
//                               height: 36,
//                               child: TextField(
//                                 controller: _iqaControllers[i],
//                                 focusNode: _iqaFocusNodes[i],
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(fontSize: 12, color: filled ? _StationColors.greenDark : Colors.black87),
//                                 decoration: InputDecoration(
//                                   hintText: lane.iqaLabelFor(i),
//                                   isDense: true,
//                                   filled: true,
//                                   fillColor: filled ? _StationColors.greenBg : Colors.white,
//                                   contentPadding: const EdgeInsets.symmetric(vertical: 8),
//                                   border: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(6),
//                                     borderSide: BorderSide(color: filled ? _StationColors.green : _StationColors.slateBorder),
//                                   ),
//                                   enabledBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(6),
//                                     borderSide: BorderSide(color: filled ? _StationColors.green : _StationColors.slateBorder),
//                                   ),
//                                   focusedBorder: OutlineInputBorder(
//                                     borderRadius: BorderRadius.circular(6),
//                                     borderSide: const BorderSide(color: _StationColors.tealLight, width: 1.6),
//                                   ),
//                                 ),
//                                 onSubmitted: (_) {
//                                   if (i < _iqaFocusNodes.length - 1) {
//                                     _iqaFocusNodes[i + 1].requestFocus();
//                                   }
//                                 },
//                               ),
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 );
//               }),
//             ),
//             const SizedBox(height: 6),
//             Obx(
//               () => Text(
//                 'IQA STATUS  ${lane.filledIqaCount.value} / ${lane.iqaControllers.length} scanned',
//                 style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _StationColors.teal),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _scanField({
//     required String label,
//     required TextEditingController textController,
//     required FocusNode focusNode,
//     required RxBool isLoading,
//     required RxString isResolved,
//     required RxString error,
//     required String hint,
//     required VoidCallback onSubmit,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _StationColors.slate, letterSpacing: 0.5)),
//         const SizedBox(height: 6),
//         Obx(() {
//           final resolved = isResolved.value.isNotEmpty;
//           return Container(
//             height: 42,
//             decoration: BoxDecoration(
//               color: resolved ? _StationColors.greenBg : _StationColors.slateBg,
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: TextField(
//               controller: textController,
//               focusNode: focusNode,
//               enabled: !isLoading.value,
//               style: const TextStyle(fontSize: 13),
//               decoration: InputDecoration(
//                 hintText: hint,
//                 isDense: true,
//                 filled: false,
//                 contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                 suffixIcon: isLoading.value
//                     ? const Padding(
//                         padding: EdgeInsets.all(10),
//                         child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
//                       )
//                     : null,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: resolved ? _StationColors.green : _StationColors.slateBorder),
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: BorderSide(color: resolved ? _StationColors.green : _StationColors.slateBorder),
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(8),
//                   borderSide: const BorderSide(color: _StationColors.tealLight, width: 1.6),
//                 ),
//               ),
//               onSubmitted: (_) => onSubmit(),
//             ),
//           );
//         }),
//         Obx(() => error.value.isEmpty
//             ? const SizedBox.shrink()
//             : Padding(
//                 padding: const EdgeInsets.only(top: 4),
//                 child: Text(error.value, style: const TextStyle(fontSize: 11, color: _StationColors.red)),
//               )),
//       ],
//     );
//   }

//   // ── RIGHT: Flash File / Start Flash / Status / DTC / Live Parameter ──

//   Widget _mainArea() {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(24),
//       child: Obx(() {
//         if (!lane.iqaAllFilled.value) {
//           return Container(
//             padding: const EdgeInsets.all(40),
//             alignment: Alignment.center,
//             child: const Text(
//               'Complete ESN, List Number, and all IQA fields to continue.',
//               textAlign: TextAlign.center,
//               style: TextStyle(color: _StationColors.slate, fontSize: 14),
//             ),
//           );
//         }
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _flashFileCard(),
//             const SizedBox(height: 18),
//             _startFlashCard(),
//             const SizedBox(height: 18),
//             _statusPanel(),
//             const SizedBox(height: 24),
//             Row(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Expanded(child: _dtcPanel()),
//                 const SizedBox(width: 18),
//                 Expanded(child: _liveParameterPanel()),
//               ],
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _sectionCard({required String title, required Widget child}) {
//     return Container(
//       padding: const EdgeInsets.all(18),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: _StationColors.slateBorder),
//         boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 3))],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _StationColors.slate, letterSpacing: 0.5)),
//           const SizedBox(height: 10),
//           child,
//         ],
//       ),
//     );
//   }

//   Widget _flashFileCard() {
//     return _sectionCard(
//       title: 'FLASH FILE',
//       child: Obx(() {
//         if (lane.resolvedFlashFileName.value == null) {
//           return const Text('Scan a List Number to resolve the flash file.', style: TextStyle(color: _StationColors.slate, fontSize: 13));
//         }
//         return Row(
//           children: [
//             const Icon(Icons.check_circle, size: 18, color: _StationColors.green),
//             const SizedBox(width: 8),
//             Expanded(
//               child: Text(
//                 lane.resolvedFlashFileName.value!,
//                 style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _StationColors.greenDark),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _startFlashCard() {
//     return Obx(() {
//       final ready = lane.resolvedFlashFileUrl.value != null && lane.dongleConnected.value;
//       final canFlash = ready && !lane.isFlashing.value;
//       final label = lane.isFlashing.value
//           ? 'FLASHING…'
//           : (!lane.dongleConnected.value ? 'CONNECTING DONGLE…' : (lane.resolvedFlashFileUrl.value == null ? 'SCAN LIST NUMBER FIRST' : 'START FLASH'));

//       return SizedBox(
//         height: 52,
//         child: ElevatedButton(
//           onPressed: canFlash ? () => controller.onStartFlash(laneIndex) : null,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: ready || lane.isFlashing.value ? _StationColors.teal : _StationColors.slateBorder,
//             disabledBackgroundColor: _StationColors.slateBorder,
//             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
//           ),
//           child: lane.isFlashing.value
//               ? Row(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
//                     const SizedBox(width: 10),
//                     Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
//                   ],
//                 )
//               : Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: ready ? Colors.white : _StationColors.slate)),
//         ),
//       );
//     });
//   }

//   Widget _statusPanel() {
//     return Obx(() {
//       if (!lane.isFlashing.value && lane.flashProgress.value == 0 && lane.flashStatus.value.isEmpty) {
//         return const SizedBox.shrink();
//       }
//       final failed = lane.flashStatus.value.startsWith('Flash Failed');
//       final completed = lane.flashStatus.value == 'Flash Completed';
//       final accent = failed ? _StationColors.red : (completed ? _StationColors.greenDark : _StationColors.teal);
//       final bg = failed ? _StationColors.redBg : (completed ? _StationColors.greenBg : _StationColors.tealBg);

//       return Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(color: bg, border: Border.all(color: accent), borderRadius: BorderRadius.circular(12)),
//         child: Column(
//           children: [
//             if (lane.isFlashing.value || completed) ...[
//               Text(lane.formattedElapsed, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _StationColors.charcoal)),
//               const SizedBox(height: 4),
//               Text('${(lane.flashProgress.value * 100).round()}%', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
//               const SizedBox(height: 8),
//               ClipRRect(
//                 borderRadius: BorderRadius.circular(4),
//                 child: LinearProgressIndicator(
//                   value: lane.flashProgress.value.clamp(0.0, 1.0),
//                   minHeight: 8,
//                   backgroundColor: Colors.white,
//                   valueColor: AlwaysStoppedAnimation(accent),
//                 ),
//               ),
//               const SizedBox(height: 10),
//             ],
//             Text(lane.flashStatus.value, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: accent)),
//             if (completed && lane.iqaWriteStatus.value.isNotEmpty) ...[
//               const SizedBox(height: 6),
//               Text(
//                 lane.iqaWriteStatus.value,
//                 style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: lane.iqaWriteStatus.value.toLowerCase().contains('successful') ? _StationColors.greenDark : _StationColors.red),
//               ),
//             ],
//           ],
//         ),
//       );
//     });
//   }

//   Widget _dtcPanel() {
//     return _sectionCard(
//       title: 'DTC',
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Obx(() {
//             if (lane.isReadingDtc.value) {
//               return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
//             }
//             if (lane.dtcReadResults.isEmpty) {
//               return const Text('No DTCs read yet.', style: TextStyle(color: _StationColors.slate, fontSize: 13));
//             }
//             return Column(children: lane.dtcReadResults.map(_dtcTile).toList());
//           }),
//           const SizedBox(height: 10),
//           OutlinedButton(
//             onPressed: () => controller.readLiveDtcForLane(laneIndex),
//             style: OutlinedButton.styleFrom(side: const BorderSide(color: _StationColors.teal)),
//             child: const Text('Read DTCs', style: TextStyle(color: _StationColors.teal, fontWeight: FontWeight.bold)),
//           ),
//         ],
//       ),
//     );
//   }

//   // raw = "CODE - description (status)" — same parsing as the DTC
//   // dialog, so both views show identical, consistent formatting.
//   Widget _dtcTile(String raw) {
//     final splitIndex = raw.indexOf(' - ');
//     final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
//     var rest = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

//     String? statusLabel;
//     final statusMatch = RegExp(r'\(([^()]+)\)\s*$').firstMatch(rest);
//     if (statusMatch != null) {
//       statusLabel = statusMatch.group(1);
//       rest = rest.substring(0, statusMatch.start).trim();
//     }

//     final statusLower = (statusLabel ?? '').toLowerCase();
//     Color badgeColor;
//     String badgeLabel;
//     if (statusLower == 'active' || statusLower == 'current') {
//       badgeColor = _StationColors.red;
//       badgeLabel = 'Active';
//     } else if (statusLower == 'pending') {
//       badgeColor = _StationColors.amber;
//       badgeLabel = 'Pending';
//     } else if (statusLower == 'inactive') {
//       badgeColor = _StationColors.greenDark;
//       badgeLabel = 'InActive';
//     } else {
//       badgeColor = _StationColors.greenDark;
//       badgeLabel = statusLower.isNotEmpty ? 'History' : '-';
//     }

//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//       decoration: BoxDecoration(
//         color: _StationColors.redBg.withOpacity(0.5),
//         border: Border.all(color: _StationColors.red.withOpacity(0.35)),
//         borderRadius: BorderRadius.circular(8),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: _StationColors.red)),
//                 if (rest.isNotEmpty) ...[
//                   const SizedBox(height: 2),
//                   Text(rest, style: const TextStyle(fontSize: 12, color: Colors.black87)),
//                 ],
//               ],
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//             decoration: BoxDecoration(
//               color: badgeColor.withOpacity(0.12),
//               border: Border.all(color: badgeColor.withOpacity(0.5)),
//               borderRadius: BorderRadius.circular(6),
//             ),
//             child: Text(badgeLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: badgeColor)),
//           ),
//         ],
//       ),
//     );
//   }

//  Widget _liveParameterPanel() {
//     return _sectionCard(
//       title: 'LIVE PARAMETER',
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Obx(() {
//             if (lane.isLoadingPid.value) {
//               return const Padding(padding: EdgeInsets.all(12), child: Center(child: CircularProgressIndicator()));
//             }
//             if (lane.liveParameterCodes.isEmpty) {
//               return const Text('No parameters loaded yet.', style: TextStyle(color: _StationColors.slate, fontSize: 13));
//             }
//             return Column(
//               children: lane.liveParameterCodes.map((code) {
//                 final variable = code.piCodeVariable?.firstOrNull;
//                 final label = variable?.longName ?? variable?.shortName ?? code.shortName ?? code.code ?? '-';
//                 final unit = variable?.unit ?? '';
//                 return Obx(() {
//                   final liveValue = variable?.id != null ? lane.livePidValues[variable!.id] : null;
//                   final isError = liveValue != null && (liveValue == 'Not Found' || liveValue.toUpperCase().contains('ERROR'));
//                   final hasValue = liveValue != null;
//                   return Container(
//                     margin: const EdgeInsets.only(bottom: 8),
//                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: _StationColors.slateBg,
//                       border: Border.all(color: _StationColors.slateBorder),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Row(
//                       children: [
//                         Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: Colors.black87), overflow: TextOverflow.ellipsis)),
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: isError ? _StationColors.redBg : (hasValue ? _StationColors.greenBg : Colors.white),
//                             border: Border.all(color: isError ? _StationColors.red : (hasValue ? _StationColors.green : _StationColors.slateBorder)),
//                             borderRadius: BorderRadius.circular(6),
//                           ),
//                           child: Text(
//                             liveValue != null ? '$liveValue${unit.isNotEmpty ? ' $unit' : ''}' : '--',
//                             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isError ? _StationColors.red : (hasValue ? _StationColors.greenDark : _StationColors.slate)),
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 });
//               }).toList(),
//             );
//           }),
//           const SizedBox(height: 10),
//           Obx(() => OutlinedButton(
//                 onPressed: () => controller.togglePidPlaybackForLane(laneIndex),
//                 style: OutlinedButton.styleFrom(side: BorderSide(color: lane.pidPlaying.value ? _StationColors.red : _StationColors.teal)),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     if (lane.pidPlaying.value) const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2)),
//                     if (lane.pidPlaying.value) const SizedBox(width: 8),
//                     Text(
//                       lane.pidPlaying.value ? 'Reading...' : 'Run',
//                       style: TextStyle(color: lane.pidPlaying.value ? _StationColors.red : _StationColors.teal, fontWeight: FontWeight.bold),
//                     ),
//                   ],
//                 ),
//               )),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';
import 'package:simpson/views/screens/psf_homeScreen/views/activity_log_tag.dart';
import 'package:simpson/views/screens/psf_homeScreen/views/psf_session_history_screen.dart';

class _StationColors {
  static const teal = Color(0xFF0E6E6E);
  static const tealLight = Color(0xFF1B9494);
  static const tealBg = Color(0xFFE8F5F5);
  static const charcoal = Color(0xFF1E2A32);
  static const green = Color(0xFF2ECC71);
  static const greenDark = Color(0xFF1B7A3E);
  static const greenBg = Color(0xFFEAFAF1);
  static const amber = Color(0xFFB9770E);
  static const amberBg = Color(0xFFFEF6E7);
  static const red = Color(0xFFD64545);
  static const redBg = Color(0xFFFDEDED);
  static const slate = Color(0xFF7C8698);
  static const slateBorder = Color(0xFFDDE1E9);
  static const slateBg = Color(0xFFF7F8FA);
}

/// One lane's full detail view. Binds DIRECTLY to the lane's own
/// TextEditingControllers/FocusNodes/RxValues — NEVER local copies.
/// Local controllers seeded once in initState() only reflect
/// whichever lane was first shown, and Flutter reuses the same State
/// object when switching lanes unless given a distinct key — that
/// combination is exactly what caused every lane to show the same
/// ESN/IQA data. Direct binding has nothing to go stale.
///
/// IMPORTANT: wherever this widget is constructed (in
/// psf_home_screen_view.dart), it must be given
/// key: ValueKey(laneIndex) so switching lanes creates a genuinely
/// fresh widget instance.
class PsfLaneFullScreenView extends StatefulWidget {
  const PsfLaneFullScreenView({
    super.key,
    required this.laneIndex,
    required this.lane,
    required this.controller,
  });

  final int laneIndex;
  final PsfLane lane;
  final PsfHomeScreenController controller;

  @override
  State<PsfLaneFullScreenView> createState() => _PsfLaneFullScreenViewState();
}

class _PsfLaneFullScreenViewState extends State<PsfLaneFullScreenView> {
  bool _flashExpanded = true;
  bool _dtcExpanded = false;
  bool _pidExpanded = false;
  String? _activityFilter;
  int get laneIndex => widget.laneIndex;
  PsfLane get lane => widget.lane;
  PsfHomeScreenController get controller => widget.controller;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.onOpenLiveParameter(laneIndex);
      controller.onOpenDtc(laneIndex);
    });

    // Show a popup the instant THIS lane's flash succeeds, then
    // transition it into "processing" while IQA/DTC load, and close
    // it automatically once that's done. Reads lane.isPostFlashProcessing
    // (owned by the controller) — never a local field, since a local
    // one would never actually reflect real progress.
    ever(lane.flashStatus, (String status) {
      if (status == 'Flash Completed') {
        _showFlashSuccessPopup();
      }
    });
  }

  void _showFlashSuccessPopup() {
    Get.dialog(
      Obx(() => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: _StationColors.greenDark),
                SizedBox(width: 10),
                Text('Flashing Successful'),
              ],
            ),
            content: lane.isPostFlashProcessing.value
                ? const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _StationColors.teal)),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              'Reading DTC and writing IQA — please wait…')),
                    ],
                  )
                : const Text('DTC read and IQA write complete.'),
            actions: lane.isPostFlashProcessing.value
                ? []
                : [
                    TextButton(
                      onPressed: () => Get.back(),
                      child: const Text('OK'),
                    ),
                  ],
          )),
      barrierDismissible: false,
    );

    ever(lane.isPostFlashProcessing, (bool processing) {
      if (!processing && Get.isDialogOpen == true) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Get.isDialogOpen == true) Get.back();
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _StationColors.slateBg,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(width: 320, child: _leftSidebar(context)),
          const VerticalDivider(
              width: 1, thickness: 1, color: _StationColors.slateBorder),
          Expanded(child: _mainArea(context)),
        ],
      ),
    );
  }

  // adjust path

  Map<String, String> _parseLogEntry(String raw) {
    final match =
        RegExp(r'^\[(\d{2}:\d{2}:\d{2})\]\s*\[(\w+)\]\s*(.*)$').firstMatch(raw);
    if (match != null) {
      return {
        'time': match.group(1)!,
        'tag': match.group(2)!,
        'message': match.group(3)!
      };
    }
    final legacy = RegExp(r'^\[(\d{2}:\d{2}:\d{2})\]\s*(.*)$').firstMatch(raw);
    if (legacy != null) {
      return {
        'time': legacy.group(1)!,
        'tag': 'GENERAL',
        'message': legacy.group(2)!
      };
    }
    return {'time': '', 'tag': 'GENERAL', 'message': raw};
  }

  Widget _tagChip(String tag, {VoidCallback? onTap, bool selected = false}) {
    final color = Color(ActivityLogTag.colorValue(tag));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // ── LEFT: ESN / IQA — bound directly to lane's real controllers,
  // border-only design (no background tint), consistent alignment ──

  Widget _leftSidebar(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Obx(
                    () => Text(
                      lane.ecuModelName.value.isEmpty
                          ? "ECU MODEL NAME"
                          : lane.ecuModelName.value,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _StationColors.charcoal),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                      color: _StationColors.tealBg, shape: BoxShape.circle),
                  child: IconButton(
                    icon: const Icon(Icons.refresh,
                        color: _StationColors.teal, size: 18),
                    onPressed: () => controller.resetLane(laneIndex),
                    tooltip: 'Reset lane for next engine',
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.all(6),
                    constraints: const BoxConstraints(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            // _scanField(
            //   context: context,
            //   label: 'ESN NUMBER',
            //   textController: lane.esnController,
            //   focusNode: lane.esnFocusNode,
            //   isLoading: lane.isLookingUpEsn,
            //   isResolved: lane.esn,
            //   error: lane.esnError,
            //   hint: 'e.g. 111111111111111',
            //   onChanged: () => controller.onEsnFieldChanged(laneIndex),
            //   onSubmit: () => controller.onScanEsnForLane(laneIndex),
            // ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _scanField(
                    context: context,
                    label: 'ESN NUMBER',
                    textController: lane.esnController,
                    focusNode: lane.esnFocusNode,
                    isLoading: lane.isLookingUpEsn,
                    isResolved: lane.esn,
                    error: lane.esnError,
                    hint: 'e.g. 111111111111111',
                    onChanged: () => controller.onEsnFieldChanged(laneIndex),
                    onSubmit: () => controller.onScanEsnForLane(laneIndex),
                  ),
                ),
                Obx(() {
                  if (lane.esn.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    // Nudge down so it lines up with the input box, not the label above it.
                    padding: const EdgeInsets.only(left: 8, top: 22),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: () =>
                          Get.to(() => PsfSessionHistoryScreen(lane: lane)),
                      child: Container(
                        height: 44,
                        width: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: _StationColors.tealBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _StationColors.teal.withOpacity(0.3)),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: _StationColors.teal,
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
            const SizedBox(height: 22),
            const Text('IQA NUMBERS',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: _StationColors.slate,
                    letterSpacing: 0.5)),
            const SizedBox(height: 10),
            Column(
              children: List.generate(lane.iqaControllers.length, (i) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: lane.iqaControllers[i],
                    builder: (context, value, _) {
                      final filled = value.text.trim().length == 7;
                      final borderColor = filled
                          ? _StationColors.green
                          : _StationColors.slateBorder;
                      return Row(
                        children: [
                          SizedBox(
                            width: 88,
                            height: 44,
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: borderColor,
                                    width: filled ? 1.6 : 1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (filled) ...[
                                    const Icon(Icons.check_circle,
                                        size: 13,
                                        color: _StationColors.greenDark),
                                    const SizedBox(width: 5),
                                  ],
                                  Text(
                                    'INJ ${i + 1}',
                                    style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: filled
                                            ? _StationColors.greenDark
                                            : _StationColors.charcoal),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: 44,
                              child: Focus(
                                onKeyEvent: (node, event) {
                                  if (event is KeyDownEvent &&
                                      (event.logicalKey ==
                                              LogicalKeyboardKey.tab ||
                                          event.logicalKey ==
                                              LogicalKeyboardKey.enter)) {
                                    if (i < lane.iqaFocusNodes.length - 1) {
                                      lane.iqaFocusNodes[i + 1].requestFocus();
                                    }
                                    return KeyEventResult.handled;
                                  }
                                  return KeyEventResult.ignored;
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: borderColor,
                                        width: filled ? 1.6 : 1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Theme(
                                    data: Theme.of(context).copyWith(
                                      textSelectionTheme:
                                          TextSelectionThemeData(
                                        selectionColor:
                                            Colors.grey.withOpacity(0.4),
                                        selectionHandleColor:
                                            _StationColors.teal,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: lane.iqaControllers[i],
                                      focusNode: lane.iqaFocusNodes[i],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: filled
                                              ? _StationColors.greenDark
                                              : Colors.black87),
                                      decoration: InputDecoration(
                                        hintText: lane.iqaLabelFor(i),
                                        hintStyle: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.normal),
                                        isDense: true,
                                        filled: false,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                vertical: 12),
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                      ),
                                      onChanged: (_) => controller
                                          .onIqaFieldChanged(laneIndex, i),
                                      onSubmitted: (_) {
                                        if (i < lane.iqaFocusNodes.length - 1) {
                                          lane.iqaFocusNodes[i + 1]
                                              .requestFocus();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Obx(
              () => Text(
                'IQA STATUS  ${lane.filledIqaCount.value} / ${lane.iqaControllers.length} scanned',
                style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                    color: _StationColors.teal),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _scanField({
    required BuildContext context,
    required String label,
    required TextEditingController textController,
    required FocusNode focusNode,
    required RxBool isLoading,
    required RxString isResolved,
    required RxString error,
    required String hint,
    required VoidCallback onChanged,
    required VoidCallback onSubmit,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: _StationColors.slate,
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        Obx(() {
          final resolved = isResolved.value.isNotEmpty;
          return Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: resolved
                      ? _StationColors.green
                      : _StationColors.slateBorder,
                  width: resolved ? 1.6 : 1),
            ),
            child: Focus(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent &&
                    (event.logicalKey == LogicalKeyboardKey.tab ||
                        event.logicalKey == LogicalKeyboardKey.enter)) {
                  onSubmit();
                  return KeyEventResult.handled;
                }
                return KeyEventResult.ignored;
              },
              child: Theme(
                data: Theme.of(context).copyWith(
                  textSelectionTheme: TextSelectionThemeData(
                    selectionColor: Colors.grey.withOpacity(0.4),
                    selectionHandleColor: _StationColors.teal,
                  ),
                ),
                child: TextField(
                  controller: textController,
                  focusNode: focusNode,
                  enabled: !isLoading.value,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    suffixIcon: isLoading.value
                        ? const Padding(
                            padding: EdgeInsets.all(10),
                            child: SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2)),
                          )
                        : null,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                  onChanged: (_) => onChanged(),
                  onSubmitted: (_) => onSubmit(),
                ),
              ),
            ),
          );
        }),
        Obx(() => error.value.isEmpty
            ? const SizedBox.shrink()
            : Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(error.value,
                    style: const TextStyle(
                        fontSize: 11, color: _StationColors.red)),
              )),
      ],
    );
  }

  // ── RIGHT: Flash File / DTC / PID / Activity Log ────────────────

  Widget _mainArea(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Obx(() {
              if (!lane.iqaAllFilled.value) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: const BoxDecoration(
                              color: _StationColors.tealBg,
                              shape: BoxShape.circle),
                          child: const Icon(Icons.checklist_rtl_rounded,
                              color: _StationColors.teal, size: 34),
                        ),
                        const SizedBox(height: 20),
                        const Text('Waiting for scan',
                            style: TextStyle(
                                color: _StationColors.charcoal,
                                fontSize: 16,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        const Text(
                          'Complete ESN and all\nIQA fields to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: _StationColors.slate, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _flashSection(),
                  const SizedBox(height: 14),
                  _dtcSection(),
                  const SizedBox(height: 14),
                  _pidSection(),
                ],
              );
            }),
          ),
        ),
        _activityLogSection(),
      ],
    );
  }

  Widget _expandableCard({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    Widget? trailing,
    Widget? extraAction,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _StationColors.slateBorder),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: _StationColors.charcoal)),
                  const Spacer(),
                  if (trailing != null) ...[
                    trailing,
                    const SizedBox(width: 10)
                  ],
                  if (extraAction != null) ...[
                    extraAction,
                    const SizedBox(width: 6)
                  ],
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: _StationColors.slate),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: child,
            ),
        ],
      ),
    );
  }

  // ── FLASH SECTION ──────────────────────────────────────────────

  Widget _flashSection() {
    return Obx(() {
      final completed = lane.flashStatus.value == 'Flash Completed';
      final failed = lane.flashStatus.value.startsWith('Flash Failed');

      Widget? trailing;
      if (completed) {
        trailing = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: const BoxDecoration(
                  color: _StationColors.greenDark, shape: BoxShape.circle),
              child: const Icon(Icons.check, color: Colors.white, size: 13),
            ),
            const SizedBox(width: 6),
            const Text('Successful',
                style: TextStyle(
                    fontSize: 11.5,
                    color: _StationColors.greenDark,
                    fontWeight: FontWeight.bold)),
          ],
        );
      } else if (lane.isFlashing.value) {
        trailing = Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: _StationColors.tealBg,
              borderRadius: BorderRadius.circular(12)),
          child: Text('${(lane.flashProgress.value * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontSize: 11.5,
                  color: _StationColors.teal,
                  fontWeight: FontWeight.bold)),
        );
      } else if (failed) {
        trailing = const Text('Failed',
            style: TextStyle(
                fontSize: 11.5,
                color: _StationColors.red,
                fontWeight: FontWeight.bold));
      }

      return _expandableCard(
        title: 'FLASH FILE',
        expanded: _flashExpanded,
        onTap: () => setState(() => _flashExpanded = !_flashExpanded),
        trailing: trailing,
        child: _flashBody(),
      );
    });
  }

  Widget _flashBody() {
    return Obx(() {
      final failed = lane.flashStatus.value.startsWith('Flash Failed');
      final completed = lane.flashStatus.value == 'Flash Completed';

      if (failed) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: _StationColors.redBg, shape: BoxShape.circle),
                child: const Icon(Icons.close_rounded,
                    color: _StationColors.red, size: 28),
              ),
              const SizedBox(height: 14),
              const Text('Flashing Failed',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _StationColors.red)),
              const SizedBox(height: 6),
              Text(lane.flashStatus.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, color: _StationColors.slate)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: lane.dongleConnected.value
                    ? () => controller.onStartFlash(laneIndex)
                    : null,
                style: ElevatedButton.styleFrom(
                    backgroundColor: _StationColors.teal,
                    disabledBackgroundColor: _StationColors.slateBorder,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8))),
                child: const Text('Start Flashing',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ],
          ),
        );
      }

      if (completed && !lane.isFlashing.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => lane.isPostFlashProcessing.value
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: _StationColors.teal)),
                          SizedBox(height: 8),
                          Text('Reading DTC/IQA — please wait…',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _StationColors.teal)),
                        ],
                      ),
                    )
                  : const SizedBox.shrink()),
              if (lane.resolvedFlashFileName.value != null)
                Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Text(lane.resolvedFlashFileName.value!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11.5, color: _StationColors.slate))),
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: _StationColors.teal, shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 28),
              ),
              const SizedBox(height: 14),
              const Text('Flashing successful',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _StationColors.charcoal)),
              const SizedBox(height: 4),
              Text('Completed in ${lane.formattedElapsed}',
                  style: const TextStyle(
                      fontSize: 12, color: _StationColors.slate)),
              if (lane.iqaWriteStatus.value.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(lane.iqaWriteStatus.value,
                    style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: lane.iqaWriteStatus.value
                                .toLowerCase()
                                .contains('successful')
                            ? _StationColors.greenDark
                            : _StationColors.red)),
              ],
            ],
          ),
        );
      }

      if (lane.isFlashing.value) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (lane.resolvedFlashFileName.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(lane.resolvedFlashFileName.value!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 11.5, color: _StationColors.slate)),
              ),
            Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                    color: _StationColors.tealBg, shape: BoxShape.circle),
                child: const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation(_StationColors.teal))),
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                  color: _StationColors.tealBg,
                  borderRadius: BorderRadius.circular(8)),
              child: Text(lane.flashStatus.value,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _StationColors.teal)),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Elapsed  ${lane.formattedElapsed}',
                    style: const TextStyle(
                        fontSize: 12, color: _StationColors.slate)),
                Text('${(lane.flashProgress.value * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _StationColors.teal)),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                  value: lane.flashProgress.value.clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: _StationColors.slateBg,
                  valueColor:
                      const AlwaysStoppedAnimation(_StationColors.teal)),
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (lane.resolvedFlashFileName.value != null)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                  color: _StationColors.greenBg,
                  border: Border.all(color: _StationColors.green),
                  borderRadius: BorderRadius.circular(6)),
              child: Row(children: [
                const Icon(Icons.check_circle,
                    size: 15, color: _StationColors.green),
                const SizedBox(width: 6),
                Expanded(
                    child: Text(lane.resolvedFlashFileName.value!,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _StationColors.greenDark),
                        overflow: TextOverflow.ellipsis)),
              ]),
            ),
          if (!lane.dongleConnected.value)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                  color: _StationColors.amberBg,
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: _StationColors.amber.withOpacity(0.4))),
              child: Row(children: [
                const Icon(Icons.info_outline,
                    size: 16, color: _StationColors.amber),
                const SizedBox(width: 8),
                const Expanded(
                    child: Text('Waiting for the dongle to connect…',
                        style: TextStyle(
                            fontSize: 12, color: _StationColors.amber))),
              ]),
            ),
          Center(
            child: ElevatedButton(
              onPressed: (lane.resolvedFlashFileUrl.value != null &&
                      lane.dongleConnected.value)
                  ? () => controller.onStartFlash(laneIndex)
                  : null,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _StationColors.teal,
                  disabledBackgroundColor: _StationColors.slateBorder,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8))),
              child: const Text('Start Flashing',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ),
        ],
      );
    });
  }

  // ── DTC SECTION ────────────────────────────────────────────────

  Widget _dtcSection() {
    return Obx(() => _expandableCard(
          title: 'DTC',
          expanded: _dtcExpanded,
          onTap: () => setState(() => _dtcExpanded = !_dtcExpanded),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
                color: _StationColors.tealBg,
                borderRadius: BorderRadius.circular(12)),
            child: Text('Count: ${lane.dtcReadResults.length}',
                style: const TextStyle(
                    fontSize: 11.5, color: _StationColors.teal)),
          ),
          extraAction: Obx(() {
            final busy = lane.isReadingDtc.value;
            final canRead = lane.dongleConnected.value && !busy;
            final canClear = canRead && lane.dtcReadResults.isNotEmpty;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: canRead
                      ? () => controller.readLiveDtcForLane(laneIndex)
                      : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: canRead
                                ? _StationColors.teal
                                : _StationColors.slateBorder)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      if (busy)
                        const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 1.6))
                      else
                        Icon(Icons.search,
                            size: 14,
                            color: canRead
                                ? _StationColors.teal
                                : _StationColors.slate),
                      const SizedBox(width: 5),
                      Text(busy ? 'Reading…' : 'Read DTCs',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: canRead
                                  ? _StationColors.teal
                                  : _StationColors.slate)),
                    ]),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: canClear ? () => _confirmClearDtc() : null,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: canClear
                                ? _StationColors.red
                                : _StationColors.slateBorder)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.delete_sweep_rounded,
                          size: 14,
                          color: canClear
                              ? _StationColors.red
                              : _StationColors.slate),
                      const SizedBox(width: 5),
                      Text('Clear DTC',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: canClear
                                  ? _StationColors.red
                                  : _StationColors.slate)),
                    ]),
                  ),
                ),
              ],
            );
          }),
          child: Obx(() => lane.dtcReadResults.isEmpty
              ? const Text('No data yet',
                  style: TextStyle(color: _StationColors.slate, fontSize: 13))
              : Column(children: lane.dtcReadResults.map(_dtcTile).toList())),
        ));
  }

  void _confirmClearDtc() {
    Get.defaultDialog(
      title: 'Clear DTC?',
      middleText:
          'This will clear all fault codes stored on Lane ${lane.laneNumber}\'s ECU.',
      textConfirm: 'Clear',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: _StationColors.red,
      onConfirm: () {
        Get.back();
        controller.clearDtcForLane(laneIndex);
      },
    );
  }

  Widget _dtcTile(String raw) {
    final splitIndex = raw.indexOf(' - ');
    final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
    var rest = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

    String? statusLabel;
    final statusMatch = RegExp(r'\(([^()]+)\)\s*$').firstMatch(rest);
    if (statusMatch != null) {
      statusLabel = statusMatch.group(1);
      rest = rest.substring(0, statusMatch.start).trim();
    }

    final statusLower = (statusLabel ?? '').toLowerCase();
    Color badgeColor;
    String badgeLabel;
    if (statusLower == 'active' || statusLower == 'current') {
      badgeColor = _StationColors.red;
      badgeLabel = 'Active';
    } else if (statusLower == 'pending') {
      badgeColor = _StationColors.amber;
      badgeLabel = 'Pending';
    } else if (statusLower == 'inactive') {
      badgeColor = _StationColors.greenDark;
      badgeLabel = 'InActive';
    } else {
      badgeColor = _StationColors.greenDark;
      badgeLabel = statusLower.isNotEmpty ? 'History' : '-';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
          border: Border.all(color: _StationColors.slateBorder),
          borderRadius: BorderRadius.circular(6)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.5,
                        color: Colors.black87)),
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(rest,
                      style: const TextStyle(
                          fontSize: 11.5, color: _StationColors.slate))
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: badgeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: badgeColor.withOpacity(0.4))),
            child: Text(badgeLabel,
                style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: badgeColor)),
          ),
        ],
      ),
    );
  }

  // ── PID / LIVE PARAMETER SECTION ────────────────────────────────

  Widget _pidSection() {
    return _expandableCard(
      title: 'PID',
      expanded: _pidExpanded,
      onTap: () => setState(() => _pidExpanded = !_pidExpanded),
      trailing: Obx(() {
        final playing = lane.pidPlaying.value;
        return ElevatedButton.icon(
          onPressed: () => controller.togglePidPlaybackForLane(laneIndex),
          icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
              size: 16),
          label: Text(playing ? 'Stop' : 'Run',
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          style: ElevatedButton.styleFrom(
            backgroundColor: playing ? _StationColors.red : _StationColors.teal,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }),
      child: Obx(() {
        if (lane.liveParameterCodes.isEmpty) {
          return const Text('No data yet',
              style: TextStyle(color: _StationColors.slate, fontSize: 13));
        }
        final isPlaying = lane.pidPlaying.value;
        final list = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(lane.liveParameterCodes.length, (index) {
            final code = lane.liveParameterCodes[index];
            final variable = code.piCodeVariable?.firstOrNull;
            final label = variable?.longName ??
                variable?.shortName ??
                code.shortName ??
                code.code ??
                'PID';
            final unit = variable?.unit ?? '';
            return Obx(() {
              final liveValue = variable?.id != null
                  ? lane.livePidValues[variable!.id]
                  : null;
              final isError = liveValue != null &&
                  (liveValue == 'Not Found' ||
                      liveValue.toUpperCase().contains('ERROR'));
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Expanded(
                          child: Text(label,
                              style: const TextStyle(
                                  fontSize: 13, color: _StationColors.charcoal),
                              overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 12),
                      Text(
                        liveValue != null
                            ? '$liveValue ${unit.isNotEmpty ? unit : ''}'.trim()
                            : '—',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: liveValue == null
                                ? _StationColors.slate
                                : (isError
                                    ? _StationColors.red
                                    : _StationColors.teal)),
                      ),
                    ]),
                  ),
                  if (index != lane.liveParameterCodes.length - 1)
                    Divider(
                        height: 1,
                        thickness: 1,
                        color: _StationColors.slateBorder.withOpacity(0.6)),
                ],
              );
            });
          }),
        );

        return Stack(
          alignment: Alignment.topCenter,
          children: [
            Opacity(
                opacity: isPlaying ? 0.35 : 1.0,
                child: IgnorePointer(ignoring: isPlaying, child: list)),
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4))
                      ]),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor:
                            AlwaysStoppedAnimation(_StationColors.teal)),
                    const SizedBox(height: 10),
                    Text('Reading live parameters...',
                        style: TextStyle(
                            fontSize: 12,
                            color: _StationColors.slate.withOpacity(0.9),
                            fontWeight: FontWeight.w600)),
                  ]),
                ),
              ),
          ],
        );
      }),
    );
  }

  // ── ACTIVITY LOG ─────────────────────────────────────────────

  Color _activityLogColor(String entry) {
    final lower = entry.toLowerCase();
    if (entry.contains('❌') ||
        lower.contains('fail') ||
        lower.contains('error')) return _StationColors.red;
    if (entry.contains('✅') ||
        lower.contains('successful') ||
        lower.contains('pass') ||
        lower.contains('complete')) return _StationColors.greenDark;
    return _StationColors.slate;
  }

  // Widget _activityLogSection() {
  //   return Container(
  //     constraints: const BoxConstraints(maxHeight: 160),
  //     margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
  //     padding: const EdgeInsets.all(14),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: _StationColors.slateBorder),
  //       boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, -2))],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const Text('Activity', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _StationColors.charcoal)),
  //             const Spacer(),
  //             IconButton(icon: const Icon(Icons.fullscreen, size: 20), color: _StationColors.teal, visualDensity: VisualDensity.compact, onPressed: _showActivityFullScreen),
  //           ],
  //         ),
  //         const Divider(height: 14),
  //         Expanded(
  //           child: Obx(() => ListView(
  //                 padding: EdgeInsets.zero,
  //                 children: lane.activityLog.map((e) => Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(e, style: TextStyle(fontSize: 11.5, color: _activityLogColor(e))))).toList(),
  //               )),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _activityLogSection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _StationColors.slateBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, -2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Activity',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: _StationColors.charcoal)),
              const Spacer(),
              IconButton(
                  icon: const Icon(Icons.fullscreen, size: 20),
                  color: _StationColors.teal,
                  visualDensity: VisualDensity.compact,
                  onPressed: _showActivityFullScreen),
            ],
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 24,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: ActivityLogTag.allTags.length,
              separatorBuilder: (_, __) => const SizedBox(width: 6),
              itemBuilder: (context, i) {
                final tag = ActivityLogTag.allTags[i];
                return _tagChip(
                  tag,
                  selected: _activityFilter == tag,
                  onTap: () => setState(() =>
                      _activityFilter = _activityFilter == tag ? null : tag),
                );
              },
            ),
          ),
          const Divider(height: 14),
          Expanded(
            child: Obx(() {
              final entries = lane.activityLog.where((e) {
                if (_activityFilter == null) return true;
                return _parseLogEntry(e)['tag'] == _activityFilter;
              }).toList();

              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    _activityFilter == null
                        ? 'No activity yet'
                        : 'No "$_activityFilter" entries yet',
                    style: const TextStyle(
                        color: _StationColors.slate, fontSize: 11.5),
                  ),
                );
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: entries.map((e) {
                  final parsed = _parseLogEntry(e);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tagChip(parsed['tag']!),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '[${parsed['time']}] ${parsed['message']}',
                            style: TextStyle(
                                fontSize: 11.5, color: _activityLogColor(e)),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  // void _showActivityFullScreen() {
  //   Get.dialog(
  //     Dialog.fullscreen(
  //       child: Scaffold(
  //         appBar: AppBar(
  //           iconTheme: const IconThemeData(color: Colors.white),
  //           backgroundColor: _StationColors.teal,
  //           foregroundColor: Colors.white,
  //           title: Text('Activity Log — Lane ${lane.laneNumber}'),
  //         ),
  //         backgroundColor: _StationColors.slateBg,
  //         body: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Obx(() => lane.activityLog.isEmpty
  //               ? const Center(
  //                   child: Text('No activity yet',
  //                       style: TextStyle(color: _StationColors.slate)))
  //               : ListView.builder(
  //                   itemCount: lane.activityLog.length,
  //                   itemBuilder: (context, i) => Padding(
  //                     padding: const EdgeInsets.symmetric(vertical: 5),
  //                     child: SelectableText(lane.activityLog[i],
  //                         style: TextStyle(
  //                             fontSize: 13,
  //                             color: _activityLogColor(lane.activityLog[i]))),
  //                   ),
  //                 )),
  //         ),
  //       ),
  //     ),
  //     barrierDismissible: true,
  //   );
  // }

  void _showActivityFullScreen() {
    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: _StationColors.teal,
            foregroundColor: Colors.white,
            title: Text('Activity Log — Lane ${lane.laneNumber}'),
          ),
          backgroundColor: _StationColors.slateBg,
          body: StatefulBuilder(
            builder: (context, setDialogState) {
              return SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: SizedBox(
                        height: 30,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: ActivityLogTag.allTags.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 6),
                          itemBuilder: (context, i) {
                            final tag = ActivityLogTag.allTags[i];
                            return _tagChip(
                              tag,
                              selected: _activityFilter == tag,
                              onTap: () => setDialogState(() =>
                                  _activityFilter =
                                      _activityFilter == tag ? null : tag),
                            );
                          },
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: Obx(() {
                        final entries = lane.activityLog.where((e) {
                          if (_activityFilter == null) return true;
                          return _parseLogEntry(e)['tag'] == _activityFilter;
                        }).toList();

                        if (entries.isEmpty) {
                          return Center(
                            child: Text(
                              _activityFilter == null
                                  ? 'No activity yet'
                                  : 'No "$_activityFilter" entries yet',
                              style:
                                  const TextStyle(color: _StationColors.slate),
                            ),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: entries.length,
                          itemBuilder: (context, i) {
                            final parsed = _parseLogEntry(entries[i]);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: _StationColors.slateBorder),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _tagChip(parsed['tag']!),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: SelectableText(
                                      '[${parsed['time']}] ${parsed['message']}',
                                      style: TextStyle(
                                          fontSize: 13,
                                          color: _activityLogColor(entries[i])),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}
