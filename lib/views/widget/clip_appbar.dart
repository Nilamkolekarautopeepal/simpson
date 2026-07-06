import 'package:simpson/themes/app_colors.dart';
import 'package:simpson/utils/sizes.dart';
import 'package:flutter/material.dart';

class RoundedBottomContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(25.0),
        bottomRight: Radius.circular(25.0),
      ),
      child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.linearGradientPrimary,
                AppColors.linearGradientSecondary
              ],
            ),
          ),
          height: Sizes.heightClip(context),
          width: double.infinity,
          child: Image.asset("asset/logo/images/loginimage.png")),
    );
  }
}

@override
Path getClip(Size size) {
  final path = Path();
  path.lineTo(0, size.height - 30); // Start at the top-left
  path.quadraticBezierTo(size.width / 2, size.height, size.width,
      size.height - 30); // Curve to the top-right
  path.lineTo(size.width, 0); // Line to the bottom-right
  path.close(); // Close the path

  return path;
}

@override
bool shouldReclip(CustomClipper<Path> oldClipper) {
  return false;
}
