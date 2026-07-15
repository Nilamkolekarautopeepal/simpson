import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/modals/pidDataset.model.dart' show Code, PiCodeVariables;
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';


const Color _kPrimary = Color(0xFF003874);

/// Centered Live Parameter dialog for one lane, split into "Live
/// Parameters" and "IQA" tabs based on each PID code's messageType.
class PsfLiveParameterDialog extends StatelessWidget {
  const PsfLiveParameterDialog({super.key, required this.lane, required this.onRefresh});

  final PsfLane lane;
  final VoidCallback onRefresh;

  static void show(PsfLane lane, VoidCallback onRefresh) {
    Get.dialog(PsfLiveParameterDialog(lane: lane, onRefresh: onRefresh));
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
                    Obx(
                      () => IconButton(
                        icon: lane.isLoadingPid.value
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.refresh, size: 20, color: Colors.grey),
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
                        Tab(text: 'IQA (${lane.iqaParameterCodes.length})'),
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
                        _codeList(lane.liveParameterCodes, emptyText: 'No live parameters found for this lane.'),
                        _codeList(lane.iqaParameterCodes, emptyText: 'No IQA parameters found for this lane.'),
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

  Widget _codeList(List<Code> codes, {required String emptyText}) {
    // Flatten each Code's piCodeVariable list into individual rows —
    // a single Code (e.g. "IQA", code 220079) can contain several
    // named sub-variables (IQA 1, IQA 2, IQA 3...), and each one needs
    // its own row rather than only showing the first.
    final rows = <_ParamRow>[];
    for (final code in codes) {
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
      return Center(child: Text(emptyText, style: const TextStyle(color: Colors.grey)));
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) => _codeTile(rows[i]),
    );
  }

  Widget _codeTile(_ParamRow row) {
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
          // TODO: replace this placeholder value with a live PLC read of
          // this code's actual register/byte position, scaled by
          // variable.resolution / variable.offset, once wired to PlcService.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6)),
            child: Text(
              unit.isEmpty ? '--' : '-- $unit',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _kPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// One flattened, displayable row: a Code paired with one of its
/// piCodeVariable sub-entries (or null if the Code has none at all).
class _ParamRow {
  const _ParamRow({required this.code, required this.variable});
  final Code code;
  final PiCodeVariables? variable;
}
