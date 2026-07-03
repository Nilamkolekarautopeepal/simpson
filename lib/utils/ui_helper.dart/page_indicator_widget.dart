// Flutter imports:
import 'package:flutter/material.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/utils/app_constants.dart';
import 'package:simpson/utils/sizes.dart';

class PageIndicator extends StatelessWidget {
  final int currentPage;
  final int length;
  final double bottomOffset;
  final double? width;

  const PageIndicator({
    Key? key,
   required this.currentPage,
   required this.length,
   required this.bottomOffset,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      margin: EdgeInsets.only(bottom: bottomOffset),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List<Widget>.generate(
            length,
            (index) => SelectorWidget(
                  active: currentPage == index,
                )).toList(),
      ),
    );
  }
}

class SelectorWidget extends StatelessWidget {
  final bool active;

  const SelectorWidget({Key? key,required this.active}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = active ? Sizes.s15 : Sizes.s8;
    return AnimatedContainer(
      margin: EdgeInsets.symmetric(horizontal: Sizes.s5),
      duration: Duration(milliseconds: Constants.delaySmall),
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.pinkishGrey,
        borderRadius: BorderRadius.all(
          Radius.circular(Sizes.s8),
        ),
        border: Border.all(
          color: AppColors.white,
        ),
      ),
    );
  }
}
