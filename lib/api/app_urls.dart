import 'package:simpson/services/auth/auth_service.dart';
import 'package:intl/intl.dart';

class AppURLs {
  static String get payable =>
      "/method/hr_ess.hr_ess.api.expense.get_payable_account?company={${auth.currentUser.company}";

  static String permission({
    required String emp_id,
  }) =>
      "/method/hr_ess.hr_ess.api.role_permission.get_session_user_role_permission?emp_id=${emp_id}";

  static String get proposeOfTravall =>
      "/method/hr_ess.hr_ess.api.expense.get_purpose_of_travel";
  static String get getExpenceApprover =>
      "/method/hr_ess.hr_ess.api.expense.get_expense_approver?employee=${auth.currentUser.name}";
  static String get applyExpenseClaim =>
      "/method/hr_ess.hr_ess.api.expense.createExpensesTransactions";
  static String get leaveApprovalList =>
      "/method/hr_ess.hr_ess.api.leave.approvalTransitionList?org=Indictrans&is_pagination=true&page_size=10&page=1";
  static String expenseList({
    required String month,
    required String year,
    required int page,
  }) =>
      "/method/hr_ess.hr_ess.api.expense.getexpensesTransactions?org=${auth.currentUser.company}&is_pagination=true&page_size=10&month=$month&page=$page&year=$year";
  static String get getCategories => "/categories/getCategories";
  static String get login => "/method/hr_ess.hr_ess.api.login.login";
  static String employeelist({
    required int page,
  }) =>
      "/method/hr_ess.hr_ess.api.profile.get_employee_list?is_pagination=true&page_size=10&page=$page";
  static String get todaybirthday =>
      "/method/hr_ess.hr_ess.api.dashboard.todaybirthday?org=${auth.currentUser.company}";
  static String get forgetpassword =>
      "/method/hr_ess.hr_ess.api.login.forgot_password";
  static String get verifyOTP => "/method/hr_ess.hr_ess.api.login.verify_otp";
  static String get punchAttendance =>
      "/method/hr_ess.hr_ess.api.attendance.punchAttendance";
  static String get address =>
      "/method/hr_ess.hr_ess.api.address.get_address?emp_id=${auth.currentUser.name}";
  static String get upCominBirthday =>
      "/method/hr_ess.hr_ess.api.dashboard.upcomingbirthday?org=${auth.currentUser.company}";
  static String get markAttendance =>
      "/method/hr_ess.hr_ess.api.attendance.punchAttendance";
  static String get getDailyAttendanceDetails =>
      "/method/hr_ess.hr_ess.api.attendance.daily_punch_attendance_list?emp_id=${auth.currentUser.name}&org=${auth.currentUser.company}&attendance_date=${DateFormat('yyyy-MM-dd').format(DateTime.now())}";
  static String get getMonthlyAttendanceDetails =>
      "/method/hr_ess.hr_ess.api.attendance.monthly_attendance_status_wise_filtered_list?emp_id=${auth.currentUser.name}&month=${DateTime.now().month.toString()}&year=${DateTime.now().year.toString()}";
  // static String getDailyAttendanceDetails({required String todaydate}) =>"/method/hr_ess.hr_ess.api.attendance.daily_punch_attendance_list?emp_id=${auth.currentUser.name}&org=${auth.currentUser.company}&attendance_date=${todaydate}";
  static String get addAddress =>
      "/method/hr_ess.hr_ess.api.address.add_address";
  static String getLeaveList(
          {required String month, required String year, required int page}) =>
      "/method/hr_ess.hr_ess.api.leave.leavelist?org=${auth.currentUser.company}&month=$month&page=$page&year=$year&is_pagination=truepage_size=10";
  static String get travalPlanList =>
      "/method/hr_ess.hr_ess.api.expense.gettravelplan?emp_id=${auth.currentUser.name}&org=${auth.currentUser.company}&is_pagination=false";
  static String get leaveTypeList =>
      "/method/hr_ess.hr_ess.api.leave.get_leave_types?emp_id=${auth.currentUser.name}&org=${auth.currentUser.company}";
  static String get applyLeave =>
      "/method/hr_ess.hr_ess.api.leave.add_leave_request";
  static String get expenceApprovalReject =>
      "/method/hr_ess.hr_ess.api.expense.approve_reject_expense_transaction";
  static String get leaveApprovalReject =>
      "/method/hr_ess.hr_ess.api.leave.approve_or_reject_leave";
  static String get addTravelPlan =>
      "/method/hr_ess.hr_ess.api.expense.addtravelplan";
  static String get expenseType =>
      "/method/hr_ess.hr_ess.api.expense.get_expense_type";
  static String get travelType =>
      "/method/hr_ess.hr_ess.api.expense.get_travel_type";
  static String downloadSalarySlip(
          {required int month, required int year, required String org}) =>
      "https://hr-ess-uat.frappe.cloud/api/method/hr_ess.hr_ess.api.salary.download_salaryslip_pdf?month=$month&year=$year&org=$org";
  static String get getEmployeePersonalDetails =>
      "/method/hr_ess.hr_ess.api.profile.get_employee_personal_details?emp_id=${auth.currentUser.name}";
  static String getEmployeeCardPersonalDetails(String empId) =>
      "/method/hr_ess.hr_ess.api.profile.get_employee_personal_details?emp_id=$empId";
  static String getEmployeeAddress(String empId) =>
      "/method/hr_ess.hr_ess.api.address.get_address?emp_id=$empId";
  static String downloadEmployeeSalarySlip(
          {required int month,
          required int year,
          required String org,
          required String empId}) =>
      "https://hr-ess-uat.frappe.cloud/api/method/hr_ess.hr_ess.api.salary.download_salaryslip_pdf?month=$month&year=$year&org=$org&emp_id=$empId";
  static String get leaveCancleRequest =>
      "/method/hr_ess.hr_ess.api.leave.cancel_approved_request";
  static String get travelFunding =>
      "/method/hr_ess.hr_ess.api.expense.get_travel_funding";
}
