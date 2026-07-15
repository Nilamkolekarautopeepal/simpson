import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:simpson/api/app_urls.dart';
import 'package:simpson/modals/all.models.dart';
import 'package:simpson/modals/esn.model.dart' as esn_ds;
import 'package:simpson/modals/flashRecord.model.dart';
import 'package:simpson/modals/harness.model.dart';
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
            )..interceptors.add(ApiLogInterceptor()));

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

  /// PFS-specific List Number lookup — distinct from getVariantsList()
  /// above (which hits plain /variant/list/ and only returns the old
  /// variant_ecu shape). This hits analyze_prodbud/variant/list/,
  /// which returns d_dataset_ecu / t_dataset_ecu — the real source of
  /// PFS's single resolved flash file per lane.
  Future<ListNumber> getProdbudVariantsList({String? accessToken}) async {
    try {
      debugPrint("🔵 [ProdbudVariantsService] GET ${ApiUrls.prodbudVariantList}");

      final response = await _dio.get(
        ApiUrls.prodbudVariantList,
        options: Options(
          headers: accessToken != null
              ? {"Authorization": "JWT $accessToken"}
              : null,
        ),
      );

      debugPrint("🔵 [ProdbudVariantsService] statusCode=${response.statusCode}");
      debugPrint("🔵 [ProdbudVariantsService] response.data=${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ListNumber.fromJson(_asMap(response.data));
      }

      throw Exception(
          "Failed to load PFS variants with status ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint(
          "🔴 [ProdbudVariantsService] DioException: ${e.type} statusCode=${e.response?.statusCode}");
      debugPrint("🔴 [ProdbudVariantsService] response.data=${e.response?.data}");

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

  Future<HarnessName> getHarnessList({
    required String harnessName,
    String? accessToken,
  }) async {
    final response = await _dio.get(
      ApiUrls.harnessNumber,
      queryParameters: {'name': harnessName},
      options: Options(
        headers: {'Authorization': 'JWT $accessToken'},
      ),
    );
    print('🔵 [HarnessService] GET ${response.requestOptions.uri}');
    print('🔵 [HarnessService] statusCode=${response.statusCode}');
    print('🔵 [HarnessService] response.data=${response.data}');
    return HarnessName.fromJson(response.data);
  }

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
      default:
        return "Something went wrong. Please try again.";
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
      } catch (_) {
        final preview = data.length > 120 ? data.substring(0, 120) : data;
        throw Exception(
          "Server did not return JSON (got: $preview...). "
          "Check that ApiUrls.baseUrl / the endpoint path is correct.",
        );
      }
    }
    throw Exception("Unexpected response format from server");
  }
}
