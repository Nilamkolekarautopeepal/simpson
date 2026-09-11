import 'package:simpson/utils/app_constants.dart';
import 'package:simpson/routes/app_pages.dart';
import 'package:get/get.dart';

class SplashScreenDartController extends GetxController {
  @override
  void onReady() {                         
    super.onReady();
    Future.delayed(Duration(seconds: Constants.splashDelay), () {
      getScreen();
    });
  }

  Future<void> getScreen() async {
    Get.offAllNamed(Routes.LOGIN);          
  }
}