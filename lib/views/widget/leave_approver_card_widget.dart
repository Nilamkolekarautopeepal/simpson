import 'package:autopeepalApp/modals/leaveApproverRequest.modal.dart';
import 'package:autopeepalApp/services/permission_service.dart';
import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LeaveApproverCard extends StatelessWidget {
  final LeaveApproverRequest request;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const LeaveApproverCard({
    Key? key,
    required this.request,
    this.onApprove,
    this.onReject,
  }) : super(key: key);

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'approved':
        return AppColors.green;
      case 'rejected':
        return AppColors.error;
      case 'open':
        return AppColors.primary;
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
    final emp = request.employeeDetails;
    final statusColor = _getStatusColor(request.status);
    final formattedFrom = _formatDate(request.fromDate);
    final formattedTo = _formatDate(request.toDate);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: statusColor,
              width: 6,
            ),
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
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      request.employeeName?[0] ?? '?',
                      style: const TextStyle(
                        color: Colors.blue,
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
                          request.employeeName ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          emp?.designation ?? 'N/A',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
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
                      request.status?.toUpperCase() ?? 'N/A',
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
                    // Leave type and total days
                    Row(
                      children: [
                        _buildDetailChip(
                          icon: Icons.beach_access,
                          value: request.leaveType ?? 'N/A',
                        ),
                        const Spacer(),
                        _buildDetailChip(
                          icon: Icons.calendar_today,
                          value: '${request.totalLeaveDays ?? 0} days',
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Date range
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

              // Reason section
              if (request.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 16),
                const Text(
                  "REASON",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  request.description ?? "",
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],

              // Approver and actions
              const Divider(height: 24, thickness: 1),

              Row(
                children: [
                  // const Icon(
                  //   Icons.person_outline,
                  //   size: 16,
                  //   color: Colors.grey,
                  // ),
                  // const SizedBox(width: 6),
                  // Text(
                  //   "Approver: ${emp?.leaveApprover ?? 'N/A'}",
                  //   style: TextStyle(

                  //     fontSize: 13,
                  //     color: Colors.grey[600],
                  //   ),
                  // ),
                  const Spacer(),
                  if (onApprove != null || onReject != null) ...[
                    if (onReject != null)
                      if (permissionService.can("expense", "reject")) ...[
                        TextButton(
                          onPressed: onReject,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text("REJECT"),
                        ),
                      ],
                    if (onApprove != null)
                      if (permissionService.can("expense", "approve")) ...[
                        ElevatedButton(
                          onPressed: onApprove,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                          ),
                          child: const Text("APPROVE"),
                        ),
                      ]
                  ],
                ],
              ),
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
          Icon(icon, size: 18, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
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
              color: isStart ? Colors.blue[700] : Colors.purple[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isStart ? Colors.blue[900] : Colors.purple[900],
            ),
          ),
        ],
      ),
    );
  }
}
