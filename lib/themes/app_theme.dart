library theme;

import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart';
import 'package:autopeepalApp/themes/app_bar_theme.dart';
import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/themes/color_scheme.dart';
export '../utils/assets.dart';
export 'app_colors.dart';

ThemeData appTheme = ThemeData(
    brightness: Brightness.light,
    colorScheme: colorScheme,
    primaryColor: AppColors.primary,
    fontFamily: "Inter-Regular",
    // textTheme: GoogleFonts.poppinsTextTheme().apply(bodyColor: Colors.black),
    scaffoldBackgroundColor: AppColors.gray500,
    appBarTheme: appBarTheme);
