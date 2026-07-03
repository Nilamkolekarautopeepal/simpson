import 'package:autopeepalApp/common_widgets/ui_helper_widgets.dart';
import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:autopeepalApp/utils/fonts.dart';
import 'package:flutter/material.dart';

class TitleAndSubtitleText extends StatelessWidget {
  final String title1;
  final String title2;
  const TitleAndSubtitleText({
    super.key,
    required this.title1,
    required this.title2,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title1,
          style: TextStyle(
              fontSize: 12,
              color: AppColors.subtitleColor,
              fontFamily: Font.interNormal,
              fontWeight: FontWeight.w400),
        ),
        C5(),
        Text(
          title2,
          style: TextStyle(
              fontSize: 12,
              color: AppColors.black,
              fontFamily: Font.interMedium,
              fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

class SubtitleAndtitleText extends StatelessWidget {
  final String title1;
  final String title2;
  const SubtitleAndtitleText({
    super.key,
    required this.title1,
    required this.title2,
  });
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title2,
          style: TextStyle(
              fontSize: 12,
              color: AppColors.black,
              fontWeight: FontWeight.w700),
        ),
        C5(),
        Text(
          title1,
          style: TextStyle(
              fontSize: 12,
              color: AppColors.subtitleColor,
              fontWeight: FontWeight.w400),
        ),
      ],
    );
  }
}
