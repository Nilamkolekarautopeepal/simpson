class PermissionData {
  final List<String> roles;
  final Map<String, dynamic> modules;

  PermissionData({required this.roles, required this.modules});

  factory PermissionData.fromJson(Map<String, dynamic> json) {
    final inner = json['message']['message'];
    final roles = List<String>.from(inner['role']);
    
    // Remove known non-permission keys
    final modules = Map<String, dynamic>.from(inner)
      ..remove('message')
      ..remove('role');

    return PermissionData(roles: roles, modules: modules);
  }
}
