import 'package:autopeepalApp/common_widgets/ui_helper_widgets.dart';
import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:flutter/material.dart';

class NoInternetView extends StatelessWidget {
  NoInternetView({Key? key, required this.onTap}) : super(key: key);
  final void Function() onTap;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("asset/logo/images/nointernet.png"),
              C10(),
              Text(
                "No Internet Connection",
                style: TextStyle(
                    fontFamily: "Inter-Bold",
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1D2939)),
              ),
              C10(),
              Text(
                "Please check your internet connection and try again to reload the page.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF667085),
                    fontFamily: "Inter-Regular"),
              ),
              C20(),
              InkWell(
                onTap: onTap,
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
                        "Reload",
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
            ],
          ),
        ),
      ),
    );
  }
}
