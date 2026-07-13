import 'package:get/get.dart';

import '../controllers/ecu_flashing_page_controller.dart';

class EcuFlashingPageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EcuFlashingPageController>(
      () => EcuFlashingPageController(),
    );
  }
}
