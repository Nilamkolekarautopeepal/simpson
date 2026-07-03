import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
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
                // Only render steps that have actually been reached —
                // future steps are hidden entirely, not just disabled.
                final visibleCount = (controller.currentStepIndex.value + 1)
                    .clamp(0, controller.steps.length);
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: visibleCount,
                  itemBuilder: (context, index) {
                    final step = controller.steps[index];
                    if (step.type == StepType.iqaGroup) {
                      return _buildIqaGroupTile(index);
                    }
                    return _buildStepTile(index);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(int index) {
    final step = controller.steps[index];
    final isCompleted = index < controller.currentStepIndex.value;
    final isActive = index == controller.currentStepIndex.value;

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
                color: isCompleted ? Colors.green : AppColors.themeColor,
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
          TextField(
            cursorColor: AppColors.themeColor,
            controller: controller.stepControllers[index],
            focusNode: controller.stepFocusNodes[index],
            enabled: true, // editable at all times once shown/unlocked
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: isCompleted
                  ? Colors.green.withOpacity(0.06)
                  : Colors.white,
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
                borderSide: BorderSide(color: AppColors.themeColor, width: 1.5),
              ),
              hintText: isActive ? 'Scan or enter ${step.label}' : '',
            ),
            onChanged: (_) => controller.onFieldChanged(index),
            onSubmitted: (_) => controller.submitStep(index),
          ),
          if (step.key == 'esn')
            Obx(
              () => controller.esnError.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        controller.esnError.value,
                        style: const TextStyle(color: Colors.red, fontSize: 11),
                      ),
                    ),
            ),
        ],
      ),
    );
  }

  /// IQA1..IQA4 shown together as one group once Harness is confirmed.
  Widget _buildIqaGroupTile(int index) {
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
                color: isCompleted ? Colors.green : AppColors.themeColor,
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
                  TextField(
                    cursorColor: AppColors.themeColor,
                    controller: controller.iqaControllers[i],
                    focusNode: controller.iqaFocusNodes[i],
                    enabled: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white,
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
                        borderSide:
                            BorderSide(color: AppColors.themeColor, width: 1.5),
                      ),
                      hintText: 'Scan ${controller.iqaLabels[i]}',
                    ),
                    onChanged: (_) => controller.onIqaFieldChanged(i),
                    onSubmitted: (_) => controller.submitIqaField(i),
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
            child: Obx(() {
              if (!controller.allStepsComplete) {
                // Nothing to show yet — still working through the scan steps.
                return const SizedBox.shrink();
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildFlashSection(),
                  if (controller.flashComplete.value) ...[
                    const SizedBox(height: 16),
                    _buildDtcSection(),
                    const SizedBox(height: 12),
                    _buildPidSection(),
                  ],
                ],
              );
            }),
          ),
        ),
        // Activity is pinned to the bottom and visible from the very start.
        _buildActivitySection(),
      ],
    );
  }

  Widget _buildFlashSection() {
    return Obx(() {
      final expanded = controller.flashExpanded.value;

      // Compact status shown next to the chevron, regardless of state.
      // Complete uses an actual checkmark icon instead of text.
      String? statusText;
      if (controller.flashInProgress.value) {
        statusText = '${(controller.flashProgress.value * 100).round()}%';
      }

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
                    if (controller.flashComplete.value) ...[
                      Column(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check,
                                color: Colors.white, size: 14),
                                
                                
                          ),
                          const SizedBox(height: 5),
                          Text('Flashing Successful',
                          style: TextStyle(
                              fontSize: 12, color:Colors. green.shade800,
                              fontWeight: FontWeight.bold
                              ),),
                        ],
                      ),
                      
                      const SizedBox(width: 10),
                    ] else if (statusText != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.themeColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
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
      if (controller.flashComplete.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.selectedFlashFile.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.selectedFlashFile.value!,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ),
            Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                Text(
                  controller.formattedElapsed,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 1.0,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Flashing successful',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }

      if (controller.flashInProgress.value) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (controller.selectedFlashFile.value != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  controller.selectedFlashFile.value!,
                  style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                ),
              ),
            Row(
              children: [
                const Expanded(child: SizedBox.shrink()),
                Text(
                  controller.formattedElapsed,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: controller.flashProgress.value,
                minHeight: 6,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.themeColor),
              ),
            ),
          ],
        );
      }

      // Unlocked (all scan steps done) but flashing hasn't started yet.
      return Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: controller.selectedFlashFile.value,
              isExpanded: true,
              hint: const Text('Choose a file', style: TextStyle(fontSize: 13)),
              items: controller.availableFlashFiles
                  .map(
                    (file) => DropdownMenuItem(
                      value: file,
                      child: Text(file, style: const TextStyle(fontSize: 13)),
                    ),
                  )
                  .toList(),
              onChanged: controller.selectFlashFile,
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide:
                      BorderSide(color: AppColors.themeColor, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: Icon(
              Icons.play_circle_fill,
              color: controller.selectedFlashFile.value != null
                  ? AppColors.themeColor
                  : Colors.grey.shade400,
              size: 28,
            ),
            onPressed: controller.selectedFlashFile.value != null
                ? controller.startFlashing
                : null,
            tooltip: controller.selectedFlashFile.value != null
                ? 'Start flashing'
                : 'Select a file first',
          ),
        ],
      );
    });
  }

  Widget _buildDtcSection() {
    return Obx(() => _buildExpandableSection(
          title: 'DTC',
          expanded: controller.dtcExpanded.value,
          onTap: controller.toggleDtc,
          trailingLabel: 'Count: ${controller.dtcCount}',
          items: controller.dtcList,
          itemBuilder: _buildDtcCard,
        ));
  }

  /// Boxed DTC card: code bold on top, description grey below.
  /// Expects "CODE - description" (falls back to showing the raw
  /// string as the code if that separator isn't present).
  Widget _buildDtcCard(String raw) {
    final splitIndex = raw.indexOf(' - ');
    final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
    final description =
        splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
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
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPidSection() {
    return Obx(() => _buildExpandableSection(
          title: 'PID',
          expanded: controller.pidExpanded.value,
          onTap: controller.togglePid,
          trailingLabel: null,
          items: controller.pidList,
          itemBuilder: _buildPidCard,
        ));
  }

  /// Boxed PID card, same style as the DTC cards: label bold on top,
  /// value grey below. Expects "Label — value" (falls back to showing
  /// the raw string as the label if that separator isn't present).
  Widget _buildPidCard(String raw) {
    final splitIndex = raw.indexOf(' — ');
    final label = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
    final value =
        splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12.5,
              color: Colors.black87,
            ),
          ),
          if (value.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required bool expanded,
    required VoidCallback onTap,
    required String? trailingLabel,
    required List<String> items,
    Widget Function(String item)? itemBuilder,
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
                  const Spacer(),
                  if (trailingLabel != null) ...[
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
                    const SizedBox(width: 10),
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
          const Text('Activity', style: TextStyle(fontWeight: FontWeight.w600)),
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
}