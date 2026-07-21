
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import 'package:simpson/dev/dev_screen.dart';
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/themes/app_colors.dart';
import '../controllers/home_page_controller.dart';
// StepType is exported from home_page_controller.dart

class HomePageView extends GetView<HomePageController> {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: controller.station,
        actions: [
          Obx(
            () => InkWell(
              onTap: controller.retryPlcConnection,
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
                      controller.isPlcConnecting.value
                          ? 'Connecting…'
                          : (controller.isPlcConnected.value ? 'PLC ' : 'PLC '),
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
          Obx(() {
            if (!controller.canConnectDongle.value) {
              return const SizedBox.shrink();
            }
            return InkWell(
              onTap: controller.retryDongleConnection,
              borderRadius: BorderRadius.circular(6),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (controller.dongleConnecting.value)
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
                          color: controller.dongleConnected.value
                              ? Colors.greenAccent
                              : Colors.redAccent,
                        ),
                      ),
                    const SizedBox(width: 8),
                    Text(
                      controller.dongleConnecting.value
                          ? 'Connecting…'
                          : 'Dongle ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: controller.logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      backgroundColor: const Color(0xFFF4F5F7),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSidebar(),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 230,
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Obx(
              () {
                final visibleCount = (controller.currentStepIndex.value + 1)
                    .clamp(0, controller.steps.length);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleCount,
                  itemBuilder: (context, index) {
                    final step = controller.steps[index];
                    if (step.type == StepType.iqaGroup) {
                      return _buildIqaGroupTile(index, context);
                    }
                    return _buildStepTile(index, context);
                  },
                );
              },
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => _showRecipeDialog(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.list_alt, size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Text(
                    'Recipe',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => controller.harnessReceipes.isEmpty
                        ? const SizedBox.shrink()
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.themeColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.harnessReceipes.length}',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.themeColor),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          InkWell(
            onTap: () => Get.to(() => const DevLogsPage()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(Icons.bug_report_outlined,
                      size: 18, color: Colors.grey.shade700),
                  const SizedBox(width: 10),
                  Text(
                    'API Logs',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(int index, BuildContext context) {
    final step = controller.steps[index];
    final isCompleted = index < controller.currentStepIndex.value;
    final isActive = index == controller.currentStepIndex.value;

    int? maxLen;
    if (step.key == 'list') {
      maxLen = 4;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color:
                    isCompleted ? AppColors.themeColor : AppColors.themeColor,
              ),
              const SizedBox(width: 6),
              Text(
                step.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: TextSelectionThemeData(
                selectionColor: Colors.blueAccent[100],
                selectionHandleColor: AppColors.themeColor,
              ),
            ),
            child: TextField(
              cursorColor: AppColors.themeColor,
              controller: controller.stepControllers[index],
              focusNode: controller.stepFocusNodes[index],
              enabled: true,
              maxLength: maxLen,
              keyboardType: maxLen != null ? TextInputType.number : null,
              inputFormatters: maxLen != null
                  ? [FilteringTextInputFormatter.digitsOnly]
                  : null,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor:
                    isCompleted ? Colors.green.withOpacity(0.06) : Colors.white,
                counterText: maxLen != null ? '' : null,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: AppColors.themeColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      BorderSide(color: AppColors.themeColor, width: 1.5),
                ),
                hintText: isActive
                    ? (maxLen != null
                        ? 'Scan or enter ${step.label} ($maxLen digits)'
                        : 'Scan or enter ${step.label}')
                    : '',
              ),
              onChanged: (_) => controller.onFieldChanged(index),
              onSubmitted: (_) => controller.submitStep(index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIqaGroupTile(
    int index,
    BuildContext context,
  ) {
    final isActive = index == controller.currentStepIndex.value;
    final isCompleted = index < controller.currentStepIndex.value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 16,
                color: AppColors.themeColor,
              ),
              const SizedBox(width: 6),
              Text(
                'IQA',
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: Colors.black87,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...List.generate(controller.iqaLabels.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.iqaLabels[i],
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 2),
                  Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.tab) {
                        controller.submitIqaField(i);
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: Theme(
                      data: Theme.of(context).copyWith(
                        textSelectionTheme: TextSelectionThemeData(
                          selectionColor: Colors.blueAccent[100],
                          selectionHandleColor: AppColors.themeColor,
                        ),
                      ),
                      child: TextField(
                        cursorColor: AppColors.themeColor,
                        controller: controller.iqaControllers[i],
                        focusNode: controller.iqaFocusNodes[i],
                        enabled: true,
                        maxLength: 7,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(color: AppColors.themeColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                                color: AppColors.themeColor, width: 1.5),
                          ),
                          hintText: 'Scan ${controller.iqaLabels[i]}',
                        ),
                        onChanged: (_) => controller.onIqaFieldChanged(i),
                        onSubmitted: (_) => controller.submitIqaField(i),
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

  Widget _buildMainContent() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Obx(() {
                  if (!controller.allStepsComplete) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFlashSection(),
                      const SizedBox(height: 16),
                      // ── DTC section is now ALWAYS shown once scan steps
                      // are complete — no longer gated behind
                      // flashComplete. It's populated either by a
                      // completed flash OR by the standalone "Read DTCs"
                      // button in its header (no flashing required for
                      // the latter). The section itself shows "No data
                      // yet" until either path populates dtcList.
                      _buildDtcSection(),
                      if (controller.flashComplete.value) ...[
                        const SizedBox(height: 12),
                        _buildPidSection(),
                      ],
                    ],
                  );
                }),
              ],
            ),
          ),
        ),
        _buildActivitySection(),
      ],
    );
  }

  /// Recipe popup: static reference table straight from the harness
  /// data (sensor_name / reg_address / type / pin_no / value / unit),
  /// which now comes from the matched variant's prodbud_variant_harness
  /// (see _isValidHarness in the controller) rather than a separate
  /// harness API. A sensor's VALUE only ever changes from the static
  /// value once the operator uses the WRITE action on that row — there
  /// is no automatic PLC read here.
  void _showRecipeDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: SizedBox(
          width: 860,
          height: 520,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Recipe',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 10),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.harnessReceipes.length} sensor${controller.harnessReceipes.length == 1 ? '' : 's'}',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.themeColor),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => ElevatedButton.icon(
                        onPressed: controller.isReadingPlcValues.value
                            ? null
                            : controller.readAllSensorValues,
                        icon: controller.isReadingPlcValues.value
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download, size: 16),
                        label: Text(controller.isReadingPlcValues.value
                            ? 'Reading…'
                            : 'Write Values'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          textStyle: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon:
                          const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => Get.back(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.harnessReceipes.isEmpty) {
                      return Center(
                        child: Text(
                          'No recipe data yet — scan a harness first.',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }
                    return SingleChildScrollView(child: _buildRecipeTable());
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecipeTable() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7FA),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text('SENSOR NAME',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('REG. ADDRESS',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('TYPE',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('PIN NO',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 2,
                    child: Text('VALUE',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 1,
                    child: Text('UNIT',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
                Expanded(
                    flex: 3,
                    child: Text('WRITE',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          const SizedBox(height: 4),
          ...controller.harnessReceipes.map((sensor) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      sensor.sensorName ?? '-',
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${sensor.regAddress ?? '-'}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          sensor.type ?? '-',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${sensor.pinNo ?? '-'}',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Obx(() {
                      final live = sensor.id != null
                          ? controller.livePlcValues[sensor.id]
                          : null;
                      final display = live ?? '-';
                      final isLive = live != null && live != 'ERR';
                      return Text(
                        display,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: live == 'ERR'
                              ? Colors.red
                              : (isLive
                                  ? AppColors.themeColor
                                  : Colors.grey.shade500),
                        ),
                      );
                    }),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      sensor.unit ?? '-',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: _SensorWriteAction(
                      sensor: sensor,
                      controller: controller,
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

  Widget _buildFlashSection() {
    return Obx(() {
      final expanded = controller.flashExpanded.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: controller.toggleFlash,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Text('Flash File',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Obx(() {
                      if (controller.flashComplete.value) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Column(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: AppColors.themeColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Flashing Successful',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.themeColor,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        );
                      }

                      if (controller.flashInProgress.value) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Obx(() {
                            final pct =
                                (controller.flashProgress.value * 100).round();
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.themeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '$pct%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.themeColor,
                                ),
                              ),
                            );
                          }),
                        );
                      }

                      return const SizedBox.shrink();
                    }),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildFlashBody(),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildFlashBody() {
    return Obx(() {
      // ── Error state ──
      if (controller.flashErrorMessage.value.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close_rounded,
                    color: Colors.red.shade400, size: 30),
              ),
              const SizedBox(height: 18),
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
              const SizedBox(height: 20),
              if (controller.selectedFlashFile.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    controller.selectedFlashFile.value!,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ),
              ElevatedButton(
                onPressed: controller.dongleConnected.value
                    ? controller.startFlashing
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.themeColor,
                  disabledBackgroundColor: Colors.grey.shade300,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Start Flashing',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!controller.dongleConnected.value) ...[
                const SizedBox(height: 10),
                Text(
                  'Waiting for the dongle to reconnect…',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(fontSize: 11.5, color: Colors.orange.shade800),
                ),
              ],
            ],
          ),
        );
      }

      // ── Success state ──
      if (controller.flashComplete.value && !controller.flashInProgress.value) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (controller.selectedFlashFile.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    controller.selectedFlashFile.value!,
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                  ),
                ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: AppColors.themeColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Flashing successful',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
              ),
              const SizedBox(height: 6),
              Text(
                'Completed in ${controller.formattedElapsed}',
                style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
              ),
            ],
          ),
        );
      }

      // ── In-progress state ──
      if (controller.flashInProgress.value) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.themeColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColors.themeColor),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Obx(
              () => Text(
                controller.flashStatus.value,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Obx(() {
              String message = 'Please keep the dongle connected';

              switch (controller.flashStatus.value) {
                case 'Writing IQA Values...':
                  message = 'Writing injector calibration values...';
                  break;
                case 'Loading DTCs...':
                  message = 'Reading Diagnostic Trouble Codes...';
                  break;
                case 'Loading PIDs...':
                  message = 'Reading Live Parameters...';
                  break;
                case 'Completed':
                  message = 'Almost done...';
                  break;
              }

              return Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              );
            }),
            const SizedBox(height: 20),
            if (controller.selectedFlashFile.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  controller.selectedFlashFile.value!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: AppColors.themeColor,
                      fontWeight: FontWeight.bold),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    'Elapsed  ${controller.formattedElapsed}',
                    style:
                        TextStyle(fontSize: 12.5, color: Colors.grey.shade700),
                  ),
                ),
                Obx(
                  () => Text(
                    '${(controller.flashProgress.value * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.themeColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(
              () => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: controller.flashProgress.value,
                  minHeight: 12,
                  backgroundColor: Colors.grey.shade200,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppColors.themeColor),
                ),
              ),
            ),
          ],
        );
      }

      // ── File selection state ──
      if (controller.flashFilesLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        );
      }

      if (controller.flashFilesError.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            controller.flashFilesError.value,
            style: TextStyle(color: Colors.red.shade700, fontSize: 12.5),
          ),
        );
      }

      if (controller.availableFlashFiles.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No flash files available',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!controller.dongleConnected.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Waiting for the dongle to connect automatically…',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 260),
            child: ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: controller.availableFlashFiles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final file = controller.availableFlashFiles[index];
                final isSelected = controller.selectedFlashFile.value == file;

                return GestureDetector(
                  onTap: () => controller.selectFlashFile(file),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.themeColor
                            : Colors.grey.shade300,
                        width: isSelected ? 1.5 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        file,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      trailing: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppColors.themeColor
                              : Colors.transparent,
                          border: Border.all(
                            color: AppColors.themeColor,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton(
              onPressed: (controller.selectedFlashFile.value != null &&
                      controller.dongleConnected.value)
                  ? controller.startFlashing
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                disabledBackgroundColor: Colors.grey.shade300,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Flashing',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    });
  }

  Widget _buildDtcSection() {
    return Obx(
      () => _buildExpandableSection(
        title: 'DTC',
        expanded: controller.dtcExpanded.value,
        onTap: controller.toggleDtc,
        trailingLabel: 'Count: ${controller.dtcCount}',
        items: controller.dtcList,
        itemBuilder: _buildDtcCard,
        onRefresh: controller.refreshDtcResults,
        onClear: controller.clearDTC,
        // ── Standalone "Read DTCs" action — calls the SAME logic that
        // populates dtcList after a successful flash (_loadDtcResults),
        // but no flashing happens here at all. Requires the dongle to
        // be connected and a flash file selected (so the correct DTC
        // dataset is known) — see readDtcsManually() in the controller.
        extraAction: Obx(() {
          final busy = controller.isReadingDtcManually.value;
          final canRead = controller.dongleConnected.value && !busy;
          return InkWell(
            borderRadius: BorderRadius.circular(6),
            onTap: canRead ? controller.readDtcsManually : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: canRead ? AppColors.themeColor : Colors.grey.shade300,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.6),
                    )
                  else
                    Icon(
                      Icons.search,
                      size: 14,
                      color:
                          canRead ? AppColors.themeColor : Colors.grey.shade400,
                    ),
                  const SizedBox(width: 5),
                  Text(
                    busy ? 'Reading…' : 'Read DTCs',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color:
                          canRead ? AppColors.themeColor : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDtcCard(String raw) {
    String code = raw;
    String description = '';
    String status = '';

    final statusMatch = RegExp(r'\(([^()]*)\)\s*$').firstMatch(raw);
    String withoutStatus = raw;
    if (statusMatch != null) {
      status = statusMatch.group(1)?.trim() ?? '';
      withoutStatus = raw.substring(0, statusMatch.start).trim();
    }

    final splitIndex = withoutStatus.indexOf(' - ');
    code = splitIndex == -1
        ? withoutStatus
        : withoutStatus.substring(0, splitIndex).trim();
    description =
        splitIndex == -1 ? '' : withoutStatus.substring(splitIndex + 3).trim();

    final statusLower = status.toLowerCase();
    Color badgeColor;
    String badgeLabel;
    if (statusLower == 'active' || statusLower == 'current') {
      badgeColor = Colors.red.shade600;
      badgeLabel = 'Active';
    } else if (statusLower == 'pending') {
      badgeColor = Colors.orange.shade700;
      badgeLabel = 'Pending';
    } else if (statusLower == 'inactive') {
      badgeColor = Colors.green.shade600;
      badgeLabel = 'InActive';
    } 
    else {
      badgeColor = Colors.green.shade600;
      badgeLabel = status.isNotEmpty ? 'History' : '-';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  code,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: Colors.black87,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style:
                        TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
                  ),
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
              border: Border.all(color: badgeColor.withOpacity(0.4)),
            ),
            child: Text(
              badgeLabel,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.bold,
                color: badgeColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPidSection() {
    return Obx(() {
      final expanded = controller.pidExpanded.value;

      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: controller.togglePid,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    const Text('PID',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Obx(() {
                      final playing = controller.pidPlaying.value;
                      return ElevatedButton.icon(
                        onPressed: controller.togglePidPlayback,
                        icon: Icon(
                          playing
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                        label: Text(playing ? 'Stop' : 'Run',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: playing
                              ? Colors.red.shade600
                              : AppColors.themeColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more),
                  ],
                ),
              ),
            ),
            if (expanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Obx(() {
                  if (controller.livePidCodes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text('No data yet',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 13)),
                    );
                  }

                  final codes = controller.livePidCodes;
                  final isPlaying = controller.pidPlaying.value;

                  final list = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(codes.length, (index) {
                      final code = codes[index];
                      final variable = code.piCodeVariable?.firstOrNull;
                      final label = variable?.longName ??
                          variable?.shortName ??
                          code.shortName ??
                          code.code ??
                          'PID';
                      final liveValue = variable?.id != null
                          ? controller.livePidValues[variable!.id]
                          : null;
                      final unit = variable?.unit ?? '';
                      final isError = liveValue != null &&
                          (liveValue == 'Not Found' ||
                              liveValue.toString().contains('ERROR'));

                      final row = Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade800,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              liveValue != null
                                  ? '$liveValue ${unit.isNotEmpty ? unit : ''}'
                                      .trim()
                                  : '—',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: liveValue == null
                                    ? Colors.grey.shade400
                                    : (isError
                                        ? Colors.red
                                        : AppColors.themeColor),
                              ),
                            ),
                          ],
                        ),
                      );

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          row,
                          if (index != codes.length - 1)
                            Divider(
                              height: 1,
                              thickness: 1,
                              color: Colors.grey.shade100,
                            ),
                        ],
                      );
                    }),
                  );

                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Opacity(
                        opacity: isPlaying ? 0.35 : 1.0,
                        child: IgnorePointer(
                          ignoring: isPlaying,
                          child: list,
                        ),
                      ),
                      if (isPlaying)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.themeColor),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Reading live parameters...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                }),
              ),
          ],
        ),
      );
    });
  }

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required String? trailingLabel,
    required List<String> items,
    Widget Function(String item)? itemBuilder,
    VoidCallback? onRefresh,
    VoidCallback? onClear,
    Widget? extraAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
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
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (trailingLabel != null) ...[
                    const SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.themeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trailingLabel,
                        style: TextStyle(
                            fontSize: 12, color: AppColors.themeColor),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (extraAction != null) extraAction,
                  if (onRefresh != null) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onRefresh,
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.refresh,
                          size: 18,
                          color: AppColors.themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (onClear != null) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: onClear,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.themeColor),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.themeColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(expanded ? Icons.expand_less : Icons.expand_more),
                ],
              ),
            ),
          ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: items.isEmpty
                  ? Text(
                      'No data yet',
                      style:
                          TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    )
                  : (itemBuilder != null
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children:
                              items.map((item) => itemBuilder(item)).toList(),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: items
                              .map((item) => Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Text('• $item',
                                        style: const TextStyle(fontSize: 13)),
                                  ))
                              .toList(),
                        )),
            ),
        ],
      ),
    );
  }

  void _copyActivityLog() {
    final text = controller.activityLog.join('\n');
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied',
      '${controller.activityLog.length} log line${controller.activityLog.length == 1 ? '' : 's'} copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.themeColor,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
    );
  }

  Color _activityLogColor(String entry) {
    final lower = entry.toLowerCase();

    if (entry.contains('❌') ||
        lower.contains('failed') ||
        lower.contains('error') ||
        lower.contains('mismatch') ||
        lower.contains('not recognized') ||
        lower.contains('not found')) {
      return Colors.red.shade700;
    }

    if (entry.contains('✅') ||
        lower.contains('successful') ||
        lower.contains('success') ||
        lower.contains('connected') ||
        lower.contains('complete')) {
      return Colors.green.shade700;
    }

    return Colors.grey.shade700;
  }

//   Widget _buildActivitySection() {
//     return Container(
//       constraints: const BoxConstraints(maxHeight: 180),
//       margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(10),
//         border: Border.all(color: Colors.grey.shade300),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.04),
//             blurRadius: 8,
//             offset: const Offset(0, -2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               const Text('Activity',
//                   style: TextStyle(fontWeight: FontWeight.w600)),
//               const Spacer(),
//               Obx(() => IconButton(
//                     icon: const Icon(Icons.save_alt, size: 18),
//                     tooltip: "Save Activity Log",
//                     color: AppColors.themeColor,
//                     onPressed: controller.activityLog.isEmpty
//                         ? null
//                         : () async {
//                             await controller.saveActivityLog();
//                           },
//                   )),
//               Obx(
//                 () => IconButton(
//                   icon: const Icon(Icons.copy, size: 18),
//                   color: AppColors.themeColor,
//                   tooltip: 'Copy all activity log',
//                   visualDensity: VisualDensity.compact,
//                   onPressed: controller.activityLog.isEmpty
//                       ? null
//                       : () => _copyActivityLog(),
//                 ),
//               ),
//             ],
//           ),
//           const Divider(height: 16),
//           Expanded(
//             child: Obx(
//               () => ListView(
//                 padding: EdgeInsets.zero,
//                 children: controller.activityLog
//                     .map((entry) => Padding(
//                           padding: const EdgeInsets.symmetric(vertical: 3),
//                           child: Text(
//                             entry,
//                             style: TextStyle(
//                                 fontSize: 12.5, color: Colors.grey.shade700),
//                           ),
//                         ))
//                     .toList(),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ══════════════════════════════════════════════════════════════════════
// Additions to HomePageView (home_page_view.dart)
// ══════════════════════════════════════════════════════════════════════

// ── 1) Add a "fullscreen" IconButton to _buildActivitySection()'s header
//    row, right before the existing Save/Copy buttons.
//
// BEFORE:
//
//   Row(
//     children: [
//       const Text('Activity',
//           style: TextStyle(fontWeight: FontWeight.w600)),
//       const Spacer(),
//       Obx(() => IconButton(
//             icon: const Icon(Icons.save_alt, size: 18),
//             ...
//
// AFTER — add the fullscreen button right after the Spacer, before Save:

  Widget _buildActivitySection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 180),
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Activity',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const Spacer(),
              // ── NEW: open the full activity log in a full-screen dialog ──
              IconButton(
                icon: const Icon(Icons.fullscreen, size: 20),
                color: AppColors.themeColor,
                tooltip: 'Open full screen',
                visualDensity: VisualDensity.compact,
                onPressed: _showActivityFullScreen,
              ),
              Obx(() => IconButton(
                    icon: const Icon(Icons.save_alt, size: 18),
                    tooltip: "Save Activity Log",
                    color: AppColors.themeColor,
                    onPressed: controller.activityLog.isEmpty
                        ? null
                        : () async {
                            await controller.saveActivityLog();
                          },
                  )),
              Obx(
                () => IconButton(
                  icon: const Icon(Icons.copy, size: 18),
                 color: AppColors.themeColor,
                  tooltip: 'Copy all activity log',
                  visualDensity: VisualDensity.compact,
                  onPressed: controller.activityLog.isEmpty
                      ? null
                      : () => _copyActivityLog(),
                ),
              ),
            ],
          ),
          const Divider(height: 16),
          Expanded(
            child: Obx(
              () => ListView(
                padding: EdgeInsets.zero,
                children: controller.activityLog
                    .map((entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            entry,
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade700),
                          ),
                        ))
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }


  void _showActivityFullScreen() {
    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
             iconTheme: const IconThemeData(
    color: Colors.white, // Back arrow color
  ),
            backgroundColor: AppColors.themeColor,
            foregroundColor: Colors.white,
            title: const Text('Activity Log'),
            actions: [
              Obx(() => IconButton(
                    icon: const Icon(Icons.save_alt,color:Colors.white),
                    tooltip: 'Save Activity Log',
                    onPressed: controller.activityLog.isEmpty
                        ? null
                        : () async {
                            await controller.saveActivityLog();
                          },
                  )),
              Obx(() => IconButton(
                    icon: const Icon(Icons.copy,color:Colors.white),
                    tooltip: 'Copy all activity log',
                    onPressed: controller.activityLog.isEmpty
                        ? null
                        : () => _copyActivityLog(),
                   )),
              // IconButton(
              //   icon: const Icon(Icons.close,color:Colors.white),
              //   tooltip: 'Close',
              //   onPressed: () => Get.back(),
              // ),
            ],
          ),
          backgroundColor: const Color(0xFFF4F5F7),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Obx(() {
              if (controller.activityLog.isEmpty) {
                return Center(
                  child: Text(
                    'No activity yet',
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                );
              }
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white),
                ),
                child: ListView.builder(
                  itemCount: controller.activityLog.length,
                  itemBuilder: (context, index) {
                    final entry = controller.activityLog[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: SelectableText(
                        entry,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: _activityLogColor(entry),
                        ),
                      ),
                    );
                  },
                ),
              );
            }),
          ),
        ),
      ),
      barrierDismissible: true,
    );
  }
}

class _SensorWriteAction extends StatefulWidget {
  const _SensorWriteAction({required this.sensor, required this.controller});

  final list_ds.Receipe sensor;
  final HomePageController controller;

  @override
  State<_SensorWriteAction> createState() => _SensorWriteActionState();
}

class _SensorWriteActionState extends State<_SensorWriteAction> {
  final TextEditingController _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  void _submit() async {
    final text = _valueController.text.trim();
    final value = int.tryParse(text);
    if (value == null) return;

    await widget.controller.writeSensorValue(widget.sensor, value);
    _valueController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = widget.sensor.id;
      final isBusy =
          id != null && widget.controller.writeInFlightSensorIds.contains(id);

      return Row(
        children: [
          SizedBox(
            width: 70,
            height: 32,
            child: TextField(
              controller: _valueController,
              enabled: !isBusy,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                filled: true,
                fillColor: const Color(0xFFF5F7FA),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                hintText: 'value',
                hintStyle: const TextStyle(fontSize: 11),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ],
      );
    });
  }
}
