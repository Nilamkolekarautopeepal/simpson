import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/utils/assets.dart';
import 'package:simpson/utils/sizes.dart';
import 'package:simpson/utils/strings.dart';
import 'package:simpson/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';


import 'buttons.dart';


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
              C20(),
              Container(
                child: Image.asset(
                  Assets.logo,
                  fit: BoxFit.contain,
                ),
                height: Sizes.s100,
                width: Sizes.s100,
              ),
              C20(),
              Text(
                "Something went wrong",
                style: TextStyles.defaultBold.copyWith(
                  fontSize: FontSizes.s20,
                ),
                textAlign: TextAlign.center,
              ),
              C20(),
              Text(
                errorDetails.exceptionAsString(),
                style: TextStyles.defaultRegular.copyWith(
                  fontSize: FontSizes.s14,
                  color: Colors.red,
                ),
                textAlign: TextAlign.justify,
              ),
              C20(),

              Container(
                height: Sizes.s10,
              ),

              AppButton(
                title: Strings.restartApp,
                onTap: () {
                  // AppRoutes.makeFirst(context, SplashScreen());
                },
              ),
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
