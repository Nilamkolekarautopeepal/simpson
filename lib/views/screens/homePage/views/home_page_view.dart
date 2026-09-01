//--------------------------------------------
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:simpson/common_widgets/custom_app_bar.dart';
import 'package:simpson/dev/dev_screen.dart';
import 'package:simpson/modals/listNumber.model.dart' as list_ds;
import 'package:simpson/views/screens/homePage/views/home_session_history_screen.dart';
import '../controllers/home_page_controller.dart';
// StepType is exported from home_page_controller.dart

class _StationColors {
  static const navy = Color(0xFF16232C);
  static const teal = Color(0xFF1F4D59);
  static const tealBg = Color(0xFF264F5C);
  static const brightGreen = Color(0xFF00E676);
  static const red = Color(0xFFFF6B6B);
  static const redBg = Color(0xFF4A2626);
  static const amber = Color(0xFFE0A63E);
  static const amberBg = Color(0xFF4A3B1A);
  static const slate = Color(0xFFA9BAC2);
  static const slateBorder = Color(0xFF345A66);
  static const slateBg = Color(0xFF1B333D);
}

class HomePageView extends GetView<HomePageController> {
  const HomePageView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CommonAppBar(
        title: controller.station,
        actions: [
          Obx(() {
            final connecting = controller.isPlcConnecting.value;
            final connected = controller.isPlcConnected.value;
            final color = connecting
                ? _StationColors.brightGreen
                : (connected ? _StationColors.brightGreen : _StationColors.red);
            return InkWell(
              onTap: controller.retryPlcConnection,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (connecting)
                        Padding(
                          padding: const EdgeInsets.all(1),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints.tightFor(
                                width: 15, height: 15),
                            child: CircularProgressIndicator(
                                strokeWidth: 1.2, color: color),
                          ),
                        )
                      else
                        Icon(Icons.circle, size: 10, color: color),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          connecting ? 'Connecting…' : 'PLC',
                          style: TextStyle(
                              color: color,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          Obx(() {
            if (!controller.canConnectDongle.value) {
              return const Padding(padding: EdgeInsets.zero);
            }
            final connecting = controller.dongleConnecting.value;
            final connected = controller.dongleConnected.value;
            final color = connecting
                ? _StationColors.brightGreen
                : (connected ? _StationColors.brightGreen : _StationColors.red);
            return InkWell(
              onTap: controller.retryDongleConnection,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (connecting)
                        Padding(
                          padding: const EdgeInsets.all(1),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints.tightFor(
                                width: 15, height: 15),
                            child: CircularProgressIndicator(
                                strokeWidth: 1.2, color: color),
                          ),
                        )
                      else
                        Icon(Icons.circle, size: 10, color: color),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          connecting ? 'Connecting…' : 'Dongle',
                          style: TextStyle(
                              color: color,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
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
      backgroundColor: _StationColors.navy,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 1, child: _buildSidebar()),
          Expanded(flex: 5, child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      color: _StationColors.teal,
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
                      for (int index = 0; index < visibleCount; index++) ...[
                        controller.steps[index].type == StepType.iqaGroup
                            ? _buildIqaGroupTile(index, context)
                            : _buildStepTile(index, context),
                        // ── List No. / Harness — shown right below the ESN
                        // field itself, styled like the ESN input box ──
                        if (controller.steps[index].key == 'esn' &&
                            (controller.resolvedListNumber.value.isNotEmpty ||
                                controller
                                    .resolvedHarnessName.value.isNotEmpty))
                          _buildResolvedInfoTile(),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
          Divider(height: 1, color: _StationColors.slateBorder),
          InkWell(
            onTap: () => _showRecipeDialog(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.list_alt, size: 18, color: Colors.white),
                  const Padding(
                    padding: EdgeInsets.only(left: 10),
                    child: Text(
                      'HIL Setup',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Obx(
                    () => controller.harnessReceipes.isEmpty
                        ? const Padding(padding: EdgeInsets.zero)
                        : Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color:
                                  _StationColors.brightGreen.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${controller.harnessReceipes.length}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: _StationColors.brightGreen),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ),
          Divider(height: 1, color: _StationColors.slateBorder),
          InkWell(
            onTap: () => Get.to(() => const DevLogsPage()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(Icons.bug_report_outlined,
                      size: 18, color: Colors.white),
                  Padding(
                    padding: const EdgeInsets.only(left: 10),
                    child: Text(
                      'API Logs',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withOpacity(0.85),
                      ),
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

  Widget _buildResolvedInfoTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (controller.resolvedListNumber.value.isNotEmpty)
            _readOnlyInfoRow(
                'LIST NUMBER', controller.resolvedListNumber.value),
          if (controller.resolvedHarnessName.value.isNotEmpty)
            _readOnlyInfoRow('HARNESS', controller.resolvedHarnessName.value),
        ],
      ),
    );
  }

  Widget _readOnlyInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.5)),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: _StationColors.slateBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
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
                color: isCompleted ? _StationColors.brightGreen : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                step.label,
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
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
                      selectionColor:
                          _StationColors.brightGreen.withOpacity(0.4),
                      selectionHandleColor: _StationColors.brightGreen,
                    ),
                  ),
                  child: TextField(
                    cursorColor: _StationColors.brightGreen,
                    controller: controller.stepControllers[index],
                    focusNode: controller.stepFocusNodes[index],
                    enabled: true,
                    maxLength: maxLen,
                    keyboardType: null,
                    inputFormatters: null,
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: isCompleted
                          ? _StationColors.brightGreen.withOpacity(0.12)
                          : _StationColors.slateBg,
                      counterText: null,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      hintStyle:
                          TextStyle(color: Colors.white.withOpacity(0.4)),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide:
                            BorderSide(color: Colors.white.withOpacity(0.2)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(6),
                        borderSide: BorderSide(
                            color: isCompleted
                                ? _StationColors.brightGreen
                                : Colors.white.withOpacity(0.2)),
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        borderSide: BorderSide(
                            color: _StationColors.brightGreen, width: 1.5),
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                          border:
                              Border.all(color: Colors.white.withOpacity(0.25)),
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          size: 18,
                          color: Colors.white,
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
                color: isCompleted ? _StationColors.brightGreen : Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'IQA',
                style: TextStyle(
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  color: Colors.white,
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
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(0.5)),
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
                          selectionColor:
                              _StationColors.brightGreen.withOpacity(0.4),
                          selectionHandleColor: _StationColors.brightGreen,
                        ),
                      ),
                      child: TextField(
                        cursorColor: _StationColors.brightGreen,
                        controller: controller.iqaControllers[i],
                        focusNode: controller.iqaFocusNodes[i],
                        enabled: true,
                        maxLength: 7,
                        style:
                            const TextStyle(fontSize: 13, color: Colors.white),
                        decoration: InputDecoration(
                          isDense: true,
                          filled: true,
                          fillColor: _StationColors.slateBg,
                          counterText: '',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 12),
                          hintStyle:
                              TextStyle(color: Colors.white.withOpacity(0.35)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                                color: Colors.white.withOpacity(0.2)),
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(6)),
                            borderSide: BorderSide(
                                color: _StationColors.brightGreen, width: 1.5),
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
        backgroundColor: _StationColors.navy,
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
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white)),
                    const SizedBox(width: 10),
                    Obx(
                      () => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _StationColors.brightGreen.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${controller.harnessReceipes.length} sensor${controller.harnessReceipes.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                              fontSize: 12, color: _StationColors.brightGreen),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Obx(
                      () => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
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
                                        strokeWidth: 2, color: Colors.black87),
                                  )
                                : const Icon(
                                    Icons.download,
                                    size: 16,
                                    color: Colors.black87,
                                  ),
                            label: Text(controller.isReadingPlcValues.value
                                ? 'Reading…'
                                : 'Read Current value'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _StationColors.brightGreen,
                              foregroundColor: Colors.black87,
                              disabledBackgroundColor:
                                  controller.isReadingPlcValues.value
                                      ? _StationColors.brightGreen
                                      : Colors.white.withOpacity(0.1),
                              disabledForegroundColor:
                                  controller.isReadingPlcValues.value
                                      ? Colors.black87
                                      : Colors.white38,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              textStyle: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 8),
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
                                        strokeWidth: 2, color: Colors.black87),
                                  )
                                : const Icon(
                                    Icons.upload,
                                    size: 16,
                                    color: Colors.black87,
                                  ),
                            label: Text(controller.isWritingAllSensors.value
                                ? 'Writing…'
                                : 'Write'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _StationColors.brightGreen,
                              foregroundColor: Colors.black87,
                              disabledBackgroundColor:
                                  controller.isWritingAllSensors.value
                                      ? _StationColors.brightGreen
                                      : Colors.white.withOpacity(0.1),
                              disabledForegroundColor:
                                  controller.isWritingAllSensors.value
                                      ? Colors.black87
                                      : Colors.white38,
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
                      icon: const Icon(Icons.close,
                          size: 20, color: Colors.white),
                      onPressed: () => Get.back(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Divider(height: 1, color: _StationColors.slateBorder),
                const SizedBox(height: 12),
                Expanded(
                  child: Obx(() {
                    if (controller.harnessReceipes.isEmpty) {
                      return Center(
                        child: Text(
                          'No recipe data yet — scan a harness first.',
                          style:
                              TextStyle(color: Colors.white.withOpacity(0.5)),
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
          border: Border.all(color: _StationColors.slateBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: Table(
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(2),
            2: FlexColumnWidth(2),
            3: FlexColumnWidth(1.4),
            4: FlexColumnWidth(2),
            5: FlexColumnWidth(1),
            6: FlexColumnWidth(2),
          },
          border: TableBorder(
            horizontalInside:
                BorderSide(color: _StationColors.slateBorder, width: 1),
            verticalInside:
                BorderSide(color: _StationColors.slateBorder, width: 1),
          ),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: _StationColors.navy),
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
            for (int i = 0; i < rows.length; i++)
              TableRow(
                decoration: BoxDecoration(
                  color: i.isEven ? _StationColors.teal : _StationColors.navy,
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
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildRecipeRowCells(list_ds.Receipe sensor) {
    return [
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              sensor.sensorName ?? '-',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              '${sensor.regAddress ?? '-'}',
              style:
                  TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Center(
              child: Text(
                sensor.type ?? '-',
                style: const TextStyle(fontSize: 11, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              '${sensor.pinNo ?? '-'}',
              style:
                  TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ),
      ),
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
                      ? _StationColors.redBg
                      : (isLive
                          ? _StationColors.brightGreen.withOpacity(0.18)
                          : Colors.transparent),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  display,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    color: isError
                        ? _StationColors.red
                        : (isLive
                            ? _StationColors.brightGreen
                            : Colors.white.withOpacity(0.5)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Center(
            child: Text(
              sensor.unit ?? '-',
              style:
                  TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
            ),
          ),
        ),
      ),
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
          color: _StationColors.teal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _StationColors.slateBorder),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white)),
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
                                  color: _StationColors.brightGreen,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.black87, size: 14),
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'Flashing Successful',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: _StationColors.brightGreen,
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
                                color: _StationColors.brightGreen
                                    .withOpacity(0.18),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${pct.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _StationColors.brightGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }),
                        );
                      }

                      return const SizedBox.shrink();
                    }),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white),
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
                  color: _StationColors.redBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: _StationColors.red, size: 30),
              ),
              const SizedBox(height: 18),
              const Text(
                'Flashing Failed',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _StationColors.red),
              ),
              const SizedBox(height: 8),
              Text(
                controller.flashErrorMessage.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.white.withOpacity(0.7)),
              ),
              const SizedBox(height: 20),
              if (controller.selectedFlashFile.value != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    controller.selectedFlashFile.value!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              ElevatedButton(
                onPressed: controller.dongleConnected.value
                    ? controller.startFlashing
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _StationColors.brightGreen,
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: Colors.white.withOpacity(0.15),
                  elevation: 3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Start Flashing',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!controller.dongleConnected.value) ...[
                const SizedBox(height: 10),
                const Text(
                  'Waiting for the dongle to reconnect…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: _StationColors.amber),
                ),
              ],
            ],
          ),
        );
      }

      // ── Success state ──
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
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.white.withOpacity(0.5)),
                  ),
                ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: _StationColors.brightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.black87, size: 30),
              ),
              const SizedBox(height: 16),
              const Text(
                'Flashing successful',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Completed in ${controller.formattedElapsed}',
                style: TextStyle(
                    fontSize: 12.5, color: Colors.white.withOpacity(0.6)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: controller.dongleConnected.value
                    ? controller.startFlashing
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _StationColors.brightGreen,
                  foregroundColor: Colors.black87,
                  disabledBackgroundColor: Colors.white.withOpacity(0.15),
                  elevation: 3,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Start Flashing',
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
              if (!controller.dongleConnected.value) ...[
                const SizedBox(height: 10),
                const Text(
                  'Waiting for the dongle to reconnect…',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: _StationColors.amber),
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
                  color: _StationColors.amber.withOpacity(0.16),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: _StationColors.amber.withOpacity(0.4)),
                ),
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_StationColors.amber),
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
                  color: Colors.white,
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
                  color: Colors.white.withOpacity(0.6),
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
                  style: const TextStyle(
                      fontSize: 13,
                      color: _StationColors.brightGreen,
                      fontWeight: FontWeight.bold),
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Obx(
                  () => Text(
                    'Elapsed  ${controller.formattedElapsed}',
                    style: TextStyle(
                        fontSize: 12.5, color: Colors.white.withOpacity(0.6)),
                  ),
                ),
                Obx(
                  () => Text(
                    '${(controller.flashProgress.value * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _StationColors.brightGreen,
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
                  backgroundColor: Colors.white.withOpacity(0.08),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      _StationColors.brightGreen),
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
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: _StationColors.brightGreen),
            ),
          ),
        );
      }

      if (controller.flashFilesError.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            controller.flashFilesError.value,
            style: const TextStyle(color: _StationColors.red, fontSize: 12.5),
          ),
        );
      }

      if (controller.availableFlashFiles.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            'No flash files available',
            style:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
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
                  color: _StationColors.amberBg,
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: _StationColors.amber.withOpacity(0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        size: 16, color: _StationColors.amber),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Waiting for the dongle to connect automatically…',
                        style: TextStyle(
                            fontSize: 12, color: _StationColors.amber),
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
                      color: _StationColors.slateBg,
                      border: Border.all(
                        color: isSelected
                            ? _StationColors.brightGreen
                            : Colors.white.withOpacity(0.15),
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
                          color: Colors.white,
                        ),
                      ),
                      trailing: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? _StationColors.brightGreen
                              : Colors.transparent,
                          border: Border.all(
                            color: _StationColors.brightGreen,
                            width: 1.5,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                color: Colors.black87, size: 14)
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
                backgroundColor: _StationColors.brightGreen,
                foregroundColor: Colors.black87,
                disabledBackgroundColor: Colors.white.withOpacity(0.15),
                elevation: 3,
                padding:
                    const EdgeInsets.symmetric(horizontal: 50, vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Start Flashing',
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
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
      badgeColor = _StationColors.red;
      badgeLabel = 'Active';
    } else if (statusLower == 'pending') {
      badgeColor = _StationColors.amber;
      badgeLabel = 'Pending';
    } else if (statusLower == 'inactive') {
      badgeColor = _StationColors.brightGreen;
      badgeLabel = 'History';
    } else {
      badgeColor = _StationColors.brightGreen;
      badgeLabel = status.isNotEmpty ? 'History' : '-';
    }

    // ── Related sensor name for this DTC code (plain string from backend) ──
    final String? relatedSensorName = controller.dtcRelatedSensors[code];
    final bool hasSensor =
        relatedSensorName != null && relatedSensorName.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _StationColors.slateBorder),
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
                    color: Colors.white,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Related Sensor: ${hasSensor ? relatedSensorName : '-'}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _StationColors.brightGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
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

  Widget _buildDtcCard1(String raw) {
    String code = raw;
    String description = '';
    String status = '';
    String register = '-';

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
      badgeColor = _StationColors.red;
      badgeLabel = 'Active';
    } else if (statusLower == 'pending') {
      badgeColor = _StationColors.amber;
      badgeLabel = 'Pending';
    } else if (statusLower == 'inactive') {
      badgeColor = _StationColors.brightGreen;
      badgeLabel = 'History';
    } else {
      badgeColor = _StationColors.brightGreen;
      badgeLabel = status.isNotEmpty ? 'History' : '-';
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: _StationColors.slateBorder),
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
                    color: Colors.white,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                        fontSize: 11.5, color: Colors.white.withOpacity(0.6)),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Related Sensor :  $register',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: _StationColors.brightGreen,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.15),
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
          color: _StationColors.teal,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _StationColors.slateBorder),
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
                        style: TextStyle(
                            fontWeight: FontWeight.w600, color: Colors.white)),
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
                              ? _StationColors.red
                              : _StationColors.brightGreen,
                          foregroundColor: Colors.black87,
                          elevation: 2,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                    Icon(expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white),
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
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 13)),
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
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.white,
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
                                    ? Colors.white.withOpacity(0.4)
                                    : (isError
                                        ? _StationColors.red
                                        : _StationColors.brightGreen),
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
                              color:
                                  _StationColors.slateBorder.withOpacity(0.6),
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
                              color: _StationColors.teal,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 3,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _StationColors.amber),
                                ),
                                SizedBox(height: 10),
                                Text(
                                  'Reading live parameters...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
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
        color: _StationColors.teal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _StationColors.slateBorder),
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
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, color: Colors.white)),
                  if (trailingLabel != null) ...[
                    const SizedBox(width: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _StationColors.brightGreen.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        trailingLabel,
                        style: const TextStyle(
                            fontSize: 12,
                            color: _StationColors.brightGreen,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (extraAction != null) extraAction,
                  if (onRefresh != null) ...[
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: onRefresh,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.refresh,
                          size: 18,
                          color: Colors.white,
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
                          border: Border.all(color: _StationColors.red),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Clear',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: _StationColors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.white),
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
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 13),
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
                                        style: const TextStyle(
                                            fontSize: 13, color: Colors.white)),
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
      backgroundColor: _StationColors.teal,
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
      return _StationColors.red;
    }

    if (entry.contains('✅') ||
        lower.contains('successful') ||
        lower.contains('success') ||
        lower.contains('connected') ||
        lower.contains('complete')) {
      return _StationColors.brightGreen;
    }

    return _StationColors.slate;
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
    final legacy = RegExp(r'^\[(\d{2}:\d{2}:\d{2})\]\s*(.*)$').firstMatch(raw);
    if (legacy != null) {
      return {
        'time': legacy.group(1)!,
        'tag': 'All',
        'message': legacy.group(2)!,
      };
    }
    return {'time': '', 'tag': 'All', 'message': raw};
  }

  Color _tagColor(String tag) {
    switch (tag) {
      case 'ESN':
        return const Color(0xFF4DD0C8);
      case 'PLC':
        return const Color(0xFF9C89F5);
      case 'DONGLE':
        return const Color(0xFFF0A860);
      case 'FLASH':
        return const Color(0xFF5C9CF0);
      case 'DTC':
        return _StationColors.red;
      case 'IQA':
        return const Color(0xFFF06BAE);
      case 'PID':
        return _StationColors.brightGreen;
      case 'HARNESS':
        return const Color(0xFFB4A5E8);
      case 'SESSION':
        return const Color(0xFF8FA5B8);
      default:
        return _StationColors.slate;
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
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
              color: selected ? color : Colors.white.withOpacity(0.35)),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black87 : Colors.white.withOpacity(0.75),
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  // Widget _buildActivitySection() {
  //   return Container(
  //     constraints: const BoxConstraints(maxHeight: 220),
  //     margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
  //     padding: const EdgeInsets.all(16),
  //     decoration: BoxDecoration(
  //       color: _StationColors.teal,
  //       borderRadius: BorderRadius.circular(10),
  //       border: Border.all(color: _StationColors.slateBorder),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.black.withOpacity(0.2),
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
  //                 style: TextStyle(
  //                     fontWeight: FontWeight.w600, color: Colors.white)),
  //             const Spacer(),
  //             IconButton(
  //               icon: const Icon(
  //                 Icons.fullscreen,
  //                 size: 20,
  //                 color: Colors.white,
  //               ),
  //               tooltip: 'Open full screen',
  //               visualDensity: VisualDensity.compact,
  //               onPressed: _showActivityFullScreen,
  //             ),
  //             Obx(() => IconButton(
  //                   icon: const Icon(
  //                     Icons.save_alt,
  //                     size: 18,
  //                     color: Colors.white,
  //                   ),
  //                   tooltip: "Save Activity Log",
  //                   onPressed: controller.activityLog.isEmpty
  //                       ? null
  //                       : () async {
  //                           await controller.saveActivityLog();
  //                         },
  //                 )),
  //             Obx(
  //               () => IconButton(
  //                 icon: const Icon(
  //                   Icons.copy,
  //                   size: 18,
  //                   color: Colors.white,
  //                 ),
  //                 tooltip: 'Copy all activity log',
  //                 visualDensity: VisualDensity.compact,
  //                 onPressed: controller.activityLog.isEmpty
  //                     ? null
  //                     : () => _copyActivityLog(),
  //               ),
  //             ),
  //           ],
  //         ),
  //         const SizedBox(height: 8),
  //         Obx(() {
  //           final active = controller.activityLogFilter.value;
  //           return SizedBox(
  //             height: 24,
  //             child: ListView.separated(
  //               scrollDirection: Axis.horizontal,
  //               itemCount: _allTags.length,
  //               separatorBuilder: (_, __) => const SizedBox(width: 6),
  //               itemBuilder: (context, i) {
  //                 final tag = _allTags[i];
  //                 final isAllChip = tag == 'All';
  //                 return _tagChip(
  //                   tag,
  //                   selected: isAllChip ? active == null : active == tag,
  //                   onTap: () => controller.setActivityLogFilter(
  //                     isAllChip ? null : tag,
  //                   ),
  //                 );
  //               },
  //             ),
  //           );
  //         }),
  //         Divider(height: 16, color: _StationColors.slateBorder),
  //         Expanded(
  //           child: Obx(() {
  //             final filter = controller.activityLogFilter.value;
  //             final entries = controller.activityLog.where((entry) {
  //               if (filter == null) return true;
  //               return _parseLogEntry(entry)['tag'] == filter;
  //             }).toList();

  //             if (entries.isEmpty) {
  //               return Center(
  //                 child: Text(
  //                   filter == null
  //                       ? 'No activity yet'
  //                       : 'No "$filter" entries yet',
  //                   style: TextStyle(
  //                       color: Colors.white.withOpacity(0.5), fontSize: 12.5),
  //                 ),
  //               );
  //             }

  //             return ListView(
  //               padding: EdgeInsets.zero,
  //               children: entries.map((entry) {
  //                 final parsed = _parseLogEntry(entry);
  //                 return Padding(
  //                   padding: const EdgeInsets.symmetric(vertical: 3),
  //                   child: Row(
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       _tagChip(parsed['tag']!),
  //                       const SizedBox(width: 6),
  //                       Expanded(
  //                         child: Text(
  //                           '[${parsed['time']}] ${parsed['message']}',
  //                           style: TextStyle(
  //                               fontSize: 12.5,
  //                               color: _activityLogColor(entry)),
  //                         ),
  //                       ),
  //                     ],
  //                   ),
  //                 );
  //               }).toList(),
  //             );
  //           }),
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
        color: _StationColors.teal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _StationColors.slateBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
                  style: TextStyle(
                      fontWeight: FontWeight.w600, color: Colors.white)),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.fullscreen,
                  size: 20,
                  color: Colors.white,
                ),
                tooltip: 'Open full screen',
                visualDensity: VisualDensity.compact,
                onPressed: _showActivityFullScreen,
              ),
              Obx(() => IconButton(
                    icon: const Icon(
                      Icons.save_alt,
                      size: 18,
                      color: Colors.white,
                    ),
                    tooltip: "Save Activity Log",
                    onPressed: controller.activityLog.isEmpty
                        ? null
                        : () async {
                            await controller.saveActivityLog();
                          },
                  )),
              Obx(
                () => IconButton(
                  icon: const Icon(
                    Icons.copy,
                    size: 18,
                    color: Colors.white,
                  ),
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
          Divider(height: 16, color: _StationColors.slateBorder),
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
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12.5),
                  ),
                );
              }

              return ListView(
                padding: EdgeInsets.zero,
                children: entries.map((entry) {
                  final parsed = _parseLogEntry(entry);
                  final tag = parsed['tag']!;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (tag != 'All') ...[
                          _tagChip(tag),
                          const SizedBox(width: 8),
                        ],
                        Expanded(
                          child: Text(
                            '[${parsed['time']}] ${parsed['message']}',
                            style: TextStyle(
                                fontSize: 12.5,
                                color: _activityLogColor(entry)),
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

  void _showActivityFullScreen() {
    Get.dialog(
      Dialog.fullscreen(
        child: Scaffold(
          appBar: AppBar(
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: _StationColors.navy,
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
          backgroundColor: _StationColors.navy,
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, color: _StationColors.slateBorder),
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
                              TextStyle(color: Colors.white.withOpacity(0.5)),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final parsed = _parseLogEntry(entries[index]);
                        final tag = parsed['tag']!;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: _StationColors.teal,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: _StationColors.slateBorder),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (tag != 'All') ...[
                                _tagChip(tag),
                                const SizedBox(width: 10),
                              ],
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
    _valueController = TextEditingController(
      text: widget.sensor.value?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant _SensorWriteAction oldWidget) {
    super.didUpdateWidget(oldWidget);
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
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final id = widget.sensor.id;

      final isRowBusy =
          id != null && widget.controller.writeInFlightSensorIds.contains(id);

      final isGlobalBusy = widget.controller.isReadingPlcValues.value ||
          widget.controller.isWritingAllSensors.value;

      final isBusy = isRowBusy || isGlobalBusy;

      return Center(
        child: IntrinsicWidth(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: TextField(
              controller: _valueController,
              enabled: !isBusy,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.white),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: _StationColors.navy,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(6),
                  borderSide: BorderSide.none,
                ),
                hintText: 'value',
                hintStyle: TextStyle(
                    fontSize: 11, color: Colors.white.withOpacity(0.4)),
              ),
              onSubmitted: (_) => _submit(),
            ),
          ),
        ),
      );
    });
  }
}
