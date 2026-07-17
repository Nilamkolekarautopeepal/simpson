import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/modals/pidDataset.model.dart' show Code, PiCodeVariables;
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';


const Color _kPrimary = Color(0xFF003874);

/// Centered Live Parameter dialog for one lane, split into "Live
/// Parameters" and "IQA" tabs based on each PID code's messageType.
///
/// Live Parameters tab shows real values read from the ECU
/// (lane.livePidValues), driven by the Run/Stop button.
///
/// IQA tab shows exactly the values that were entered/written for
/// this lane (lane.iqaControllers) — capped to that count, not every
/// possible IQA variable the dataset happens to define — so a 4-cylinder
/// lane always shows exactly 4 rows.
class PsfLiveParameterDialog extends StatelessWidget {
  const PsfLiveParameterDialog({
    super.key,
    required this.lane,
    required this.onRefresh,
    required this.onTogglePlayback,
  });

  final PsfLane lane;
  final VoidCallback onRefresh;
  final VoidCallback onTogglePlayback;

  static void show(PsfLane lane, VoidCallback onRefresh, VoidCallback onTogglePlayback) {
    Get.dialog(PsfLiveParameterDialog(lane: lane, onRefresh: onRefresh, onTogglePlayback: onTogglePlayback));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 520,
        height: 600,
        child: DefaultTabController(
          length: 2,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Header ──
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.speed, color: _kPrimary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Live Parameters — Lane ${lane.laneNumber}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Obx(() {
                      final playing = lane.pidPlaying.value;
                      return TextButton.icon(
                        onPressed: onTogglePlayback,
                        icon: Icon(playing ? Icons.stop_rounded : Icons.play_arrow_rounded, size: 18),
                        label: Text(playing ? 'Stop' : 'Run', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                        style: TextButton.styleFrom(
                          foregroundColor: playing ? Colors.red.shade600 : _kPrimary,
                        ),
                      );
                    }),
                    Obx(
                      () => IconButton(
                        icon: lane.isLoadingPid.value
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 20, color: Colors.grey),
                        tooltip: 'Reload parameter list',
                        onPressed: lane.isLoadingPid.value ? null : onRefresh,
                        splashRadius: 18,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                      onPressed: () => Get.back(),
                      splashRadius: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── Tabs ──
                Container(
                  decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.all(4),
                  child: Obx(
                    () => TabBar(
                      indicator: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      labelColor: _kPrimary,
                      unselectedLabelColor: Colors.grey.shade600,
                      dividerColor: Colors.transparent,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      tabs: [
                        Tab(text: 'Live Parameters (${lane.liveParameterCodes.length})'),
                        Tab(text: 'IQA (${lane.iqaControllers.length})'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // ── Body ──
                Expanded(
                  child: Obx(() {
                    if (lane.isLoadingPid.value) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (lane.pidError.value.isNotEmpty) {
                      return Center(
                        child: Text(lane.pidError.value, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                      );
                    }
                    return TabBarView(
                      children: [
                        _liveParameterList(),
                        _iqaWrittenList(),
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // LIVE PARAMETERS TAB — real ECU reads
  // ═══════════════════════════════════════════════

  Widget _liveParameterList() {
    final rows = <_ParamRow>[];
    for (final code in lane.liveParameterCodes) {
      final variables = code.piCodeVariable ?? [];
      if (variables.isEmpty) {
        rows.add(_ParamRow(code: code, variable: null));
        continue;
      }
      for (final v in variables) {
        rows.add(_ParamRow(code: code, variable: v));
      }
    }

    if (rows.isEmpty) {
      return const Center(child: Text('No live parameters found for this lane.', style: TextStyle(color: Colors.grey)));
    }

    // Plain (non-reactive) ListView — each tile below owns its own Obx
    // scoped to just the value it reads. Wrapping this whole builder in
    // one outer Obx doesn't work: ListView.builder's itemBuilder runs
    // lazily (as items scroll into view), which is *after* the Obx's
    // build() already finished tracking — so GetX sees no observables
    // read and throws "improper use of GetX".
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) => _liveParameterTile(rows[i]),
    );
  }

  Widget _liveParameterTile(_ParamRow row) {
    final code = row.code;
    final variable = row.variable;
    final unit = variable?.unit ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  variable?.longName ?? variable?.shortName ?? code.shortName ?? code.code ?? '-',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                ),
                if ((code.code ?? '').isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(code.code!, style: TextStyle(fontSize: 11.5, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
          // Scoped Obx — only this value box rebuilds when
          // lane.livePidValues changes, not the whole list.
          Obx(() {
            final liveValue = variable?.id != null ? lane.livePidValues[variable!.id] : null;
            final isError = liveValue != null && (liveValue == 'Not Found' || liveValue.toUpperCase().contains('ERROR'));
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: Text(
                liveValue != null ? '$liveValue${unit.isNotEmpty ? ' $unit' : ''}' : (unit.isEmpty ? '--' : '-- $unit'),
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: isError ? Colors.red : _kPrimary,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // IQA TAB — exactly the entered/written values,
  // capped to lane.iqaControllers.length (e.g. 4)
  // ═══════════════════════════════════════════════

  Widget _iqaWrittenList() {
    final count = lane.iqaControllers.length;
    if (count == 0) {
      return const Center(child: Text('No IQA fields configured for this lane.', style: TextStyle(color: Colors.grey)));
    }

    return ListView.builder(
      itemCount: count,
      itemBuilder: (context, i) => _iqaWrittenTile(i),
    );
  }

  Widget _iqaWrittenTile(int i) {
    // Each tile owns its own Obx, scoped to just this controller's text
    // and the overall write-status line — same reasoning as the live
    // parameter tiles above.
    return Obx(() {
      final value = lane.iqaControllers[i].text.trim();
      final hasValue = value.isNotEmpty;
      final writeStatus = lane.iqaWriteStatus.value;
      final wasWritten = writeStatus.toLowerCase().contains('successful');

      return Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: const Color(0xFFF5F7FA), borderRadius: BorderRadius.circular(10)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(lane.iqaLabelFor(i), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                  if (wasWritten) ...[
                    const SizedBox(height: 3),
                    Text('Written to ECU', style: TextStyle(fontSize: 11.5, color: Colors.green.shade700)),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
              child: Text(
                hasValue ? value : '--',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: hasValue ? _kPrimary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

/// One flattened, displayable row: a Code paired with one of its
/// piCodeVariable sub-entries (or null if the Code has none at all).
class _ParamRow {
  const _ParamRow({required this.code, required this.variable});
  final Code code;
  final PiCodeVariables? variable;
}
