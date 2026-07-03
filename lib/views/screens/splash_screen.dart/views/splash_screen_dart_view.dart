import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/splash_screen_dart_controller.dart';

class SplashScreenDartView extends GetView<SplashScreenDartController> {
  const SplashScreenDartView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'asset/images/ic_backgroungimg.png',
              fit: BoxFit.cover,
            ),
          ),
          Center(
            child: Image.asset(
              'asset/images/ic_sidialogo1.png',
              width: 280,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                    "🔴 [SplashScreen] Failed to load ic_sidialogo1.png: $error");
                return const Text(
                  'Logo not found',
                  style: TextStyle(color: Colors.red),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}