// import 'dart:convert';
// import 'dart:io';
// import 'package:dio/dio.dart';
// import 'package:flutter/foundation.dart';
// import 'package:simpson/api/app_urls.dart';
// import 'package:simpson/modals/all.models.dart';
// import 'package:simpson/modals/esn.model.dart' as esn_ds;
// import 'package:simpson/modals/flashRecord.model.dart';
// import 'package:simpson/modals/listNumber.model.dart';
// import 'package:simpson/modals/pidDataset.model.dart'; // adjust to wherever PidDataset actually lives
// import 'package:simpson/modals/dtcDataset.model.dart'; // adjust to wherever DtcDataset actually lives
// import 'package:simpson/modals/user.model.dart';
// import 'package:simpson/services/api_log_service.dart';

// class AuthService {
//   final Dio _dio;

//   AuthService({Dio? dio})
//       : _dio = dio ??
//             (Dio(
//               BaseOptions(
//                 connectTimeout: const Duration(seconds: 15),
//                 receiveTimeout: const Duration(seconds: 15),
//                 headers: {"Accept": "application/json"},
//               ),
//             )..interceptors.add(ApiLogInterceptor()));

//   Future<User> login({
//     required String username,
//     required String password,
//     required String macId,
//     required String deviceType,
//   }) async {
//     try {
//       final formData = FormData.fromMap({
//         "username": username,
//         "password": password,
//         "mac_id": macId,
//         "device_type": deviceType,
//       });

//       debugPrint("🔵 [AuthService] POST ${ApiUrls.login}");
//       debugPrint(
//           "🔵 [AuthService] body: username=$username mac_id=$macId device_type=$deviceType");

//       final response = await _dio.post(
//         ApiUrls.login,
//         data: formData,
//       );

//       debugPrint("🔵 [AuthService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [AuthService] response.data=${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return User.fromJson(_asMap(response.data));
//       }

//       throw Exception("Login failed with status ${response.statusCode}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [AuthService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [AuthService] response.data=${e.response?.data}");
//       final data = e.response?.data;
//       String? serverMessage;
//       if (data is Map) {
//         serverMessage =
//             (data["detail"] ?? data["message"] ?? data["error"])?.toString();
//       } else if (data is String && data.trim().isNotEmpty) {
//         try {
//           final decoded = jsonDecode(data);
//           if (decoded is Map) {
//             serverMessage =
//                 (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
//                     ?.toString();
//           }
//         } catch (_) {
//           // response wasn't JSON, ignore and fall back below
//         }
//       }

//       throw Exception(
//         serverMessage ?? _friendlyMessage(e),
//       );
//     }
//   }

//   Future<AllModel> getModels({String? accessToken}) async {
//     try {
//       debugPrint("🔵 [ModelsService] GET ${ApiUrls.models}");

//       final response = await _dio.get(
//         ApiUrls.models,
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//       debugPrint("🔵 [ModelsService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [ModelsService] response.data=${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return AllModel.fromJson(_asMap(response.data));
//       }

//       throw Exception(
//           "Failed to load models with status ${response.statusCode}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [ModelsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [ModelsService] response.data=${e.response?.data}");

//       final data = e.response?.data;
//       String? serverMessage;
//       if (data is Map) {
//         serverMessage =
//             (data["detail"] ?? data["message"] ?? data["error"])?.toString();
//       } else if (data is String && data.trim().isNotEmpty) {
//         try {
//           final decoded = jsonDecode(data);
//           if (decoded is Map) {
//             serverMessage =
//                 (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
//                     ?.toString();
//           }
//         } catch (_) {
//           // response wasn't JSON, ignore and fall back below
//         }
//       }

//       throw Exception(serverMessage ?? _friendlyMessage(e));
//     }
//   }

//   Future<FlashRecord> getFlashRecords({String? accessToken}) async {
//     try {
//       debugPrint("🔵 [FlashRecordService] GET ${ApiUrls.flashRecords}");

//       final response = await _dio.get(
//         ApiUrls.flashRecords,
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//       debugPrint("🔵 [FlashRecordService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [FlashRecordService] response.data=${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return FlashRecord.fromJson(_asMap(response.data));
//       }

//       throw Exception(
//           "Failed to load flash records with status ${response.statusCode}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [FlashRecordService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [FlashRecordService] response.data=${e.response?.data}");

//       final data = e.response?.data;
//       String? serverMessage;
//       if (data is Map) {
//         serverMessage =
//             (data["detail"] ?? data["message"] ?? data["error"])?.toString();
//       } else if (data is String && data.trim().isNotEmpty) {
//         try {
//           final decoded = jsonDecode(data);
//           if (decoded is Map) {
//             serverMessage =
//                 (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
//                     ?.toString();
//           }
//         } catch (_) {
//           // response wasn't JSON, ignore and fall back below
//         }
//       }

//       throw Exception(serverMessage ?? _friendlyMessage(e));
//     }
//   }

//   Future<ListNumber> getVariantsList({String? accessToken}) async {
//     try {
//       debugPrint("🔵 [VariantsService] GET ${ApiUrls.listNumber}");

//       final response = await _dio.get(
//         ApiUrls.listNumber,
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//       debugPrint("🔵 [VariantsService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [VariantsService] response.data=${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return ListNumber.fromJson(_asMap(response.data));
//       }

//       throw Exception(
//           "Failed to load variants with status ${response.statusCode}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [VariantsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [VariantsService] response.data=${e.response?.data}");

//       final data = e.response?.data;
//       String? serverMessage;
//       if (data is Map) {
//         serverMessage =
//             (data["detail"] ?? data["message"] ?? data["error"])?.toString();
//       } else if (data is String && data.trim().isNotEmpty) {
//         try {
//           final decoded = jsonDecode(data);
//           if (decoded is Map) {
//             serverMessage =
//                 (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
//                     ?.toString();
//           }
//         } catch (_) {
//           // response wasn't JSON, ignore and fall back below
//         }
//       }

//       throw Exception(serverMessage ?? _friendlyMessage(e));
//     }
//   }


//   Future<PidDataset> getPidDataset({
//     required int id,
//     String? accessToken,
//   }) async {
//     try {
//       debugPrint("🔵 [DatasetsService] GET ${ApiUrls.pidDataset}?id=$id");

//       final response = await _dio.get(
//         ApiUrls.pidDataset,
//         queryParameters: {"id": id},
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//       debugPrint("🔵 [DatasetsService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [DatasetsService] response.data=${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return PidDataset.fromJson(_asMap(response.data));
//       }

//       throw Exception(
//           "Failed to load PID dataset with status ${response.statusCode}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [DatasetsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [DatasetsService] response.data=${e.response?.data}");

//       final data = e.response?.data;
//       String? serverMessage;
//       if (data is Map) {
//         serverMessage =
//             (data["detail"] ?? data["message"] ?? data["error"])?.toString();
//       } else if (data is String && data.trim().isNotEmpty) {
//         try {
//           final decoded = jsonDecode(data);
//           if (decoded is Map) {
//             serverMessage =
//                 (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
//                     ?.toString();
//           }
//         } catch (_) {
//           // response wasn't JSON, ignore and fall back below
//         }
//       }

//       throw Exception(serverMessage ?? _friendlyMessage(e));
//     }
//   }

//   Future<DtcDataset> getDtcDataset({
//     required int id,
//     String? accessToken,
//   }) async {
//     try {
//       debugPrint("🔵 [DatasetsService] GET ${ApiUrls.dtcDataset}?id=$id");

//       final response = await _dio.get(
//         ApiUrls.dtcDataset,
//         queryParameters: {"id": id},
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//       debugPrint("🔵 [DatasetsService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [DatasetsService] response.data=${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return DtcDataset.fromJson(_asMap(response.data));
//       }

//       throw Exception(
//           "Failed to load DTC dataset with status ${response.statusCode}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [DatasetsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [DatasetsService] response.data=${e.response?.data}");

//       final data = e.response?.data;
//       String? serverMessage;
//       if (data is Map) {
//         serverMessage =
//             (data["detail"] ?? data["message"] ?? data["error"])?.toString();
//       } else if (data is String && data.trim().isNotEmpty) {
//         try {
//           final decoded = jsonDecode(data);
//           if (decoded is Map) {
//             serverMessage =
//                 (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
//                     ?.toString();
//           }
//         } catch (_) {
//           // response wasn't JSON, ignore and fall back below
//         }
//       }

//       throw Exception(serverMessage ?? _friendlyMessage(e));
//     }
//   }

//   Future<esn_ds.EsnNumber> getEsnList({
//     required String engSlno,
//     String? accessToken,
//   }) async {
//     try {
//       debugPrint(
//           "🔵 [EsnService] GET ${ApiUrls.engineSerialNumber}?eng_slno=$engSlno");

//       final response = await _dio.get(
//         ApiUrls.engineSerialNumber,
//         queryParameters: {"eng_slno": engSlno},
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//       debugPrint("🔵 [EsnService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [EsnService] response.data=${response.data}");

//       if (response.statusCode == 200 || response.statusCode == 201) {
//         return esn_ds.EsnNumber.fromJson(_asMap(response.data));
//       }

//       throw Exception(
//           "Failed to load ESN list with status ${response.statusCode}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [EsnService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [EsnService] response.data=${e.response?.data}");

//       final data = e.response?.data;
//       String? serverMessage;
//       if (data is Map) {
//         serverMessage =
//             (data["detail"] ?? data["message"] ?? data["error"])?.toString();
//       } else if (data is String && data.trim().isNotEmpty) {
//         try {
//           final decoded = jsonDecode(data);
//           if (decoded is Map) {
//             serverMessage =
//                 (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
//                     ?.toString();
//           }
//         } catch (_) {
//           // response wasn't JSON, ignore and fall back below
//         }
//       }

//       throw Exception(serverMessage ?? _friendlyMessage(e));
//     }
//   }


//   //------------------------test bed session and eol session apis-----------------------------
//   Future<void> createTestBedSession({
//     required int? esnId,
//     required int? dongleId,
//     required String? datasetType,
//     required String? datafileName,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String flashStatus,
//     required String iqaStatus,
//     required String dtcStatus,
//     required List<String> activityLog,
//     String? accessToken,
//   }) async {
//     try {
//       final activityText = activityLog.join('\n');
//       final activityBytes = utf8.encode(activityText);

//       final formData = FormData.fromMap({
//         "esn_id": esnId?.toString() ?? '',
//         "dongle_id": dongleId?.toString() ?? '',
//         "dataset_type": datasetType ?? '',
//         "datafile_name": datafileName ?? '',
//         "start_date": startDate.toIso8601String(),
//         "end_date": endDate.toIso8601String(),
//         "flash_status": flashStatus,
//         "iqa_status": iqaStatus,
//         "dtc_status": dtcStatus,
//         "activity_report": MultipartFile.fromBytes(
//           activityBytes,
//           filename: 'activity_log_${DateTime.now().millisecondsSinceEpoch}.txt',
//         ),
//       });
//       debugPrint("🔵 [TestBedSessionService] POST ${ApiUrls.createTestBedSession}");
//       debugPrint(
//           "🔵 [TestBedSessionService] esn_id=$esnId dongle_id=$dongleId dataset_type=$datasetType "
//           "flash=$flashStatus iqa=$iqaStatus dtc=$dtcStatus");

//       final response = await _dio.post(
//         ApiUrls.createTestBedSession,
//         data: formData,
//         options: Options(
//           headers: accessToken != null ? {"Authorization": "JWT $accessToken"} : null,
//         ),
//       );

//       debugPrint("🔵 [TestBedSessionService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [TestBedSessionService] response.data=${response.data}");
//     } on DioException catch (e) {
//       debugPrint("🔴 [TestBedSessionService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [TestBedSessionService] response.data=${e.response?.data}");
//       rethrow;
//     }
//   }

  

//   //=================================eol session apis-----------------------------
//  Future<void> createEolSession({
//     required int? esnId,
//     required int? dongleId,
//     required String? datasetType,
//     required String? datafileName,
//     required DateTime startDate,
//     required DateTime endDate,
//     required String continutyStatus,
//     required String flashStatus,
//     required String iqaStatus,
//     required String dtcStatus,
//     required List<String> activityLog,
//     String? accessToken,
//   }) async {
//     try {
//       final activityText = activityLog.join('\n');
//       final activityBytes = utf8.encode(activityText);

//       final formData = FormData.fromMap({
//         "esn_id": esnId?.toString() ?? '',
//         "dongle_id": dongleId?.toString() ?? '',
//         "dataset_type": datasetType ?? '',
//         "datafile_name": datafileName ?? '',
//         "start_date": startDate.toIso8601String(),
//         "end_date": endDate.toIso8601String(),
//         "continuty_status": continutyStatus,
//         "flash_status": flashStatus,
//         "iqa_status": iqaStatus,
//         "dtc_status": dtcStatus,
//         "activity_report": MultipartFile.fromBytes(
//           activityBytes,
//           filename: 'activity_log_${DateTime.now().millisecondsSinceEpoch}.txt',
//         ),
//       });

//       debugPrint("🔵 [EolSessionService] POST ${ApiUrls.createEolSession}");
//       debugPrint(
//           "🔵 [EolSessionService] esn_id=$esnId dongle_id=$dongleId dataset_type=$datasetType "
//           "flash=$flashStatus iqa=$iqaStatus dtc=$dtcStatus continuty=$continutyStatus");

//       final response = await _dio.post(
//         ApiUrls.createEolSession,
//         data: formData,
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//      debugPrint("🔵 [EolSessionService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [EolSessionService] response.data=${response.data}");
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [EolSessionService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [EolSessionService] response.data=${e.response?.data}");
//       rethrow; // let the caller (activity log) know it actually failed
//     }
//   }

//   Future<Map<String, dynamic>> getSessionHistory({
//     required String esn,
//     String? accessToken,
//   }) async {
//     try {
//       debugPrint("🔵 [SessionHistoryService] GET ${ApiUrls.sessionByEsn}?esn=$esn");

//       final response = await _dio.get(
//         ApiUrls.sessionByEsn,
//         queryParameters: {"esn": esn},
//         options: Options(
//           headers: accessToken != null
//               ? {"Authorization": "JWT $accessToken"}
//               : null,
//         ),
//       );

//       debugPrint("🔵 [SessionHistoryService] statusCode=${response.statusCode}");
//       debugPrint("🔵 [SessionHistoryService] response.data=${response.data}");

//       return response.data is Map ? _asMap(response.data) : {};
//     } on DioException catch (e) {
//       debugPrint(
//           "🔴 [SessionHistoryService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
//       debugPrint("🔴 [SessionHistoryService] response.data=${e.response?.data}");
//       return {};
//     }
//   }
//   //================================

//   String _friendlyMessage(DioException e) {
//   final statusCode = e.response?.statusCode;
//   if (statusCode != null) {
//     switch (statusCode) {
//       case 400:
//         return "Invalid login request. Please check your details.";
//       case 401:
//       case 403:
//         return "Invalid username or password.";
//       case 404:
//         return "Login service not found. Please contact support.";
//       case 500:
//       case 502:
//       case 503:
//         return "Server error. Please try again later.";
//       default:
//         return "Login failed (error $statusCode). Please try again.";
//     }
//   }

//   switch (e.type) {
//     case DioExceptionType.connectionTimeout:
//     case DioExceptionType.sendTimeout:
//     case DioExceptionType.receiveTimeout:
//       return "The server took too long to respond. Please try again.";
//     case DioExceptionType.connectionError:
//       return "Could not connect to the server. Check your internet connection.";
//     case DioExceptionType.badCertificate:
//       return "Could not establish a secure connection to the server (certificate error).";
//     case DioExceptionType.cancel:
//       return "Request was cancelled.";
//     case DioExceptionType.unknown:
//       debugPrint("🔴 [AuthService] Underlying error: ${e.error} (${e.error.runtimeType})");
//       debugPrint("🔴 [AuthService] Message: ${e.message}");
//       final underlying = e.error;
//       if (underlying is SocketException) {
//         if (underlying.osError?.errorCode == 11001 ||
//             underlying.message.toLowerCase().contains('lookup') ||
//             underlying.message.toLowerCase().contains('resolve')) {
//           return "Could not reach the server. Please check the server address or your DNS/network settings.";
//         }
//         return "Could not connect to the server. Check your internet connection or firewall settings.";
//       }
//       if (underlying != null && underlying.toString().toLowerCase().contains('handshake')) {
//         return "Could not establish a secure connection to the server (SSL/TLS handshake failed).";
//       }
//       return "Could not connect to the server. Please check your network connection and try again.";
//     default:
//       return "Something went wrong. Please try again.";
//   }
// }

//   Map<String, dynamic> _asMap(dynamic data) {
//     if (data is Map<String, dynamic>) {
//       return data;
//     } else if (data is String) {
//       try {
//         final decoded = jsonDecode(data);
//         if (decoded is Map<String, dynamic>) {
//           return decoded;
//         }
//       } catch (_) {
//         // Not a JSON string, fall through
//       }
//     }
//     throw Exception("Unexpected response format: ${data.runtimeType}");
//   }
// }

import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:simpson/api/app_urls.dart';
import 'package:simpson/modals/all.models.dart';
import 'package:simpson/modals/esn.model.dart' as esn_ds;
import 'package:simpson/modals/flashRecord.model.dart';
import 'package:simpson/modals/listNumber.model.dart';
import 'package:simpson/modals/pidDataset.model.dart'; // adjust to wherever PidDataset actually lives
import 'package:simpson/modals/dtcDataset.model.dart'; // adjust to wherever DtcDataset actually lives
import 'package:simpson/modals/user.model.dart';
import 'package:simpson/services/api_log_service.dart';

class AuthService {
  final Dio _dio;

  AuthService({Dio? dio})
      : _dio = dio ??
            (Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {"Accept": "application/json"},
              ),
            )
              ..interceptors.add(ApiLogInterceptor())
              ..httpClientAdapter = IOHttpClientAdapter(
                createHttpClient: () {
                  final client = HttpClient();
                  if (kDebugMode) {
                    // ⚠️ DEBUG ONLY: bypass certificate validation so the
                    // app can talk to servers using self-signed certs
                    // during development/testing. This block is stripped
                    // out of release builds by kDebugMode, so production
                    // traffic always gets full certificate validation.
                    client.badCertificateCallback =
                        (X509Certificate cert, String host, int port) {
                      debugPrint(
                          "🟡 [AuthService] Bypassing bad certificate for $host:$port (debug mode only)");
                      return true;
                    };
                  }
                  return client;
                },
              ));

  Future<User> login({
    required String username,
    required String password,
    required String macId,
    required String deviceType,
  }) async {
    try {
      final formData = FormData.fromMap({
        "username": username,
        "password": password,
        "mac_id": macId,
        "device_type": deviceType,
      });

      debugPrint("🔵 [AuthService] POST ${ApiUrls.login}");
      debugPrint(
          "🔵 [AuthService] body: username=$username mac_id=$macId device_type=$deviceType");

      final response = await _dio.post(
        ApiUrls.login,
        data: formData,
      );

      debugPrint("🔵 [AuthService] statusCode=${response.statusCode}");
      debugPrint("🔵 [AuthService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return User.fromJson(_asMap(response.data));
      }

      throw Exception("Login failed with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [AuthService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [AuthService] response.data=${e.response?.data}");
      final data = e.response?.data;
      String? serverMessage;
      if (data is Map) {
        serverMessage =
            (data["detail"] ?? data["message"] ?? data["error"])?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            serverMessage =
                (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
                    ?.toString();
          }
        } catch (_) {
          // response wasn't JSON, ignore and fall back below
        }
      }

      throw Exception(
        serverMessage ?? _friendlyMessage(e),
      );
    }
  }

  Future<AllModel> getModels({String? accessToken}) async {
    try {
      debugPrint("🔵 [ModelsService] GET ${ApiUrls.models}");

      final response = await _dio.get(
        ApiUrls.models,
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [ModelsService] statusCode=${response.statusCode}");
      debugPrint("🔵 [ModelsService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AllModel.fromJson(_asMap(response.data));
      }

      throw Exception(
          "Failed to load models with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [ModelsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [ModelsService] response.data=${e.response?.data}");

      final data = e.response?.data;
      String? serverMessage;
      if (data is Map) {
        serverMessage =
            (data["detail"] ?? data["message"] ?? data["error"])?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            serverMessage =
                (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
                    ?.toString();
          }
        } catch (_) {
          // response wasn't JSON, ignore and fall back below
        }
      }

      throw Exception(serverMessage ?? _friendlyMessage(e));
    }
  }

  Future<FlashRecord> getFlashRecords({String? accessToken}) async {
    try {
      debugPrint("🔵 [FlashRecordService] GET ${ApiUrls.flashRecords}");

      final response = await _dio.get(
        ApiUrls.flashRecords,
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [FlashRecordService] statusCode=${response.statusCode}");
      debugPrint("🔵 [FlashRecordService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return FlashRecord.fromJson(_asMap(response.data));
      }

      throw Exception(
          "Failed to load flash records with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [FlashRecordService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [FlashRecordService] response.data=${e.response?.data}");

      final data = e.response?.data;
      String? serverMessage;
      if (data is Map) {
        serverMessage =
            (data["detail"] ?? data["message"] ?? data["error"])?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            serverMessage =
                (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
                    ?.toString();
          }
        } catch (_) {
          // response wasn't JSON, ignore and fall back below
        }
      }

      throw Exception(serverMessage ?? _friendlyMessage(e));
    }
  }

  Future<ListNumber> getVariantsList({String? accessToken}) async {
    try {
      debugPrint("🔵 [VariantsService] GET ${ApiUrls.listNumber}");

      final response = await _dio.get(
        ApiUrls.listNumber,
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [VariantsService] statusCode=${response.statusCode}");
      debugPrint("🔵 [VariantsService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ListNumber.fromJson(_asMap(response.data));
      }

      throw Exception(
          "Failed to load variants with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [VariantsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [VariantsService] response.data=${e.response?.data}");

      final data = e.response?.data;
      String? serverMessage;
      if (data is Map) {
        serverMessage =
            (data["detail"] ?? data["message"] ?? data["error"])?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            serverMessage =
                (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
                    ?.toString();
          }
        } catch (_) {
          // response wasn't JSON, ignore and fall back below
        }
      }

      throw Exception(serverMessage ?? _friendlyMessage(e));
    }
  }

  Future<PidDataset> getPidDataset({
    required int id,
    String? accessToken,
  }) async {
    try {
      debugPrint("🔵 [DatasetsService] GET ${ApiUrls.pidDataset}?id=$id");

      final response = await _dio.get(
        ApiUrls.pidDataset,
        queryParameters: {"id": id},
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [DatasetsService] statusCode=${response.statusCode}");
      debugPrint("🔵 [DatasetsService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PidDataset.fromJson(_asMap(response.data));
      }

      throw Exception(
          "Failed to load PID dataset with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [DatasetsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [DatasetsService] response.data=${e.response?.data}");

      final data = e.response?.data;
      String? serverMessage;
      if (data is Map) {
        serverMessage =
            (data["detail"] ?? data["message"] ?? data["error"])?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            serverMessage =
                (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
                    ?.toString();
          }
        } catch (_) {
          // response wasn't JSON, ignore and fall back below
        }
      }

      throw Exception(serverMessage ?? _friendlyMessage(e));
    }
  }

  Future<DtcDataset> getDtcDataset({
    required int id,
    String? accessToken,
  }) async {
    try {
      debugPrint("🔵 [DatasetsService] GET ${ApiUrls.dtcDataset}?id=$id");

      final response = await _dio.get(
        ApiUrls.dtcDataset,
        queryParameters: {"id": id},
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [DatasetsService] statusCode=${response.statusCode}");
      debugPrint("🔵 [DatasetsService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return DtcDataset.fromJson(_asMap(response.data));
      }

      throw Exception(
          "Failed to load DTC dataset with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [DatasetsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [DatasetsService] response.data=${e.response?.data}");

      final data = e.response?.data;
      String? serverMessage;
      if (data is Map) {
        serverMessage =
            (data["detail"] ?? data["message"] ?? data["error"])?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            serverMessage =
                (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
                    ?.toString();
          }
        } catch (_) {
          // response wasn't JSON, ignore and fall back below
        }
      }

      throw Exception(serverMessage ?? _friendlyMessage(e));
    }
  }

  Future<esn_ds.EsnNumber> getEsnList({
    required String engSlno,
    String? accessToken,
  }) async {
    try {
      debugPrint(
          "🔵 [EsnService] GET ${ApiUrls.engineSerialNumber}?eng_slno=$engSlno");

      final response = await _dio.get(
        ApiUrls.engineSerialNumber,
        queryParameters: {"eng_slno": engSlno},
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [EsnService] statusCode=${response.statusCode}");
      debugPrint("🔵 [EsnService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return esn_ds.EsnNumber.fromJson(_asMap(response.data));
      }

      throw Exception(
          "Failed to load ESN list with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [EsnService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [EsnService] response.data=${e.response?.data}");

      final data = e.response?.data;
      String? serverMessage;
      if (data is Map) {
        serverMessage =
            (data["detail"] ?? data["message"] ?? data["error"])?.toString();
      } else if (data is String && data.trim().isNotEmpty) {
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            serverMessage =
                (decoded["detail"] ?? decoded["message"] ?? decoded["error"])
                    ?.toString();
          }
        } catch (_) {
          // response wasn't JSON, ignore and fall back below
        }
      }

      throw Exception(serverMessage ?? _friendlyMessage(e));
    }
  }

  //------------------------test bed session and eol session apis-----------------------------
  Future<void> createTestBedSession({
    required int? esnId,
    required int? dongleId,
    required String? datasetType,
    required String? datafileName,
    required DateTime startDate,
    required DateTime endDate,
    required String flashStatus,
    required String iqaStatus,
    required String dtcStatus,
    required List<String> activityLog,
    String? accessToken,
  }) async {
    try {
      final activityText = activityLog.join('\n');
      final activityBytes = utf8.encode(activityText);

      final formData = FormData.fromMap({
        "esn_id": esnId?.toString() ?? '',
        "dongle_id": dongleId?.toString() ?? '',
        "dataset_type": datasetType ?? '',
        "datafile_name": datafileName ?? '',
        "start_date": startDate.toIso8601String(),
        "end_date": endDate.toIso8601String(),
        "flash_status": flashStatus,
        "iqa_status": iqaStatus,
        "dtc_status": dtcStatus,
        "activity_report": MultipartFile.fromBytes(
          activityBytes,
          filename: 'activity_log_${DateTime.now().millisecondsSinceEpoch}.txt',
        ),
      });
      debugPrint("🔵 [TestBedSessionService] POST ${ApiUrls.createTestBedSession}");
      debugPrint(
          "🔵 [TestBedSessionService] esn_id=$esnId dongle_id=$dongleId dataset_type=$datasetType "
          "flash=$flashStatus iqa=$iqaStatus dtc=$dtcStatus");

      final response = await _dio.post(
        ApiUrls.createTestBedSession,
        data: formData,
        options: Options(
          headers: accessToken != null ? {"Authorization": "JWT $accessToken"} : null,
        ),
      );

      debugPrint("🔵 [TestBedSessionService] statusCode=${response.statusCode}");
      debugPrint("🔵 [TestBedSessionService] response.data=${response.data}");
    } on DioException catch (e) {
      debugPrint("🔴 [TestBedSessionService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [TestBedSessionService] response.data=${e.response?.data}");
      rethrow;
    }
  }

  //=================================eol session apis-----------------------------
  Future<void> createEolSession({
    required int? esnId,
    required int? dongleId,
    required String? datasetType,
    required String? datafileName,
    required DateTime startDate,
    required DateTime endDate,
    required String continutyStatus,
    required String flashStatus,
    required String iqaStatus,
    required String dtcStatus,
    required List<String> activityLog,
    String? accessToken,
  }) async {
    try {
      final activityText = activityLog.join('\n');
      final activityBytes = utf8.encode(activityText);

      final formData = FormData.fromMap({
        "esn_id": esnId?.toString() ?? '',
        "dongle_id": dongleId?.toString() ?? '',
        "dataset_type": datasetType ?? '',
        "datafile_name": datafileName ?? '',
        "start_date": startDate.toIso8601String(),
        "end_date": endDate.toIso8601String(),
        "continuty_status": continutyStatus,
        "flash_status": flashStatus,
        "iqa_status": iqaStatus,
        "dtc_status": dtcStatus,
        "activity_report": MultipartFile.fromBytes(
          activityBytes,
          filename: 'activity_log_${DateTime.now().millisecondsSinceEpoch}.txt',
        ),
      });

      debugPrint("🔵 [EolSessionService] POST ${ApiUrls.createEolSession}");
      debugPrint(
          "🔵 [EolSessionService] esn_id=$esnId dongle_id=$dongleId dataset_type=$datasetType "
          "flash=$flashStatus iqa=$iqaStatus dtc=$dtcStatus continuty=$continutyStatus");

      final response = await _dio.post(
        ApiUrls.createEolSession,
        data: formData,
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [EolSessionService] statusCode=${response.statusCode}");
      debugPrint("🔵 [EolSessionService] response.data=${response.data}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [EolSessionService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [EolSessionService] response.data=${e.response?.data}");
      rethrow; // let the caller (activity log) know it actually failed
    }
  }

  Future<Map<String, dynamic>> getSessionHistory({
    required String esn,
    String? accessToken,
  }) async {
    try {
      debugPrint("🔵 [SessionHistoryService] GET ${ApiUrls.sessionByEsn}?esn=$esn");

      final response = await _dio.get(
        ApiUrls.sessionByEsn,
        queryParameters: {"esn": esn},
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [SessionHistoryService] statusCode=${response.statusCode}");
      debugPrint("🔵 [SessionHistoryService] response.data=${response.data}");

      return response.data is Map ? _asMap(response.data) : {};
    } on DioException catch (e) {
      debugPrint(
          "🔴 [SessionHistoryService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [SessionHistoryService] response.data=${e.response?.data}");
      return {};
    }
  }
  //================================

  String _friendlyMessage(DioException e) {
    final statusCode = e.response?.statusCode;
    if (statusCode != null) {
      switch (statusCode) {
        case 400:
          return "Invalid login request. Please check your details.";
        case 401:
        case 403:
          return "Invalid username or password.";
        case 404:
          return "Login service not found. Please contact support.";
        case 500:
        case 502:
        case 503:
          return "Server error. Please try again later.";
        default:
          return "Login failed (error $statusCode). Please try again.";
      }
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return "The server took too long to respond. Please try again.";
      case DioExceptionType.connectionError:
        return "Could not connect to the server. Check your internet connection.";
      case DioExceptionType.badCertificate:
        return "Could not establish a secure connection to the server (certificate error).";
      case DioExceptionType.cancel:
        return "Request was cancelled.";
      case DioExceptionType.unknown:
        debugPrint("🔴 [AuthService] Underlying error: ${e.error} (${e.error.runtimeType})");
        debugPrint("🔴 [AuthService] Message: ${e.message}");
        final underlying = e.error;
        if (underlying is SocketException) {
          if (underlying.osError?.errorCode == 11001 ||
              underlying.message.toLowerCase().contains('lookup') ||
              underlying.message.toLowerCase().contains('resolve')) {
            return "Could not reach the server. Please check the server address or your DNS/network settings.";
          }
          return "Could not connect to the server. Check your internet connection or firewall settings.";
        }
        if (underlying != null && underlying.toString().toLowerCase().contains('handshake')) {
          return "Could not establish a secure connection to the server (SSL/TLS handshake failed).";
        }
        return "Could not connect to the server. Please check your network connection and try again.";
      default:
        return "Something went wrong. Please try again.";
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) {
      return data;
    } else if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) {
          return decoded;
        }
      } catch (_) {
        // Not a JSON string, fall through
      }
    }
    throw Exception("Unexpected response format: ${data.runtimeType}");
  }
}
