import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/utils/sizes.dart';
import 'package:flutter/material.dart';


class SlidingSegmentedWidget extends StatelessWidget {
  final String title;
  final bool isSelected;

  const SlidingSegmentedWidget({
    Key? key,
    required this.title,
    this.isSelected = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(Sizes.s10),
      child: Text(
        title,
        style: TextStyles.defaultMedium.copyWith(
          color: isSelected ? Colors.white : Colors.black,
          fontSize: FontSizes.s14,
        ),
      ),
    );
  }
}
