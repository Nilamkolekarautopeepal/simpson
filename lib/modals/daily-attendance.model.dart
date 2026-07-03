class DailyAttendance {
  String? name;
  String? employee;
  String? employeeName;
  String? attendanceDate;
  String? company;
  String? status;
  String? shift;
  int? earlyExit;
  String? owner;
  String? modifiedBy;

  
  factory DailyAttendance.empty() {
  return DailyAttendance(
    name: null,
    employee: null,
    employeeName: null,
    attendanceDate: null,
    company: null,
    status: null,
    shift: null,
    earlyExit: null,
    owner: null,
    modifiedBy: null,
  );
}


  DailyAttendance({
    this.name,
    this.employee,
    this.employeeName,
    this.attendanceDate,
    this.company,
    this.status,
    this.shift,
    this.earlyExit,
    this.owner,
    this.modifiedBy,
  });

  factory DailyAttendance.fromMap(Map<String, dynamic> json) {
    return DailyAttendance(
      name: json['name'] as String?,
      employee: json['employee'] as String?,
      employeeName: json['employee_name'] as String?,
      attendanceDate: json['attendance_date'] as String?,
      company: json['company'] as String?,
      status: json['status'] as String?,
      shift: json['shift'] as String?,
      earlyExit: json['early_exit'] is int ? json['early_exit'] as int? : int.tryParse(json['early_exit']?.toString() ?? '0'),
      owner: json['owner'] as String?,
      modifiedBy: json['modified_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employee': employee,
      'employee_name': employeeName,
      'attendance_date': attendanceDate,
      'company': company,
      'status': status,
      'shift': shift,
      'early_exit': earlyExit,
      'owner': owner,
      'modified_by': modifiedBy,
    };
  }
}
