class ExpenseTypeModel {
  final String expenseType;

  ExpenseTypeModel({required this.expenseType});

  factory ExpenseTypeModel.fromJson(Map<String, dynamic> json) {
    return ExpenseTypeModel(
      expenseType: json['expense_type'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'expense_type': expenseType,
    };
  }
}
