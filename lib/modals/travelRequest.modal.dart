class TravelRequest {
  String? name;
  String? purposeOfTravel;
  String? travelType;
  String? travelFunding;
  String? travelProof;
  String? company;
  String? employee;
  String? employeeName;
  String? cellNumber;
  String? preferedEmail;
  String? dateOfBirth;
  int? docstatus;
  String? modified;
  EmpDetails? empDetails;
  String? travelFrom;
  String? travelTo;
  String? departureDate;
  Map<String, dynamic>? travelExpense;

  TravelRequest({
    this.name,
    this.purposeOfTravel,
    this.travelType,
    this.travelFunding,
    this.travelProof,
    this.company,
    this.employee,
    this.employeeName,
    this.cellNumber,
    this.preferedEmail,
    this.dateOfBirth,
    this.docstatus,
    this.modified,
    this.empDetails,
    this.travelFrom,
    this.travelTo,
    this.departureDate,
    this.travelExpense,
  });

  factory TravelRequest.fromMap(Map<String, dynamic> json) {
    return TravelRequest(
      name: json['name'],
      purposeOfTravel: json['purpose_of_travel'],
      travelType: json['travel_type'],
      travelFunding: json['travel_funding'],
      travelProof: json['travel_proof'],
      company: json['company'],
      employee: json['employee'],
      employeeName: json['employee_name'],
      cellNumber: json['cell_number'],
      preferedEmail: json['prefered_email'],
      dateOfBirth: json['date_of_birth'],
      docstatus: json['docstatus'],
      modified: json['modified'],
      empDetails: json['emp_details'] != null
          ? EmpDetails.fromJson(json['emp_details'])
          : EmpDetails.empty(),
      travelFrom: json['travel_from'],
      travelTo: json['travel_to'],
      departureDate: json['departure_date'],
      travelExpense: json['travel_expense'] != null
          ? Map<String, dynamic>.from(json['travel_expense'])
          : {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'purpose_of_travel': purposeOfTravel,
      'travel_type': travelType,
      'travel_funding': travelFunding,
      'travel_proof': travelProof,
      'company': company,
      'employee': employee,
      'employee_name': employeeName,
      'cell_number': cellNumber,
      'prefered_email': preferedEmail,
      'date_of_birth': dateOfBirth,
      'docstatus': docstatus,
      'modified': modified,
      'emp_details': empDetails?.toJson(),
      'travel_from': travelFrom,
      'travel_to': travelTo,
      'departure_date': departureDate,
      'travel_expense': travelExpense,
    };
  }
}

class EmpDetails {
  String? name;
  String? employeeName;
  String? designation;

  EmpDetails({this.name, this.employeeName, this.designation});

  factory EmpDetails.fromJson(Map<String, dynamic> json) {
    return EmpDetails(
      name: json['name'],
      employeeName: json['employee_name'],
      designation: json['designation'],
    );
  }

  factory EmpDetails.empty() {
    return EmpDetails(
      name:"",
      employeeName: "",
      designation: "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'employee_name': employeeName,
      'designation': designation,
    };
  }
}
