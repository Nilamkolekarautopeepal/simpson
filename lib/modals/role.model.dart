class Role {
  final String id;
  final String roleCode;
  final String roleName;

  Role({
    required this.id,
    required this.roleCode,
    required this.roleName,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['id'],
      roleCode: json['role_code'],
      roleName: json['role_name'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role_code': roleCode,
      'role_name': roleName,
    };
  }
}
