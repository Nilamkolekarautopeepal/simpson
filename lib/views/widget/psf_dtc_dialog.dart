// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';

// /// Same palette as the lane card and Live Parameter dialog — kept
// /// identical so every screen in the app reads as one consistent
// /// product rather than a patchwork of one-off colors per dialog.
// class _LaneColors {
//   static const navy = Color(0xFF003874);
//   static const navyLight = Color(0xFF1D5FA0);
//   static const green = Color(0xFF2ECC71);
//   static const greenDark = Color(0xFF1B7A3E);
//   static const greenBg = Color(0xFFEAFAF1);
//   static const red = Color(0xFFD64545);
//   static const redBg = Color(0xFFFDEDED);
//   static const slate = Color(0xFF7C8698);
//   static const slateBorder = Color(0xFFDDE1E9);
//   static const slateBg = Color(0xFFF7F8FA);
// }

// /// Same signature diagonal sheen used across the lane card and Live
// /// Parameter dialog — the one glossy device repeated everywhere.
// class _GlossOverlay extends StatelessWidget {
//   const _GlossOverlay({this.borderRadius, this.opacity = 0.16});
//   final BorderRadius? borderRadius;
//   final double opacity;

//   @override
//   Widget build(BuildContext context) {
//     return Positioned.fill(
//       child: IgnorePointer(
//         child: ClipRRect(
//           borderRadius: borderRadius ?? BorderRadius.zero,
//           child: DecoratedBox(
//             decoration: BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 stops: const [0.0, 0.42, 0.55],
//                 colors: [
//                   Colors.white.withOpacity(opacity),
//                   Colors.white.withOpacity(opacity * 0.28),
//                   Colors.white.withOpacity(0),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// List<BoxShadow> _raisedShadow(Color tint, {double strength = 1}) => [
//       BoxShadow(color: tint.withOpacity(0.22 * strength), blurRadius: 3, offset: const Offset(0, 1)),
//       BoxShadow(color: tint.withOpacity(0.14 * strength), blurRadius: 12, offset: const Offset(0, 5)),
//     ];

// /// Centered DTC dialog for one lane. Shows the REAL codes read off
// /// the ECU (lane.dtcReadResults) — not just the dataset catalog of
// /// every possible code. Call [show] rather than constructing this
// /// directly.
// class PsfDtcDialog extends StatelessWidget {
//   const PsfDtcDialog({
//     super.key,
//     required this.lane,
//     required this.onRefresh,
//     required this.onClearDtc,
//   });

//   final PsfLane lane;
//   final VoidCallback onRefresh;
//   final VoidCallback onClearDtc;

//   static void show(PsfLane lane, VoidCallback onRefresh, VoidCallback onClearDtc) {
//     Get.dialog(PsfDtcDialog(lane: lane, onRefresh: onRefresh, onClearDtc: onClearDtc));
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       backgroundColor: Colors.transparent,
//       child: Container(
//         width: 480,
//         height: 560,
//         decoration: BoxDecoration(
//           color: Colors.white,
//           borderRadius: BorderRadius.circular(16),
//           boxShadow: _raisedShadow(Colors.black, strength: 1.4),
//         ),
//         clipBehavior: Clip.antiAlias,
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             _header(),
//             Expanded(
//               child: Padding(
//                 padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
//                 child: Obx(() {
//                   if (lane.isReadingDtc.value) {
//                     return const Center(
//                       child: CircularProgressIndicator(color: _LaneColors.navy),
//                     );
//                   }
//                   if (lane.dtcError.value.isNotEmpty) {
//                     return Center(
//                       child: Text(
//                         lane.dtcError.value,
//                         style: const TextStyle(color: _LaneColors.red, fontWeight: FontWeight.w600),
//                         textAlign: TextAlign.center,
//                       ),
//                     );
//                   }
//                   if (lane.dtcReadResults.isEmpty) {
//                     return _emptyState();
//                   }
//                   return ListView.builder(
//                     itemCount: lane.dtcReadResults.length,
//                     itemBuilder: (context, i) => _dtcTile(lane.dtcReadResults[i]),
//                   );
//                 }),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   /// Navy gradient header with the gloss sheen — same treatment as
//   /// the lane card's ECU header bar and the Live Parameter dialog, so
//   /// every dialog in the app reads as one consistent surface.
//   Widget _header() {
//     return Container(
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [_LaneColors.navyLight, _LaneColors.navy],
//         ),
//       ),
//       child: Stack(
//         children: [
//           const _GlossOverlay(),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Container(
//                       padding: const EdgeInsets.all(10),
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.14),
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: Colors.white.withOpacity(0.25)),
//                       ),
//                       child: const Icon(Icons.report_gmailerrorred, color: Colors.white, size: 22),
//                     ),
//                     const SizedBox(width: 12),
//                     Expanded(
//                       child: Text(
//                         'DTC — Lane ${lane.laneNumber}',
//                         style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
//                       ),
//                     ),
//                     Obx(
//                       () => IconButton(
//                         icon: lane.isReadingDtc.value
//                             ? const SizedBox(
//                                 width: 16,
//                                 height: 16,
//                                 child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                               )
//                             : const Icon(Icons.refresh, size: 20, color: Colors.white70),
//                         tooltip: 'Read DTCs from ECU',
//                         onPressed: lane.isReadingDtc.value ? null : onRefresh,
//                         splashRadius: 18,
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.close, size: 20, color: Colors.white70),
//                       onPressed: () => Get.back(),
//                       splashRadius: 18,
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 4),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Obx(
//                         () => Text(
//                           '${lane.dtcReadResults.length} code${lane.dtcReadResults.length == 1 ? '' : 's'} found on ECU',
//                           style: const TextStyle(fontSize: 12.5, color: Colors.white70),
//                         ),
//                       ),
//                     ),
//                     Obx(() {
//                       final disabled = lane.isReadingDtc.value || lane.dtcReadResults.isEmpty;
//                       return Opacity(
//                         opacity: disabled ? 0.45 : 1,
//                         child: _clearDtcButton(disabled: disabled),
//                       );
//                     }),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   /// Clearing DTCs is destructive (wipes the ECU's stored fault
//   /// history) — confirm before actually calling it, same as any
//   /// "delete" action, rather than firing on a single accidental tap.
//   Widget _clearDtcButton({required bool disabled}) {
//     return Container(
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(20),
//         gradient: const LinearGradient(colors: [_LaneColors.red, Color(0xFF9E2E2E)]),
//         boxShadow: _raisedShadow(_LaneColors.red, strength: 0.6),
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(20),
//         child: InkWell(
//           borderRadius: BorderRadius.circular(20),
//           onTap: disabled
//               ? null
//               : () {
//                   Get.defaultDialog(
//                     title: 'Clear DTC?',
//                     middleText: 'This will clear all fault codes stored on Lane ${lane.laneNumber}\'s ECU. This cannot be undone.',
//                     textConfirm: 'Clear',
//                     textCancel: 'Cancel',
//                     confirmTextColor: Colors.white,
//                     buttonColor: _LaneColors.red,
//                     onConfirm: () {
//                       Get.back();
//                       onClearDtc();
//                     },
//                   );
//                 },
//           child: Stack(
//             children: [
//               _GlossOverlay(borderRadius: BorderRadius.circular(20), opacity: 0.2),
//               const Padding(
//                 padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
//                 child: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white),
//                     SizedBox(width: 5),
//                     Text('CLEAR DTC', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   /// Success state — glossy green confirmation card instead of a bare
//   /// icon + grey text, matching the Flash File confirmation chip look.
//   Widget _emptyState() {
//     return Center(
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.6)],
//           ),
//           border: Border.all(color: _LaneColors.green),
//           borderRadius: BorderRadius.circular(12),
//           boxShadow: _raisedShadow(_LaneColors.green, strength: 0.5),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(Icons.check_circle, color: _LaneColors.greenDark, size: 36),
//             const SizedBox(height: 10),
//             const Text(
//               'No DTCs detected on this ECU.',
//               style: TextStyle(color: _LaneColors.greenDark, fontWeight: FontWeight.w700),
//             ),
//             const SizedBox(height: 4),
//             Text('Tap refresh to read again.', style: TextStyle(color: _LaneColors.greenDark.withOpacity(0.7), fontSize: 11.5)),
//           ],
//         ),
//       ),
//     );
//   }

//   /// raw is "CODE - description (status)" — split it back apart for
//   /// display. Red accent dot + tinted gradient card, matching the
//   /// error-state language used across the lane card and other dialogs.
//   Widget _dtcTile(String raw) {
//     final splitIndex = raw.indexOf(' - ');
//     final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
//     final rest = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [_LaneColors.redBg, _LaneColors.redBg.withOpacity(0.55)],
//         ),
//         border: Border.all(color: _LaneColors.red.withOpacity(0.4)),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Container(
//             width: 9,
//             height: 9,
//             margin: const EdgeInsets.only(top: 5, right: 10),
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: _LaneColors.red,
//               boxShadow: [BoxShadow(color: _LaneColors.red.withOpacity(0.5), blurRadius: 5)],
//             ),
//           ),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _LaneColors.red)),
//                 if (rest.isNotEmpty) ...[
//                   const SizedBox(height: 3),
//                   Text(rest, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';

/// Same palette as the lane card and Live Parameter dialog — kept
/// identical so every screen in the app reads as one consistent
/// product rather than a patchwork of one-off colors per dialog.
class _LaneColors {
  static const navy = Color(0xFF003874);
  static const navyLight = Color(0xFF1D5FA0);
  static const green = Color(0xFF2ECC71);
  static const greenDark = Color(0xFF1B7A3E);
  static const greenBg = Color(0xFFEAFAF1);
  static const red = Color(0xFFD64545);
  static const redBg = Color(0xFFFDEDED);
  static const slate = Color(0xFF7C8698);
  static const slateBorder = Color(0xFFDDE1E9);
  static const slateBg = Color(0xFFF7F8FA);
}

/// Same signature diagonal sheen used across the lane card and Live
/// Parameter dialog — the one glossy device repeated everywhere.
class _GlossOverlay extends StatelessWidget {
  const _GlossOverlay({this.borderRadius, this.opacity = 0.16});
  final BorderRadius? borderRadius;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.zero,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.42, 0.55],
                colors: [
                  Colors.white.withOpacity(opacity),
                  Colors.white.withOpacity(opacity * 0.28),
                  Colors.white.withOpacity(0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<BoxShadow> _raisedShadow(Color tint, {double strength = 1}) => [
      BoxShadow(color: tint.withOpacity(0.22 * strength), blurRadius: 3, offset: const Offset(0, 1)),
      BoxShadow(color: tint.withOpacity(0.14 * strength), blurRadius: 12, offset: const Offset(0, 5)),
    ];

/// Centered DTC dialog for one lane. Shows the REAL codes read off
/// the ECU (lane.dtcReadResults) — not just the dataset catalog of
/// every possible code. Call [show] rather than constructing this
/// directly.
class PsfDtcDialog extends StatelessWidget {
  const PsfDtcDialog({
    super.key,
    required this.lane,
    required this.onRefresh,
    required this.onClearDtc,
  });

  final PsfLane lane;
  final VoidCallback onRefresh;
  final VoidCallback onClearDtc;

  static void show(PsfLane lane, VoidCallback onRefresh, VoidCallback onClearDtc) {
    Get.dialog(PsfDtcDialog(lane: lane, onRefresh: onRefresh, onClearDtc: onClearDtc));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        height: 560,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: _raisedShadow(Colors.black, strength: 1.4),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _header(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
                child: Obx(() {
                  if (lane.isReadingDtc.value) {
                    return const Center(
                      child: CircularProgressIndicator(color: _LaneColors.navy),
                    );
                  }
                  if (lane.dtcError.value.isNotEmpty) {
                    return Center(
                      child: Text(
                        lane.dtcError.value,
                        style: const TextStyle(color: _LaneColors.red, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  if (lane.dtcReadResults.isEmpty) {
                    return _emptyState();
                  }
                  return ListView.builder(
                    itemCount: lane.dtcReadResults.length,
                    itemBuilder: (context, i) => _dtcTile(lane.dtcReadResults[i]),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Navy gradient header with the gloss sheen — same treatment as
  /// the lane card's ECU header bar and the Live Parameter dialog, so
  /// every dialog in the app reads as one consistent surface.
  Widget _header() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_LaneColors.navyLight, _LaneColors.navy],
        ),
      ),
      child: Stack(
        children: [
          const _GlossOverlay(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 14, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.report_gmailerrorred, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'DTC — Lane ${lane.laneNumber}',
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                    Obx(
                      () => IconButton(
                        icon: lane.isReadingDtc.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.refresh, size: 20, color: Colors.white70),
                        tooltip: 'Read DTCs from ECU',
                        onPressed: lane.isReadingDtc.value ? null : onRefresh,
                        splashRadius: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.white70),
                      onPressed: () => Get.back(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => Text(
                          '${lane.dtcReadResults.length} code${lane.dtcReadResults.length == 1 ? '' : 's'} found on ECU',
                          style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                        ),
                      ),
                    ),
                    Obx(() {
                      final disabled = lane.isReadingDtc.value || lane.dtcReadResults.isEmpty;
                      return Opacity(
                        opacity: disabled ? 0.45 : 1,
                        child: _clearDtcButton(disabled: disabled),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Clearing DTCs is destructive (wipes the ECU's stored fault
  /// history) — confirm before actually calling it, same as any
  /// "delete" action, rather than firing on a single accidental tap.
  Widget _clearDtcButton({required bool disabled}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(colors: [_LaneColors.red, Color(0xFF9E2E2E)]),
        boxShadow: _raisedShadow(_LaneColors.red, strength: 0.6),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: disabled
              ? null
              : () {
                  Get.defaultDialog(
                    title: 'Clear DTC?',
                    middleText: 'This will clear all fault codes stored on Lane ${lane.laneNumber}\'s ECU.',
                    textConfirm: 'Clear',
                    textCancel: 'Cancel',
                    confirmTextColor: Colors.white,
                    buttonColor: _LaneColors.red,
                    onConfirm: () {
                      Get.back();
                      onClearDtc();
                    },
                  );
                },
          child: Stack(
            children: [
              _GlossOverlay(borderRadius: BorderRadius.circular(20), opacity: 0.2),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.white),
                    SizedBox(width: 5),
                    Text('CLEAR DTC', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Success state — glossy green confirmation card instead of a bare
  /// icon + grey text, matching the Flash File confirmation chip look.
  Widget _emptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [_LaneColors.greenBg, _LaneColors.greenBg.withOpacity(0.6)],
          ),
          border: Border.all(color: _LaneColors.green),
          borderRadius: BorderRadius.circular(12),
          boxShadow: _raisedShadow(_LaneColors.green, strength: 0.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: _LaneColors.greenDark, size: 36),
            const SizedBox(height: 10),
            const Text(
              'No DTCs detected on this ECU.',
              style: TextStyle(color: _LaneColors.greenDark, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Tap refresh to read again.', style: TextStyle(color: _LaneColors.greenDark.withOpacity(0.7), fontSize: 11.5)),
          ],
        ),
      ),
    );
  }

  /// raw is "CODE - description (status)" — split it back apart for
  /// display. Red accent dot + tinted gradient card, matching the
  /// error-state language used across the lane card and other dialogs.
  Widget _dtcTile(String raw) {
    final splitIndex = raw.indexOf(' - ');
    final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
    var rest = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

    // The status ("Active", "Inactive", "Pending", etc.) comes through
    // as a trailing "(...)" on the description — pull it out so it can
    // be shown as its own small badge instead of buried in the text.
    String? statusLabel;
    final statusMatch = RegExp(r'\(([^()]+)\)\s*$').firstMatch(rest);
    if (statusMatch != null) {
      statusLabel = statusMatch.group(1);
      rest = rest.substring(0, statusMatch.start).trim();
    }

    final bool isActive = (statusLabel ?? '').toLowerCase().contains('active') &&
        !(statusLabel ?? '').toLowerCase().contains('inactive');
    final Color statusColor = isActive ? _LaneColors.red : _LaneColors.slate;
    final Color statusBg = isActive ? _LaneColors.redBg : _LaneColors.slateBg;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_LaneColors.redBg, _LaneColors.redBg.withOpacity(0.55)],
        ),
        border: Border.all(color: _LaneColors.red.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 9,
            height: 9,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _LaneColors.red,
              boxShadow: [BoxShadow(color: _LaneColors.red.withOpacity(0.5), blurRadius: 5)],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _LaneColors.red)),
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(rest, style: const TextStyle(fontSize: 12.5, color: Colors.black87)),
                ],
              ],
            ),
          ),
          if (statusLabel != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusBg,
                border: Border.all(color: statusColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.2),
              ),
            ),
          ],
        ],
      ),
    );
  }
}