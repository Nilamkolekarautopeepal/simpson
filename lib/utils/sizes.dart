import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_logs.dart';

double defaultScreenWidth = 400;
double defaultScreenHeight = 810;
double screenWidth = defaultScreenWidth;
double screenHeight = defaultScreenHeight;

///Adapting screen and font size.
///Let your UI display a reasonable layout on different screen sizes!
class Sizes {
  static bool initialized = false;
  static double s0 = 0;
  static double s1 = 1;
  static double s2 = 2;
  static double s3 = 3;
  static double s4 = 4;
  static double s5 = 5;
  static double s6 = 6;
  static double s8 = 8;
  static double s9 = 9;
  static double s10 = 10;
  static double s11 = 11;
  static double s12 = 12;
  static double s15 = 15;
  static double s18 = 18;
  static double s20 = 20;
  static double s25 = 25;
  static double s30 = 30;
  static double s35 = 35;
  static double s40 = 40;
  static double s50 = 50;
  static double s60 = 60;
  static double s70 = 70;
  static double s80 = 80;
  static double s90 = 90;
  static double s100 = 100;
  static double s120 = 120;
  static double s150 = 150;
  static double s165 = 165;
  static double s200 = 200;
  static double s250 = 250;
  static double s300 = 300;

  ///initialize sizes
  ///Should be called only once
  ///
  static void initScreenAwareSizes(BuildContext context) {
    if (initialized) {
      errorLogs('Sizes already initialized');
      printScreenInformation();
      return;
    }
    initialized = true;

    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    if (screenWidth > 300 && screenWidth < 500) {
      defaultScreenWidth = 450;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenWidth > 500 && screenWidth < 600) {
      defaultScreenWidth = 500;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenWidth > 600 && screenWidth < 700) {
      defaultScreenWidth = 550;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenWidth > 700 && screenWidth < 1050) {
      defaultScreenWidth = 800;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else {
      defaultScreenWidth = screenWidth;
      defaultScreenHeight = screenHeight;
    }

    // ScreenUtil.init(
    //   context,
    //   width: defaultScreenWidth,
    //   height: defaultScreenHeight,
    //   allowFontScaling: true,
    // );

    FontSizes.initScreenAwareFontSize();

    s1 = ScreenUtil().setWidth(s1);
    s2 = ScreenUtil().setWidth(s2);
    s3 = ScreenUtil().setWidth(s3);
    s4 = ScreenUtil().setWidth(s4);
    s5 = ScreenUtil().setWidth(s5);
    s6 = ScreenUtil().setWidth(s6);
    s8 = ScreenUtil().setWidth(s8);
    s9 = ScreenUtil().setWidth(s9);
    s10 = ScreenUtil().setWidth(s10);
    s11 = ScreenUtil().setWidth(s11);
    s12 = ScreenUtil().setWidth(s12);
    s15 = ScreenUtil().setWidth(s15);
    s18 = ScreenUtil().setWidth(s18);
    s20 = ScreenUtil().setWidth(s20);
    s25 = ScreenUtil().setWidth(s25);
    s30 = ScreenUtil().setWidth(s30);
    s40 = ScreenUtil().setWidth(s40);
    s50 = ScreenUtil().setWidth(s50);
    s60 = ScreenUtil().setWidth(s60);
    s70 = ScreenUtil().setWidth(s70);
    s80 = ScreenUtil().setWidth(s80);
    s90 = ScreenUtil().setWidth(s90);
    s100 = ScreenUtil().setWidth(s100);
    s120 = ScreenUtil().setWidth(s120);
    s150 = ScreenUtil().setWidth(s150);
    s165 = ScreenUtil().setWidth(s165);
    s200 = ScreenUtil().setWidth(s200);

    printScreenInformation();
  }

  static void printScreenInformation() {
    appLogs('''
    Device Screen Details
    screenWidth: $screenWidth
    screenHeight: $screenHeight
    ---------X--------X-----------
    defaultScreenWidth: $defaultScreenWidth
    defaultScreenHeight: $defaultScreenHeight
    Actual : After
    1      : $s1 
    10     : $s10
    15     : $s15
    20     : $s20
    100    : $s100
    FontSize
    Actual : After
    15  :  ${FontSizes.s15} 
    20  :  ${FontSizes.s20}  
    Ratio of actual width dp to design draft px: ${ScreenUtil().scaleWidth}
    Ratio of actual height dp to design draft px: ${ScreenUtil().scaleHeight}
    ''');
  }

  static double heightClip(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight > 300 && screenHeight < 500) {
      defaultScreenWidth = 220;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 500 && screenHeight < 600) {
      defaultScreenWidth = 220;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 600 && screenHeight < 700) {
      defaultScreenWidth = 220;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 700 && screenHeight < 1050) {
      defaultScreenWidth = 255;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else {
      defaultScreenWidth = 255;
      defaultScreenHeight = 255;
    }
    return defaultScreenWidth;
  }

  static double heightClipSearch(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight > 300 && screenHeight < 500) {
      defaultScreenWidth = 180;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 500 && screenHeight < 600) {
      defaultScreenWidth = 180;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 600 && screenHeight < 700) {
      defaultScreenWidth = 180;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 700 && screenHeight < 1050) {
      defaultScreenWidth = 180;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else {
      defaultScreenWidth = 250;
      defaultScreenHeight = 250;
    }
    return defaultScreenWidth;
  }

  static double heightClipSearchStoreDetails(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    if (screenHeight > 300 && screenHeight < 500) {
      defaultScreenWidth = 350;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 500 && screenHeight < 600) {
      defaultScreenWidth = 350;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 600 && screenHeight < 700) {
      defaultScreenWidth = 300;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else if (screenHeight > 700 && screenHeight < 1050) {
      defaultScreenWidth = 300;
      defaultScreenHeight = defaultScreenWidth * screenHeight / screenWidth;
    } else {
      defaultScreenWidth = 300;
      defaultScreenHeight = 300;
    }
    return defaultScreenWidth;
  }
}

class FontSizes {
  static bool initialized = false;

  static double s7 = 7;
  static double s8 = 8;
  static double s9 = 9;
  static double s10 = 10;
  static double s11 = 11;
  static double s12 = 12;
  static double s13 = 13;
  static double s14 = 14;
  static double s15 = 15;
  static double s16 = 16;
  static double s17 = 17;
  static double s18 = 18;
  static double s19 = 19;
  static double s20 = 20;
  static double s21 = 21;
  static double s22 = 22;
  static double s23 = 23;
  static double s24 = 24;
  static double s25 = 25;
  static double s26 = 26;
  static double s27 = 27;
  static double s28 = 28;
  static double s29 = 29;
  static double s30 = 30;
  static double s36 = 36;

  ///initialize FontSize
  ///
  static initScreenAwareFontSize() {
    if (initialized) {
      errorLogs('FontSize already initialized');
      return;
    }
    initialized = true;
    s7 = ScreenUtil().setSp(s7);
    s8 = ScreenUtil().setSp(s8);
    s9 = ScreenUtil().setSp(s9);
    s10 = ScreenUtil().setSp(s10);
    s11 = ScreenUtil().setSp(s11);
    s12 = ScreenUtil().setSp(s12);
    s13 = ScreenUtil().setSp(s13);
    s14 = ScreenUtil().setSp(s14);
    s15 = ScreenUtil().setSp(s15);
    s16 = ScreenUtil().setSp(s16);
    s17 = ScreenUtil().setSp(s17);
    s18 = ScreenUtil().setSp(s18);
    s19 = ScreenUtil().setSp(s19);
    s20 = ScreenUtil().setSp(s20);
    s21 = ScreenUtil().setSp(s21);
    s22 = ScreenUtil().setSp(s22);
    s23 = ScreenUtil().setSp(s23);
    s24 = ScreenUtil().setSp(s24);
    s25 = ScreenUtil().setSp(s25);
    s26 = ScreenUtil().setSp(s26);
    s27 = ScreenUtil().setSp(s27);
    s28 = ScreenUtil().setSp(s28);
    s29 = ScreenUtil().setSp(s29);
    s30 = ScreenUtil().setSp(s30);
    s36 = ScreenUtil().setSp(s36);
  }
}
