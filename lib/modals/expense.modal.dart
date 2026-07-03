class Expense {
  String? name;
  String? expenseApprover;
  String? approvalStatus;
  String? employee;
  String? employeeName;
  String? company;
  double? grandTotal;
  double? totalClaimedAmount;
  double? totalAmountReimbursed;
  String? postingDate;
  int? isPaid;
  String? modeOfPayment;
  String? payableAccount;
  String? clearanceDate;
  String? remark;
  String? project;
  String? costCenter;
  String? status;
  String? task;
  String? deliveryTrip;
  String? vehicleLog;
  EmpDetails? empDetails;
  List<List<dynamic>>? expenseDetails;

  Expense({
    this.name,
    this.expenseApprover,
    this.approvalStatus,
    this.employee,
    this.employeeName,
    this.company,
    this.grandTotal,
    this.totalClaimedAmount,
    this.totalAmountReimbursed,
    this.postingDate,
    this.isPaid,
    this.modeOfPayment,
    this.payableAccount,
    this.clearanceDate,
    this.remark,
    this.project,
    this.costCenter,
    this.status,
    this.task,
    this.deliveryTrip,
    this.vehicleLog,
    this.empDetails,
    this.expenseDetails,
  });

  factory Expense.fromMap(Map<String, dynamic> json) {
    return Expense(
      name: json['name'] ?? "",
      expenseApprover: json['expense_approver']  ?? "",
      approvalStatus: json['approval_status']?? "",
      employee: json['employee']?? "",
      employeeName: json['employee_name'] ?? "" ,
      company: json['company'] ?? "" ,
      grandTotal: (json['grand_total'] as num?)?.toDouble(),
      totalClaimedAmount: (json['total_claimed_amount'] as num?)?.toDouble(),
      totalAmountReimbursed: (json['total_amount_reimbursed'] as num?)?.toDouble(),
      postingDate: json['posting_date'] ?? "" ,
      isPaid: (json['is_paid'] as num?)?.toInt() ,
      modeOfPayment: json['mode_of_payment'] ?? "" ,
      payableAccount: json['payable_account'] ?? "" ,
      clearanceDate: json['clearance_date'] ?? "" ,
      remark: json['remark'] ?? "" ,
      project: json['project'] ?? "" ,
      costCenter: json['cost_center'] ?? "" ,
      status: json['status'] ?? "" ,
      task: json['task'] ?? "" ,
      deliveryTrip: json['delivery_trip'] ?? "" ,
      vehicleLog: json['vehicle_log'] ?? "" ,
      empDetails: json['emp_details'] != null
          ? EmpDetails.fromJson(json['emp_details'])
          : null,
      expenseDetails: json['expense_details'] != null
          ? List<List<dynamic>>.from(
              json['expense_details'].map<List<dynamic>>(
                (e) => List<dynamic>.from(e),
              ),
            )
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'expense_approver': expenseApprover,
      'approval_status': approvalStatus,
      'employee': employee,
      'employee_name': employeeName,
      'company': company,
      'grand_total': grandTotal,
      'total_claimed_amount': totalClaimedAmount,
      'total_amount_reimbursed': totalAmountReimbursed,
      'posting_date': postingDate,
      'is_paid': isPaid,
      'mode_of_payment': modeOfPayment,
      'payable_account': payableAccount,
      'clearance_date': clearanceDate,
      'remark': remark,
      'project': project,
      'cost_center': costCenter,
      'status': status,
      'task': task,
      'delivery_trip': deliveryTrip,
      'vehicle_log': vehicleLog,
      'emp_details': empDetails?.toJson(),
      'expense_details': expenseDetails,
    };
  }
}

class EmpDetails {
  String? name;
  String? employeeName;
  String? designation;
  String? grade;

  EmpDetails({
    this.name,
    this.employeeName,
    this.designation,
    this.grade,
  });

  factory EmpDetails.fromJson(Map<String, dynamic> json) {
    return EmpDetails(
      name: json['name'] ?? "" ,
      employeeName: json['employee_name'] ?? "" ,
      designation: json['designation'] ?? "" ,
      grade: json['grade'] ?? "" ,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employee_name': employeeName,
      'designation': designation,
      'grade': grade,
    };
  }
}
