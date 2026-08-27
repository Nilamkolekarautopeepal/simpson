import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../controllers/home_page_controller.dart';

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

class HomeSessionHistoryScreen extends StatelessWidget {
  const HomeSessionHistoryScreen({super.key, required this.controller});

  final HomePageController controller;

  static void show(HomePageController controller) {
    Get.to(() => HomeSessionHistoryScreen(controller: controller));
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
          color: Colors.white,
          tooltip: 'Back',
          onPressed: () => Get.back(),
        ),
        title: Obx(
          () => Text(
            'History — ESN ${controller.currentEsn.value.isEmpty ? "—" : controller.currentEsn.value}',
          ),
        ),
      ),
      body: Obx(() {
        final testbed = controller.testbedSessionHistory;

        if (controller.currentEsn.value.isEmpty) {
          return _emptyState(
            icon: Icons.qr_code_scanner,
            title: 'No ESN scanned yet',
            subtitle: 'Scan an ESN on the home screen to see its history.',
          );
        }

        if (testbed.isEmpty) {
          return _emptyState(
            icon: Icons.history,
            title: 'No previous sessions found',
            subtitle: 'This ESN has no testbed session history yet.',
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionHeader('TESTBED SESSIONS', testbed.length),
            const SizedBox(height: 10),
            ...testbed.map((s) => _sessionCard(s)),
          ],
        );
      }),
    );
  }

  Widget _emptyState(
      {required IconData icon,
      required String title,
      required String subtitle}) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
                  Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
                color: _StationColors.brightGreen.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: _StationColors.brightGreen, size: 34),
          ),
          const SizedBox(height: 20),
          Text(title,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _StationColors.charcoal)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: _StationColors.slate, fontSize: 13),
          ),
        ],
      ),
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
                    'Start: ${startDate != null ? _formatDate(startDate) : '—'}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _StationColors.charcoal),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'End: ${endDate != null ? _formatDate(endDate) : '—'}',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _StationColors.charcoal),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _infoRow('Station', session['station_id']?.toString()),
          _infoRow('Dongle', session['dongle_id']?.toString()),
          _infoRow('Harness',
              '${session['harness_name'] ?? '—'} (${session['harness_type'] ?? '—'})'),
          _infoRow('Dataset',
              '${session['dataset_type'] ?? '—'} — ${session['datafile_name'] ?? '—'}'),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
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
    return '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
  }
}
