import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/utils/app_logs.dart';

final PermissionService permissionService = PermissionService();

class PermissionService {
  Map<String, dynamic> _permissionData = {};
  List<String> _roles = [];

  /// Load flat structure from AppPreferences
  Future<void> loadPermissions() async {
    appLogs("Loading permission data...");
    final stored = await AppPreferences.getPermissionData();

    if (stored != null && stored.isNotEmpty) {
      _permissionData = stored;
      _roles = List<String>.from(_permissionData['role'] ?? []);
      appLogs("Roles loaded: $_roles");
    } else {
      _permissionData = {};
      _roles = [];
    }
  }

  /// Get roles
  List<String> get roles => _roles;

  /// Get permissions for a module (e.g., 'leave', 'employee')
  Map<String, dynamic> getPermissionsFor(String module) {
    return Map<String, dynamic>.from(_permissionData[module] ?? {});
  }

  /// Check if a module has a specific permission
  bool can(String module, String action) {
    return _permissionData[module]?[action] == true;
  }

  /// Special for dashboard view
  bool get canViewDashboard {
    return _permissionData['dashboard']?['view'] == true;
  }

  /// Clear everything
  Future<void> clearPermissions() async {
    _permissionData = {};
    _roles = [];
    await AppPreferences.clearPermissionData();
  }
}
