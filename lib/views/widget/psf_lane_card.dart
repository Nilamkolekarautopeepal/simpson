// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
// import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';
// import 'package:simpson/views/widget/psf_dtc_dialog.dart';
// import 'package:simpson/views/widget/views_widget/psf_live_parameter_dialog.dart';

// class _LaneColors {
//   static const navy = Color(0xFF003874);
//   static const navyLight = Color(0xFF1D5FA0);
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
// LinearGradient _glossGradient({double opacity = 0.16}) {
//   return LinearGradient(
//     begin: Alignment.topCenter,
//     end: Alignment.bottomCenter,
//     stops: const [0.0, 0.42, 0.55],
//     colors: [
//       Colors.white.withOpacity(opacity),
//       Colors.white.withOpacity(opacity * 0.28),
//       Colors.white.withOpacity(0),
//     ],
//   );
// }

// List<BoxShadow> _raisedShadow(Color tint, {double strength = 1}) => [
//       BoxShadow(
//         color: tint.withOpacity(0.28 * strength),
//         blurRadius: 3,
//         offset: const Offset(0, 1),
//       ),
//       BoxShadow(
//         color: tint.withOpacity(0.18 * strength),
//         blurRadius: 14,
//         offset: const Offset(0, 6),
//       ),
//     ];

// class PsfLaneCard extends StatelessWidget {
//   const PsfLaneCard({
//     super.key,
//     required this.laneIndex,
//     required this.lane,
//     required this.controller,
//     required this.width,
//     required this.height,
//   });

//   final int laneIndex;
//   final PsfLane lane;
//   final PsfHomeScreenController controller;
//   final double width;
//   final double height;

//   @override
//   Widget build(BuildContext context) {
//     return Obx(() {
//       final matched = lane.isTargetLane.value;
//       final borderColor = matched ? _LaneColors.green : _LaneColors.slateBorder;

//       return Container(
//         width: width,
//         height: height,
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(14),
//           gradient: const LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [Colors.white, Color(0xFFFCFDFF)],
//           ),
//           border: Border.all(color: borderColor, width: matched ? 1.8 : 1),
//           boxShadow: _raisedShadow(
//             matched ? _LaneColors.green : Colors.black,
//             strength: matched ? 1.3 : 0.7,
//           ),
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(14),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.stretch,
//             children: [
//               // ── fixed header ──
//               _ecuHeaderRow(),
//               _esnScanRow(),
//               _listNumberScanRow(),
//               const SizedBox(height: 2),
//               Divider(
//                   height: 1,
//                   thickness: 1,
//                   color: _LaneColors.slateBorder.withOpacity(0.8)),

//               // ── scrollable middle ──
//               Expanded(
//                 child: SingleChildScrollView(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.stretch,
//                     children: [
//                       const SizedBox(height: 10),
//                       _iqaScanGrid(),
//                       if (lane.iqaAllFilled.value) _flashFileBox(),
//                     ],
//                   ),
//                 ),
//               ),

//               // ── fixed footer ──
//               if (lane.iqaAllFilled.value) ...[
//                 _startFlashButton(),
//                 _bigFlashStatus(),
//               ],
//               _statusLine('IQA STATUS',
//                   '${lane.filledIqaCount.value} / ${lane.iqaControllers.length} scanned'),
//               const SizedBox(height: 4),
//               _dtcAndLiveParameter(context),
//               const SizedBox(height: 14),
//             ],
//           ),
//         ),
//       );
//     });
//   }

//   Widget _ecuHeaderRow() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
//       decoration: BoxDecoration(
//         borderRadius: const BorderRadius.vertical(
//             top: Radius.circular(9), bottom: Radius.circular(9)),
//         gradient: const LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [_LaneColors.navyLight, _LaneColors.navy],
//         ),
//         boxShadow: _raisedShadow(_LaneColors.navy, strength: 0.9),
//       ),
//       foregroundDecoration: BoxDecoration(
//         borderRadius: const BorderRadius.vertical(
//             top: Radius.circular(9), bottom: Radius.circular(9)),
//         gradient: _glossGradient(),
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//           children: [
//             Expanded(
//               child: Text(
//                 '${lane.laneNumber}. ${lane.ecuModelName.value}',
//                 style: const TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.white,
//                   letterSpacing: 0.2,
//                 ),
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ),
//             IconButton(
//               icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
//               padding: EdgeInsets.zero,
//               constraints: const BoxConstraints(),
//               onPressed: () => controller.resetLane(laneIndex),
//               tooltip: 'Reset lane for next engine',
//             ),
//             const SizedBox(width: 6),
//             _ledDot(lane.isLedOn.value),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _ledDot(bool on) {
//     final Color core = on ? const Color(0xFF4ADE80) : const Color(0xFFEF5350);
//     return Container(
//       width: 13,
//       height: 13,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         gradient: RadialGradient(
//           center: const Alignment(-0.3, -0.3),
//           colors: [Colors.white.withOpacity(0.9), core, core],
//           stops: const [0.0, 0.35, 1.0],
//         ),
//         boxShadow: [
//           BoxShadow(
//               color: core.withOpacity(0.75), blurRadius: 8, spreadRadius: 0.5),
//         ],
//       ),
//     );
//   }

 
//   Widget _autoScanField({
//     required String label,
//     required TextEditingController textController,
//     required FocusNode focusNode,
//     required bool isLoading,
//     required bool isResolved,
//     required String resolvedText,
//     required String awaitingText,
//     required String error,
//     required String hint,
//     required VoidCallback onChanged,
//     required VoidCallback onSubmit,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.stretch,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w800,
//                 color: _LaneColors.slate,
//                 letterSpacing: 0.5),
//           ),
//           const SizedBox(height: 4),
//           Container(
//             height: 38,
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(6),
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: isResolved
//                     ? [
//                         _LaneColors.greenBg,
//                         _LaneColors.greenBg.withOpacity(0.7)
//                       ]
//                     : [
//                         _LaneColors.slateBg,
//                         const Color.fromARGB(255, 245, 246, 247)
//                       ],
//               ),
//               border: Border.all(
//                   color:
//                       isResolved ? _LaneColors.green : _LaneColors.slateBorder),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.04),
//                   blurRadius: 3,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: TextField(
//               controller: textController,
//               focusNode: focusNode,
//               enabled: !isLoading,
//               style: const TextStyle(fontSize: 12),
//               decoration: InputDecoration(
//                 hintText: hint,
//                 hintStyle:
//                     const TextStyle(fontSize: 11.5, color: _LaneColors.slate),
//                 isDense: true,
//                 filled: false,
//                 contentPadding:
//                     const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
//                 suffixIcon: isLoading
//                     ? const Padding(
//                         padding: EdgeInsets.all(10),
//                         child: SizedBox(
//                             width: 16,
//                             height: 16,
//                             child: CircularProgressIndicator(strokeWidth: 2)),
//                       )
//                     : null,
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(6),
//                   borderSide: BorderSide.none,
//                 ),
//                 enabledBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(6),
//                   borderSide: BorderSide.none,
//                 ),
//                 focusedBorder: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(6),
//                   borderSide: const BorderSide(
//                       color: _LaneColors.navyLight, width: 1.6),
//                 ),
//               ),
//               onChanged: (_) => onChanged(),
//               onSubmitted: (_) => onSubmit(),
//             ),
//           ),
//           if (error.isNotEmpty)
//             Padding(
//               padding: const EdgeInsets.only(top: 4),
//               child: Text(error,
//                   style: const TextStyle(
//                       fontSize: 10.5,
//                       color: _LaneColors.red,
//                       fontWeight: FontWeight.w600)),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _esnScanRow() {
//     return _autoScanField(
//       label: 'ESN NUMBER',
//       textController: lane.esnController,
//       focusNode: lane.esnFocusNode,
//       isLoading: lane.isLookingUpEsn.value,
//       isResolved: lane.esn.value.isNotEmpty,
//       resolvedText: 'ESN: ${lane.esn.value}',
//       awaitingText: 'Scan or type the engine serial number',
//       error: lane.esnError.value,
//       hint: 'e.g. 12345678912345',
//       onChanged: () => controller.onEsnFieldChanged(laneIndex),
//       onSubmit: () => controller.onScanEsnForLane(laneIndex),
//     );
//   }

//   Widget _listNumberScanRow() {
//     if (lane.esn.value.isEmpty) return const SizedBox.shrink();

//     return _autoScanField(
//       label: 'LIST NUMBER',
//       textController: lane.listNumberController,
//       focusNode: lane.listNumberFocusNode,
//       isLoading: lane.isLookingUpListNumber.value,
//       isResolved: lane.listNumber.value.isNotEmpty,
//       resolvedText: 'List No: ${lane.listNumber.value}',
//       awaitingText: 'Scan or type the list number',
//       error: lane.listNumberError.value,
//       hint: 'e.g. 3293',
//       onChanged: () => controller.onListNumberFieldChanged(laneIndex),
//       onSubmit: () => controller.onScanListNumberForLane(laneIndex),
//     );
//   }

//   Widget _boxedLabel(String text) {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//       alignment: Alignment.center,
//       padding: const EdgeInsets.symmetric(vertical: 9),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [_LaneColors.slateBg, Colors.white],
//         ),
//         border: Border.all(color: _LaneColors.slateBorder),
//         borderRadius: BorderRadius.circular(6),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.bold,
//             color: _LaneColors.slate),
//         overflow: TextOverflow.ellipsis,
//       ),
//     );
//   }

//   Widget _iqaScanGrid() {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text(
//             'IQA NUMBERS',
//             style: TextStyle(
//                 fontSize: 10,
//                 fontWeight: FontWeight.w800,
//                 color: _LaneColors.slate,
//                 letterSpacing: 0.5),
//           ),
//           const SizedBox(height: 6),
//           ...List.generate(lane.iqaControllers.length, (i) {
//             return Padding(
//               padding: const EdgeInsets.only(bottom: 8),
//               child: Row(
//                 children: [
//                   Expanded(
//                     child: Container(
//                       padding: const EdgeInsets.symmetric(vertical: 9),
//                       alignment: Alignment.center,
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           begin: Alignment.topCenter,
//                           end: Alignment.bottomCenter,
//                           colors: [_LaneColors.slateBg, Colors.white],
//                         ),
//                         border: Border.all(color: _LaneColors.slateBorder),
//                         borderRadius: BorderRadius.circular(6),
//                       ),
//                       child: Text(
//                         'INJECTOR ${i + 1}',
//                         style: const TextStyle(
//                             fontSize: 10.5,
//                             fontWeight: FontWeight.bold,
//                             color: _LaneColors.navy),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 8),
//                   Expanded(
//                     child: Container(
//                       height: 34,
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(6),
//                         color: Colors.white,
//                         boxShadow: [
//                           BoxShadow(
//                               color: Colors.black.withOpacity(0.03),
//                               blurRadius: 2,
//                               offset: const Offset(0, 1)),
//                         ],
//                       ),
//                       child: TextField(
//                         controller: lane.iqaControllers[i],
//                         focusNode: lane.iqaFocusNodes[i],
//                         textAlign: TextAlign.center,
//                         style: const TextStyle(fontSize: 11),
//                         decoration: InputDecoration(
//                           hintText: lane.iqaLabelFor(i),
//                           hintStyle: const TextStyle(fontSize: 10),
//                           isDense: true,
//                           contentPadding:
//                               const EdgeInsets.symmetric(vertical: 8),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(6),
//                             borderSide: const BorderSide(
//                                 color: _LaneColors.slateBorder),
//                           ),
//                           enabledBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(6),
//                             borderSide: const BorderSide(
//                                 color: _LaneColors.slateBorder),
//                           ),
//                           focusedBorder: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(6),
//                             borderSide: const BorderSide(
//                                 color: _LaneColors.navyLight, width: 1.6),
//                           ),
//                         ),
//                         onChanged: (_) =>
//                             controller.onIqaFieldChanged(laneIndex, i),
//                         onSubmitted: (_) {
//                           if (i < lane.iqaFocusNodes.length - 1) {
//                             lane.iqaFocusNodes[i + 1].requestFocus();
//                           }
//                         },
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }),
//         ],
//       ),
//     );
//   }


//   Widget _flashFileBox() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
//       child: Builder(builder: (context) {
//         if (lane.flashFilesError.value.isNotEmpty) {
//           return Container(
//             padding: const EdgeInsets.all(8),
//             decoration: BoxDecoration(
//                 color: _LaneColors.redBg,
//                 borderRadius: BorderRadius.circular(6)),
//             child: Text(lane.flashFilesError.value,
//                 style: const TextStyle(fontSize: 10.5, color: _LaneColors.red)),
//           );
//         }
//         if (lane.resolvedFlashFileName.value == null) {
//           return _boxedLabel('FLASH FILE NAME');
//         }
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'FLASH FILE',
//               style: TextStyle(
//                   fontSize: 10,
//                   fontWeight: FontWeight.w800,
//                   color: _LaneColors.slate,
//                   letterSpacing: 0.5),
//             ),
//             const SizedBox(height: 6),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [
//                     _LaneColors.greenBg,
//                     _LaneColors.greenBg.withOpacity(0.6)
//                   ],
//                 ),
//                 border: Border.all(color: _LaneColors.green),
//                 borderRadius: BorderRadius.circular(6),
//                 boxShadow: [
//                   BoxShadow(
//                       color: _LaneColors.green.withOpacity(0.18),
//                       blurRadius: 10,
//                       offset: const Offset(0, 3)),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const Icon(Icons.check_circle,
//                       size: 15, color: _LaneColors.green),
//                   const SizedBox(width: 6),
//                   Expanded(
//                     child: Text(
//                       lane.resolvedFlashFileName.value!,
//                       style: const TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.bold,
//                           color: _LaneColors.green),
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         );
//       }),
//     );
//   }

//   Widget _startFlashButton() {
//     final bool ready =
//         lane.resolvedFlashFileUrl.value != null && lane.dongleConnected.value;
//     final bool canFlash = ready && !lane.isFlashing.value;
//     final String label = lane.isFlashing.value
//         ? 'FLASHING…'
//         : (!lane.dongleConnected.value
//             ? 'CONNECTING DONGLE…'
//             : (lane.resolvedFlashFileUrl.value == null
//                 ? 'SCAN LIST NUMBER FIRST'
//                 : 'START FLASH'));

//     final List<Color> gradientColors = lane.isFlashing.value
//         ? [_LaneColors.greenDark, const Color(0xFF11592D)]
//         : (ready
//             ? [_LaneColors.green, _LaneColors.greenDark]
//             : [_LaneColors.slateBorder, _LaneColors.slateBorder]);

//     final Color glowTint =
//         lane.isFlashing.value || ready ? _LaneColors.green : Colors.black;
//     final Color textColor =
//         lane.isFlashing.value || ready ? Colors.white : _LaneColors.slate;

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
//       child: Column(
//         children: [
//           Container(
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: gradientColors,
//               ),
//               boxShadow: _raisedShadow(glowTint,
//                   strength: ready || lane.isFlashing.value ? 1.1 : 0.4),
//             ),
//             foregroundDecoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(8),
//               gradient: _glossGradient(
//                   opacity: ready || lane.isFlashing.value ? 0.22 : 0.08),
//             ),
//             child: Material(
//               color: Colors.transparent,
//               borderRadius: BorderRadius.circular(8),
//               child: InkWell(
//                 borderRadius: BorderRadius.circular(8),
//                 onTap:
//                     canFlash ? () => controller.onStartFlash(laneIndex) : null,
//                 child: Padding(
//                   padding: const EdgeInsets.symmetric(vertical: 11),
//                   child: Center(
//                     child: lane.isFlashing.value
//                         ? Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               const SizedBox(
//                                   width: 14,
//                                   height: 14,
//                                   child: CircularProgressIndicator(
//                                       strokeWidth: 2, color: Colors.white)),
//                               const SizedBox(width: 8),
//                               Text(label,
//                                   style: const TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.w800,
//                                       color: Colors.white,
//                                       letterSpacing: 0.3)),
//                             ],
//                           )
//                         : Text(label,
//                             style: TextStyle(
//                                 fontSize: 12,
//                                 fontWeight: FontWeight.w800,
//                                 color: textColor,
//                                 letterSpacing: 0.3)),
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           if (lane.isFlashing.value || lane.flashProgress.value > 0) ...[
//             const SizedBox(height: 8),
//             ClipRRect(
//               borderRadius: BorderRadius.circular(3),
//               child: Container(
//                 height: 6,
//                 decoration: BoxDecoration(color: _LaneColors.slateBg),
//                 child: FractionallySizedBox(
//                   alignment: Alignment.centerLeft,
//                   widthFactor: lane.flashProgress.value.clamp(0.0, 1.0),
//                   child: Container(
//                     decoration: const BoxDecoration(
//                       gradient: LinearGradient(
//                         colors: [_LaneColors.green, _LaneColors.greenDark],
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ],
//       ),
//     );
//   }

//   Widget _bigFlashStatus() {
//     if (!lane.isFlashing.value &&
//         lane.flashProgress.value == 0 &&
//         lane.flashStatus.value.isEmpty) {
//       return const SizedBox.shrink();
//     }

//     final failed = lane.flashStatus.value.startsWith('Flash Failed');
//     final completed = lane.flashStatus.value == 'Flash Completed';

//     final Color accent = failed
//         ? _LaneColors.red
//         : (completed ? _LaneColors.greenDark : _LaneColors.slate);
//     final List<Color> bgColors = failed
//         ? [_LaneColors.redBg, _LaneColors.redBg.withOpacity(0.6)]
//         : (completed
//             ? [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.6)]
//             : [_LaneColors.slateBg, Colors.white]);

//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
//       child: Container(
//         width: double.infinity,
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//               begin: Alignment.topCenter,
//               end: Alignment.bottomCenter,
//               colors: bgColors),
//           border: Border.all(color: accent),
//           borderRadius: BorderRadius.circular(8),
//           boxShadow: _raisedShadow(accent, strength: 0.6),
//         ),
//         foregroundDecoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(8),
//           gradient: _glossGradient(opacity: 0.14),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.center,
//             children: [
//               if (lane.isFlashing.value || completed) ...[
//                 Text(
//                   lane.formattedElapsed,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                       fontSize: 28,
//                       fontWeight: FontWeight.bold,
//                       color: Colors.black87),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   '${(lane.flashProgress.value * 100).round()}%',
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold,
//                     color: completed ? _LaneColors.greenDark : _LaneColors.navy,
//                   ),
//                 ),
//                 const SizedBox(height: 6),
//               ],
//               Text(
//                 lane.flashStatus.value,
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w800,
//                   color: failed
//                       ? _LaneColors.red
//                       : (completed ? _LaneColors.greenDark : Colors.black87),
//                 ),
//               ),
//               if (completed && lane.iqaWriteStatus.value.isNotEmpty) ...[
//                 const SizedBox(height: 6),
//                 Text(
//                   lane.iqaWriteStatus.value,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 11.5,
//                     fontWeight: FontWeight.w700,
//                     color: lane.iqaWriteStatus.value
//                             .toLowerCase()
//                             .contains('successful')
//                         ? _LaneColors.greenDark
//                         : _LaneColors.red,
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _statusLine(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
//       child: RichText(
//         text: TextSpan(
//           style: const TextStyle(
//               fontSize: 11.5,
//               fontWeight: FontWeight.bold,
//               color: _LaneColors.navy),
//           children: [
//             TextSpan(text: '$label  '),
//             TextSpan(
//                 text: value,
//                 style: const TextStyle(
//                     fontWeight: FontWeight.normal, color: _LaneColors.slate)),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _dtcAndLiveParameter(BuildContext context) {
//     Widget pillButton(
//         {required String label, required VoidCallback onPressed}) {
//       return Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(6),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(6),
//           onTap: onPressed,
//           child: Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 9),
//             alignment: Alignment.center,
//             decoration: BoxDecoration(
//               gradient: const LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [Colors.white, Color(0xFFF4F7FB)],
//               ),
//               border: Border.all(color: _LaneColors.navy.withOpacity(0.55)),
//               borderRadius: BorderRadius.circular(6),
//               boxShadow: [
//                 BoxShadow(
//                     color: _LaneColors.navy.withOpacity(0.08),
//                     blurRadius: 6,
//                     offset: const Offset(0, 2)),
//               ],
//             ),
//             child: Text(
//               label,
//               style: const TextStyle(
//                   fontSize: 11.5,
//                   fontWeight: FontWeight.w800,
//                   color: _LaneColors.navy,
//                   letterSpacing: 0.3),
//             ),
//           ),
//         ),
//       );
//     }

//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 12),
//       child: Column(
//         children: [
//           pillButton(
//             label: 'DTC',
//             onPressed: () async {
//               await controller.onOpenDtc(laneIndex);
//               PsfDtcDialog.show(
//                 lane,
//                 () => controller.readLiveDtcForLane(laneIndex),
//                 () => controller.clearDtcForLane(laneIndex),
//               );

//               if (lane.dongleConnected.value) {
//                 controller.readLiveDtcForLane(laneIndex);
//               }
//             },
//           ),
//           const SizedBox(height: 10),
//           pillButton(
//             label: 'LIVE PARAMETER',
//             onPressed: () async {
//               await controller.onOpenLiveParameter(laneIndex);
//               PsfLiveParameterDialog.show(
//                 lane,
//                 () => controller.loadPidForLane(laneIndex),
//                 () => controller.togglePidPlaybackForLane(laneIndex),
//               );
//             },
//           ),
//         ],
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';
import 'package:simpson/views/widget/psf_dtc_dialog.dart';
import 'package:simpson/views/widget/views_widget/psf_live_parameter_dialog.dart';

/// ── Color system ────────────────────────────────────────────────
/// Same palette as before — every hex value is untouched. What
/// changes is HOW these colors are applied: flat fills become
/// gradients, single shadows become layered ambient + contact
/// shadows, and a soft diagonal sheen sits over the glossiest
/// surfaces (header, buttons, status panel) to read as glass/gloss
/// rather than matte paint.
///  - navy        = brand / primary action
///  - green       = matched / connected / ready
///  - greenDark   = actively flashing
///  - amber       = waiting on operator input
///  - red         = error / failed
///  - slate       = idle / neutral chrome
class _LaneColors {
  static const navy = Color(0xFF003874);
  static const navyLight = Color(0xFF1D5FA0);
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

/// A soft diagonal sheen — the one signature device repeated across
/// every glossy surface (header bar, start-flash button, big status
/// panel). It's a whisper-thin white gradient banding across the top
/// third, at low opacity, so it reads as a light catching a curved
/// glass/lacquer surface rather than a literal highlight streak.
/// Same visual sheen as before, but painted via Container's
/// foregroundDecoration instead of a Stack + Positioned.fill overlay.
/// This draws directly on top of the container's own content with no
/// extra layout participants at all — the Stack/Positioned/IgnorePointer
/// nesting was a more fragile way to get the identical pixel result.
LinearGradient _glossGradient({double opacity = 0.16}) {
  return LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: const [0.0, 0.42, 0.55],
    colors: [
      Colors.white.withOpacity(opacity),
      Colors.white.withOpacity(opacity * 0.28),
      Colors.white.withOpacity(0),
    ],
  );
}

/// Layered shadow set used for every "raised" surface — a tight,
/// dark contact shadow close to the edge plus a wider, softer ambient
/// shadow underneath. Two shadows read as real depth; one shadow
/// reads as a drop-shadow filter.
List<BoxShadow> _raisedShadow(Color tint, {double strength = 1}) => [
      BoxShadow(
        color: tint.withOpacity(0.28 * strength),
        blurRadius: 3,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: tint.withOpacity(0.18 * strength),
        blurRadius: 14,
        offset: const Offset(0, 6),
      ),
    ];

class PsfLaneCard extends StatelessWidget {
  const PsfLaneCard({
    super.key,
    required this.laneIndex,
    required this.lane,
    required this.controller,
    required this.width,
    required this.height,
  });

  final int laneIndex;
  final PsfLane lane;
  final PsfHomeScreenController controller;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final matched = lane.isTargetLane.value;
      final borderColor = matched ? _LaneColors.green : _LaneColors.slateBorder;

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xFFFCFDFF)],
          ),
          border: Border.all(color: borderColor, width: matched ? 1.8 : 1),
          boxShadow: _raisedShadow(
            matched ? _LaneColors.green : Colors.black,
            strength: matched ? 1.3 : 0.7,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── fixed header ──
              _ecuHeaderRow(),
              _esnScanRow(),
              _listNumberScanRow(),
              const SizedBox(height: 2),
              Divider(height: 1, thickness: 1, color: _LaneColors.slateBorder.withOpacity(0.8)),

              // ── scrollable middle ──
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 10),
                      _iqaScanGrid(),
                      if (lane.iqaAllFilled.value) _flashFileBox(),
                    ],
                  ),
                ),
              ),

              // ── fixed footer ──
              if (lane.iqaAllFilled.value) ...[
                _startFlashButton(),
                _bigFlashStatus(),
              ],
              _statusLine('IQA STATUS', '${lane.filledIqaCount.value} / ${lane.iqaControllers.length} scanned'),
              const SizedBox(height: 4),
              _dtcAndLiveParameter(context),
              const SizedBox(height: 14),
            ],
          ),
        ),
      );
    });
  }

  /// Header — navy gradient instead of flat fill, with the gloss
  /// sheen riding over the top and a real glow behind the LED, so the
  /// whole bar reads like backlit brushed-metal/glass rather than a
  /// painted rectangle.
  Widget _ecuHeaderRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9), bottom: Radius.circular(9)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_LaneColors.navyLight, _LaneColors.navy],
        ),
        boxShadow: _raisedShadow(_LaneColors.navy, strength: 0.9),
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(9), bottom: Radius.circular(9)),
        gradient: _glossGradient(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '${lane.laneNumber}. ${lane.ecuModelName.value}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.2,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => controller.resetLane(laneIndex),
              tooltip: 'Reset lane for next engine',
            ),
            const SizedBox(width: 6),
            _ledDot(lane.isLedOn.value),
          ],
        ),
      ),
    );
  }

  /// LED indicator with a real radial glow and a tiny glass highlight
  /// on the upper-left, so it reads as an illuminated bead rather
  /// than a flat filled circle.
  Widget _ledDot(bool on) {
    final Color core = on ? const Color(0xFF4ADE80) : const Color(0xFFEF5350);
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.3),
          colors: [Colors.white.withOpacity(0.9), core, core],
          stops: const [0.0, 0.35, 1.0],
        ),
        boxShadow: [
          BoxShadow(color: core.withOpacity(0.75), blurRadius: 8, spreadRadius: 0.5),
        ],
      ),
    );
  }

  /// Shared style for the auto-scan fields (ESN, List Number) — glass
  /// inset look: a subtle inner gradient and a thin top highlight so
  /// each field reads as a recessed glass slot rather than a plain
  /// bordered box.
  Widget _autoScanField({
    required String label,
    required TextEditingController textController,
    required FocusNode focusNode,
    required bool isLoading,
    required bool isResolved,
    required String resolvedText,
    required String awaitingText,
    required String error,
    required String hint,
    required VoidCallback onChanged,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _LaneColors.slate, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Container(
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isResolved
                    ? [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.7)]
                    : [_LaneColors.slateBg, Colors.white],
              ),
            ),
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              enabled: !isLoading,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 11.5, color: _LaneColors.slate),
                isDense: true,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                suffixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: isResolved ? _LaneColors.green : _LaneColors.slateBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: isResolved ? _LaneColors.green : _LaneColors.slateBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: const BorderSide(color: _LaneColors.navyLight, width: 1.6),
                ),
              ),
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error, style: const TextStyle(fontSize: 10.5, color: _LaneColors.red, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _esnScanRow() {
    return _autoScanField(
      label: 'ESN NUMBER',
      textController: lane.esnController,
      focusNode: lane.esnFocusNode,
      isLoading: lane.isLookingUpEsn.value,
      isResolved: lane.esn.value.isNotEmpty,
      resolvedText: 'ESN: ${lane.esn.value}',
      awaitingText: 'Scan or type the engine serial number',
      error: lane.esnError.value,
      hint: 'e.g. 111111111111111',
      onChanged: () => controller.onEsnFieldChanged(laneIndex),
      onSubmit: () => controller.onScanEsnForLane(laneIndex),
    );
  }

  /// List Number — only usable once ESN has matched. Resolves to
  /// exactly one flash file (see resolvedFlashFileName below), not a
  /// list to choose from.
  Widget _listNumberScanRow() {
    if (lane.esn.value.isEmpty) return const SizedBox.shrink();

    return _autoScanField(
      label: 'LIST NUMBER',
      textController: lane.listNumberController,
      focusNode: lane.listNumberFocusNode,
      isLoading: lane.isLookingUpListNumber.value,
      isResolved: lane.listNumber.value.isNotEmpty,
      resolvedText: 'List No: ${lane.listNumber.value}',
      awaitingText: 'Scan or type the list number',
      error: lane.listNumberError.value,
      hint: 'e.g. 3293',
      onChanged: () => controller.onListNumberFieldChanged(laneIndex),
      onSubmit: () => controller.onScanListNumberForLane(laneIndex),
    );
  }

  Widget _boxedLabel(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_LaneColors.slateBg, Colors.white],
        ),
        border: Border.all(color: _LaneColors.slateBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _LaneColors.slate),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _iqaScanGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IQA NUMBERS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _LaneColors.slate, letterSpacing: 0.5),
          ),
          const SizedBox(height: 6),
          ...List.generate(lane.iqaControllers.length, (i) {
            final filled = lane.iqaControllers[i].text.trim().length == 7;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: filled
                              ? [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.7)]
                              : [_LaneColors.slateBg, Colors.white],
                        ),
                        border: Border.all(color: filled ? _LaneColors.green : _LaneColors.slateBorder),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (filled) ...[
                            const Icon(Icons.check_circle, size: 12),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            'INJECTOR ${i + 1}',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: filled ? _LaneColors.greenDark : _LaneColors.navy,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: filled
                              ? [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.3)]
                              : [Colors.white, Colors.white],
                        ),
                      ),
                      child: TextField(
                        controller: lane.iqaControllers[i],
                        focusNode: lane.iqaFocusNodes[i],
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 11, color: filled ? _LaneColors.greenDark : Colors.black87, fontWeight: filled ? FontWeight.w700 : FontWeight.normal),
                        decoration: InputDecoration(
                          hintText: lane.iqaLabelFor(i),
                          hintStyle: const TextStyle(fontSize: 10),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: filled ? _LaneColors.green : _LaneColors.slateBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: filled ? _LaneColors.green : _LaneColors.slateBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: _LaneColors.navyLight, width: 1.6),
                          ),
                        ),
                        onChanged: (_) => controller.onIqaFieldChanged(laneIndex, i),
                        onSubmitted: (_) {
                          if (i < lane.iqaFocusNodes.length - 1) {
                            lane.iqaFocusNodes[i + 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _flashFileBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Builder(builder: (context) {
        if (lane.flashFilesError.value.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _LaneColors.redBg, borderRadius: BorderRadius.circular(6)),
            child: Text(lane.flashFilesError.value, style: const TextStyle(fontSize: 10.5, color: _LaneColors.red)),
          );
        }
        if (lane.resolvedFlashFileName.value == null) {
          return _boxedLabel('FLASH FILE NAME');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FLASH FILE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _LaneColors.slate, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.6)],
                ),
                border: Border.all(color: _LaneColors.green),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(color: _LaneColors.green.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 15, color: _LaneColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lane.resolvedFlashFileName.value!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _LaneColors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Start Flash button — this is the card's signature glossy
  /// element: a real gradient fill, layered shadow that lifts off
  /// the card, and the diagonal sheen riding across the top so it
  /// reads like a lacquered hardware button, not a Material default.
  Widget _startFlashButton() {
    final bool ready = lane.resolvedFlashFileUrl.value != null && lane.dongleConnected.value;
    final bool canFlash = ready && !lane.isFlashing.value;

    // isFlashing must be checked FIRST — during an active flash, the
    // main isolate's dongleConnected is intentionally false (the
    // dongle is in active use by the flash isolate's own connection,
    // freed up right before it spawns). Checking dongleConnected
    // first would show "CONNECTING DONGLE…" for the entire flash
    // instead of "FLASHING…" with the progress panel.
    final String label = lane.isFlashing.value
        ? 'FLASHING…'
        : (!lane.dongleConnected.value
            ? 'CONNECTING DONGLE…'
            : (lane.resolvedFlashFileUrl.value == null ? 'SCAN LIST NUMBER FIRST' : 'START FLASH'));

    final List<Color> gradientColors = lane.isFlashing.value
        ? [_LaneColors.greenDark, const Color(0xFF11592D)]
        : (ready ? [_LaneColors.green, _LaneColors.greenDark] : [_LaneColors.slateBorder, _LaneColors.slateBorder]);

    final Color glowTint = lane.isFlashing.value || ready ? _LaneColors.green : Colors.black;
    final Color textColor = lane.isFlashing.value || ready ? Colors.white : _LaneColors.slate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
              ),
              boxShadow: _raisedShadow(glowTint, strength: ready || lane.isFlashing.value ? 1.1 : 0.4),
            ),
            foregroundDecoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: _glossGradient(opacity: ready || lane.isFlashing.value ? 0.22 : 0.08),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: canFlash ? () => controller.onStartFlash(laneIndex) : null,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Center(
                    child: lane.isFlashing.value
                        ? Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                              const SizedBox(width: 8),
                              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3)),
                            ],
                          )
                        : Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor, letterSpacing: 0.3)),
                  ),
                ),
              ),
            ),
          ),
          if (lane.isFlashing.value || lane.flashProgress.value > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: Container(
                height: 6,
                decoration: BoxDecoration(color: _LaneColors.slateBg),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: lane.flashProgress.value.clamp(0.0, 1.0),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_LaneColors.green, _LaneColors.greenDark],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Big flash status panel — same tri-state coloring (failed /
  /// completed / in-progress) but now a soft gradient card with a
  /// gloss sheen, so it feels like part of the same lacquered-glass
  /// family as the header and the Start Flash button.
  Widget _bigFlashStatus() {
    if (!lane.isFlashing.value && lane.flashProgress.value == 0 && lane.flashStatus.value.isEmpty) {
      return const SizedBox.shrink();
    }

    final failed = lane.flashStatus.value.startsWith('Flash Failed');
    final completed = lane.flashStatus.value == 'Flash Completed';

    final Color accent = failed ? _LaneColors.red : (completed ? _LaneColors.greenDark : _LaneColors.slate);
    final List<Color> bgColors = failed
        ? [_LaneColors.redBg, _LaneColors.redBg.withOpacity(0.6)]
        : (completed
            ? [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.6)]
            : [_LaneColors.slateBg, Colors.white]);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: bgColors),
          border: Border.all(color: accent),
          borderRadius: BorderRadius.circular(8),
          boxShadow: _raisedShadow(accent, strength: 0.6),
        ),
        foregroundDecoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          gradient: _glossGradient(opacity: 0.14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (lane.isFlashing.value || completed) ...[
                Text(
                  lane.formattedElapsed,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(lane.flashProgress.value * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: completed ? _LaneColors.greenDark : _LaneColors.navy,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                lane.flashStatus.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: failed ? _LaneColors.red : (completed ? _LaneColors.greenDark : Colors.black87),
                ),
              ),
              if (completed && lane.iqaWriteStatus.value.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  lane.iqaWriteStatus.value,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: lane.iqaWriteStatus.value.toLowerCase().contains('successful')
                        ? _LaneColors.greenDark
                        : _LaneColors.red,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _LaneColors.navy),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal, color: _LaneColors.slate)),
          ],
        ),
      ),
    );
  }

  /// DTC / Live Parameter — glass-outline pill buttons with a subtle
  /// gradient fill instead of flat white, so they read as part of
  /// the same glossy family rather than plain Material outlines.
  Widget _dtcAndLiveParameter(BuildContext context) {
    Widget pillButton({required String label, required VoidCallback onPressed}) {
      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF4F7FB)],
              ),
              border: Border.all(color: _LaneColors.navy.withOpacity(0.55)),
              borderRadius: BorderRadius.circular(6),
              boxShadow: [
                BoxShadow(color: _LaneColors.navy.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: Text(
              label,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _LaneColors.navy, letterSpacing: 0.3),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          pillButton(
            label: 'DTC',
            onPressed: () async {
              await controller.onOpenDtc(laneIndex);
              PsfDtcDialog.show(
                lane,
                () => controller.readLiveDtcForLane(laneIndex),
                () => controller.clearDtcForLane(laneIndex),
              );
              // Auto-read live DTCs the moment the dialog opens —
              // same command the refresh button runs, just automatic,
              // so the operator sees real ECU state immediately
              // instead of stale/empty data until they tap refresh.
              // Only when the dongle is actually connected; if it
              // isn't, readLiveDtcForLane already shows its own
              // "connect the dongle first" message.
              if (lane.dongleConnected.value) {
                controller.readLiveDtcForLane(laneIndex);
              }
            },
          ),
          const SizedBox(height: 10),
          pillButton(
            label: 'LIVE PARAMETER',
            onPressed: () async {
              await controller.onOpenLiveParameter(laneIndex);
              PsfLiveParameterDialog.show(
                lane,
                () => controller.loadPidForLane(laneIndex),
                () => controller.togglePidPlaybackForLane(laneIndex),
              );
            },
          ),
        ],
      ),
    );
  }
}