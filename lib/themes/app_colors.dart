// ignore_for_file: unnecessary_const

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:simpson/api/app_envirments.dart';
import 'package:simpson/app.dart';
import 'package:simpson/utils/app_enums.dart';

class AppColors {
  static const Color subtitleColor = Color(0xFF667085);
  static const Color primaryLight = Color(0xFFa5f0ba);
  static const Color green = Color(0xFF618264);
  static const Color grrenButtonn = Color(0xFf39A657);
  static const Color darkGrey = Color(0xFFE697D95);
  static const Color faintGrey = Color(0xFFF2F4F7);
  static const Color white = const Color(0xFFFFFFFF);
  static const Color pinkishGrey = const Color(0xff00E7DADA);
  static const Color error = Color(0xFFF04438);
  static const Color status = const Color(0xFFF79009);
  static const Color black = Color(0xFF27272B);
  static const Color blackFaint = Color(0xFF666666);
  static const Color grey = Color(0xFFEAECF0); //EAECF0
  static const Color greyLight = Color(0xFFF5F5F5);
  static const Color Warning = Colors.yellow;
  static const Color linearGradientPrimary = Color(0xFF66BB6A);
  static const Color linearGradientSecondary = Color(0xFF1B5F20);

  static const Color headerImageBackground = Color(0xFFE1F2CB);
  static const Color headertext = Color(0xFF1E2A44);
  static const Color headersubText = Color(0xFF4A90E2);
  static const Color textFieldBorderColor = Color(0xFFD0D5DD);
  static const Color textFieldLableColor = Color(0xFF667085);

  static const Color darkBlack = Color(0xFF101828);

// figma colors
  static const Color gray200 = Color(0xFFEAECF0);
  static const Color gray500 = Color(0xFFEAECF0);
  static const Color baseWhite = Color(0xFFFFFFFF);
  static const Color gray800 = Color(0xFF1D2939);
  static const Color dashbordItemType = Color(0xFF344054);
  static const Color dashbordItemPickTime = Color(0xFF1570EF);
  static const Color lightGrey = Color(0xFFECECEC);
  static const Color divider = Color(0xFF707070);
  static const Color iconArrow = Color(0xFF8A94A4);

  static Color get primary {
    switch (App.instance.baseURLType) {
      case AtomURLType.LOCAL:
        return const Color(0xFF165C3B);
      case AtomURLType.DEV:
        return const Color(0xFFDDEEFF);
      case AtomURLType.PROD:
        return const Color(0xFF165C3B);
    }
    return const Color(0xFF165C3B);
  }

  static Color get greetingColor {
    switch (App.instance.baseURLType) {
      case AtomURLType.LOCAL:
        return const Color(0xffA30024);
      case AtomURLType.DEV:
        return const Color(0xFFFF0000);
      case AtomURLType.PROD:
        return const Color(0xffA30024);
    }
    return const Color(0xffA30024);
  }

  static Color get primarySwatch {
    switch (App.instance.baseURLType) {
      case AtomURLType.LOCAL:
        return const MaterialColor(
          0xffA30024,
          <int, Color>{
            50: Color(0xffA30024),
            100: Color(0xffA30024),
            200: Color(0xffA30024),
            300: Color(0xffA30024),
            400: Color(0xffA30024),
            500: Color(0xffA30024),
            600: Color(0xffA30024),
            700: Color(0xffA30024),
            800: Color(0xffA30024),
            900: Color(0xffA30024),
          },
        );
      case AtomURLType.DEV:
        return const MaterialColor(
          0xffA30024,
          <int, Color>{
            50: Color(0xffA30024),
            100: Color(0xffA30024),
            200: Color(0xffA30024),
            300: Color(0xffA30024),
            400: Color(0xffA30024),
            500: Color(0xffA30024),
            600: Color(0xffA30024),
            700: Color(0xffA30024),
            800: Color(0xffA30024),
            900: Color(0xffA30024),
          },
        );
      case AtomURLType.PROD:
        return const MaterialColor(
          0xffA30024,
          <int, Color>{
            50: Color(0xffA30024),
            100: Color(0xffA30024),
            200: Color(0xffA30024),
            300: Color(0xffA30024),
            400: Color(0xffA30024),
            500: Color(0xffA30024),
            600: Color(0xffA30024),
            700: Color(0xffA30024),
            800: Color(0xffA30024),
            900: Color(0xffA30024),
          },
        );
    }
    return const MaterialColor(
      0xffA30024,
      <int, Color>{
        50: Color(0xffA30024),
        100: Color(0xffA30024),
        200: Color(0xffA30024),
        300: Color(0xffA30024),
        400: Color(0xffA30024),
        500: Color(0xffA30024),
        600: Color(0xffA30024),
        700: Color(0xffA30024),
        800: Color(0xffA30024),
        900: Color(0xffA30024),
      },
    );
  }

  static Color get secondary {
    switch (App.instance.baseURLType) {
      case AtomURLType.LOCAL:
        return const Color(0xFF33596E);
      case AtomURLType.DEV:
        return const Color(0xFFFF0000);
      case AtomURLType.PROD:
        return const Color(0xFF33596E);
    }
    return const Color(0xFF33596E);
  }

  static Color get ternary {
    switch (App.instance.baseURLType) {
      case AtomURLType.LOCAL:
        return const Color(0xFF4E7D96);
      case AtomURLType.DEV:
        return const Color(0xFFFF0000);
      case AtomURLType.PROD:
        return const Color(0xFF4E7D96);
    }
    return const Color(0xFF4E7D96);
  }

  static Color get random =>
      // ignore: deprecated_member_use
      Color((math.Random().nextDouble() * 0xFFFFFF).toInt()).withOpacity(1.0);

  static Color getMasterUserColorByStatus(String status) {
    switch (status) {
      case UserStatus.ACTIVE:
        return Colors.green;
      case UserStatus.PENDINGAPPROVAL:
        return Colors.redAccent;
      case UserStatus.INPROCESS:
        return Colors.orange;
      case UserStatus.INACTIVE:
        return Colors.red;
    }
    return AppColors.primary;
  }

  static Color getColorByIndex(int index) {
    switch (index) {
      case 0:
        return AppColors.primary;
      case 1:
        return Colors.redAccent;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.greenAccent;
      case 4:
        return Colors.green;
      case 5:
        return Colors.deepPurple;
      case 6:
        return Colors.indigo;
    }
    return AppColors.primary;
  }
}
