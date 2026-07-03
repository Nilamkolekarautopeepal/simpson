import 'package:flutter/material.dart';

class CustomDivider extends StatelessWidget {
  final double startWidth;
  final double endWidth;
  final double height;
  final TextDirection textDirection;

  const CustomDivider({
    required this.startWidth,
    required this.endWidth,
    required this.height,
    required this.textDirection,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: textDirection,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: switch (textDirection) {
              TextDirection.rtl => [Colors.grey.shade400, Colors.grey.shade300],
              TextDirection.ltr => [Colors.grey.shade300, Colors.grey.shade400]
            },
            stops: [startWidth / (startWidth + endWidth), 1.0],
          ),
        ),
        height: height,
      ),
    );
  }
}
