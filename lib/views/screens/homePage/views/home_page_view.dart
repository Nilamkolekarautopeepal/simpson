import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import 'package:simpson/dev/dev_screen.dart';
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/views/screens/homePage/views/home_session_history_screen.dart';
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
          // IconButton(
          //   icon: const Icon(Icons.logout, color: Colors.white),
          //   onPressed: controller.logout,
          //   tooltip: 'Logout',
          // ),

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
            child: Builder(
              builder: (context) => Obx(
                () {
                  final visibleCount = (controller.currentStepIndex.value + 1)
                      .clamp(0, controller.steps.length);
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      for (int index = 0; index < visibleCount; index++)
                        controller.steps[index].type == StepType.iqaGroup
                            ? _buildIqaGroupTile(index, context)
                            : _buildStepTile(index, context),
                      if (controller.resolvedListNumber.value.isNotEmpty ||
                          controller.resolvedHarnessName.value.isNotEmpty)
                        _buildResolvedInfoTile(),
                    ],
                  );
                },
              ),
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
                    'HIL Setup',
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Theme(
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
                    keyboardType: null,
                    inputFormatters: null,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isCompleted
                          ? Colors.green.withOpacity(0.06)
                          : Colors.white,
                      counterText: null,
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
                      hintText: isActive ? ('Scan or enter ${step.label}') : '',
                    ),
                    onChanged: (_) => controller.onFieldChanged(index),
                    onSubmitted: (_) => controller.submitStep(index),
                  ),
                ),
              ),
              // ── History button — only on the ESN row, once an ESN has resolved ──
              if (step.key == 'esn')
                Obx(() {
                  if (controller.currentEsn.value.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(6),
                      onTap: () => Get.to(() =>
                          HomeSessionHistoryScreen(controller: controller)),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.themeColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                              color: AppColors.themeColor.withOpacity(0.3)),
                        ),
                        child: Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: AppColors.themeColor,
                        ),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolvedInfoTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: AppColors.themeColor),
              const SizedBox(width: 6),
              Text(
                'Resolved from ESN',
                style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (controller.resolvedListNumber.value.isNotEmpty)
            _readOnlyInfoRow('List No.', controller.resolvedListNumber.value),
          if (controller.resolvedHarnessName.value.isNotEmpty)
            _readOnlyInfoRow('Harness', controller.resolvedHarnessName.value),
        ],
      ),
    );
  }

  Widget _readOnlyInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.themeColor.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.themeColor.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 10.5,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87)),
          ],
        ),
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
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── Read: pulls live values FROM the PLC ──
                          ElevatedButton.icon(
                            onPressed: controller.isReadingPlcValues.value ||
                                    controller.isWritingAllSensors.value
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
                                : 'Read Current value'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.themeColor,
                              foregroundColor: Colors.white,
                              // Stay colored (not grey) while THIS op is the
                              // one running; only turn grey when blocked by
                              // the OTHER op.
                              disabledBackgroundColor:
                                  controller.isReadingPlcValues.value
                                      ? AppColors.themeColor
                                      : Colors.grey.shade300,
                              disabledForegroundColor:
                                  controller.isReadingPlcValues.value
                                      ? Colors.white
                                      : Colors.grey.shade500,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // ── Write: pushes server values TO the PLC, one after another ──
                          ElevatedButton.icon(
                            onPressed: controller.isWritingAllSensors.value ||
                                    controller.isReadingPlcValues.value
                                ? null
                                : controller.writeAllSensorValues,
                            icon: controller.isWritingAllSensors.value
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.upload, size: 16),
                            label: Text(controller.isWritingAllSensors.value
                                ? 'Writing…'
                                : 'Write'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.themeColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  controller.isWritingAllSensors.value
                                      ? AppColors.themeColor
                                      : Colors.grey.shade300,
                              disabledForegroundColor:
                                  controller.isWritingAllSensors.value
                                      ? Colors.white
                                      : Colors.grey.shade500,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
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
    final rows = controller.harnessReceipes;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior:
            Clip.antiAlias, // keeps header/rows inside the rounded corners
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3), // Sensor Name
            1: FlexColumnWidth(2), // Reg Address
            2: FlexColumnWidth(2), // Type
            3: FlexColumnWidth(1.4), // Pin No
            4: FlexColumnWidth(2), // Current Value
            5: FlexColumnWidth(1), // Unit
            6: FlexColumnWidth(2), // Write
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: Colors.grey.shade200, width: 1),
            verticalInside: BorderSide(color: Colors.grey.shade200, width: 1),
          ),
          children: [
            // ── Header row ──
            TableRow(
              decoration: BoxDecoration(
                color: AppColors.themeColor.withOpacity(0.06),
              ),
              children: [
                _headerCell('SENSOR NAME'),
                _headerCell('REG. ADDRESS'),
                _headerCell('TYPE'),
                _headerCell('PIN NO'),
                _headerCell('CURRENT VALUE'),
                _headerCell('UNIT'),
                _headerCell('WRITE'),
              ],
            ),

            // ── Data rows ──
            for (int i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i.isEven ? Colors.white : const Color(0xFFFAFBFC),
                ),
                children: _buildRecipeRowCells(rows[i]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AppColors.themeColor,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecipeRowCells(list_ds.Receipe sensor) {
    return [
      // Sensor Name
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              sensor.sensorName ?? '-',
              style:
                  const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),

      // Reg Address
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              '${sensor.regAddress ?? '-'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ),
      ),

      // Type — chip style
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Center(
                child: Text(
                  sensor.type ?? '-',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade800),
                ),
              ),
            ),
          ),
        ),
      ),

      // Pin No
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              '${sensor.pinNo ?? '-'}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
            ),
          ),
        ),
      ),

      // Current Value — live, reactive
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Obx(() {
            final live =
                sensor.id != null ? controller.livePlcValues[sensor.id] : null;
            final display = live ?? '-';
            final isLive = live != null && live != 'ERR';
            final isError = live == 'ERR';

            return Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isError
                      ? Colors.red.withOpacity(0.08)
                      : (isLive
                          ? AppColors.themeColor.withOpacity(0.08)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isError
                        ? Colors.red
                        : (isLive
                            ? AppColors.themeColor
                            : Colors.grey.shade500),
                  ),
                ),
              ),
            );
          }),
        ),
      ),

      // Unit
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              sensor.unit ?? '-',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ),
        ),
      ),

      // Write action — writes THIS row's server-supplied value to the PLC on tap
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Center(
            child: _SensorWriteAction(
              sensor: sensor,
              controller: controller,
            ),
          ),
        ),
      ),
    ];
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
                            final pct = controller.flashProgress.value * 100;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.themeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(1)}%',
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
              const SizedBox(height: 20),
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
                case 'Writing PLC Values...':
                  message = 'Writing sensor recipe values to PLC...';
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
                    '${(controller.flashProgress.value * 100).toStringAsFixed(1)}%',
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

  // Widget _buildDtcCard(String raw) {
  //   String code = raw;
  //   String description = '';
  //   String status = '';

  //   final statusMatch = RegExp(r'\(([^()]*)\)\s*$').firstMatch(raw);
  //   String withoutStatus = raw;
  //   if (statusMatch != null) {
  //     status = statusMatch.group(1)?.trim() ?? '';
  //     withoutStatus = raw.substring(0, statusMatch.start).trim();
  //   }

  //   final splitIndex = withoutStatus.indexOf(' - ');
  //   code = splitIndex == -1
  //       ? withoutStatus
  //       : withoutStatus.substring(0, splitIndex).trim();
  //   description =
  //       splitIndex == -1 ? '' : withoutStatus.substring(splitIndex + 3).trim();

  //   final statusLower = status.toLowerCase();
  //   Color badgeColor;
  //   String badgeLabel;
  //   if (statusLower == 'active' || statusLower == 'current') {
  //     badgeColor = Colors.red.shade600;
  //     badgeLabel = 'Active';
  //   } else if (statusLower == 'pending') {
  //     badgeColor = Colors.orange.shade700;
  //     badgeLabel = 'Pending';
  //   } else if (statusLower == 'inactive') {
  //     badgeColor = Colors.green.shade600;
  //     badgeLabel = 'History'; // ← was 'InActive'
  //   } else {
  //     badgeColor = Colors.green.shade600;
  //     badgeLabel = status.isNotEmpty ? 'History' : '-';
  //   }

  //   return Container(
  //     width: double.infinity,
  //     margin: const EdgeInsets.only(bottom: 6),
  //     padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //     decoration: BoxDecoration(
  //       border: Border.all(color: Colors.grey.shade300),
  //       borderRadius: BorderRadius.circular(6),
  //     ),
  //     child: Row(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Expanded(
  //           child: Column(
  //             crossAxisAlignment: CrossAxisAlignment.start,
  //             children: [
  //               Text(
  //                 code,
  //                 style: const TextStyle(
  //                   fontWeight: FontWeight.bold,
  //                   fontSize: 12.5,
  //                   color: Colors.black87,
  //                 ),
  //               ),
  //               if (description.isNotEmpty) ...[
  //                 const SizedBox(height: 2),
  //                 Text(
  //                   description,
  //                   style:
  //                       TextStyle(fontSize: 11.5, color: Colors.grey.shade600),
  //                 ),
  //               ],
  //             ],
  //           ),
  //         ),
  //         const SizedBox(width: 10),
  //         Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
  //           decoration: BoxDecoration(
  //             color: badgeColor.withOpacity(0.1),
  //             borderRadius: BorderRadius.circular(10),
  //             border: Border.all(color: badgeColor.withOpacity(0.4)),
  //           ),
  //           child: Text(
  //             badgeLabel,
  //             style: TextStyle(
  //               fontSize: 10.5,
  //               fontWeight: FontWeight.bold,
  //               color: badgeColor,
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }
  Widget _buildDtcCard(String raw) {
    String code = raw;
    String description = '';
    String status = '';
    String register = '-';

    // ✅ Extract register field first — format: ... [REG:xxx]
    final registerMatch = RegExp(r'\[REG:([^\]]*)\]\s*$').firstMatch(raw);
    String withoutRegister = raw;
    if (registerMatch != null) {
      register = registerMatch.group(1)?.trim() ?? '-';
      withoutRegister = raw.substring(0, registerMatch.start).trim();
    }

    final statusMatch = RegExp(r'\(([^()]*)\)\s*$').firstMatch(withoutRegister);
    String withoutStatus = withoutRegister;
    if (statusMatch != null) {
      status = statusMatch.group(1)?.trim() ?? '';
      withoutStatus = withoutRegister.substring(0, statusMatch.start).trim();
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
      badgeLabel = 'History';
    } else {
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
                // ✅ Register row — placeholder for now
                // ✅ Register row — placeholder for now, colored like the status text
                const SizedBox(height: 4),
                Text(
                  'Register: $register',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grrenButtonn,
                  ),
                ),
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

  Map<String, String> _parseLogEntry(String raw) {
    final match =
        RegExp(r'^\[(\d{2}:\d{2}:\d{2})\]\s*\[(\w+)\]\s*(.*)$').firstMatch(raw);
    if (match != null) {
      return {
        'time': match.group(1)!,
        'tag': match.group(2)!,
        'message': match.group(3)!,
      };
    }
    // Fallback for any pre-existing untagged entries.
    final legacy = RegExp(r'^\[(\d{2}:\d{2}:\d{2})\]\s*(.*)$').firstMatch(raw);
    if (legacy != null) {
      return {
        'time': legacy.group(1)!,
        'tag': 'GENERAL',
        'message': legacy.group(2)!,
      };
    }
    return {'time': '', 'tag': 'GENERAL', 'message': raw};
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'ESN':
        return const Color(0xFF0E6E6E); // teal
      case 'PLC':
        return const Color(0xFF6C5CE7); // purple
      case 'DONGLE':
        return const Color(0xFFE67E22); // orange
      case 'FLASH':
        return const Color(0xFF2D6CDF); // blue
      case 'DTC':
        return const Color(0xFFD64545); // red
      case 'IQA':
        return const Color(0xFFDB2777); // pink
      case 'PID':
        return const Color(0xFF27AE60); // green
      case 'HARNESS':
        return const Color(0xFF8E7CC3); // lavender
      case 'SESSION':
        return const Color(0xFF34495E); // slate
      default:
        return Colors.grey.shade600;
    }
  }

  Widget _tagChip(String tag, {VoidCallback? onTap, bool selected = false}) {
    final color = _tagColor(tag);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? color : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.white : color,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  static const _allTags = [
    'ESN',
    'PLC',
    'DONGLE',
    'FLASH',
    'DTC',
    'IQA',
    'PID',
    'HARNESS',
    'SESSION',
    'GENERAL'
  ];

  // Widget _buildActivitySection() {
  //   return Container(
  //     constraints: const BoxConstraints(maxHeight: 180),
  //     margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: Colors.white,
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: Colors.grey.shade300),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.04),
  //           blurRadius: 8,
  //           offset: const Offset(0, -2),
  //         ),
  //       ],
  //     ),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Row(
  //           children: [
  //             const Text('Activity',
  //                 style: TextStyle(fontWeight: FontWeight.w600)),
  //             const Spacer(),
  //             // ── Open the full activity log in a full-screen dialog ──
  //             IconButton(
  //               icon: const Icon(Icons.fullscreen, size: 20),
  //               color: AppColors.themeColor,
  //               tooltip: 'Open full screen',
  //               visualDensity: VisualDensity.compact,
  //               onPressed: _showActivityFullScreen,
  //             ),
  //             Obx(() => IconButton(
  //                   icon: const Icon(Icons.save_alt, size: 18),
  //                   tooltip: "Save Activity Log",
  //                   color: AppColors.themeColor,
  //                   onPressed: controller.activityLog.isEmpty
  //                       ? null
  //                       : () async {
  //                           await controller.saveActivityLog();
  //                         },
  //                 )),
  //             Obx(
  //               () => IconButton(
  //                 icon: const Icon(Icons.copy, size: 18),
  //                 color: AppColors.themeColor,
  //                 tooltip: 'Copy all activity log',
  //                 visualDensity: VisualDensity.compact,
  //                 onPressed: controller.activityLog.isEmpty
  //                     ? null
  //                     : () => _copyActivityLog(),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const Divider(height: 16),
  //         Expanded(
  //           child: Obx(
  //             () => ListView(
  //               padding: EdgeInsets.zero,
  //               children: controller.activityLog
  //                   .map((entry) => Padding(
  //                         padding: const EdgeInsets.symmetric(vertical: 3),
  //                         child: Text(
  //                           entry,
  //                           style: TextStyle(
  //                               fontSize: 12.5, color: Colors.grey.shade700),
  //                         ),
  //                       ))
  //                   .toList(),
  //             ),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildActivitySection() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 220),
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
          const SizedBox(height: 8),
          // ── Tag filter row ──
          Obx(() {
            final active = controller.activityLogFilter.value;
            return SizedBox(
              height: 24,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _allTags.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (context, i) {
                  final tag = _allTags[i];
                  return _tagChip(
                    tag,
                    selected: active == tag,
                    onTap: () => controller.setActivityLogFilter(tag),
                  );
                },
              ),
            );
          }),
          const Divider(height: 16),
          Expanded(
            child: Obx(() {
              final filter = controller.activityLogFilter.value;
              final entries = controller.activityLog.where((entry) {
                if (filter == null) return true;
                return _parseLogEntry(entry)['tag'] == filter;
              }).toList();

              if (entries.isEmpty) {
                return Center(
                  child: Text(
                    filter == null
                        ? 'No activity yet'
                        : 'No "$filter" entries yet',
                    style:
                        TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
                  ),
                );
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: entries.map((entry) {
                  final parsed = _parseLogEntry(entry);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 3),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _tagChip(parsed['tag']!),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '[${parsed['time']}] ${parsed['message']}',
                            style: TextStyle(
                                fontSize: 12.5, color: Colors.grey.shade700),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  // void _showActivityFullScreen() {
  //   Get.dialog(
  //     Dialog.fullscreen(
  //       child: Scaffold(
  //         appBar: AppBar(
  //           iconTheme: const IconThemeData(
  //             color: Colors.white, // Back arrow color
  //           ),
  //           backgroundColor: AppColors.themeColor,
  //           foregroundColor: Colors.white,
  //           title: const Text('Activity Log'),
  //           actions: [
  //             Obx(() => IconButton(
  //                   icon: const Icon(Icons.save_alt, color: Colors.white),
  //                   tooltip: 'Save Activity Log',
  //                   onPressed: controller.activityLog.isEmpty
  //                       ? null
  //                       : () async {
  //                           await controller.saveActivityLog();
  //                         },
  //                 )),
  //             Obx(() => IconButton(
  //                   icon: const Icon(Icons.copy, color: Colors.white),
  //                   tooltip: 'Copy all activity log',
  //                   onPressed: controller.activityLog.isEmpty
  //                       ? null
  //                       : () => _copyActivityLog(),
  //                 )),
  //           ],
  //         ),
  //         backgroundColor: const Color(0xFFF4F5F7),
  //         body: Padding(
  //           padding: const EdgeInsets.all(16),
  //           child: Obx(() {
  //             if (controller.activityLog.isEmpty) {
  //               return Center(
  //                 child: Text(
  //                   'No activity yet',
  //                   style: TextStyle(color: Colors.grey.shade500),
  //                 ),
  //               );
  //             }
  //             return Container(
  //               width: double.infinity,
  //               padding: const EdgeInsets.all(16),
  //               decoration: BoxDecoration(
  //                 color: Colors.white,
  //                 borderRadius: BorderRadius.circular(10),
  //                 border: Border.all(color: Colors.white),
  //               ),
  //               child: ListView.builder(
  //                 itemCount: controller.activityLog.length,
  //                 itemBuilder: (context, index) {
  //                   final entry = controller.activityLog[index];
  //                   return Padding(
  //                     padding: const EdgeInsets.symmetric(vertical: 5),
  //                     child: SelectableText(
  //                       entry,
  //                       style: TextStyle(
  //                         fontSize: 13.5,
  //                         color: _activityLogColor(entry),
  //                       ),
  //                     ),
  //                   );
  //                 },
  //               ),
  //             );
  //           }),
  //         ),
  //       ),
  //     ),
  //     barrierDismissible: true,
  //   );
  // }
  void _showActivityFullScreen() {
    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: AppColors.themeColor,
            foregroundColor: Colors.white,
            title: const Text('Activity Log'),
            actions: [
              Obx(() => IconButton(
                    icon: const Icon(Icons.save_alt, color: Colors.white),
                    tooltip: 'Save Activity Log',
                    onPressed: controller.activityLog.isEmpty
                        ? null
                        : () async {
                            await controller.saveActivityLog();
                          },
                  )),
              Obx(() => IconButton(
                    icon: const Icon(Icons.copy, color: Colors.white),
                    tooltip: 'Copy all activity log',
                    onPressed: controller.activityLog.isEmpty
                        ? null
                        : () => _copyActivityLog(),
                  )),
            ],
          ),
          backgroundColor: const Color(0xFFF4F5F7),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Tag filter row ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Obx(() {
                    final active = controller.activityLogFilter.value;
                    return SizedBox(
                      height: 30,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _allTags.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (context, i) {
                          final tag = _allTags[i];
                          return _tagChip(
                            tag,
                            selected: active == tag,
                            onTap: () => controller.setActivityLogFilter(tag),
                          );
                        },
                      ),
                    );
                  }),
                ),
                const Divider(height: 1),
                // ── Log list fills all remaining space ──
                Expanded(
                  child: Obx(() {
                    final filter = controller.activityLogFilter.value;
                    final entries = controller.activityLog.where((entry) {
                      if (filter == null) return true;
                      return _parseLogEntry(entry)['tag'] == filter;
                    }).toList();

                    if (entries.isEmpty) {
                      return Center(
                        child: Text(
                          filter == null
                              ? 'No activity yet'
                              : 'No "$filter" entries yet',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final parsed = _parseLogEntry(entries[index]);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _tagChip(parsed['tag']!),
                              const SizedBox(width: 10),
                              Expanded(
                                child: SelectableText(
                                  '[${parsed['time']}] ${parsed['message']}',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: _activityLogColor(entries[index]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
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
  late final TextEditingController _valueController;

  @override
  void initState() {
    super.initState();

    // Pre-fill from the server-supplied value instead of starting empty.
    _valueController = TextEditingController(
      text: widget.sensor.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _SensorWriteAction oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If the recipe list is reloaded (e.g. harness rescanned) and this
    // row now points at a different sensor's value, refresh the field.
    if (oldWidget.sensor.value != widget.sensor.value) {
      _valueController.text = widget.sensor.value?.toString() ?? '';
    }
  }

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
    // Value box (livePlcValues) is updated inside writeSensorValue itself
    // after the read-back, so no extra work needed here.
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = widget.sensor.id;

      // This row's own write in flight.
      final isRowBusy =
          id != null && widget.controller.writeInFlightSensorIds.contains(id);

      // Global Read or global Write in progress locks every row too.
      final isGlobalBusy = widget.controller.isReadingPlcValues.value ||
          widget.controller.isWritingAllSensors.value;

      final isBusy = isRowBusy || isGlobalBusy;

      // ✅ No fixed-size SizedBox — the field sizes itself from its
      // content + padding via IntrinsicWidth, and is centered inside
      // the table cell via the outer Center.
      return Center(
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _valueController,
              enabled: !isBusy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
        ),
      );
    });
  }
}
