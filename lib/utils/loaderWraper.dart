import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:flutter/material.dart';

class LoaderWrapper extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  LoaderWrapper({required this.isLoading, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        child,
        if (isLoading)
          Container(
            // ignore: deprecated_member_use
            color: Colors.black.withOpacity(0.2),
            child: Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary), // Change color to blue
                strokeWidth: 4, // Increase the thickness of the circle
                semanticsLabel:
                    'Loading', // Add a semantic label for accessibility
              ),
            ),
          ),
      ],
    );
  }
}
