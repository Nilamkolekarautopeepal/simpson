import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:flutter/material.dart';


class RowWidgetDashbord extends StatelessWidget {
  final String? title1;
  final String? image1;
  final String? title2;
  final String? image2;
  final bool? isSecond;
  // final AppRoutes app;
  final Function? onTap1;
  final Function? onTap2;
  const RowWidgetDashbord(
      {Key? key,
      this.title1,
      this.image1,
      this.title2,
      this.image2,
      this.isSecond,
      this.onTap1,
      this.onTap2})
      : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: (screenWidth - 10) / 2,
          height: 135 * ((screenWidth - 10) / 2) / 165,
          child: GestureDetector(
            onTap: ()=>this.onTap1,
            child: Card(
              color: AppColors.grey,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 20, 10, 25),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.asset(
                      'assets/' + image1!,
                      height: 60,
                      width: 60,
                    ),
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Text(
                        title1!,
                        style: TextStyles.defaultMedium
                            .copyWith(fontSize: Sizes.s18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isSecond!)
          Container(
            width: (screenWidth - 10) / 2,
            height: 135 * ((screenWidth - 10) / 2) / 165,
            child: GestureDetector(
              onTap: ()=>this.onTap2,
              child: 
              Card(
                color: AppColors.grey,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 10, 25),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(
                        'assets/' + image2!,
                        height: 60,
                        width: 60,
                      ),
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Text(
                          title2!,
                          style: TextStyles.defaultMedium
                              .copyWith(fontSize: Sizes.s18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        if (!isSecond!)
          Container(
            width: (screenWidth - 10) / 2,
            height: screenWidth / 2,
          )
      ],
    );
  }
}
