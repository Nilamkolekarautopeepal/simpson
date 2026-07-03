class LeaveApproverRequest {
  String? name;
  String? company;
  String? employee;
  String? employeeName;
  String? leaveType;
  String? fromDate;
  String? toDate;
  double? totalLeaveDays;
  String? postingDate;
  String? status;
  String? description;
  String? modified;
  String? owner;
  String? creation;
  String? modifiedBy;
  EmployeeDetails? employeeDetails;

  LeaveApproverRequest({
    this.name,
    this.company,
    this.employee,
    this.employeeName,
    this.leaveType,
    this.fromDate,
    this.toDate,
    this.totalLeaveDays,
    this.postingDate,
    this.status,
    this.description,
    this.modified,
    this.owner,
    this.creation,
    this.modifiedBy,
    this.employeeDetails,
  });

  factory LeaveApproverRequest.fromMap(Map<String, dynamic> json) {
    return LeaveApproverRequest(
      name: json['name'],
      company: json['company'],
      employee: json['employee'],
      employeeName: json['employee_name'],
      leaveType: json['leave_type'],
      fromDate: json['from_date'],
      toDate: json['to_date'],
      totalLeaveDays: (json['total_leave_days'] as num?)?.toDouble(),
      postingDate: json['posting_date'],
      status: json['status'],
      description: json['description'],
      modified: json['modified'],
      owner: json['owner'],
      creation: json['creation'],
      modifiedBy: json['modified_by'],
      employeeDetails: json['employee_details'] != null
          ? EmployeeDetails.fromJson(json['employee_details'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'company': company,
        'employee': employee,
        'employee_name': employeeName,
        'leave_type': leaveType,
        'from_date': fromDate,
        'to_date': toDate,
        'total_leave_days': totalLeaveDays,
        'posting_date': postingDate,
        'status': status,
        'description': description,
        'modified': modified,
        'owner': owner,
        'creation': creation,
        'modified_by': modifiedBy,
        'employee_details': employeeDetails?.toJson(),
      };
}

class EmployeeDetails {
  String? name;
  String? firstName;
  String? lastName;
  String? employeeName;
  String? salutation;
  String? gender;
  String? dateOfBirth;
  String? designation;
  String? leaveApprover;

  EmployeeDetails({
    this.name,
    this.firstName,
    this.lastName,
    this.employeeName,
    this.salutation,
    this.gender,
    this.dateOfBirth,
    this.designation,
    this.leaveApprover,
  });

  factory EmployeeDetails.fromJson(Map<String, dynamic> json) {
    return EmployeeDetails(
      name: json['name'],
      firstName: json['first_name'],
      lastName: json['last_name'],
      employeeName: json['employee_name'],
      salutation: json['salutation'],
      gender: json['gender'],
      dateOfBirth: json['date_of_birth'],
      designation: json['designation'],
      leaveApprover: json['leave_approver'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'first_name': firstName,
        'last_name': lastName,
        'employee_name': employeeName,
        'salutation': salutation,
        'gender': gender,
        'date_of_birth': dateOfBirth,
        'designation': designation,
        'leave_approver': leaveApprover,
      };
}
