import 'dart:convert';

ResponseModel reasonsModelFromJson(String str) =>
    ResponseModel.fromJson(json.decode(str));

String reasonsModelToJson(ResponseModel data) => json.encode(data.toJson());

class ResponseModel {
  ResponseModel({
    this.statusCode,
    this.responseBody,
    this.errorFlag,
    this.path,
    this.headers,
  });

  int? statusCode;
  dynamic responseBody;
  bool? errorFlag;
  String? path;
  dynamic headers;

  factory ResponseModel.fromJson(Map<String, dynamic> json) => ResponseModel(
        statusCode: json["statusCode"],
        responseBody: json["responseBody"],
        errorFlag: json["errorFlag"],
        path: json["path"],
        headers: json["headers"],
      );

  Map<String, dynamic> toJson() => {
        "statusCode": statusCode,
        "responseBody": responseBody!.toJson(),
        "errorFlag": errorFlag,
        "path": path,
        "headers": headers,
      };
}
