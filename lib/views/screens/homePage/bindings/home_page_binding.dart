import 'package:get/get.dart';
import 'package:simpson/services/plc/plc_service.dart';

import '../controllers/home_page_controller.dart';

class HomePageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomePageController>(
      () => HomePageController(),
    );
    Get.put(PlcService());
  }
}
