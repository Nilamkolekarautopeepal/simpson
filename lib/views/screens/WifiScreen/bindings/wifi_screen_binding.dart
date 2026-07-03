import 'package:get/get.dart';

import '../controllers/wifi_screen_controller.dart';

class WifiScreenBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HotspotController>(
      () => HotspotController(),
    );
  }
}
