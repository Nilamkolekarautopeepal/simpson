import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';

class _StationColors {
  static const teal = Color(0xFF1F4D59);
  static const tealLight = Color(0xFF2C6478);
  static const charcoal = Color(0xFF16232C);
  static const green = Color(0xFF2ECC71);
  static const red = Color(0xFFD64545);
   static const slateBg = Color(0xFF1B333D);
    static const slateBorder = Color(0xFF345A66);
  
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
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _StationColors.teal,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
            child: Obx(
        () => ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
              PointerDeviceKind.trackpad,
            },
          ),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: controller.lanes.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _laneChip(i),
          ),
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

      final Color dotColor = (lane.dongleConnected.value || flashing || reconnecting) ? _StationColors.green : _StationColors.red;

      String subLabel;
      Color subLabelColor;
      if (reconnecting) {
        subLabel = 'Finishing up...';
        subLabelColor = Colors.white;
        print(  'Lane $index is reconnecting after flash, showing "Finishing up..."');
      } else if (flashing) {
        subLabel = 'Flashing... ${(lane.flashProgress.value * 100).round()}%';
        subLabelColor = Colors.white;
        print(  'Lane $index is flashing, showing progress: ${subLabel}');
      } else if (failed) {
        subLabel = 'Failed';
        print('Failed lane ${lane.laneNumber}');
        subLabelColor = Colors.white;
        print(  'Lane $index has failed, showing "Failed"');
      } else if (completed) {
        subLabel = 'Flash Successful';
        print('Completed lane ${lane.laneNumber}');
        subLabelColor = Colors.white;
        print(  'Lane $index has completed successfully, showing "Flash Successful"');
      } else if (lane.dongleConnected.value) {
        subLabel = lane.esn.value.isEmpty ? 'Ready' : 'Idle';
        subLabelColor = Colors.white;
        print(  'Lane $index is connected and idle, showing "${subLabel}"');
      } else {
        subLabel = 'Offline';
        subLabelColor = Colors.white;
        print(  'Lane $index is offline, showing "Offline"');
      }

             return Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => controller.expandLane(index),
          child: Container(
            width: 190,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isExpanded
                  ? _StationColors.tealLight
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isExpanded
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.12),
                  width: isExpanded ? 1.5 : 1),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${lane.laneNumber}. ${lane.ecuModelName.value.isEmpty ? "ECU MODEL NAME" : lane.ecuModelName.value}',
                        textAlign: TextAlign.start,
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
                        textAlign: TextAlign.start,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          height: 1.0,
                          color: isExpanded ? Colors.white70 : Colors.white38,
                        ),
                      ),
                    ],
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
