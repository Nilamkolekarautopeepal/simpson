import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';
import 'package:simpson/views/widget/psf_dtc_dialog.dart';
import 'package:simpson/views/widget/views_widget/psf_live_parameter_dialog.dart';

/// ── Color system ────────────────────────────────────────────────
/// Kept in one place so every lane card reads consistently:
///  - navy        = brand / primary action
///  - green       = matched / connected / ready
///  - greenDark   = actively flashing
///  - amber       = waiting on operator input
///  - red         = error / failed
///  - slate       = idle / neutral chrome
class _LaneColors {
  static const navy = Color(0xFF003874);
  static const navyLight = Color(0xFF1D5FA0);
  static const green = Color(0xFF2ECC71);
  static const greenDark = Color(0xFF1B7A3E);
  static const greenBg = Color(0xFFEAFAF1);
  static const amber = Color(0xFFB9770E);
  static const amberBg = Color(0xFFFEF6E7);
  static const red = Color(0xFFD64545);
  static const redBg = Color(0xFFFDEDED);
  static const slate = Color(0xFF7C8698);
  static const slateBorder = Color(0xFFDDE1E9);
  static const slateBg = Color(0xFFF7F8FA);
}

class PsfLaneCard extends StatelessWidget {
  const PsfLaneCard({
    super.key,
    required this.laneIndex,
    required this.lane,
    required this.controller,
    required this.width,
    required this.height,
  });

  final int laneIndex;
  final PsfLane lane;
  final PsfHomeScreenController controller;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final matched = lane.isTargetLane.value;
      final borderColor = matched ? _LaneColors.green : _LaneColors.slateBorder;

      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white,
          border: Border.all(color: borderColor, width: matched ? 1.6 : 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(matched ? 0.08 : 0.04),
              blurRadius: matched ? 14 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── fixed header ──
            _ecuHeaderRow(),
            _esnScanRow(),
            _listNumberScanRow(),
            const Divider(height: 1, thickness: 1, color: _LaneColors.slateBorder),

            // ── scrollable middle ──
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 10),
                    _iqaScanGrid(),
                    if (lane.iqaAllFilled.value) _flashFileBox(),
                  ],
                ),
              ),
            ),

            // ── fixed footer ──
            if (lane.iqaAllFilled.value) ...[
              _startFlashButton(),
              _bigFlashStatus(),
            ],
            _statusLine('IQA STATUS', '${lane.filledIqaCount.value} / ${lane.iqaControllers.length} scanned'),
            const SizedBox(height: 4),
            _dtcAndLiveParameter(context),
            const SizedBox(height: 14),
          ],
        ),
      );
    });
  }

  /// Header keeps the navy brand color as a filled bar rather than a
  /// plain black-bordered box — makes the card read as "on" and gives
  /// the LED dot somewhere with enough contrast to actually pop.
  Widget _ecuHeaderRow() {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 10, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _LaneColors.navy,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(6), bottom: Radius.circular(6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${lane.laneNumber}. ${lane.ecuModelName.value}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18, color: Colors.white70),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => controller.resetLane(laneIndex),
            tooltip: 'Reset lane for next engine',
          ),
          const SizedBox(width: 6),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: lane.isLedOn.value ? const Color(0xFF4ADE80) : const Color(0xFFEF5350),
              boxShadow: [
                BoxShadow(
                  color: (lane.isLedOn.value ? const Color(0xFF4ADE80) : const Color(0xFFEF5350)).withOpacity(0.6),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Shared style for the auto-scan fields (ESN, List Number) — no
  /// SCAN buttons anymore; typing pauses for 2s, then the controller
  /// auto-submits. A clear label above each field tells the operator
  /// exactly what to enter there.
  Widget _autoScanField({
    required String label,
    required TextEditingController textController,
    required FocusNode focusNode,
    required bool isLoading,
    required bool isResolved,
    required String resolvedText,
    required String awaitingText,
    required String error,
    required String hint,
    required VoidCallback onChanged,
    required VoidCallback onSubmit,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _LaneColors.slate, letterSpacing: 0.4),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 38,
            child: TextField(
              controller: textController,
              focusNode: focusNode,
              enabled: !isLoading,
              style: const TextStyle(fontSize: 12),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: const TextStyle(fontSize: 11.5, color: _LaneColors.slate),
                isDense: true,
                filled: true,
                fillColor: isResolved ? _LaneColors.greenBg : _LaneColors.slateBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                suffixIcon: isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _LaneColors.slateBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: isResolved ? _LaneColors.green : _LaneColors.slateBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: const BorderSide(color: _LaneColors.navy, width: 1.5),
                ),
              ),
              onChanged: (_) => onChanged(),
              onSubmitted: (_) => onSubmit(),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              //Icon(
               // isResolved ? Icons.check_circle : Icons.radio_button_unchecked,
               // size: 13,
                //color: isResolved ? _LaneColors.green : _LaneColors.slate,
             // ),
              //const SizedBox(width: 5),
              //Expanded(
                // child: Text(
                //   isResolved ? resolvedText : awaitingText,
                //   style: TextStyle(
                //     fontSize: 11,
                //     fontWeight: isResolved ? FontWeight.bold : FontWeight.w600,
                //     color: isResolved ? _LaneColors.green : _LaneColors.slate,
                //   ),
                //   overflow: TextOverflow.ellipsis,
               // ),
             // ),
            ],
          ),
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(error, style: const TextStyle(fontSize: 10.5, color: _LaneColors.red, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _esnScanRow() {
    return _autoScanField(
      label: 'ESN NUMBER',
      textController: lane.esnController,
      focusNode: lane.esnFocusNode,
      isLoading: lane.isLookingUpEsn.value,
      isResolved: lane.esn.value.isNotEmpty,
      resolvedText: 'ESN: ${lane.esn.value}',
      awaitingText: 'Scan or type the engine serial number',
      error: lane.esnError.value,
      hint: 'e.g. 111111111111111',
      onChanged: () => controller.onEsnFieldChanged(laneIndex),
      onSubmit: () => controller.onScanEsnForLane(laneIndex),
    );
  }

  /// List Number — only usable once ESN has matched. Resolves to
  /// exactly one flash file (see resolvedFlashFileName below), not a
  /// list to choose from.
  Widget _listNumberScanRow() {
    if (lane.esn.value.isEmpty) return const SizedBox.shrink();

    return _autoScanField(
      label: 'LIST NUMBER',
      textController: lane.listNumberController,
      focusNode: lane.listNumberFocusNode,
      isLoading: lane.isLookingUpListNumber.value,
      isResolved: lane.listNumber.value.isNotEmpty,
      resolvedText: 'List No: ${lane.listNumber.value}',
      awaitingText: 'Scan or type the list number',
      error: lane.listNumberError.value,
      hint: 'e.g. 3293',
      onChanged: () => controller.onListNumberFieldChanged(laneIndex),
      onSubmit: () => controller.onScanListNumberForLane(laneIndex),
    );
  }

  Widget _boxedLabel(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: _LaneColors.slateBg,
        border: Border.all(color: _LaneColors.slateBorder),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _LaneColors.slate),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _iqaScanGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IQA NUMBERS',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _LaneColors.slate, letterSpacing: 0.4),
          ),
          const SizedBox(height: 6),
          ...List.generate(lane.iqaControllers.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _LaneColors.slateBg,
                        border: Border.all(color: _LaneColors.slateBorder),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'INJECTOR ${i + 1}',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: _LaneColors.navy),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 34,
                      child: TextField(
                        controller: lane.iqaControllers[i],
                        focusNode: lane.iqaFocusNodes[i],
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                        decoration: InputDecoration(
                          hintText: lane.iqaLabelFor(i),
                          hintStyle: const TextStyle(fontSize: 10),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(4)),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: _LaneColors.slateBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(4),
                            borderSide: const BorderSide(color: _LaneColors.navy, width: 1.5),
                          ),
                        ),
                        onChanged: (_) => controller.onIqaFieldChanged(laneIndex, i),
                        onSubmitted: (_) {
                          if (i < lane.iqaFocusNodes.length - 1) {
                            lane.iqaFocusNodes[i + 1].requestFocus();
                          }
                        },
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

  /// Single resolved flash file (from the List Number scan) — not a
  /// list to pick from, just a confirmation of the one file that
  /// matches this lane's ECU.
  Widget _flashFileBox() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
      child: Builder(builder: (context) {
        if (lane.flashFilesError.value.isNotEmpty) {
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: _LaneColors.redBg, borderRadius: BorderRadius.circular(4)),
            child: Text(lane.flashFilesError.value, style: const TextStyle(fontSize: 10.5, color: _LaneColors.red)),
          );
        }
        if (lane.resolvedFlashFileName.value == null) {
          return _boxedLabel('FLASH FILE NAME');
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FLASH FILE',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: _LaneColors.slate, letterSpacing: 0.4),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: _LaneColors.greenBg,
                border: Border.all(color: _LaneColors.green),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 15, color: _LaneColors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      lane.resolvedFlashFileName.value!,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: _LaneColors.green),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  /// Start Flash button — light green once the dongle is connected
  /// and ready to go, dark green the instant a flash is actually in
  /// progress, grey while genuinely blocked on a prerequisite.
  Widget _startFlashButton() {
    final bool ready = lane.resolvedFlashFileUrl.value != null && lane.dongleConnected.value;
    final bool canFlash = ready && !lane.isFlashing.value;

    final String label = !lane.dongleConnected.value
        ? 'CONNECTING DONGLE…'
        : (lane.resolvedFlashFileUrl.value == null
            ? 'SCAN LIST NUMBER FIRST'
            : (lane.isFlashing.value ? 'FLASHING…' : 'START FLASH'));

    final Color fillColor = lane.isFlashing.value
        ? _LaneColors.greenDark
        : (ready ? _LaneColors.green : _LaneColors.slateBorder);
    final Color textColor = lane.isFlashing.value || ready ? Colors.white : _LaneColors.slate;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        children: [
          Material(
            color: fillColor,
            borderRadius: BorderRadius.circular(4),
            child: InkWell(
              borderRadius: BorderRadius.circular(4),
              onTap: canFlash ? () => controller.onStartFlash(laneIndex) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Center(
                  child: lane.isFlashing.value
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 8),
                            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
                          ],
                        )
                      : Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: textColor)),
                ),
              ),
            ),
          ),
          if (lane.isFlashing.value || lane.flashProgress.value > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: lane.flashProgress.value,
                minHeight: 6,
                backgroundColor: _LaneColors.slateBg,
                color: _LaneColors.greenDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _bigFlashStatus() {
    if (!lane.isFlashing.value && lane.flashProgress.value == 0 && lane.flashStatus.value.isEmpty) {
      return const SizedBox.shrink();
    }

    final failed = lane.flashStatus.value.startsWith('Flash Failed');
    final completed = lane.flashStatus.value == 'Flash Completed';

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: failed ? _LaneColors.redBg : (completed ? _LaneColors.greenBg : _LaneColors.slateBg),
          border: Border.all(color: failed ? _LaneColors.red : (completed ? _LaneColors.green : _LaneColors.slateBorder)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            if (lane.isFlashing.value || completed) ...[
              Text(
                lane.formattedElapsed,
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 4),
              Text(
                '${(lane.flashProgress.value * 100).round()}%',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: completed ? _LaneColors.greenDark : _LaneColors.navy),
              ),
              const SizedBox(height: 6),
            ],
            Text(
              lane.flashStatus.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: failed ? _LaneColors.red : (completed ? _LaneColors.greenDark : Colors.black87),
              ),
            ),
            if (completed && lane.iqaWriteStatus.value.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                lane.iqaWriteStatus.value,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: lane.iqaWriteStatus.value.toLowerCase().contains('successful')
                      ? _LaneColors.greenDark
                      : _LaneColors.red,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statusLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _LaneColors.navy),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(text: value, style: const TextStyle(fontWeight: FontWeight.normal, color: _LaneColors.slate)),
          ],
        ),
      ),
    );
  }

  Widget _dtcAndLiveParameter(BuildContext context) {
    return Column(
      children: [
        OutlinedButton(
          onPressed: () async {
            await controller.onOpenDtc(laneIndex);
            PsfDtcDialog.show(lane, () => controller.readLiveDtcForLane(laneIndex));
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: _LaneColors.navy),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
          ),
          child: const Text('DTC', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: _LaneColors.navy)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () async {
            await controller.onOpenLiveParameter(laneIndex);
            PsfLiveParameterDialog.show(
              lane,
              () => controller.loadPidForLane(laneIndex),
              () => controller.togglePidPlaybackForLane(laneIndex),
            );
          },
          child: const Text('LIVE PARAMETER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: _LaneColors.navy)),
        ),
      ],
    );
  }
}
