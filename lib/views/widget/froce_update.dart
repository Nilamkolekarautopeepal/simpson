// ignore_for_file: deprecated_member_use

import 'package:autopeepalApp/api/app_api.dart';
import 'package:autopeepalApp/common_widgets/ui_helper_widgets.dart';
import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/utils/extension/extension/map_extensions.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io' show Platform;

import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class FroceUpdateView extends StatelessWidget {
  const FroceUpdateView(
      {super.key, required this.buildNumber, required this.buildversion});
  final String buildNumber;
  final String buildversion;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 24.0, right: 24.0, top: 10, bottom: 10),
        child: Column(
          children: [
            Spacer(),
            Image.asset("asset/logo/images/allishversion.png"),
            C10(),
            Text(
              "New Update Available",
              style: TextStyle(
                  fontFamily: "Inter-Bold",
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2939)),
            ),
            C10(),
            Text(
              "You are using an older app version. Update the app for new features and optimum experience.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085),
                  fontFamily: "Inter-Regular"),
            ),
            Spacer(),
            Text(
              "Allish Version $buildversion(${buildNumber})",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085),
                  fontFamily: "Inter-Regular"),
            ),
            Spacer(),
            InkWell(
              onTap: () async {
                Get.back();
                if (Platform.isAndroid) {
                  const url =
                      'https://play.google.com/store/apps/details?id=example.autopeepalApp.com.prod&hl=en';

                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  } else {
                    throw 'Could not launch $url';
                  }
                } else {
                  const url =
                      'https://apps.apple.com/in/app/allish-uk/id6502819288';
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  } else {
                    throw 'Could not launch $url';
                  }
                }
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Center(
                    child: Text(
                      "Update App",
                      style: TextStyle(
                          fontFamily: "Inter-SemiBold",
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.white),
                    ),
                  ),
                ),
              ),
            ),
            C10(),
          ],
        ),
      ),
    );
  }
}

class FroceUpdateController extends GetxController {
  checkUpdate() async {
    try {
      PackageInfo packageInfoDetails = await PackageInfo.fromPlatform();
      Map<String, dynamic> postData = Map();
      postData.add(
          key: 'Platform', value: Platform.isAndroid ? "Android" : "Ios");

      Map<String, dynamic> responseData =
          await AppAPIs.post('/api/FarmFresh/GetAppVersion', data: postData);
      if (responseData.getBool('success')) {
        List<dynamic> rawList =
            responseData.getMap("response").getList("Table");
        int apiBuildNUmber = int.parse(rawList[0]["BuildNumber"]);
        if (int.parse(packageInfoDetails.buildNumber) > apiBuildNUmber) {
        } else {
          Get.bottomSheet(FroceUpdateView(
            buildNumber: apiBuildNUmber.toString(),
            buildversion: rawList[0]["AppVersion"].toString(),
          ));
        }
      }
    } catch (e) {}
  }
}
