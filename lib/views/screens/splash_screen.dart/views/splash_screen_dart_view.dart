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
              'asset/logo/00.png',
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
