class Leave {
  String? name;
  Employee? employee;
  String? leaveType;
  String? fromDate;
  String? toDate;
  double? totalLeaveDays;
  String? postingDate;
  String? description;
  String? leaveApprover;
  String? status;
  int? halfDay;
  String? halfDayDate;
  String? creation;
  String? modified;

  Leave({
    this.name,
    this.employee,
    this.leaveType,
    this.fromDate,
    this.toDate,
    this.totalLeaveDays,
    this.postingDate,
    this.description,
    this.leaveApprover,
    this.status,
    this.halfDay,
    this.halfDayDate,
    this.creation,
    this.modified,
  });

  factory Leave.fromMap(Map<String, dynamic> json) {
    return Leave(
      name: json['name'],
      employee: json['employee'] != null
          ? Employee.fromJson(json['employee'])
          : null,
      leaveType: json['leave_type'],
      fromDate: json['from_date'],
      toDate: json['to_date'],
      totalLeaveDays: (json['total_leave_days'] != null)
          ? (json['total_leave_days'] as num).toDouble()
          : null,
      postingDate: json['posting_date'],
      description: json['description'],
      leaveApprover: json['leave_approver'],
      status: json['status'],
      halfDay: json['half_day'],
      halfDayDate: json['half_day_date'],
      creation: json['creation'],
      modified: json['modified'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employee': employee?.toJson(),
      'leave_type': leaveType,
      'from_date': fromDate,
      'to_date': toDate,
      'total_leave_days': totalLeaveDays,
      'posting_date': postingDate,
      'description': description,
      'leave_approver': leaveApprover,
      'status': status,
      'half_day': halfDay,
      'half_day_date': halfDayDate,
      'creation': creation,
      'modified': modified,
    };
  }
}

class Employee {
  String? name;
  String? firstName;
  String? lastName;
  String? salutation;
  String? gender;
  String? designation;
  String? companyEmail;
  String? cellNumber;
  String? dateOfBirth;
  String? displayName;

  Employee({
    this.name,
    this.firstName,
    this.lastName,
    this.salutation,
    this.gender,
    this.designation,
    this.companyEmail,
    this.cellNumber,
    this.dateOfBirth,
    this.displayName,
  });

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      name: json['name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      salutation: json['salutation'],
      gender: json['gender'],
      designation: json['designation'],
      companyEmail: json['company_email'],
      cellNumber: json['cell_number'],
      dateOfBirth: json['date_of_birth'],
      displayName: json['display_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'salutation': salutation,
      'gender': gender,
      'designation': designation,
      'company_email': companyEmail,
      'cell_number': cellNumber,
      'date_of_birth': dateOfBirth,
      'display_name': displayName,
    };
  }
}


// Leave Type
class LeaveType {
  String? leaveType;
  double? totalLeavesAllocated;

  LeaveType({
    this.leaveType,
    this.totalLeavesAllocated,
  });

  factory LeaveType.fromMap(Map<String, dynamic> json) {
    return LeaveType(
      leaveType: json['leave_type'],
      totalLeavesAllocated: json['total_leaves_allocated'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'leave_type': leaveType,
      'total_leaves_allocated': totalLeavesAllocated,
    };
  }
}
