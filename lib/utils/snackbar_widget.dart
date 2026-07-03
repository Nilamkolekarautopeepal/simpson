import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:flutter/material.dart';

class CustomSnackBar {
  CustomSnackBar(String string);

  static void show2(BuildContext context, String message) {
    final snackBar = SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontFamily: "Inter-SemiBold"),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.none);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  static void show(BuildContext context, String message) {
    final snackBar = SnackBar(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontFamily: "Inter-SemiBold"),
              ),
            ),
            GestureDetector(
              onTap: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
              child: Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
        backgroundColor:
            message.toLowerCase() == "Coupon code applied".toLowerCase()
                ? AppColors.primary
                : Colors.red,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.none);

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
