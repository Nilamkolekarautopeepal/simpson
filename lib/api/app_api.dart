import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/api/dev/methods.dart';
import 'package:simpson/api/app_envirments.dart';
import 'package:simpson/api/dev/dev_service.dart';
import 'package:simpson/utils/app_logs.dart';
import 'package:simpson/utils/extension/extension/map_extensions.dart';
import 'package:simpson/utils/keys/api_keys.dart';
import 'package:simpson/utils/strings.dart';
import 'package:simpson/utils/ui_helper.dart/app_tost.dart';
import 'package:dio/dio.dart';
import 'package:http/http.dart' as http;

class AppAPIs {
  static const int timeOutCode = 504;
  static const int serverErrorCode = 600;
  static const int errorStatusCode = 00;
  static const int maxServerErrorCode = 9999;
  static int get timeoutDuration => 120;
  static String  token = "";
  
  static Future<Map<String, String>> get requestHeaders async => {
        APIKeys.authorization:await AppPreferences.getToken() ?? "",
        "Content-Type": "application/json"
      };

  static Dio dio = new Dio(BaseOptions(baseUrl: AppEnvironment.baseUrl));
  static setBaseURL() {
    apiLogs("AppAPI setBaseURL : ${AppEnvironment.baseUrl}");
    dio = new Dio(BaseOptions(baseUrl: AppEnvironment.baseUrl));
  }

  static Future<Map<String, dynamic>> get(
    String path, {
    // ProgressCallback onReceiveProgress,
    bool logResponse = true,
  }) async {
    token= await AppPreferences.getToken() ?? "";
    Map<String, dynamic> responseData = new Map();
    apiLogs(
        'AppAPI: post: path:${dio.options.baseUrl}$path \n requestHeaders${getPrettyMap(await requestHeaders)}');
    if (logResponse) appLogs('AppAPI: post:$path');
    bool errorFlag = false;
    bool timeOutFlag = false;
  
    try { 
      Response response = await dio
          .get(Uri.encodeFull(path),
              options: Options(
                  headers: await {
        APIKeys.authorization:await AppPreferences.getToken() ?? "",
        "Content-Type": "application/json"
      },
                  validateStatus: (status) {
                    return status! < maxServerErrorCode;
                  }),
              // onReceiveProgress: onReceiveProgress ?? _onReceiveProgress
              )
          .catchError((onError) {
        responseData.putIfAbsent(APIKeys.errorDetails, () => '$onError');
        errorFlag = true;
        // ignore: invalid_return_type_for_catch_error
        return null;
      }).timeout(new Duration(seconds: timeoutDuration), onTimeout: () async {
        timeOutFlag = true;
        // ignore: null_check_always_fails
        return null!;
      });
      responseData = await _parseDioResponse(
        response,
        path: path,
        errorFlag: errorFlag,
        timeOutFlag: timeOutFlag,
      );
    } catch (e, s) {
      errorLogs('${dio.options.baseUrl}$path has exception:$e,\n$e');
      responseData.putIfAbsent(APIKeys.statusCode, () => errorStatusCode);
      responseData.putIfAbsent(APIKeys.exception, () => '$e \n $s');
    }

    DevService.instance.insertAPICall(AppAPIsCall(
      id: getId() + " " + DateTime.now().toIso8601String(),
      type: 'GET',
      path: path,
      dateTime: DateTime.now(),
      data: {},
      response: responseData,
    ));

    if (logResponse)
      appLogs('AppAPI: responseData:$path \n ${responseData.toPretty()}');

    return responseData;
  }

  static Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    FormData? formData,
    ProgressCallback? onReceiveProgress,
    bool logResponse = false,
    bool isShowTost = false,
  }) async {
    Map<String, dynamic> responseData = new Map();
    // apiLogs(
    //     'AppAPI: post: path:${dio.options.baseUrl}$path \n ${data?.toPretty()}\n requestHeaders${getPrettyMap(requestHeaders)}');

    if (logResponse)
      appLogs(
          'AppAPI: post:$path \n ${data?.toPretty()} ${formData?.fields.map((e) => '$e').toList()} ${formData?.files.map((e) => e.key).toList()}');

    bool errorFlag = false;
    bool timeOutFlag = false;
    token= await AppPreferences.getToken() ?? "";
    try {
      Response response = await dio
          .post(Uri.encodeFull(path),
              data: data ?? formData,
              options: Options(
                  headers: await requestHeaders,
                  validateStatus: (status) {
                    return status! < maxServerErrorCode;
                  }),
              onReceiveProgress: onReceiveProgress ?? _onReceiveProgress)
          .catchError((onError) {
        responseData.putIfAbsent(APIKeys.errorDetails, () => '$onError');

        errorFlag = true;

        // ignore: null_check_always_fails
        return null!;
      }).timeout(new Duration(seconds: timeoutDuration), onTimeout: () async {
        timeOutFlag = true;
        // ignore: null_check_always_fails
        return null!;
      });

      try {
        if (response.statusCode == 200) {
          if (isShowTost == false) {
            if (response.data != null) {
              if (response.data["success"] == false) {
                // String? userId = await AppPreferences.getUserId();
                // if(userId!=""){ // for guest user fun
                //    AppTostMassage.showTostErrorMassage(massage: "$path ${response.data["message"].toString()}");
                // }
              }
            }
          }
        } else {
          if (isShowTost == false) {
            AppTostMassage.showTostErrorMassage(
                massage: "$path Something went wrong");
          }
        }
      } catch (e) {}

      responseData = await _parseDioResponse(
        response,
        path: path,
        errorFlag: errorFlag,
        timeOutFlag: timeOutFlag,
      );
    } catch (e, s) {
      errorLogs('${dio.options.baseUrl}$path has exception:$e,\n$e');
      responseData.putIfAbsent(APIKeys.statusCode, () => errorStatusCode);
      responseData.putIfAbsent(APIKeys.exception, () => '$e \n $s');
    }

    DevService.instance.insertAPICall(AppAPIsCall(
      id: getId() + " " + DateTime.now().toIso8601String(),
      type: 'POST',
      path: path,
      dateTime: DateTime.now(),
      data: data!,
      response: responseData,
    ));

    if (logResponse)
      appLogs('AppAPI: responseData:$path \n ${responseData.toPretty()}');

    return responseData;
  }


  static Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? data,
    FormData? formData,
    ProgressCallback? onReceiveProgress,
    bool logResponse = false,
    bool isShowTost = false,
  }) async {
    Map<String, dynamic> responseData = new Map();
    // apiLogs(
    //     'AppAPI: post: path:${dio.options.baseUrl}$path \n ${data?.toPretty()}\n requestHeaders${getPrettyMap(requestHeaders)}');

    if (logResponse)
      appLogs(
          'AppAPI: post:$path \n ${data?.toPretty()} ${formData?.fields.map((e) => '$e').toList()} ${formData?.files.map((e) => e.key).toList()}');

    bool errorFlag = false;
    bool timeOutFlag = false;
    token= await AppPreferences.getToken() ?? "";
    try {
      Response response = await dio
          .put(Uri.encodeFull(path),
              data: data ?? formData,
              options: Options(
                  headers: await requestHeaders,
                  validateStatus: (status) {
                    return status! < maxServerErrorCode;
                  }),
              onReceiveProgress: onReceiveProgress ?? _onReceiveProgress)
          .catchError((onError) {
        responseData.putIfAbsent(APIKeys.errorDetails, () => '$onError');

        errorFlag = true;

        // ignore: null_check_always_fails
        return null!;
      }).timeout(new Duration(seconds: timeoutDuration), onTimeout: () async {
        timeOutFlag = true;
        // ignore: null_check_always_fails
        return null!;
      });

      try {
        if (response.statusCode == 200) {
          if (isShowTost == false) {
            if (response.data != null) {
              if (response.data["success"] == false) {
                // String? userId = await AppPreferences.getUserId();
                // if(userId!=""){ // for guest user fun
                //    AppTostMassage.showTostErrorMassage(massage: "$path ${response.data["message"].toString()}");
                // }
              }
            }
          }
        } else {
          if (isShowTost == false) {
            AppTostMassage.showTostErrorMassage(
                massage: "$path Something went wrong");
          }
        }
      } catch (e) {}

      responseData = await _parseDioResponse(
        response,
        path: path,
        errorFlag: errorFlag,
        timeOutFlag: timeOutFlag,
      );
    } catch (e, s) {
      errorLogs('${dio.options.baseUrl}$path has exception:$e,\n$e');
      responseData.putIfAbsent(APIKeys.statusCode, () => errorStatusCode);
      responseData.putIfAbsent(APIKeys.exception, () => '$e \n $s');
    }

    DevService.instance.insertAPICall(AppAPIsCall(
      id: getId() + " " + DateTime.now().toIso8601String(),
      type: 'POST',
      path: path,
      dateTime: DateTime.now(),
      data: data!,
      response: responseData,
    ));

    if (logResponse)
      appLogs('AppAPI: responseData:$path \n ${responseData.toPretty()}');

    return responseData;
  }

  static Future<Map<String, dynamic>> delete(
    String path, {
    ProgressCallback? onReceiveProgress,
    bool logResponse = true,
  }) async {
    Map<String, dynamic> responseData = new Map();

    apiLogs(
        'AppAPI: delete: path:${dio.options.baseUrl}$path \n requestHeaders${getPrettyMap(requestHeaders as Map)}');

    bool errorFlag = false;
    bool timeOutFlag = false;
token= await AppPreferences.getToken() ?? "";
    try {
      Response response = await dio
          .delete(
        Uri.encodeFull(path),
        options: Options(
            headers: await requestHeaders,
            validateStatus: (status) {
              return status! < maxServerErrorCode;
            }),
      )
          .catchError((onError) {
        responseData.putIfAbsent(APIKeys.errorDetails, () => '$onError');
        errorFlag = true;
        // ignore: null_check_always_fails
        return null!;
      }).timeout(new Duration(seconds: timeoutDuration), onTimeout: () async {
        timeOutFlag = true;
        // ignore: null_check_always_fails
        return null!;
      });
      responseData = await _parseDioResponse(
        response,
        path: path,
        errorFlag: errorFlag,
        timeOutFlag: timeOutFlag,
      );
    } catch (e, s) {
      errorLogs('${dio.options.baseUrl}$path has exception:$e,\n$e');
      responseData.putIfAbsent(APIKeys.statusCode, () => errorStatusCode);
      responseData.putIfAbsent(APIKeys.exception, () => '$e \n $s');
    }

    DevService.instance.insertAPICall(AppAPIsCall(
      id: getId() + " " + DateTime.now().toIso8601String(),
      type: 'DELETE',
      path: path,
      dateTime: DateTime.now(),
      data: {},
      response: responseData,
    ));

    return responseData;
  }

  static Future<Map<String, dynamic>> _parseDioResponse(
    Response response, {
    String? path,
    bool? errorFlag,
    bool? timeOutFlag,
  }) async {
    Map<String, dynamic> responseData = new Map();

    if (timeOutFlag!) {
      apiLogs("${dio.options.baseUrl}$path Show TimeOut $timeOutFlag");
      responseData.putIfAbsent(APIKeys.statusCode, () => timeOutCode);
      responseData.putIfAbsent(
          APIKeys.message, () => Strings.timeOutErrorMessage);
    } else if (errorFlag!) {
      apiLogs("${dio.options.baseUrl}$path Show Error");
      responseData.putIfAbsent(APIKeys.statusCode, () => errorStatusCode);
      responseData.putIfAbsent(
          APIKeys.message, () => Strings.defaultErrorMessage);
      // ignore: unnecessary_null_comparison
    } else if (response != null) {
      int statusCode = response.statusCode!;

      responseData.putIfAbsent(APIKeys.statusCode, () => statusCode);
      apiLogs(
          "${dio.options.baseUrl}$path has Response statusCode:$statusCode");

      if (response.data is Map) {
        responseData = response.data;
      } else {
        responseData.putIfAbsent(APIKeys.data, () => response.data);
      }
    }

    apiLogs(
        "${dio.options.baseUrl}$path has Response body:${getPrettyMap(responseData)}");

    return responseData;
  }

  static _onReceiveProgress(
    int? count,
    int? total, {
    String? path,
  }) {
    if (total! > count!)
      apiLogs(
          "${dio.options.baseUrl}$path onReceiveProgress $count $total  ${(count / total * 100).toInt()} % ");
  }

  ///Multipart file upload
  static Future<Map<String, dynamic>> postFile(
    String path, {
    Map<String, dynamic>? data,
    String? image,
    ProgressCallback? onReceiveProgress,
    String? keyObjectName,
    bool logResponse = true,
  }) async {
    String base = AppEnvironment.baseUrl;
    Map<String, dynamic> responseData = new Map();
    final imageUploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse("$base$path"),
    );
    imageUploadRequest.headers.addAll(requestHeaders as Map<String, String>);

    final file = await http.MultipartFile.fromPath('file', image!);
    imageUploadRequest.files.add(file);

    imageUploadRequest.fields['$keyObjectName'] = json.encode(data);
    final streamedResponse = await imageUploadRequest.send();

    final response = await http.Response.fromStream(streamedResponse);

    // responseData = getMapFromJson(response.body);
    responseData.putIfAbsent(APIKeys.statusCode, () => response.statusCode);

    DevService.instance.insertAPICall(AppAPIsCall(
      id: getId() + " " + DateTime.now().toIso8601String(),
      type: 'MULTIPARTFILE',
      path: path,
      dateTime: DateTime.now(),
      data: {
        ...data!,
        ...{
          'file': imageUploadRequest.files,
        }
      },
      response: responseData,
    ));

    return responseData;
  }

  ///Multipart file upload
  static Future<Map<String, dynamic>> postMultipleFile(
    String path, {
    Map<String, dynamic>? data,
    List<File>? imageList,
    List<String>? existingImageList,
    String? keyObjectName,
    bool logResponse = true,
  }) async {
    Map<String, dynamic>? responseData = new Map();
    final imageUploadRequest = http.MultipartRequest(
      'POST',
      Uri.parse("${AppEnvironment.baseUrl}$path"),
    );
    imageUploadRequest.headers.addAll(requestHeaders as Map<String, String>);

    for (int i = 0; i < imageList!.length; i++) {
      imageUploadRequest.files
          .add(await http.MultipartFile.fromPath('file', imageList[i].path));
    }

    data?.add(key: APIKeys.webImages, value: existingImageList);

    imageUploadRequest.fields['$keyObjectName'] = json.encode(data);

    final streamedResponse = await imageUploadRequest.send();

    final response = await http.Response.fromStream(streamedResponse);

    responseData = getMapFromJson(response.body).cast<String, dynamic>();
    responseData.putIfAbsent(APIKeys.statusCode, () => response.statusCode);

    DevService.instance.insertAPICall(AppAPIsCall(
      id: getId() + " " + DateTime.now().toIso8601String(),
      type: 'MULTIPARTFILE',
      path: path,
      dateTime: DateTime.now(),
      data: {
        ...data!,
        ...{
          'file': imageUploadRequest.files,
        }
      },
      response: responseData,
    ));

    return responseData;
  }

  //

  static Future<Map<String, dynamic>> postList(
    String path, {
    List? data,
    FormData? formData,
    ProgressCallback? onReceiveProgress,
    bool logResponse = false,
    bool isShowTost = false,
  }) async {
    Map<String, dynamic> responseData = new Map();
    // apiLogs(
    //     'AppAPI: post: path:${dio.options.baseUrl}$path \n ${data?.toPretty()}\n requestHeaders${getPrettyMap(requestHeaders)}');

    if (logResponse)
      // appLogs(
      //     'AppAPI: post:$path \n ${data?.toPretty()} ${formData?.fields.map((e) => '$e').toList()} ${formData?.files.map((e) => e.key).toList()}');

      // ignore: unused_local_variable
      bool errorFlag = false;
    bool timeOutFlag = false;
    token= await AppPreferences.getToken() ?? "";
    try {
      Response response = await dio
          .post(Uri.encodeFull(path),
              data: data,
              options: Options(
                  headers: await requestHeaders,
                  validateStatus: (status) {
                    return status! < maxServerErrorCode;
                  }),
              onReceiveProgress: onReceiveProgress ?? _onReceiveProgress)
          .catchError((onError) {
        responseData.putIfAbsent(APIKeys.errorDetails, () => '$onError');

        // errorFlag = true;

        // ignore: null_check_always_fails
        return null!;
      }).timeout(new Duration(seconds: timeoutDuration), onTimeout: () async {
        timeOutFlag = true;
        // ignore: null_check_always_fails
        return null!;
      });

      try {
        if (response.statusCode == 200) {
          if (isShowTost == false) {
            if (response.data != null) {
              if (response.data["success"] == false) {
                AppTostMassage.showTostErrorMassage(
                    massage: "$path ${response.data["message"].toString()}");
              }
            }
          }
        } else {
          if (isShowTost == false) {
            AppTostMassage.showTostErrorMassage(
                massage: "$path Something went wrong");
          }
        }
      } catch (e) {}

      responseData = await _parseDioResponse(
        response,
        path: path,
        errorFlag: false,
        timeOutFlag: timeOutFlag,
      );
    } catch (e, s) {
      errorLogs('${dio.options.baseUrl}$path has exception:$e,\n$e');
      responseData.putIfAbsent(APIKeys.statusCode, () => errorStatusCode);
      responseData.putIfAbsent(APIKeys.exception, () => '$e \n $s');
    }

    DevService.instance.insertAPICall(AppAPIsCall(
      id: getId() + " " + DateTime.now().toIso8601String(),
      type: 'POST',
      path: path,
      dateTime: DateTime.now(),
      data: {},
      response: responseData,
    ));

    if (logResponse)
      appLogs('AppAPI: responseData:$path \n ${responseData.toPretty()}');

    return responseData;
  }
}
