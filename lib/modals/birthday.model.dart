class Birthday {
  final String? name;
  final String? firstName;
  final String? lastName;
  final String? employeeName;
  final String? gender;
  final String? salutation;
  final String? designation;
  final String? companyEmail;
  final String? cellNumber;
  final DateTime? dateOfBirth;

  Birthday({
    this.name,
    this.firstName,
    this.lastName,
    this.employeeName,
    this.gender,
    this.salutation,
    this.designation,
    this.companyEmail,
    this.cellNumber,
    this.dateOfBirth,
  });

  factory Birthday.fromMap(Map<String, dynamic> json) {
    return Birthday(
      name: json['name'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      employeeName: json['employee_name'] as String?,
      gender: json['gender'] as String?,
      salutation: json['salutation'] as String?,
      designation: json['designation'] as String?,
      companyEmail: json['company_email'] as String?,
      cellNumber: json['cell_number'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.tryParse(json['date_of_birth'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'first_name': firstName,
      'last_name': lastName,
      'employee_name': employeeName,
      'gender': gender,
      'salutation': salutation,
      'designation': designation,
      'company_email': companyEmail,
      'cell_number': cellNumber,
      'date_of_birth': dateOfBirth?.toIso8601String(),
    };
  }
}
