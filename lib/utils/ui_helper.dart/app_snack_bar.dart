import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/utils/strings.dart';

class AppSnackBar {
  static showSnackBarMassage(
      {required String title,
      required String massage,
      Color? backgroundColor,
      Color? textColor,
      IconData? icon,
      Color? iconColor,
      Duration? duration,
      Duration? animationDuration,
      bool? isDismissible,
      SnackPosition? snackPosition,
      DismissDirection? dismissDirection,
      bool? showProgressIndicator,
      SnackStyle? snackStyle}) {
    Get.snackbar(title, massage,
        colorText: textColor ?? AppColors.white,
        backgroundColor: backgroundColor ?? AppColors.primary,
        icon: Icon(icon, color: iconColor ?? AppColors.white),
        duration: duration ?? const Duration(seconds: 3),
        animationDuration: animationDuration ?? Duration(seconds: 1),
        snackPosition: snackPosition ?? SnackPosition.TOP,
        dismissDirection: dismissDirection ?? DismissDirection.startToEnd,
        isDismissible: isDismissible ?? true,
        showProgressIndicator: showProgressIndicator ?? false,
        snackStyle: snackStyle ?? SnackStyle.FLOATING);
  }

  static showSnackBarErrorMassage(
      {String? title,
      required String massage,
      Duration? duration,
      Duration? animationDuration,
      bool? isDismissible,
      SnackPosition? snackPosition,
      DismissDirection? dismissDirection,
      bool? showProgressIndicator,
      SnackStyle? snackStyle}) {
    Get.snackbar(title ?? Strings.error, massage,
        colorText: AppColors.white,
        backgroundColor: AppColors.error,
        icon: Icon(Icons.error, color: AppColors.white),
        duration: duration ?? const Duration(seconds: 4),
        animationDuration: animationDuration ?? Duration(seconds: 1),
        snackPosition: snackPosition ?? SnackPosition.TOP,
        dismissDirection: dismissDirection ?? DismissDirection.startToEnd,
        isDismissible: isDismissible ?? true,
        showProgressIndicator: showProgressIndicator ?? false,
        snackStyle: snackStyle ?? SnackStyle.FLOATING);
  }

  static showSnackBarWarningMassage(
      {String? title,
      required String massage,
      Duration? duration,
      Duration? animationDuration,
      bool? isDismissible,
      SnackPosition? snackPosition,
      DismissDirection? dismissDirection,
      bool? showProgressIndicator,
      SnackStyle? snackStyle}) {
    Get.snackbar(title ?? Strings.waring, massage,
        colorText: AppColors.black,
        backgroundColor: AppColors.Warning,
        icon: Icon(Icons.warning, color: AppColors.black),
        duration: duration ?? const Duration(seconds: 4),
        animationDuration: animationDuration ?? Duration(seconds: 1),
        snackPosition: snackPosition ?? SnackPosition.TOP,
        dismissDirection: dismissDirection ?? DismissDirection.startToEnd,
        isDismissible: isDismissible ?? true,
        showProgressIndicator: showProgressIndicator ?? false,
        snackStyle: snackStyle ?? SnackStyle.FLOATING);
  }
}
