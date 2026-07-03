
import 'package:autopeepalApp/utils/app_constants.dart';
import 'package:autopeepalApp/routes/app_pages.dart';
// import 'package:autopeepalApp/utils/app_constants.dart';
import 'package:get/get.dart';

// class SplashScreenDartController extends GetxController {
//   @override
//   void onInit() {
//     Future.delayed(Duration(seconds: Constants.splashDelay), () {
//       getScreen();
//     });
//     super.onInit();
//   }

//   Future<void> getScreen() async { 
//        Get.offAndToNamed(Routes.LOGIN);
//     }
     
//   }

class SplashScreenDartController extends GetxController {
  @override
  void onReady() {                          // ✅ use onReady, not onInit
    super.onReady();
    Future.delayed(Duration(seconds: Constants.splashDelay), () {
      getScreen();
    });
  }

  Future<void> getScreen() async {
    Get.offAllNamed(Routes.LOGIN);          // ✅ offAllNamed clears the stack
  }
}