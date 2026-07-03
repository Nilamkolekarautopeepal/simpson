import 'package:autopeepalApp/utils/sizes.dart';
import 'package:flutter/material.dart';


class ClipperWidget extends StatelessWidget {
  final Widget? child;

  const ClipperWidget({
    Key? key,
    this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: ClipPath(
        clipper: BottomClipper(offset: Sizes.s30),
        child: child,
      ),
    );
  }
}

class BottomClipper extends CustomClipper<Path> {
  final double offset;

  BottomClipper({
    this.offset = 0.0,
  });

  @override
  Path getClip(Size size) {
    var path = Path()
      ..lineTo(0, 0)
      ..lineTo(0, size.height)
      ..arcToPoint(
        Offset(offset, size.height - offset),
        radius: Radius.circular(offset),
      )
      ..lineTo(size.width - offset, size.height - offset)
      ..arcToPoint(
        Offset(size.width, size.height),
        radius: Radius.circular(offset),
        clockwise: true,
      )
      ..lineTo(size.width, 0)
      ..lineTo(0, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}
