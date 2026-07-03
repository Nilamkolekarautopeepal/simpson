import 'package:simpson/utils/sizes.dart';
import 'package:flutter/material.dart';
import 'package:simpson/themes/app_colors.dart';

AppBarTheme appBarTheme = AppBarTheme(
    iconTheme: IconThemeData(color: AppColors.primary),
    color: AppColors.white,
    titleTextStyle: TextStyle(
      fontWeight: FontWeight.w600,
      fontSize: FontSizes.s16,
      fontFamily: "Inter-Regular"
    ));
