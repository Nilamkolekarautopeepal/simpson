import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ListSubtitleWithImages extends StatelessWidget {
  final String title;
  final String image;

  const ListSubtitleWithImages(
      {super.key, required this.title, required this.image});
  @override
  Widget build(Object context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image widget
        Padding(
          padding: const EdgeInsets.all(0.0),
          child: SvgPicture.asset(
            image, // Replace with your image URL
            width: Sizes.s18,
            height: Sizes.s18,
          ),
        ),
        // Text widget
        C10(),
        Text(
          title,
          style: TextStyle(
              fontSize: FontSizes.s12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
              color: AppColors.subtitleColor,
              height: 1.2,
              fontFamily: "Inter-Regular"),
        ),
      ],
    );
  }
}

class ListSubtitleWithImages2 extends StatelessWidget {
  final String title;
  final String image;
  final String value;

  const ListSubtitleWithImages2(
      {super.key,
      required this.title,
      required this.image,
      required this.value});
  @override
  Widget build(Object context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image widget
        Padding(
          padding: const EdgeInsets.all(0.0),
          child: SvgPicture.asset(
            image, // Replace with your image URL
            width: Sizes.s18,
            height: Sizes.s18,
          ),
        ),
        // Text widget
        C10(),
        Text(
          title + " ",
          style: TextStyle(
              fontSize: FontSizes.s12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
              color: AppColors.subtitleColor,
              height: 1.2,
              fontFamily: "Inter-Regular"),
        ),
        Text(
          value,
          style: TextStyle(
              fontSize: FontSizes.s12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.normal,
              color: AppColors.black,
              height: 1.2,
              fontFamily: "Inter-SemiBold"),
        ),
      ],
    );
  }
}

class ListSubtitleWithImages4 extends StatelessWidget {
  final String title;
  final String image;
  final String value;

  const ListSubtitleWithImages4(
      {super.key,
      required this.title,
      required this.image,
      required this.value});
  @override
  Widget build(Object context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image widget
        Padding(
          padding: const EdgeInsets.all(0.0),
          child: SvgPicture.asset(
            image, // Replace with your image URL
            width: Sizes.s18,
            height: Sizes.s18,
          ),
        ),
        // Text widget
        C10(),

        Text(
          value,
          style: TextStyle(
              fontSize: FontSizes.s12,
              fontWeight: FontWeight.w600,
              fontStyle: FontStyle.normal,
              color: AppColors.black,
              height: 1.2,
              fontFamily: "Inter-SemiBold"),
        ),
      ],
    );
  }
}

class ListSubtitleWithImages3 extends StatelessWidget {
  final String title;
  final String image;

  const ListSubtitleWithImages3(
      {super.key, required this.title, required this.image});
  @override
  Widget build(Object context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        // Image widget
        Padding(
          padding: const EdgeInsets.all(0.0),
          child: SvgPicture.asset(
            image, // Replace with your image URL
            width: Sizes.s18,
            height: Sizes.s18,
          ),
        ),
        // Text widget
        C10(),
        Text(
          title,
          style: TextStyle(
              fontSize: FontSizes.s12,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.normal,
              color: AppColors.subtitleColor,
              height: 1.2,
              fontFamily: "Inter-Regular"),
        ),
      ],
    );
  }
}
