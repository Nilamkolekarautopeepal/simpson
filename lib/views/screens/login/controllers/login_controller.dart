import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:simpson/AppPreferences/app_areferences.dart';
import 'package:simpson/api/app_urls.dart';
import 'package:simpson/common_widgets/popup.dart';
import 'package:simpson/modals/user.model.dart';
import 'package:simpson/routes/app_pages.dart';
import 'package:simpson/services/androidOperationservice.dart';
import 'package:simpson/services/apiServices.dart';
import 'package:simpson/views/screens/psf_homeScreen/controllers/pfs_lane.dart';

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
  final RxString appVersion = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadSavedCredentials();
    _loadAppVersion();
  }

   Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    appVersion.value = '${info.version}';
    // or just 'v${info.version}' if you don't want the build number shown
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

      final macId = await AndroidOperationsService.getDeviceUniqueId();
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

            final dongleEntries = (station?.prodbudDongles ?? [])
          .map((d) {
            final ecuStations = d.ecuStation ?? [];
            final ecuIds = ecuStations
                .map((e) => e.ecu?.id)
                .whereType<int>()
                .toList();

            final ecuName = ecuStations
                .map((e) => e.ecu?.name)
                .firstWhere((n) => n != null && n.isNotEmpty, orElse: () => null);

            return {
              'mac_id': d.macId,
              'ip': d.ip,
              'is_active': d.isActive,
              'ecu_ids': ecuIds,
              'ecuId': ecuIds.firstOrNull,
              'ecuName': ecuName,
              'dongleDbId': d.id,
              'indicator_reg_addr': d.indicatorRegAddr,
              'ecu_reg_addr': d.ecuRegAddr,
            };
          })
          .toList();
      debugPrint("🔵 [Login] dongle_entries=$dongleEntries");

      final plcIp = station?.plcIp;
      final plcPort = station?.plcPort;

      debugPrint("🔵 [Login] plc_ip='$plcIp' plc_port='$plcPort'");

      await SecureStorageService.saveDongleList(jsonEncode(dongleEntries));
      await SecureStorageService.savePlcIp(plcIp);
      await SecureStorageService.savePlcPort(plcPort?.toString());

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
