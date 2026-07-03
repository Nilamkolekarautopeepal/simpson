class MontlyAttendance {
  String? name;
  String? employee;
  String? employeeName;
  String? attendanceDate;
  String? company;
  String? status;
  String? shift;
  // int? lateEntry;
  // int? earlyExit;
  String? owner;
  String? modifiedBy;

  MontlyAttendance({
    this.name,
    this.employee,
    this.employeeName,
    this.attendanceDate,
    this.company,
    this.status,
    this.shift,
    // this.lateEntry,
    // this.earlyExit,
    this.owner,
    this.modifiedBy,
  });

  factory MontlyAttendance.fromMap(Map<String, dynamic> json) {
    return MontlyAttendance(
      name: json['name'] as String?,
      employee: json['employee'] as String?,
      employeeName: json['employee_name'] as String?,
      attendanceDate: json['attendance_date'] as String?,
      company: json['company'] as String?,
      status: json['status'] as String?,
      shift: json['shift'] as String?,
      // lateEntry: json['late_entry'] as int?,
      // earlyExit: json['early_exit'] as int?,
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
      // 'late_entry': lateEntry,
      // 'early_exit': earlyExit,
      'owner': owner,
      'modified_by': modifiedBy,
    };
  }
}
