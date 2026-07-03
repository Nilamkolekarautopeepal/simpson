import 'package:get/get.dart';

import '../controllers/splash_screen_dart_controller.dart';

// class SplashScreenDartBinding extends Bindings {
//   @override
//   void dependencies() {
//     Get.lazyPut<SplashScreenDartController>(
//       () => SplashScreenDartController(),
//     );
//   }
// }
class SplashScreenDartBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<SplashScreenDartController>(  // ✅ put, not lazyPut
      SplashScreenDartController(),
    );
  }
}