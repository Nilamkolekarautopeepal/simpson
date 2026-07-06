class ReadDtcResponseModel {
  String? status;
  
  /// Represents the 2D array from .NET [Code, Description/Status]
  List<List<String>>? dtcs;
  
  int? noofdtc;

  ReadDtcResponseModel({
    this.status,
    this.dtcs,
    this.noofdtc,
  });

  factory ReadDtcResponseModel.fromJson(Map<String, dynamic> json) {
    return ReadDtcResponseModel(
      status: json['status'],
      noofdtc: json['noofdtc'],
      // Logic to handle the conversion of a 2D array if coming from JSON
      dtcs: json['dtcs'] != null
          ? (json['dtcs'] as List).map((row) => List<String>.from(row)).toList()
          : null,
    );
  }
}