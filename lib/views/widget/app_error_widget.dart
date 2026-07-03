import 'package:flutter/material.dart';
import 'package:autopeepalApp/utils/assets.dart';
import 'package:autopeepalApp/utils/sizes.dart';
///[AppErrorWidget] an Custom Error widget
///
///Only If [App.instance.devMode] is enabled error details are shown
///
class AppErrorWidget extends StatelessWidget {
  final FlutterErrorDetails errorDetails;

  const AppErrorWidget({
    Key? key,
    required this.errorDetails,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.red)),
          padding: EdgeInsets.symmetric(horizontal: Sizes.s30),
          constraints: BoxConstraints(maxHeight: screenWidth / Sizes.s2),
          child: ListView(
            children: <Widget>[
              Container(height: Sizes.s20),
              Container(
                child: Image.asset(
                  Assets.splashScreen,
                  fit: BoxFit.contain,
                ),
                height: Sizes.s100,
                width: Sizes.s100,
              ),
              // C20(),
              // Text(
              //   Strings.crashFinalTitle,
              //   style: TextStyles.defaultBold.copyWith(
              //     fontSize: FontSizes.s20,
              //   ),
              //   textAlign: TextAlign.center,
              // ),
              // C20(),
              // Text(
              //   Strings.crashFinalMessage,
              //   style: TextStyles.defaultRegular.copyWith(
              //     fontSize: FontSizes.s18,
              //   ),
              //   textAlign: TextAlign.justify,
              // ),
              // C20(),
              // DevWidget(
              //   child: Text(
              //     '${errorDetails.summary.toString()}',
              //     style: TextStyles.defaultBold.copyWith(
              //       fontSize: FontSizes.s18,
              //       color: Colors.red,
              //     ),
              //   ),
              // ),
              Container(height: Sizes.s10),
              // DevWidget(
              //   child: Text(
              //     "$errorDetails",
              //     style: TextStyles.defaultRegular.copyWith(
              //       fontSize: FontSizes.s13,
              //       color: Colors.red,
              //     ),
              //   ),
              // ),
              // AppButton(
              //   title: Strings.restartApp,
              //   onTap: () {
              //     AppRoutes.splash;
              //   },
              // ),
              Container(
                height: Sizes.s50,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
