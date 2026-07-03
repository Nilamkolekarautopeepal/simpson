import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/api/app_api.dart';
import 'package:simpson/api/app_urls.dart';
import 'package:simpson/services/auth/auth_service.dart';
import 'package:simpson/services/permission_service.dart';
import 'package:simpson/utils/app_logs.dart';
import 'package:simpson/utils/extension/extension/map_extensions.dart';
import 'package:simpson/utils/keys/api_keys.dart';
import 'package:simpson/utils/ui_helper.dart/app_tost.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  @override
  void onInit() {
    super.onInit();
  }

  Rx<TextEditingController> usernameController = TextEditingController(text:"abc@autopeepal.com").obs;
  Rx<TextEditingController> passwordController = TextEditingController(text:"Test@123").obs;
  Rx<TextEditingController> forgetEmailController = TextEditingController().obs;
  Rx<TextEditingController> verifyOTPController = TextEditingController().obs;
  RxBool hidePassword = true.obs;
  RxString verifyEmail = "".obs;

  login() async {
    Map<String, dynamic> postData = Map();
    postData.add(key: APIKeys.username, value: usernameController.value.text);
    postData.add(key: APIKeys.password, value: passwordController.value.text);
    Map<String, dynamic> responseData =
        await AppAPIs.post(AppURLs.login, data: postData);

    try {
      if (responseData.getMap("message").getBool("success")) {
        String tokenGet = responseData
            .getMap("message")
            .getMap("data")
            .getString("Authorization");

        await AppPreferences.setToken(tokenGet);
        await AppPreferences.setUserData(
            responseData.getMap("message").getMap("data").getMap("user_data"));
        await auth.loadUser();
        getPermission(auth.currentUser.name!);
        // Get.offAndToNamed(Routes.dashboardScreen);
      } else {
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("error"));
      }
    } catch (e) {
      AppTostMassage.showTostMassage(massage: e.toString());
    }
  }

  forgetpassword() async {
    Map<String, dynamic> postData = Map();
    postData.add(key: APIKeys.email, value: forgetEmailController.value.text);
    Map<String, dynamic> responseData =
        await AppAPIs.post(AppURLs.forgetpassword, data: postData);

    try {
      if (responseData.getMap("message").getInt("status_code") == 200) {
        appLogs(responseData.toPretty());
        await AppPreferences.setToken(responseData
            .getMap("message")
            .getMap("data")
            .getString("Authorization"));
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("msg"));
        verifyEmail.value =
            responseData.getMap("message").getMap("data").getString("email");

        // Get.offAndToNamed(Routes.VERIFY_OTP, arguments: {
        //   'email': verifyEmail.value,
        // });
      } else if (responseData.getMap("message").getInt("status_code") == 404) {
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("msg"));
      } else {
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("msg"));
      }
    } catch (e) {
      AppTostMassage.showTostMassage(massage: e.toString());
    }
  }

  verifyOTP(String email) async {
    Map<String, dynamic> postData = Map();
    postData.add(key: APIKeys.email, value: email);
    postData.add(key: APIKeys.otp, value: verifyOTPController.value.text);
    Map<String, dynamic> responseData =
        await AppAPIs.post(AppURLs.verifyOTP, data: postData);

    try {
      if (responseData.getMap("message").getInt("status_code") == 200) {
        appLogs(responseData.toPretty());
        await AppPreferences.setToken(responseData
            .getMap("message")
            .getMap("data")
            .getString("Authorization"));
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("msg"));
      } else if (responseData.getMap("message").getInt("status_code") == 400) {
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("msg"));
      } else if (responseData.getMap("message").getInt("status_code") == 401) {
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("msg"));
      } else {
        AppTostMassage.showTostMassage(
            massage: responseData.getMap("message").getString("msg"));
      }
    } catch (e) {
      AppTostMassage.showTostMassage(massage: e.toString());
    }
  }

  Future<void> getPermission(String emp_id) async {
    Map<String, dynamic> responseData =
        await AppAPIs.get(AppURLs.permission(emp_id: emp_id));
    print(responseData.toPretty());
    try {
      await AppPreferences.savePermissionData(responseData.getMap("message"));

      await permissionService.loadPermissions();
//  Get.offAndToNamed(Routes.dashboardScreen);
    } catch (e) {
      print("$e");
    }
  }
}
