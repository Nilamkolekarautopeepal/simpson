import 'package:simpson/themes/app_colors.dart';
import 'package:flutter/material.dart';


class BackgroundLinearGradientWidget extends StatelessWidget {
  final double? height;

  const BackgroundLinearGradientWidget({Key? key, this.height})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.primary,
    );
  }
}
