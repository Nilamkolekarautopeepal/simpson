// import 'package:simpson/services/auth/auth_service.dart';
// import 'package:get/get.dart';

// class PermissionService extends GetxService {
//   // Singleton instance
//   static PermissionService get instance => Get.find<PermissionService>();

//   // Current user roles
//   List<Object> get currentUserRoles => auth.currentUser.empRole ?? [];

//   // Current employee ID
//   String get currentEmpId => auth.currentUser.name ?? '';

//   // Role check methods
//   bool hasRole(String roleCode) => currentUserRoles.contains(roleCode);
//   bool get isEmployee => hasRole('Employee');
//   bool get isHRUser => hasRole('HR User');
//   bool get isHRManager => hasRole('HR Manager');a
//   bool get isLeaveApprover => hasRole('Leave Approver');
//   bool get isExpenseApprover => hasRole('Expense Approver');
//   bool get isDeskUser => hasRole('Desk User');
//   bool get isGuest => hasRole('Guest');
//   bool get hasAllAccess => hasRole('All');
//   bool get isHelpDeskAdmin => hasRole('HelpDesk Admin');
//   bool get isAdmin => hasRole('admin');
//   bool get isAssetManager => hasRole('Asset Manager');
//   bool get isSystemManager => hasRole('System Manager');

//   // Check if user can access data for another employee
//   bool canAccessEmployeeData(String targetEmpId) {
//     return targetEmpId == currentEmpId || 
//            isHRUser || 
//            isHRManager || 
//            isLeaveApprover || 
//            isExpenseApprover || 
//            isAdmin ||
//            hasAllAccess;
//   }

//   // Dashboard permissions
//   bool get canViewDashboard => !isGuest;

//   // Employee profile permissions
//   bool canViewEmployeeProfile(String empId) => canAccessEmployeeData(empId);
//   bool canEditEmployeeProfile(String empId) => canAccessEmployeeData(empId) && (isHRManager || isAdmin);

//   // Leave management permissions
//   bool canApplyLeave(String empId) => empId == currentEmpId || isHRManager;
//   bool canApproveLeave() => isLeaveApprover || isHRManager || isAdmin;
//   bool canViewLeaveReports() => isHRManager || isLeaveApprover || isAdmin;

//   // Expense management permissions
//   bool canSubmitExpense(String empId) => empId == currentEmpId;
//   bool canApproveExpense() => isExpenseApprover || isHRManager || isAdmin;
//   bool canViewExpenseReports() => isExpenseApprover || isHRManager || isAdmin;

//   // Attendance permissions
//   bool canMarkAttendance(String empId) => empId == currentEmpId || isHRManager;
//   bool canViewAttendanceReports() => isHRManager || isAdmin;

//   // System administration permissions
//   bool get canManageSystemSettings => isAdmin || isSystemManager;
//   bool get canManageUserAccounts => isAdmin || isHRManager;

//   // Helpdesk permissions
//   bool get canManageTickets => isHelpDeskAdmin || isAdmin;

//   // Asset management permissions
//   bool get canManageAssets => isAssetManager || isAdmin;

//   // Check if user has any of the specified roles
//   bool hasAnyRole(List<String> roles) {
//     return currentUserRoles.any((role) => roles.contains(role));
//   }

//   // Check if user has all of the specified roles
//   bool hasAllRoles(List<String> roles) {
//     return roles.every((role) => currentUserRoles.contains(role));
//   }
// }