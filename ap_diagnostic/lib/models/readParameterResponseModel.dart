import 'dart:typed_data';

class ReadParameterResponse {
  int? pidId;
  String? pidName;
  String? status;
  Uint8List? dataArray;
  List<ReadParameterVariableResponse> variables; // Use empty list if null

  ReadParameterResponse({
    this.pidId,
    this.pidName,
    this.status,
    this.dataArray,
    List<ReadParameterVariableResponse>? variables,
  }) : variables = variables ?? [];

factory ReadParameterResponse.fromJson(Map<String, dynamic> json) {
  Uint8List? parsedData;

  final data = json['DataArray'];

  if (data != null) {
    if (data is List) {
      parsedData = Uint8List.fromList(List<int>.from(data));
    } else if (data is String) {
      parsedData = Uint8List.fromList(data.codeUnits);
    }
  }

  return ReadParameterResponse(
    pidId: json['pid_id'] as int?,
    pidName: json['pid_name'] as String?,
    status: json['Status'] as String?,
    dataArray: parsedData,
    variables: json['Variables'] != null
        ? (json['Variables'] as List)
            .map((i) => ReadParameterVariableResponse.fromJson(i))
            .toList()
        : [],
  );
}

  Map<String, dynamic> toJson() => {
        'pid_id': pidId,
        'pid_name': pidName,
        'Status': status,
        'DataArray': dataArray?.toList(),
        'Variables': variables.map((v) => v.toJson()).toList(),
      };
}

class ReadParameterVariableResponse {
  int? pidNumber;
  String? pidName;
  String? responseValue; // e.g., "850 RPM" or "12.5 V"

  ReadParameterVariableResponse({
    this.pidNumber,
    this.pidName,
    this.responseValue,
  });

  factory ReadParameterVariableResponse.fromJson(Map<String, dynamic> json) {
    return ReadParameterVariableResponse(
      pidNumber: json['pidNumber'],
      pidName: json['pidName'],
      responseValue: json['responseValue'],
    );
  }

  Map<String, dynamic> toJson() => {
        'pidNumber': pidNumber,
        'pidName': pidName,
        'responseValue': responseValue,
      };
}

class ReadParameterResponseIvn {
  String? status;
  String? pidName;
  String? responseValue;
  String? unit;

  ReadParameterResponseIvn({
    this.status,
    this.pidName,
    this.responseValue,
    this.unit,
  });

  factory ReadParameterResponseIvn.fromJson(Map<String, dynamic> json) {
    return ReadParameterResponseIvn(
      status: json['Status'] ?? "",
      pidName: json['pidName'] ?? "",
      responseValue: json['responseValue'] ?? "",
      unit: json['Unit'] ?? "",
    );
  }

  Map<String, dynamic> toJson() => {
        'Status': status,
        'pidName': pidName,
        'responseValue': responseValue,
        'Unit': unit,
      };
}