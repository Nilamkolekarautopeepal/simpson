import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:flutter/material.dart';

class TwoInlineText extends StatelessWidget {
  final String title1;
  final String title2;
  final Function? ontapAll;
  const TwoInlineText(
      {super.key, required this.title1, required this.title2, this.ontapAll});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      child: InkWell(
        onTap: () => ontapAll,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title1 == "FromYourPastOrders"
                  ? "From Your Past Orders"
                  : title1 == "TopPicksForYou"
                      ? "Top Picks For You"
                      : title1,
              style: TextStyle(
                  fontSize: FontSizes.s16,
                  color: AppColors.dashbordItemType,
                  fontFamily: "Inter-Bold",
                  fontWeight: FontWeight.w700),
            ),
            InkWell(
              onTap: () => ontapAll!(),
              child: Text(
                title2,
                style: TextStyle(
                    fontSize: FontSizes.s12,
                    color: AppColors.primary,
                    fontFamily: "Inter-SemiBold",
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
