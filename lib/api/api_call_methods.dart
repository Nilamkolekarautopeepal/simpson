import 'package:get/get.dart';
import 'package:autopeepalApp/api/api_status_code.dart';
import 'package:autopeepalApp/api/app_envirments.dart';
import 'package:autopeepalApp/api/response_model.dart';
import 'package:autopeepalApp/services/local_storage_services/local_storages_string.dart';
import 'package:autopeepalApp/services/local_storage_services/localstorage_services.dart';
import 'package:autopeepalApp/utils/keys/api_keys.dart';
import 'package:autopeepalApp/utils/strings.dart';
import 'package:autopeepalApp/utils/ui_helper.dart/app_snack_bar.dart';

class ApiService extends GetConnect {

  ApiService() {
    baseUrl = AppEnvironment.baseUrl;
    token = LocalServices.retrieveDataFromLocalStorage(
        key: LocalStorageString.token);
  }
  
  String? token;
  ResponseModel res = ResponseModel();
  static ResponseModel sendResponseToModel(
      int statusCode, dynamic body, dynamic path) {
    switch (statusCode) {
      case APIStatusCode.SUCCESS:
        return ResponseModel(
            responseBody: body, statusCode: APIStatusCode.SUCCESS, path: path);
      case APIStatusCode.postSuccess:
        return ResponseModel(
            responseBody: body,
            statusCode: APIStatusCode.postSuccess,
            path: path);
      case APIStatusCode.internalServerIssue:
        // AppSnackBar.showSnackBarErrorMassage(massage: Strings.serverError);
        return ResponseModel(
            responseBody: {}, statusCode: APIStatusCode.internalServerIssue);
      case APIStatusCode.badRequest:

        //Todo: Pending because how to expire in token in backed side it is completed then L work
        // AppSnackBar.showSnackBarErrorMassage(massage: Strings.validationFail);
        return ResponseModel(
            responseBody: body, statusCode: APIStatusCode.internalServerIssue);
      case APIStatusCode.alreadyExistError:
        AppSnackBar.showSnackBarErrorMassage(
            massage: Strings.all);
        return ResponseModel(
            responseBody: {}, statusCode: APIStatusCode.internalServerIssue);

      case APIStatusCode.unauthorized:
        // Get.offAllNamed(Routes.loginScreen);
        AppSnackBar.showSnackBarErrorMassage(massage: Strings.sessionOut);
        return ResponseModel();
    }
    return ResponseModel();
  }

  // GET request
  Future<ResponseModel> fetchData({required String endpoint}) async {
    try {
      Map<String, String> header = {
        APIKeys.authorization: token ?? Strings.empty,
        APIKeys.contentType: APIKeys.contentTypeValue
      };
      final response = await get(endpoint, headers: header);
      return sendResponseToModel(response.statusCode!, response.body, endpoint);
    } catch (e) {
      AppSnackBar.showSnackBarErrorMassage(massage: Strings.catchError);
      res.responseBody = {};
      res.statusCode = APIStatusCode.internalServerIssue;
      return res;
    }
  }

  // Example POST request
  Future<ResponseModel> postData(
      {required String endpoint,
      required Map<String, dynamic> body,
      Map<String, String>? headers}) async {
    try {
      Map<String, String> header = {
        APIKeys.authorization: token ?? Strings.empty,
        APIKeys.contentType: APIKeys.contentTypeValue
      };
      final response = await post(endpoint, body, headers: headers ?? header);
      return sendResponseToModel(response.statusCode!, response.body, endpoint);
    } catch (e) {
      AppSnackBar.showSnackBarErrorMassage(massage: Strings.catchError);
      res.responseBody = {};
      res.statusCode = APIStatusCode.internalServerIssue;
      return res;
    }
  }

  // Example PUT request
  Future<ResponseModel> putData(
      {required String endpoint,
      required Map<String, dynamic> body,
      Map<String, String>? headers}) async {
    try {
      Map<String, String> header = {
        APIKeys.authorization: token ?? Strings.empty,
        APIKeys.contentType: APIKeys.contentTypeValue
      };
      final response = await put(endpoint, body, headers: headers ?? header);
      return sendResponseToModel(response.statusCode!, response.body, endpoint);
    } catch (e) {
      AppSnackBar.showSnackBarErrorMassage(massage: Strings.catchError);
      res.responseBody = {};
      res.statusCode = APIStatusCode.internalServerIssue;
      return res;
    }
  }

  // Example PUT request
  Future<ResponseModel> patchData(
      {required String endpoint,
      required Map<String, dynamic> body,
      Map<String, String>? headers}) async {
    try {
      Map<String, String> header = {
        APIKeys.authorization: token ?? Strings.empty,
        APIKeys.contentType: APIKeys.contentTypeValue
      };
      final response = await patch(endpoint, body, headers: headers ?? header);
      return sendResponseToModel(response.statusCode!, response.body, endpoint);
    } catch (e) {
      AppSnackBar.showSnackBarErrorMassage(massage: Strings.catchError);

      res.responseBody = {};
      res.statusCode = APIStatusCode.internalServerIssue;
      return res;
    }
  }

  // Example DELETE request
  Future<ResponseModel> deleteData({required String endpoint}) async {
    try {
      Map<String, String> header = {
        APIKeys.authorization: token ?? Strings.empty,
        APIKeys.contentType: APIKeys.contentTypeValue
      };
      final response = await delete('$endpoint', headers: header);
      return sendResponseToModel(response.statusCode!, response.body, endpoint);
    } catch (e) {
      AppSnackBar.showSnackBarErrorMassage(massage: Strings.catchError);
      res.responseBody = {};
      res.statusCode = APIStatusCode.internalServerIssue;
      return res;
    }
  }
}
