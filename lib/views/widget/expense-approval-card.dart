import 'package:simpson/modals/expenseApproval.model.dart';
import 'package:simpson/services/permission_service.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:flutter/material.dart';

class ExpenseCard extends StatelessWidget {
  final ExpenseModel expense;
final GestureTapCallback onTap;
final GestureTapCallback onTapRejected;

  const ExpenseCard({Key? key, required this.expense,required this.onTap, required this.onTapRejected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE3F2FD), Colors.white],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    expense.name ?? 'Unnamed Expense',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                  ),
                  _buildStatusChip(),
                    if(permissionService.can("expense", "approve"))...[
                 InkWell(
                    onTap: () async => onTap(),
                    child: Icon(
                      Icons.add_task_sharp,
                      color: AppColors.primary,
                    ),
                  ),],
                  if(permissionService.can("expense", "reject"))...[
                   InkWell(
                    onTap: () async => onTapRejected(),
                    child: Icon(
                      Icons.cancel_outlined,
                      color: AppColors.primary,
                    ),
                  ),]
                ],
              ),

              const SizedBox(height: 16),

              // Details Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x220D47A1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                        Icons.person_outline, 'Employee', expense.employee),
                    const SizedBox(height: 12),
                    _buildDetailRow(
                        Icons.attach_money,
                        'Amount',
                        expense.totalClaimedAmount != null
                            ? '₹${expense.totalClaimedAmount!.toStringAsFixed(2)}'
                            : null),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.verified_user_outlined, 'Approver',
                        expense.expenseApprover),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.blue.shade300),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value ?? 'Not specified',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildStatusChip() {
    final status = expense.status?.toLowerCase() ?? 'unknown';
    Map<String, Color> statusColors = {
      'draft': Colors.orange,
      'submitted': Colors.blue,
      'approved': Colors.green,
      'rejected': Colors.red,
    };

    final color = statusColors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        expense.status ?? 'Unknown',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
}
