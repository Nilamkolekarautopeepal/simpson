//prathmesh girme
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';
import 'package:url_launcher/url_launcher.dart';

class _StationColors {
  static const navy = Color(0xFF16232C);
  static const teal = Color(0xFF1F4D59);
  static const tealBg = Color(0xFF264F5C);
  static const charcoal = Colors.white;
  static const brightGreen = Color(0xFF00E676);
  static const red = Color(0xFFFF6B6B);
  static const redBg = Color(0xFF4A2626);
  static const slate = Color(0xFFA9BAC2);
  static const slateBorder = Color(0xFF345A66);
  static const slateBg = Color(0xFF1B333D);
}

class PsfSessionHistoryScreen extends StatelessWidget {
  const PsfSessionHistoryScreen({super.key, required this.lane});

  final PsfLane lane;

  static void show(PsfLane lane) {
    Get.to(() => PsfSessionHistoryScreen(lane: lane));
  }

  Future<void> _openActivityReport(String relativePath) async {
    final url = Uri.parse('https://sidia.simpsons.in/media/$relativePath');
    final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
    if (!launched) {
      Get.snackbar('Could not open file', 'Failed to open $relativePath');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
            backgroundColor: _StationColors.navy,
      appBar: AppBar(
        backgroundColor: _StationColors.navy,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: const Color.fromARGB(255, 253, 253, 253),
          tooltip: 'Back to home screen',
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Text(
            'History — Lane ${lane.laneNumber} (ESN ${lane.esn.value.isEmpty ? "—" : lane.esn.value})',
          ),
        ),
      ),
      body: Obx(() {
        final eol = lane.eolSessionHistory;
        final testbed = lane.testbedSessionHistory;

        if (eol.isEmpty && testbed.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                               Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                      color: _StationColors.brightGreen.withOpacity(0.15), shape: BoxShape.circle),
                  child: const Icon(Icons.history,
                      color: _StationColors.brightGreen, size: 34),
                ),
                const SizedBox(height: 20),
                const Text('No previous sessions found',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: _StationColors.charcoal)),
                const SizedBox(height: 8),
                const Text(
                  'This ESN has no EOL or testbed session history yet.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _StationColors.slate, fontSize: 13),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (eol.isNotEmpty) ...[
              _sectionHeader('EOL SESSIONS', eol.length),
              const SizedBox(height: 10),
              ...eol.map((s) => _sessionCard(s)),
              const SizedBox(height: 20),
            ],
            if (testbed.isNotEmpty) ...[
              _sectionHeader('TESTBED SESSIONS', testbed.length),
              const SizedBox(height: 10),
              ...testbed.map((s) => _sessionCard(s)),
            ],
          ],
        );
      }),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _StationColors.slate,
                letterSpacing: 0.5)),
        const SizedBox(width: 8),
               Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: _StationColors.brightGreen.withOpacity(0.18),
              borderRadius: BorderRadius.circular(12)),
          child: Text('$count',
              style: const TextStyle(
                  fontSize: 11.5,
                  color: _StationColors.brightGreen,
                  fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _sessionCard(Map<String, dynamic> session) {
    final startDate = _parseDate(session['start_date']);
    final endDate = _parseDate(session['end_date']);
    final duration = (startDate != null && endDate != null)
        ? endDate.difference(startDate)
        : null;

        return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _StationColors.teal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _StationColors.slateBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row — model/sub-model + timestamp
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${session['model'] ?? '—'} — ${session['sub_model'] ?? '—'}',
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: _StationColors.charcoal),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'List No. ${session['list_no'] ?? '—'}',
                      style: const TextStyle(
                          fontSize: 12, color: _StationColors.slate),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    startDate != null ? _formatDate(startDate) : '—',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _StationColors.charcoal),
                  ),
                  if (duration != null)
                    Text(
                      'Duration: ${_formatDuration(duration)}',
                      style: const TextStyle(
                          fontSize: 11, color: _StationColors.slate),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
                  Divider(height: 1, color: _StationColors.slateBorder),
          const SizedBox(height: 12),

          // Middle — dongle / harness / dataset info
          _infoRow('Station', session['station_id']?.toString()),
          _infoRow('Dongle', session['dongle_id']?.toString()),
          _infoRow('Harness',
              '${session['harness_name'] ?? '—'} (${session['harness_type'] ?? '—'})'),
          _infoRow('Dataset',
              '${session['dataset_type'] ?? '—'} — ${session['datafile_name'] ?? '—'}'),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Bottom — the four status badges, color coded
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _statusBadge(
                  'Continuity', session['continuty_status']?.toString()),
              _statusBadge('Flash', session['flash_status']?.toString()),
              _statusBadge('IQA', session['iqa_status']?.toString()),
              _statusBadge('DTC', session['dtc_status']?.toString()),
            ],
          ),

          if (session['activity_report'] != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () =>
                  _openActivityReport(session['activity_report'].toString()),
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                                    const Icon(Icons.description_outlined,
                      size: 14, color: _StationColors.brightGreen),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      session['activity_report'].toString(),
                      style: const TextStyle(
                          fontSize: 11,
                          color: _StationColors.brightGreen,
                          decoration: TextDecoration.underline),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.open_in_new,
                      size: 12, color: _StationColors.brightGreen),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11.5,
                    color: _StationColors.slate,
                    fontWeight: FontWeight.w600)),
          ),
          Expanded(
            child: Text(value ?? '—',
                style: const TextStyle(
                    fontSize: 12.5, color: _StationColors.charcoal),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, String? status) {
    final isPass = (status ?? '').toLowerCase() == 'pass';
    final isFail = (status ?? '').toLowerCase() == 'fail';
       final color = isPass
        ? _StationColors.brightGreen
        : (isFail ? _StationColors.red : _StationColors.slate);
    final bg = isPass
        ? _StationColors.brightGreen.withOpacity(0.15)
        : (isFail ? _StationColors.redBg : _StationColors.slateBg);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: color.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isPass
                  ? Icons.check_circle
                  : (isFail ? Icons.cancel : Icons.help_outline),
              size: 13,
              color: color),
          const SizedBox(width: 5),
          Text('$label: ${status ?? "—"}',
              style: TextStyle(
                  fontSize: 11.5, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString());
  }

  String _formatDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year} '
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }
}
