import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response;
import 'package:simpson/api/app_urls.dart';
import 'package:simpson/services/api_log_service.dart';
import 'package:simpson/themes/app_colors.dart';

class DevLogsPage extends StatelessWidget {
  const DevLogsPage({super.key});

  static const _themeColor = Color(0xFF309F93);

  @override
  Widget build(BuildContext context) {
    final service = ApiLogService.to;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black87),
        title: const Text(
          'API Activity Log',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        actions: [
          Obx(
            () => IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.black54),
              tooltip: 'Clear all',
              onPressed: service.logs.isEmpty
                  ? null
                  : () => _confirmClear(context, service),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const _BaseUrlHeader(),
          const Divider(height: 1),
          _StatsHeader(service: service),
          const Divider(height: 1),
          Expanded(
            child: Obx(() {
              if (service.logs.isEmpty) {
                return _EmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                itemCount: service.logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) =>
                    _LogCard(entry: service.logs[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context, ApiLogService service) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear all logs?'),
        content: const Text('This can\'t be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              service.clear();
              Navigator.pop(context);
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _BaseUrlHeader extends StatelessWidget {
  const _BaseUrlHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: () => _copyBaseUrl(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Icon(Icons.dns_outlined, size: 15, color: Colors.grey.shade600),
              const SizedBox(width: 8),
              Text(
                'Base URL',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  ApiUrls.baseUrl,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: AppColors.themeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.copy_outlined, size: 14, color: Colors.grey.shade400),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _copyBaseUrl(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: ApiUrls.baseUrl));
  }
}

class _StatsHeader extends StatelessWidget {
  final ApiLogService service;
  const _StatsHeader({required this.service});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final total = service.logs.length;
      final errors = service.logs.where((e) => e.isError).length;
      return Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _StatChip(
              icon: Icons.swap_horiz,
              label: 'Total',
              value: '$total',
              color: Colors.grey.shade700,
            ),
            const SizedBox(width: 10),
            _StatChip(
              icon: Icons.error_outline,
              label: 'Errors',
              value: '$errors',
              color: errors > 0 ? Colors.red : Colors.grey.shade400,
            ),
          ],
        ),
      );
    });
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hourglass_empty, size: 40, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(
            'No API calls yet',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Requests will appear here as the app makes them',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LogCard extends StatefulWidget {
  final ApiLogEntry entry;
  const _LogCard({required this.entry});

  @override
  State<_LogCard> createState() => _LogCardState();
}

class _LogCardState extends State<_LogCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: entry.isError ? Colors.red.shade200 : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MethodBadge(method: entry.method),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _shortUrl(entry.url),
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.themeColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _StatusPill(entry: entry),
                            const SizedBox(width: 8),
                            Icon(Icons.schedule,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(
                              '${entry.duration?.inMilliseconds ?? '?'}ms',
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                            const SizedBox(width: 10),
                            Icon(Icons.access_time,
                                size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 3),
                            Text(
                              _time(entry.timestamp),
                              style: TextStyle(
                                  fontSize: 11.5, color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    color: Colors.grey.shade600,
                    tooltip: 'Copy details',
                    onPressed: () => _copy(context, _fullText(entry)),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade500,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Section(
                    title: 'URL',
                    content: entry.url,
                    color: AppColors.themeColor,
                  ),
                  _SectionDivider(),
                  _Section(
                      title: 'Request Headers',
                      content: _pretty(entry.requestHeaders)),
                  _SectionDivider(),
                  _Section(
                      title: 'Request Body',
                      content: _pretty(entry.requestBody)),
                  _SectionDivider(),
                  _Section(
                      title: 'Response Body',
                      content: _pretty(entry.responseBody)),
                  if (entry.errorMessage != null) ...[
                    _SectionDivider(),
                    _Section(
                      title: 'Error',
                      content: entry.errorMessage!,
                      color: Colors.red.shade700,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Shows just method-relative path in the collapsed header row when
  /// possible (e.g. "/datasets/get-dtc-datasets/?id=2" instead of the full
  /// "http://4.224.248.152:3389/api/v1/datasets/get-dtc-datasets/?id=2"),
  /// falling back to the full URL if parsing fails.
  String _shortUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final path = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      return path.isEmpty ? url : path;
    } catch (_) {
      return url;
    }
  }

  String _time(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

  String _pretty(dynamic data) {
    if (data == null) return '-';
    if (data is Map || data is List) {
      try {
        return const JsonEncoder.withIndent('  ').convert(data);
      } catch (_) {
        return data.toString();
      }
    }
    return data.toString();
  }

  String _fullText(ApiLogEntry entry) {
    return '${entry.method} ${entry.url}\n'
        'Status: ${entry.statusCode ?? '—'}\n\n'
        'Request Headers:\n${_pretty(entry.requestHeaders)}\n\n'
        'Request Body:\n${_pretty(entry.requestBody)}\n\n'
        'Response Body:\n${_pretty(entry.responseBody)}'
        '${entry.errorMessage != null ? '\n\nError:\n${entry.errorMessage}' : ''}';
  }

  Future<void> _copy(BuildContext context, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
  }
}

class _MethodBadge extends StatelessWidget {
  final String method;
  const _MethodBadge({required this.method});

  Color _colorFor(String m) {
    switch (m.toUpperCase()) {
      case 'GET':
        return const Color(0xFF309F93);
      case 'POST':
        return Colors.blue.shade600;
      case 'PUT':
      case 'PATCH':
        return Colors.orange.shade700;
      case 'DELETE':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        method.toUpperCase(),
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
          color: color,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final ApiLogEntry entry;
  const _StatusPill({required this.entry});

  @override
  Widget build(BuildContext context) {
    final code = entry.statusCode;
    final Color color;
    final String label;

    if (entry.isError) {
      color = Colors.red;
      label = code != null ? '$code' : 'Failed';
    } else {
      color = Colors.green.shade600;
      label = '$code';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String content;
  final Color? color;
  const _Section({required this.title, required this.content, this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3,
              height: 12,
              decoration: BoxDecoration(
                color: color ?? DevLogsPage._themeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
                color: color ?? Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(6),
          ),
          child: SelectableText(
            content,
            style: TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: color ?? Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
