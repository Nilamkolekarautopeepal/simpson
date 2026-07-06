import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/psf_home_screen_controller.dart';

import 'package:simpson/views/widget/psf_dtc_dialog.dart';

import 'package:simpson/views/widget/views_widget/psf_live_parameter_dialog.dart';

/// One lane card in the PFS Station's 6-lane horizontal grid.
/// Mirrors the client reference: ECU model name + LED dot + refresh,
/// harness status band, ESN field, tappable injector/IQA grid, flash
/// controls with real progress, DTC + live parameter buttons.
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
      return Opacity(
        opacity: lane.isLocked.value ? 0.45 : 1.0,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: Border.all(
              color: lane.isTargetLane.value ? Colors.green : Colors.grey.shade300,
              width: lane.isTargetLane.value ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(4),
            color: Colors.white,
          ),
          child: IgnorePointer(
            ignoring: lane.isLocked.value,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── fixed header ──
                _ecuHeaderRow(),
                _harnessStatusRow(),
                _esnDisplayRow(),

                // ── scrollable middle (grows/shrinks with content) ──
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _injectorIqaGrid(),
                        _boxedLabel(lane.flashFileName.value.isEmpty ? 'FLASH FILE NAME' : lane.flashFileName.value),
                      ],
                    ),
                  ),
                ),

                // ── fixed footer, pinned to bottom of the card ──
                _startFlashButton(),
                _statusLine('FLASH STATUS', lane.flashStatus.value),
                _statusLine('IQA STATUS :', lane.iqaStatusText),
                const SizedBox(height: 8),
                _dtcAndLiveParameter(context),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _ecuHeaderRow() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(border: Border.all(color: Colors.black87), borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '${lane.laneNumber}. ${lane.ecuModelName.value}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => controller.onRefreshLane(laneIndex),
          ),
          const SizedBox(width: 6),
          Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(shape: BoxShape.circle, color: lane.isLedOn.value ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _harnessStatusRow() {
    final connected = lane.isHarnessConnected.value;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: connected ? Colors.green.withOpacity(0.12) : const Color(0xFFFAFBFD),
        border: Border.all(color: connected ? Colors.green : const Color(0xFFC7CCDC)),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(connected ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: connected ? Colors.green : Colors.grey),
          const SizedBox(width: 6),
          Text(
            connected ? 'HARNESS CONNECTED' : (lane.isTargetLane.value ? 'AWAITING HARNESS' : 'LOCKED OUT'),
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: connected ? Colors.green : Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  /// Shows the ESN once matched — read-only display, NOT a second scan
  /// input. Scanning happens exactly once, in the top scan bar; this just
  /// reflects the result so it's clear at a glance which engine this
  /// lane belongs to.
  Widget _esnDisplayRow() {
    final hasEsn = lane.esn.value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Icon(Icons.qr_code_2, size: 15, color: hasEsn ? Colors.black87 : Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              hasEsn ? 'ESN: ${lane.esn.value}' : 'No ESN scanned yet',
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasEsn ? FontWeight.bold : FontWeight.normal,
                color: hasEsn ? Colors.black87 : Colors.grey.shade500,
                fontStyle: hasEsn ? FontStyle.normal : FontStyle.italic,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _boxedLabel(String text) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(border: Border.all(color: Colors.black87), borderRadius: BorderRadius.circular(3)),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
    );
  }

  Widget _injectorIqaGrid() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 4),
      child: Column(
        children: List.generate(lane.injectorStatus.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: _gridCell(
                    'INJECTOR ${i + 1}',
                    lane.injectorStatus[i],
                    onTap: () => controller.onToggleInjector(laneIndex, i),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _gridCell(
                    'IQA ${i + 1}',
                    i < lane.iqaStatus.length ? lane.iqaStatus[i] : false,
                    onTap: () => controller.onToggleIqa(laneIndex, i),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _gridCell(String label, bool active, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(3),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFC7CCDC)),
          borderRadius: BorderRadius.circular(3),
          color: active ? Colors.green.withOpacity(0.15) : const Color(0xFFFAFBFD),
        ),
        child: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _startFlashButton() {
    final bool canFlash = lane.isHarnessConnected.value && !lane.isFlashing.value;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 14),
      child: Column(
        children: [
          Material(
            color: lane.isHarnessConnected.value ? const Color(0xFF2ECC71) : const Color(0xFFB9BFD1),
            borderRadius: BorderRadius.circular(3),
            child: InkWell(
              borderRadius: BorderRadius.circular(3),
              onTap: canFlash ? () => controller.onStartFlash(laneIndex) : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Center(
                  child: lane.isFlashing.value
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0B3D1E)))
                      : Text(
                          lane.isHarnessConnected.value ? 'START FLASH' : 'CONNECT HARNESS FIRST',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF0B3D1E)),
                        ),
                ),
              ),
            ),
          ),
          if (lane.isFlashing.value || lane.flashProgress.value > 0) ...[
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(value: lane.flashProgress.value, minHeight: 6, backgroundColor: Colors.grey.shade200, color: Colors.green),
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87),
          children: [
            TextSpan(text: '$label  '),
            TextSpan(text: value, style: TextStyle(fontWeight: FontWeight.normal, color: Colors.grey.shade600)),
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
            PsfDtcDialog.show(lane, () => controller.loadDtcForLane(laneIndex));
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Colors.black87),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 8),
          ),
          child: const Text('DTC', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.black87)),
        ),
        const SizedBox(height: 10),
        TextButton(
          onPressed: () async {
            await controller.onOpenLiveParameter(laneIndex);
            PsfLiveParameterDialog.show(lane, () => controller.loadPidForLane(laneIndex));
          },
          child: const Text('LIVE PARAMETER', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.black87)),
        ),
      ],
    );
  }
}
