import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';

class _StationColors {
  static const teal = Color(0xFF0E6E6E);
  static const tealLight = Color(0xFF1B9494);
  static const charcoal = Color.fromRGBO(3, 60, 98, 1);
  static const green = Color(0xFF2ECC71);
  static const red = Color(0xFFD64545);
}

Widget _glowDot(Color core, {double size = 10}) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        center: const Alignment(-0.3, -0.3),
        colors: [Colors.white.withValues(alpha: 0.85), core, core],
        stops: const [0.0, 0.35, 1.0],
      ),
      boxShadow: [
        BoxShadow(
            color: core.withValues(alpha: 0.7), blurRadius: 6, spreadRadius: 0.4),
      ],
    ),
  );
}

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
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3)),
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

      final reconnecting = lane.isReconnectingAfterFlash.value;

      // The dot is purely this lane's OWN dongle connection state —
      // green if connected (or actively flashing/reconnecting right
      // after a flash — both are expected, not real failures), red
      // only for a genuine unexpected disconnect.
      final Color dotColor = (lane.dongleConnected.value || flashing || reconnecting) ? _StationColors.green : _StationColors.red;

      String subLabel;
      Color subLabelColor;
      if (reconnecting) {
        subLabel = 'Finishing up...';
        subLabelColor = Colors.white;
      } else if (flashing) {
        subLabel = 'Flashing... ${(lane.flashProgress.value * 100).round()}%';
        subLabelColor = Colors.white;
      } else if (failed) {
        subLabel = 'Failed';
        subLabelColor = Colors.white;
      } else if (completed) {
        subLabel = 'Flash Successful';
        subLabelColor = Colors.white;
      } else if (lane.dongleConnected.value) {
        subLabel = lane.esn.value.isEmpty ? 'Ready' : 'Idle';
        subLabelColor = Colors.white;
      } else {
        subLabel = 'Offline';
        subLabelColor = Colors.white;
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
              color: isExpanded
                  ? _StationColors.teal
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: isExpanded
                      ? _StationColors.tealLight
                      : Colors.white.withValues(alpha: 0.12)),
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
                        color: isExpanded
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.9),
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
              ],
            ),
          ),
        ),
      );
    });
  }
}
