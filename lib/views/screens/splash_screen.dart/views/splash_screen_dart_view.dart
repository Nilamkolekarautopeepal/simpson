//prathmesh girme
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
            child: Container(
              color: const Color.fromARGB(255, 251, 252, 252),
            ),
          ),
          Center(
            child: Image.asset(
              'asset/images/simpsons_logo.png',
              width: 380,
              errorBuilder: (context, error, stackTrace) {
                debugPrint(
                    "🔴 [SplashScreen] Failed to load simpsons_logo.png: $error");
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
