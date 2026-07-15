import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/api/app_urls.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/user.model.dart';
import 'package:simpson/routes/app_pages.dart';
import 'package:simpson/services/androidOperationservice.dart';
import 'package:simpson/services/apiServices.dart';

class LoginController extends GetxController {
  final AuthService _authService = AuthService();

  // Form fields — kept as Rx<TextEditingController> to match your existing usage
  // (controller.usernameController.value in the widget tree)
  final Rx<TextEditingController> usernameController =
      TextEditingController().obs;
  final Rx<TextEditingController> passwordController =
      TextEditingController().obs;

  // State
  final RxBool hidePassword = true.obs;
  final RxBool isLoading = false.obs;
  final RxBool rememberMe = false.obs;
  final RxString errorMessage = ''.obs;
  final Rx<User?> currentUser = Rx<User?>(null);

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
  }

  /// Pre-fills the form with the last saved credentials, but only if the
  /// user had "Remember Me" checked last time.
  Future<void> _loadSavedCredentials() async {
    final wasRemembered = await SecureStorageService.getRememberMe();
    rememberMe.value = wasRemembered;

    if (!wasRemembered) return;

    final savedUsername = await SecureStorageService.getSavedUsername();
    final savedPassword = await SecureStorageService.getSavedPassword();

    if (savedUsername != null) {
      usernameController.value.text = savedUsername;
    }
    if (savedPassword != null) {
      passwordController.value.text = savedPassword;
    }
  }

  Future<void> login() async {
    debugPrint("🔵 [Login] Button pressed");

    final username = usernameController.value.text.trim();
    final password = passwordController.value.text.trim();
    debugPrint(
        "🔵 [Login] username='$username' password_length=${password.length}");

    if (username.isEmpty || password.isEmpty) {
      debugPrint("🔴 [Login] Validation failed: empty username or password");
      errorMessage.value = "Username and password are required";
      _showErrorPopup(errorMessage.value);
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';
      debugPrint("🔵 [Login] Fetching macId and deviceType...");

      final macId = await _getMacId();
      final deviceType = _getDeviceType();
      debugPrint("🔵 [Login] macId=$macId deviceType=$deviceType");

      debugPrint("🔵 [Login] Calling AuthService.login() -> ${ApiUrls.login}");
      final user = await _authService.login(
        username: username,
        password: password,
        macId: macId,
        deviceType: deviceType,
      );
      debugPrint(
          "🟢 [Login] Success. user=${user.user} role=${user.role} userId=${user.userId}");

      currentUser.value = user;

      // Persist everything needed to stay "logged in" / pre-fill next time.
      await SecureStorageService.setRememberMe(rememberMe.value);
      if (rememberMe.value) {
        await SecureStorageService.saveCredentials(
          username: username,
          password: password,
        );
      } else {
        await SecureStorageService.clearCredentials();
      }

      debugPrint(
          "🔵 [Login] user.token=${user.token} access=${user.token?.access} refresh=${user.token?.refresh}");
      await SecureStorageService.saveTokens(
        accessToken: user.token?.access,
        refreshToken: user.token?.refresh,
      );

      debugPrint(
          "🔵 [Login] rememberMe=${rememberMe.value}, credentials/tokens/user data saved");

      final station = user.stationData?.firstOrNull;
      final stationType = station?.stationType?.trim();

      // Pick the active dongle if there's more than one, else just the first.
      final dongleIp = station?.prodbudDongles
              ?.firstWhereOrNull((d) => d.isActive == true)
              ?.ip ??
          station?.prodbudDongles?.firstOrNull?.ip;

      // PLC IP/port come straight from this same station object —
      // station_data[0].plc_ip / .plc_port in the raw login JSON,
      // already mapped onto StationDatum.plcIp / .plcPort.
      final plcIp = station?.plcIp;
      final plcPort = station?.plcPort;

      debugPrint(
          "🔵 [Login] station_type='$stationType' dongle_ip='$dongleIp' plc_ip='$plcIp' plc_port='$plcPort'");

      await SecureStorageService.saveDongleIp(dongleIp);
      await SecureStorageService.savePlcIp(plcIp);
      await SecureStorageService.savePlcPort(plcPort?.toString());

      // PFS stations have MULTIPLE dongles, each pre-wired to a
      // specific ECU id via ecu_station — save the whole list so the
      // PFS screen can build one lane per dongle and match scanned
      // ESNs against each lane's expected ECU id.
      final dongleListJson = jsonEncode(
        (station?.prodbudDongles ?? []).map((d) {
          final ecuStationList = d.ecuStation ?? [];
          final firstEcuStation = ecuStationList.isNotEmpty ? ecuStationList.first : null;
          final ecuId = (firstEcuStation is Map) ? firstEcuStation['ecu'] : null;
          return {
            'dongleId': d.id,
            'ip': d.ip,
            'macId': d.macId,
            'priority': d.priority,
            'ecuId': ecuId,
          };
        }).toList(),
      );
      await SecureStorageService.saveDongleList(dongleListJson);

      if (stationType == 'Testing') {
        Get.offAllNamed(Routes.HOME_PAGE, arguments: station?.stationType);
      } else {
        Get.offAllNamed(Routes.PSF_HOME_SCREEN,
            arguments: station?.stationType);
      }
    } catch (e, stackTrace) {
      debugPrint("🔴 [Login] Failed: $e");
      debugPrint("🔴 [Login] StackTrace: $stackTrace");
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
      _showErrorPopup(errorMessage.value);
    } finally {
      isLoading.value = false;
      debugPrint("🔵 [Login] isLoading reset to false");
    }
  }

  void _showErrorPopup(String message) {
    Get.dialog(
      CustomPopup(
        title: "Login Failed",
        message: message,
        confirmText: "OK",
      ),
      barrierDismissible: true,
    );
  }

  /// ["true", "<mac>"] on success, ["false", "<reason>"] on failure.
  Future<String> _getMacId() async {
    final result = await AndroidOperationsService.getDeviceUniqueId();

    if (result.length < 2) {
      throw Exception("Could not determine device id.");
    }
    if (result[0] != "true") {
      throw Exception(result[1]);
    }

    return result[1];
  }

  String _getDeviceType() {
    if (Platform.isWindows) return "windows";
    if (Platform.isMacOS) return "mac";
    if (Platform.isLinux) return "linux";
    if (Platform.isAndroid) return "android";
    if (Platform.isIOS) return "ios";
    return "unknown";
  }

  @override
  void onClose() {
    usernameController.value.dispose();
    passwordController.value.dispose();
    super.onClose();
  }
}
