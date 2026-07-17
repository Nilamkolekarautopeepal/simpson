import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';


const Color _kPrimary = Color(0xFF003874);

/// Centered DTC dialog for one lane. Shows the REAL codes read off
/// the ECU (lane.dtcReadResults) — not just the dataset catalog of
/// every possible code. Call [show] rather than constructing this
/// directly.
class PsfDtcDialog extends StatelessWidget {
  const PsfDtcDialog({super.key, required this.lane, required this.onRefresh});

  final PsfLane lane;
  final VoidCallback onRefresh;

  static void show(PsfLane lane, VoidCallback onRefresh) {
    Get.dialog(PsfDtcDialog(lane: lane, onRefresh: onRefresh));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 480,
        height: 560,
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
                    child: const Icon(Icons.report_gmailerrorred, color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'DTC — Lane ${lane.laneNumber}',
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.black87),
                    ),
                  ),
                  Obx(
                    () => IconButton(
                      icon: lane.isReadingDtc.value
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh, size: 20, color: Colors.grey),
                      tooltip: 'Read DTCs from ECU',
                      onPressed: lane.isReadingDtc.value ? null : onRefresh,
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
              const SizedBox(height: 4),
              Obx(
                () => Text(
                  '${lane.dtcReadResults.length} code${lane.dtcReadResults.length == 1 ? '' : 's'} found on ECU',
                  style: const TextStyle(fontSize: 12.5, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // ── Body ──
              Expanded(
                child: Obx(() {
                  if (lane.isReadingDtc.value) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (lane.dtcError.value.isNotEmpty) {
                    return Center(
                      child: Text(lane.dtcError.value, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                    );
                  }
                  if (lane.dtcReadResults.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green, size: 36),
                          const SizedBox(height: 10),
                          const Text('No DTCs detected on this ECU.', style: TextStyle(color: Colors.grey)),
                          const SizedBox(height: 4),
                          Text('Tap refresh to read again.', style: TextStyle(color: Colors.grey.shade500, fontSize: 11.5)),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    itemCount: lane.dtcReadResults.length,
                    itemBuilder: (context, i) => _dtcTile(lane.dtcReadResults[i]),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// raw is "CODE - description (status)" — split it back apart for display.
  Widget _dtcTile(String raw) {
    final splitIndex = raw.indexOf(' - ');
    final code = splitIndex == -1 ? raw : raw.substring(0, splitIndex).trim();
    final rest = splitIndex == -1 ? '' : raw.substring(splitIndex + 3).trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 5, right: 10),
            decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.redAccent),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (rest.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(rest, style: TextStyle(fontSize: 12.5, color: Colors.grey.shade700)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
