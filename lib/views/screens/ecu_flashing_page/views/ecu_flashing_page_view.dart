import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/routes/app_pages.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/views/screens/homePage/controllers/home_page_controller.dart';


class EcuFlashingPage extends GetView<HomePageController> {
  const EcuFlashingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        title: const Text('ECU Flashing'),
        backgroundColor: AppColors.themeColor,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: Obx(() {
          // Block manual back while actively flashing.
          if (controller.flashInProgress.value) return const SizedBox.shrink();
          return IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () =>Get.offAllNamed(Routes.HOME_PAGE),
          );
        }),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Obx(() => _buildBody()),
        ),
      ),
    );
  }

  Widget _buildBody() {
    // ── Error state ──
    if (controller.flashErrorMessage.value.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 48),
          const SizedBox(height: 16),
          Text(
            'Flashing Failed',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            controller.flashErrorMessage.value,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.themeColor,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
            ),
            child: const Text('Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    }

    // ── Success state — flash done, loading DTC/PID before navigating back ──
    if (controller.flashComplete.value) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (controller.selectedFlashFile.value != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                controller.selectedFlashFile.value!,
                textAlign: TextAlign.center,
                style:
                    TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
              ),
            ),
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.themeColor,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 12),
          const Text(
            'Flashing successful',
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87),
          ),
          const SizedBox(height: 20),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
         // const SizedBox(height: 10),
          // Text(
          //   'Loading DTC & PID data...',
          //   style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
          // ),
        ],
      );
    }

    // ── In-progress state — same UI you had inline on Home ──
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (controller.selectedFlashFile.value != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              controller.selectedFlashFile.value!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
            ),
          ),
        Text(
          controller.formattedElapsed,
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: 260,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: controller.flashProgress.value,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.themeColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(controller.flashProgress.value * 100).round()}%',
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}