import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import 'package:simpson/views/widget/psf_lane_card.dart';

import '../controllers/psf_home_screen_controller.dart';

class PsfHomeScreenView extends GetView<PsfHomeScreenController> {
  const PsfHomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: controller.station,
        actions: [
          Obx(
            () => TextButton.icon(
              onPressed: controller.onPlcButtonTapped,
              icon: Icon(
                Icons.circle,
                size: 10,
                color: controller.isPlcConnected.value ? Colors.greenAccent : Colors.redAccent,
              ),
              label: Text(
                controller.isPlcConnected.value ? 'PLC Connected' : 'Connect PLC',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.12),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: controller.logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F5F7),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _esnScanBar(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  const int visibleLaneCount = 3; // bigger cards, 3 per screen
                  const double spacing = 16;
                  final double cardWidth =
                      (constraints.maxWidth - spacing * (visibleLaneCount - 1)) / visibleLaneCount;
                  final double cardHeight = constraints.maxHeight;

                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(PsfHomeScreenController.laneCount, (i) {
                        return Padding(
                          padding: EdgeInsets.only(right: i == PsfHomeScreenController.laneCount - 1 ? 0 : spacing),
                          child: PsfLaneCard(
                            laneIndex: i,
                            lane: controller.lanes[i],
                            controller: controller,
                            width: cardWidth,
                            height: cardHeight,
                          ),
                        );
                      }),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _esnScanBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 300,
            child: TextField(
              controller: controller.esnController,
              decoration: const InputDecoration(
                hintText: 'Scan or enter ESN',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => controller.onScanEsn(),
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: controller.isLookingUpEsn.value ? null : controller.onScanEsn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF003874), // matches AppColors.themeColor
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFF003874).withOpacity(0.5),
                  disabledForegroundColor: Colors.white70,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
                child: controller.isLookingUpEsn.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('IDENTIFY MODEL', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Obx(
            () => controller.currentTargetLane.value != null
                ? TextButton(
                    onPressed: controller.resetForNextEsn,
                    child: const Text('RESET / NEXT ENGINE', style: TextStyle(fontWeight: FontWeight.w800)),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 12),
          Obx(
            () => controller.esnError.value.isEmpty
                ? const SizedBox.shrink()
                : Expanded(
                    child: Text(controller.esnError.value, style: const TextStyle(fontSize: 12, color: Colors.red)),
                  ),
          ),
        ],
      ),
    );
  }
}
