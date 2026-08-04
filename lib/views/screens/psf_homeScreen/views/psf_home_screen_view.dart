import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import 'package:simpson/views/widget/psf_lane_card.dart';
import 'psf_top_lane_status_bar.dart';
import 'psf_lane_fullscreen_view.dart';
import '../controllers/psf_home_screen_controller.dart';

class _LaneColors {
  static const green = Color(0xFF2ECC71);
  static const red = Color(0xFFD64545);
  static const slateBg = Color(0xFFF7F8FA);
}

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
        BoxShadow(
            color: core.withOpacity(0.7), blurRadius: 6, spreadRadius: 0.4),
      ],
    ),
  );
}

Widget _statusPill({required Widget child}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.14)),
    ),
    child: child,
  );
}

class PsfHomeScreenView extends GetView<PsfHomeScreenController> {
  const PsfHomeScreenView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: controller.station ?? '',
        actions: [
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: InkWell(
                onTap: controller.onPlcButtonTapped,
                borderRadius: BorderRadius.circular(20),
                child: _statusPill(
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
                        _glowDot(controller.isPlcConnected.value
                            ? _LaneColors.green
                            : _LaneColors.red),
                      const SizedBox(width: 8),
                      Text(
                        controller.isPlcConnecting.value
                            ? 'Connecting…'
                            : 'PLC',
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
          ),
          Obx(
            () => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _statusPill(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _glowDot(controller.isDongleConnectedAnywhere
                        ? _LaneColors.green
                        : _LaneColors.red),
                    const SizedBox(width: 8),
                    const Text(
                      'Dongle',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: controller.logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: _LaneColors.slateBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PsfTopLaneStatusBar(controller: controller),
          Expanded(
            child: Obx(() {
              final expanded = controller.expandedLaneIndex.value;
              if (expanded != null) {
                return PsfLaneFullScreenView(
                  laneIndex: expanded,
                  lane: controller.lanes[expanded],
                  controller: controller,
                );
              }
              return _buildLaneGrid();
            }),
          ),
        ],
      ),
    );
  }

  /// The original grid view — unchanged from before, just pulled out
  /// into its own method so it can be swapped in/out by the Obx above
  /// depending on whether a lane is currently expanded full-screen.
  Widget _buildLaneGrid() {
    return Padding(
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
            const int slotsPerScreen = 5;
            const double spacing = 16;
            final double cardWidth =
                (constraints.maxWidth - spacing * (slotsPerScreen - 1)) /
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
    );
  }
}