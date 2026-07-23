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
          // Solid color background instead of an image — avoids any
          // asset-loading/path issues entirely. Adjust the color to
          // match your brand (this matches the dark navy blue used
          // elsewhere in the splash/login screens).
          Positioned.fill(
            child: Container(
              color: const Color(0xFF0A1F44),
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