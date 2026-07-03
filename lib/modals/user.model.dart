import 'package:autopeepalApp/modals/role.model.dart';

class User {
  final String? userId;
  final String? username;
  final String? email;
  final String? mobileNo;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? company;
  final String? abbr;
  final String? displayName;
  final List<Role>? empRole;
  final String? designation;
  final String? grade;
  final String? department;
  final String? shiftCode;
  final String? shiftName;
  final String? shiftStartTime;
  final String? shiftEndTime;
  final String? reportingTo;
  final String? lastLogin;

  User({
    this.userId,
    this.username,
    this.email,
    this.mobileNo,
    this.firstName,
    this.lastName,
    this.name,
    this.company,
    this.abbr,
    this.displayName,
    this.empRole,
    this.designation,
    this.grade,
    this.department,
    this.shiftCode,
    this.shiftName,
    this.shiftStartTime,
    this.shiftEndTime,
    this.reportingTo,
    this.lastLogin,
  });

  factory User.empty() {
    return User(
      userId: '',
      username: '',
      email: '',
      mobileNo: '',
      firstName: '',
      lastName: '',
      name: '',
      company: '',
      abbr: '',
      displayName: '',
      empRole: [],
      designation: '',
      grade: '',
      department: '',
      shiftCode: '',
      shiftName: '',
      shiftStartTime: '',
      shiftEndTime: '',
      reportingTo: '',
      lastLogin: '',
    );
  }

  factory User.fromMap(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      mobileNo: json['mobile_no'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      name: json['name'] ?? '',
      company: json['company'] ?? '',
      abbr: json['abbr'] ?? '',
      displayName: json['display_name'] ?? '',
      empRole: json['emp_role'] != null
          ? List<Role>.from(json['emp_role'].map((role) => Role.fromJson(role)))
          : [],
      designation: json['designation'] ?? '',
      grade: json['grade'] ?? '',
      department: json['department'] ?? '',
      shiftCode: json['shift_code'] ?? '',
      shiftName: json['shift_name'] ?? '',
      shiftStartTime: json['shift_starttime'] ?? '',
      shiftEndTime: json['shift_endtime'] ?? '',
      reportingTo: json['reporting_to'] ?? '',
      lastLogin: json['last_login'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId ?? '',
      'username': username ?? '',
      'email': email ?? '',
      'mobile_no': mobileNo ?? '',
      'first_name': firstName ?? '',
      'last_name': lastName ?? '',
      'name': name ?? '',
      'company': company ?? '',
      'abbr': abbr ?? '',
      'display_name': displayName ?? '',
      'emp_role': empRole?.map((role) => role.toJson()).toList() ?? [],
      'designation': designation ?? '',
      'grade': grade ?? '',
      'department': department ?? '',
      'shift_code': shiftCode ?? '',
      'shift_name': shiftName ?? '',
      'shift_starttime': shiftStartTime ?? '',
      'shift_endtime': shiftEndTime ?? '',
      'reporting_to': reportingTo ?? '',
      'last_login': lastLogin ?? '',
    };
  }
}
