// import 'dart:typed_data';

// class WriteParameterResponse {
//   String? status;
//   Uint8List? dataArray;
//   int? pidNumber;
//   String? pidName;
//   String? responseValue;

//   WriteParameterResponse({
//     this.status,
//     this.dataArray,
//     this.pidNumber,
//     this.pidName,
//     this.responseValue,
//   });

//   factory WriteParameterResponse.fromJson(Map<String, dynamic> json) {
//     return WriteParameterResponse(
//       status: json['Status'],
//       dataArray: json['DataArray'] != null 
//           ? Uint8List.fromList(List<int>.from(json['DataArray'])) 
//           : null,
//       pidNumber: json['pidNumber'],
//       pidName: json['pidName'],
//       responseValue: json['responseValue'],
//     );
//   }
// }

// class WriteParameterResponseStatus {
//   String? status;

//   WriteParameterResponseStatus({this.status});

//   factory WriteParameterResponseStatus.fromJson(Map<String, dynamic> json) {
//     return WriteParameterResponseStatus(
//       status: json['Status'],
//     );
//   }
// }

import 'dart:typed_data';

class WriteParameterResponse {
  String? status;
  Uint8List? dataArray;
  int? pidNumber;
  String? pidName;
  String? responseValue;

  WriteParameterResponse({
    this.status,
    this.dataArray,
    this.pidNumber,
    this.pidName,
    this.responseValue,
  });

  factory WriteParameterResponse.fromJson(Map<String, dynamic> json) {
    return WriteParameterResponse(
      status: json['Status'],
      dataArray: json['DataArray'] != null
          ? Uint8List.fromList(List<int>.from(json['DataArray']))
          : null,
      pidNumber: json['pidNumber'],
      pidName: json['pidName'],
      responseValue: json['responseValue'],
    );
  }

  /// Convert object → Map
  Map<String, dynamic> toMap() {
    return {
      "Status": status,
      "DataArray": dataArray?.toList(),
      "pidNumber": pidNumber,
      "pidName": pidName,
      "responseValue": responseValue,
    };
  }

  /// Convert object → JSON
  Map<String, dynamic> toJson() => toMap();
}

class WriteParameterResponseStatus {
  String? status;

  WriteParameterResponseStatus({this.status});

  factory WriteParameterResponseStatus.fromJson(Map<String, dynamic> json) {
    return WriteParameterResponseStatus(
      status: json['Status'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "Status": status,
    };
  }

  Map<String, dynamic> toJson() => toMap();
}