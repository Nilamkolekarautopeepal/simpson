class Employee {
  final String? name;
  final String? salutation;
  final String? firstName;
  final String? middleName;
  final String? lastName;
  final String? dateOfBirth;
  final String? gender;
  final String? maritalStatus;
  final String? companyEmail;
  final String? personalEmail;
  final String? cellNumber;
  final String? bloodGroup;
  final String? dateOfJoining;
  final String? finalConfirmationDate;
  final int? noticeNumberOfDays;
  final String? dateOfRetirement;
  final String? company;
  final String? status;
  final String? holidayList;
  final String? creation;
  final String? modified;
  final String? owner;
  final String? modifiedBy;
  final String? displayName;
  final String? resignationLetterDate;
  final String? relievingDate;

  Employee({
    this.name,
    this.salutation,
    this.firstName,
    this.middleName,
    this.lastName,
    this.dateOfBirth,
    this.gender,
    this.maritalStatus,
    this.companyEmail,
    this.personalEmail,
    this.cellNumber,
    this.bloodGroup,
    this.dateOfJoining,
    this.finalConfirmationDate,
    this.noticeNumberOfDays,
    this.dateOfRetirement,
    this.company,
    this.status,
    this.holidayList,
    this.creation,
    this.modified,
    this.owner,
    this.modifiedBy,
    this.displayName,
    this.resignationLetterDate,
    this.relievingDate,
  });

  factory Employee.fromMap(Map<String, dynamic> data) {
    return Employee(
      name: data['name'] as String?,
      salutation: data['salutation'] as String?,
      firstName: data['first_name'] as String?,
      middleName: data['middle_name'] as String?,
      lastName: data['last_name'] as String?,
      dateOfBirth: data['date_of_birth'] as String?,
      gender: data['gender'] as String?,
      maritalStatus: data['marital_status'] as String?,
      companyEmail: data['company_email'] as String?,
      personalEmail: data['personal_email'] as String?,
      cellNumber: data['cell_number'] as String?,
      bloodGroup: data['blood_group'] as String?,
      dateOfJoining: data['date_of_joining'] as String?,
      finalConfirmationDate: data['final_confirmation_date'] as String?,
      noticeNumberOfDays: data['notice_number_of_days'] as int?,
      dateOfRetirement: data['date_of_retirement'] as String?,
      company: data['company'] as String?,
      status: data['status'] as String?,
      holidayList: data['holiday_list'] as String?,
      creation: data['creation'] as String?,
      modified: data['modified'] as String?,
      owner: data['owner'] as String?,
      modifiedBy: data['modified_by'] as String?,
      displayName: data['display_name'] as String?,
      resignationLetterDate: data['resignation_letter_date'] as String?,
      relievingDate: data['relieving_date'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'salutation': salutation,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'marital_status': maritalStatus,
      'company_email': companyEmail,
      'personal_email': personalEmail,
      'cell_number': cellNumber,
      'blood_group': bloodGroup,
      'date_of_joining': dateOfJoining,
      'final_confirmation_date': finalConfirmationDate,
      'notice_number_of_days': noticeNumberOfDays,
      'date_of_retirement': dateOfRetirement,
      'company': company,
      'status': status,
      'holiday_list': holidayList,
      'creation': creation,
      'modified': modified,
      'owner': owner,
      'modified_by': modifiedBy,
      'display_name': displayName,
      'resignation_letter_date': resignationLetterDate,
      'relieving_date': relievingDate,
    };
  }
}
