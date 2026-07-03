import 'package:simpson/modals/expense.modal.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpenseDatCard extends StatelessWidget {
  final Expense expense;

  const ExpenseDatCard({Key? key, required this.expense}) : super(key: key);

  String _formatCurrency(double? amount) {
    if (amount == null) return '₹0.00';
    return NumberFormat.currency(
      symbol: '₹',
      decimalDigits: 2,
      locale: 'en_IN',
    ).format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final initials = (expense.employeeName ?? 'E').isNotEmpty
        ? expense.employeeName!.substring(0, 1)
        : 'E';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with employee info and status
            Row(
              children: [
                CircleAvatar(
                  // ignore: deprecated_member_use
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    initials,
                    style: TextStyle(
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
                        expense.employeeName ?? 'Expense Report',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary),
                      ),
                      if (expense.empDetails?.designation != null)
                        Text(
                          expense.empDetails!.designation!,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                          ),
                        ),
                    ],
                  ),
                ),
                _buildStatusIndicator(expense.approvalStatus ?? 'Draft'),
              ],
            ),

            const SizedBox(height: 16),

            // Financial summary
            _buildSectionHeader('Financial Summary'),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildAmountBlock(
                  label: 'Grand Total',
                  amount: _formatCurrency(expense.grandTotal),
                  color: Colors.blue[50]!,
                ),
                const SizedBox(width: 8),
                _buildAmountBlock(
                  label: 'Claimed',
                  amount: _formatCurrency(expense.totalClaimedAmount),
                  color: Colors.green[50]!,
                ),
                const SizedBox(width: 8),
                _buildAmountBlock(
                  label: 'Reimbursed',
                  amount: _formatCurrency(expense.totalAmountReimbursed),
                  color: Colors.purple[50]!,
                ),
              ],
            ),

            // const SizedBox(height: 16),

            // Approval and payment info
            // Wrap(
            //   runSpacing: 12,
            //   children: [
            //     if (expense.expenseApprover != null)
            //       _buildInfoRow('Approver', expense.expenseApprover!, Icons.person),
            //     if (expense.postingDate != null)
            //       _buildInfoRow('Posted On', _formatDate(expense.postingDate), Icons.calendar_today),
            //     if (expense.clearanceDate != null)
            //       _buildInfoRow('Cleared On', _formatDate(expense.clearanceDate), Icons.check_circle),
            //     if (expense.modeOfPayment != null)
            //       _buildInfoRow('Payment Mode', expense.modeOfPayment!, Icons.payment),
            //     if (expense.payableAccount != null)
            //       _buildInfoRow('Payable Account', expense.payableAccount!, Icons.account_balance),
            //     if (expense.isPaid != null)
            //       _buildInfoRow(
            //         'Payment Status',
            //         expense.isPaid == 1 ? 'Paid' : 'Unpaid',
            //         expense.isPaid == 1 ? Icons.check : Icons.pending,
            //       ),
            //   ],
            // ),

            // const SizedBox(height: 16),

            // // Additional details
            // if (expense.project != null || expense.costCenter != null || expense.remark != null)
            //   _buildSectionHeader('Additional Details'),
            // const SizedBox(height: 8),
            // Wrap(
            //   spacing: 8,
            //   runSpacing: 8,
            //   children: [
            //     if (expense.project != null && expense.project!.isNotEmpty)
            //       _buildDetailChip('Project: ${expense.project!}', Icons.work),
            //     if (expense.costCenter != null && expense.costCenter!.isNotEmpty)
            //       _buildDetailChip('Cost Center: ${expense.costCenter!}', Icons.attach_money),
            //     if (expense.task != null && expense.task!.isNotEmpty)
            //       _buildDetailChip('Task: ${expense.task!}', Icons.task),
            //     if (expense.deliveryTrip != null && expense.deliveryTrip!.isNotEmpty)
            //       _buildDetailChip('Delivery Trip: ${expense.deliveryTrip!}', Icons.delivery_dining),
            //     if (expense.vehicleLog != null && expense.vehicleLog!.isNotEmpty)
            //       _buildDetailChip('Vehicle: ${expense.vehicleLog!}', Icons.directions_car),
            //   ],
            // ),

            // if (expense.remark != null && expense.remark!.isNotEmpty) ...[
            //   const SizedBox(height: 12),
            //   _buildInfoRow('Remarks', expense.remark!, Icons.note),
            // ],

            // // Expense details table
            // if (expense.expenseDetails != null && expense.expenseDetails!.isNotEmpty) ...[
            //   const SizedBox(height: 16),
            //   _buildSectionHeader('Expense Breakdown'),
            //   const SizedBox(height: 8),
            //   _buildExpenseTable(),
            // ],

            // const SizedBox(height: 8),
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: Text(
            //     'ID: ${expense.name ?? "N/A"} • ${_formatDate(expense.postingDate)}',
            //     style: TextStyle(
            //       fontSize: 12,
            //       color: Colors.grey[600],
            //       fontStyle: FontStyle.italic,
            //     ),
            //   ),
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    final statusColors = {
      'Draft': Colors.orange,
      'Submitted': Colors.blue,
      'Approved': Colors.green,
      'Rejected': Colors.red,
    };

    final color = statusColors[status] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildAmountBlock({
    required String label,
    required String amount,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black,
              ),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                TextSpan(
                  text: value,
                  style: TextStyle(color: Colors.grey[700]),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildDetailChip(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildExpenseTable() {
    // Assuming expenseDetails is a List<List<dynamic>> where each inner list represents a row
    // and the first row is the header
    if (expense.expenseDetails == null || expense.expenseDetails!.isEmpty) {
      return const SizedBox();
    }

    final headers =
        expense.expenseDetails!.first.map((e) => e.toString()).toList();
    final rows = expense.expenseDetails!.sublist(1);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 16,
        headingRowColor: WidgetStateProperty.all(Colors.blue[50]),
        columns:
            headers.map((header) => DataColumn(label: Text(header))).toList(),
        rows: rows.map((row) {
          return DataRow(
            cells: row.map((cell) {
              // Format amounts if they appear to be numbers
              final value = cell.toString();
              final isNumeric = double.tryParse(value) != null;
              final displayValue =
                  isNumeric ? _formatCurrency(double.tryParse(value)) : value;

              return DataCell(Text(
                displayValue,
                style: TextStyle(
                  fontWeight: isNumeric ? FontWeight.bold : FontWeight.normal,
                ),
              ));
            }).toList(),
          );
        }).toList(),
      ),
    );
  }
}
