class ExpenseModel {
  final String? name;
  final String? employee;
  final double? totalClaimedAmount;
  final String? expenseApprover;
  final String? status;

  ExpenseModel({
    this.name,
    this.employee,
    this.totalClaimedAmount,
    this.expenseApprover,
    this.status,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> json) {
    return ExpenseModel(
      name: json['name'] as String?,
      employee: json['employee'] as String?,
      totalClaimedAmount: (json['total_claimed_amount'] != null)
          ? (json['total_claimed_amount'] as num).toDouble()
          : null,
      expenseApprover: json['expense_approver'] as String?,
      status: json['status'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (employee != null) 'employee': employee,
      if (totalClaimedAmount != null) 'total_claimed_amount': totalClaimedAmount,
      if (expenseApprover != null) 'expense_approver': expenseApprover,
      if (status != null) 'status': status,
    };
  }
}
