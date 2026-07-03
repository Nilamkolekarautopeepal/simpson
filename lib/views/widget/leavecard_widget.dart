import 'package:simpson/modals/leavelist.model.dart';
import 'package:simpson/services/permission_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simpson/themes/app_theme.dart';

class LeaveCard extends StatelessWidget {
  final Leave leave;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onCancle;

  const LeaveCard({
    Key? key,
    required this.leave,
    this.onApprove,
    this.onReject,
    this.onCancle,
  }) : super(key: key);

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.error;
      case 'open':
        return AppColors.primary;
      case 'cancelled':
        return AppColors.error;

      default:
        return AppColors.grey;
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsed);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    final emp = leave.employee;
    final statusColor = _getStatusColor(leave.status);
    final formattedFrom = _formatDate(leave.fromDate);
    final formattedTo = _formatDate(leave.toDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(color: statusColor, width: 6),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with avatar and status
              Row(
                children: [
                  CircleAvatar(
                    // ignore: deprecated_member_use
                    backgroundColor: AppColors.primary.withOpacity(0.2),
                    child: Text(
                      emp?.displayName?.isNotEmpty == true
                          ? emp!.displayName![0]
                          : '?',
                      style:  TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          emp?.displayName ?? 'N/A',
                          style:  TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        Text(
                          emp?.designation ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      // ignore: deprecated_member_use
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      leave.status?.toUpperCase() ?? 'N/A',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Leave details
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _buildDetailChip(
                          icon: Icons.beach_access,
                          value: leave.leaveType ?? 'N/A',
                        ),
                        const Spacer(),
                        _buildDetailChip(
                          icon: Icons.calendar_today,
                          value: '${leave.totalLeaveDays ?? 0} days',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateBlock(
                            label: 'FROM',
                            date: formattedFrom,
                            isStart: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward,
                            size: 20, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _buildDateBlock(
                            label: 'TO',
                            date: formattedTo,
                            isStart: false,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (leave.description?.isNotEmpty ?? false)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'REASON',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          leave.description!,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ],
                    ),
                  if (permissionService.can("leave", "cancle")) ...[
                    ElevatedButton(
                      onPressed: onCancle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                      ),
                      child: const Text("CANCEL"),
                    ),
                  ]
                ],
              ),

              const SizedBox(height: 16),

              // Row(
              //   children: [
              //     const Icon(Icons.person_outline, size: 16, color: Colors.grey),
              //     const SizedBox(width: 6),
              //     Text(
              //       "Approver: ${leave.leaveApprover ?? 'N/A'}",
              //       style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              //     ),
              //     const Spacer(),
              //     if (onApprove != null || onReject != null) ...[
              //       if (onReject != null)
              //         TextButton(
              //           onPressed: onReject,
              //           style: TextButton.styleFrom(
              //             foreg // LEFT: REASON + description (vertically)roundColor: Colors.red,
              //             padding: const EdgeInsets.symmetric(horizontal: 12),
              //           ),
              //           child: const Text("REJECT"),
              //         ),
              //       if (onApprove != null)
              //         ElevatedButton(
              //           onPressed: onApprove,
              //           style: ElevatedButton.styleFrom(
              //             backgroundColor: Colors.green,
              //             padding: const EdgeInsets.symmetric(horizontal: 16),
              //           ),
              //           child: const Text("APPROVE"),
              //         ),
              //     ],
              //   ],
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildDateBlock(
      {required String label, required String date, bool isStart = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isStart ? Colors.blue[50] : Colors.purple[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isStart ?  AppColors.primary : Colors.purple[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isStart ? AppColors.primary : Colors.purple[900],
            ),
          ),
        ],
      ),
    );
  }
}
