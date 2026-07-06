import 'package:simpson/themes/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class RoundedBottomContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      width: double.infinity,
      height: double.infinity,
      child: Lottie.asset('asset/logo/animation.json'),
      // Lottie.asset('asset/logo/animation1.json')
    );
  }
}
