import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:flutter/material.dart';

class CustomLoader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      width: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Color(0xFFEAECF0), // Border color
          width: 1.0, // Border width
        ),
      ),
      child: Center(
        child: CircularProgressIndicator(
          valueColor:
              // ignore: deprecated_member_use
              AlwaysStoppedAnimation<Color>(AppColors.primary.withOpacity(0.5)),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius borderRadius;

  SkeletonLoader({
    required this.width,
    required this.height,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  _SkeletonLoaderState createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: widget.borderRadius,
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  AppColors.gray200,
                  // ignore: deprecated_member_use
                  AppColors.white.withOpacity(.9),
                  AppColors.gray200
                ],
                stops: [0.0, _animation.value, 1.0],
                begin: Alignment(-1.0, -0.3),
                end: Alignment(1.0, 0.3),
              ).createShader(bounds);
            },
            child: Container(
              color: Colors.grey[300],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}


class SkeletonLoader2 extends StatefulWidget {
  final double size;
  final BorderRadius borderRadius;

  SkeletonLoader2({
    required this.size,
    this.borderRadius = BorderRadius.zero,
  });

  @override
  _SkeletonLoader2State createState() => _SkeletonLoader2State();
}

class _SkeletonLoader2State extends State<SkeletonLoader2>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
      upperBound: 1.0,
    )..repeat(reverse: true);

    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        shape: BoxShape.circle,
        borderRadius: widget.borderRadius, // Border radius is ignored for circles
      ),
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                colors: [
                  AppColors.gray200,
                  // ignore: deprecated_member_use
                  AppColors.white.withOpacity(0.9),
                  AppColors.gray200,
                ],
                stops: [0.0, _animation.value, 1.0],
                begin: Alignment(-1.0, -0.3),
                end: Alignment(1.0, 0.3),
              ).createShader(bounds);
            },
            child: Container(
              color: Colors.grey[300],
              // This ensures that the gradient shader is clipped to the circular shape
              child: ClipOval(
                child: Container(
                  color: Colors.grey[300],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}