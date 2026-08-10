import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';
import 'package:simpson/views/screens/psf_homeScreen/views/psf_session_history_screen.dart';

//

/// Fresh accent for the full-screen views — deliberately distinct from
/// the lane card's navy so this reads as its own "station" surface,
/// while still sitting comfortably next to it. Status semantics
/// (green/red/amber) stay the same everywhere in the app on purpose —
/// changing what green/red MEAN between screens would be confusing.
class _StationColors {
  static const teal = Color(0xFF0E6E6E);
  static const tealLight = Color(0xFF1B9494);
  static const tealBg = Color(0xFFE8F5F5);
  static const charcoal = Color.fromRGBO(3, 60, 98, 1);
  static const green = Color(0xFF2ECC71);
  static const greenDark = Color(0xFF1B7A3E);
  static const amber = Color(0xFFB9770E);
  static const red = Color(0xFFD64545);
  static const redBg = Color(0xFFFDEDED);
}

/// Same _glowDot look as the app bar's Dongle pill — a radial-gradient
/// glowing bead rather than a flat circle. Dart's privacy is
/// per-file, so this can't just be imported from
/// psf_home_screen_view.dart — kept identical here on purpose so both
/// dots read as the exact same visual "dongle status" language.
Widget _glowDot(Color core, {double size = 10}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white.withOpacity(0.85), core, core],
        stops: const [0.0, 0.35, 1.0],
      ),
      boxShadow: [
        BoxShadow(color: core.withOpacity(0.7), blurRadius: 6, spreadRadius: 0.4),
      ],
    ),
  );
}

/// Persistent strip across the top of the whole station screen — every
/// lane always shows here, however many are configured, regardless of
/// whether one of them is currently open full-screen. This is what
/// lets an operator glance up and know "Lane 2 is still flashing" even
/// while looking at Lane 1's full detail view.
class PsfTopLaneStatusBar extends StatelessWidget {
  const PsfTopLaneStatusBar({super.key, required this.controller});

  final PsfHomeScreenController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      decoration: BoxDecoration(
        color: _StationColors.charcoal,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Obx(
        () => ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          itemCount: controller.lanes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => _laneChip(i),
        ),
      ),
    );
  }

  Widget _laneChip(int index) {
    final lane = controller.lanes[index];

    return Obx(() {
      final isExpanded = controller.expandedLaneIndex.value == index;
      final flashing = lane.isFlashing.value;
      final failed = lane.flashStatus.value.startsWith('Flash Failed');
      final completed = lane.flashStatus.value == 'Flash Completed';
     // While flashing, the connection is deliberately handed off to
      // the flash isolate's own separate socket — dongleConnected
      // genuinely goes false during that window even though the
      // dongle is working fine. Treat "flashing" as "connected" here
      // so the dot doesn't falsely alarm during normal operation.
      final Color dotColor = (lane.dongleConnected.value || lane.isFlashing.value)
          ? _StationColors.green
          : _StationColors.red;

      String subLabel;
      if (flashing) {
        subLabel = 'Flashing... ${(lane.flashProgress.value * 100).round()}%';
      } else if (failed) {
        subLabel = 'Failed';
      } else if (completed) {
        subLabel = 'Flash Successful';
      } else if (lane.dongleConnected.value) {
        subLabel = lane.esn.value.isEmpty ? 'Ready' : 'Idle';
      } else {
        subLabel = 'Offline';
      }

      return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
       onTap: () => controller.expandLane(index),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isExpanded ? _StationColors.teal : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: isExpanded ? _StationColors.tealLight : Colors.white.withOpacity(0.12)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
              GestureDetector(
                  onTap: () => controller.reconnectDongleWithFeedback(index),
                  behavior: HitTestBehavior.opaque,
                  child: _glowDot(dotColor, size: 10),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${lane.laneNumber}. ${lane.ecuModelName.value.isEmpty ? "ECU MODEL NAME" : lane.ecuModelName.value}',
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        color: isExpanded ? Colors.white : Colors.white.withOpacity(0.9),
                      ),
                    ),
                    Text(
                      subLabel,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        height: 1.0,
                        color: isExpanded ? Colors.white70 : Colors.white38,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => PsfSessionHistoryScreen.show(lane),
                  borderRadius: BorderRadius.circular(14),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.more_vert, size: 16, color: Colors.white70),
                  ),
                ),
              ],
            ),
              
            ),
          ),
  
      );
    });
  }
}