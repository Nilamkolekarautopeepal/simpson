import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import 'package:simpson/views/widget/psf_lane_card.dart';

import '../controllers/psf_home_screen_controller.dart';

/// Lanes are built dynamically — one per dongle from the login
/// response, each pre-wired to a specific ECU id. ESN and List
/// Number are both scanned per-lane now (see PsfLaneCard), each
/// validated against that lane's pre-wired expected ECU id.
class PsfHomeScreenView extends GetView<PsfHomeScreenController> {
  const PsfHomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: controller.station??'',
        actions: [
          Obx(
            () => InkWell(
              onTap: controller.onPlcButtonTapped,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.isPlcConnecting.value)
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.6, color: Colors.white),
                      )
                    else
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: controller.isPlcConnected.value
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      controller.isPlcConnecting.value ? 'Connecting…' : 'PLC ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: controller.isDongleConnectedAnywhere
                          ? Colors.greenAccent
                          : Colors.redAccent,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Dongle ',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Obx(() {
                final laneCount = controller.lanes.length;
                if (laneCount == 0) {
                  return const Center(
                    child: Text(
                      'No dongles found for this station from login data.',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }
                return LayoutBuilder(
                  builder: (context, constraints) {
                    // Boxes are always sized as if 5 fit on screen —
                    // if there are fewer lanes (e.g. 2, from a
                    // 2-dongle station), they stay that same fixed
                    // width and the rest of the screen is left blank
                    // rather than stretching to fill it. Horizontal
                    // scroll only kicks in once there are more than 5.
                    const int slotsPerScreen = 5;
                    const double spacing = 16;
                    final double cardWidth = (constraints.maxWidth -
                            spacing * (slotsPerScreen - 1)) /
                        slotsPerScreen;
                    final double cardHeight = constraints.maxHeight;

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(laneCount, (i) {
                          return Padding(
                            padding: EdgeInsets.only(
                                right: i == laneCount - 1 ? 0 : spacing),
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
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
