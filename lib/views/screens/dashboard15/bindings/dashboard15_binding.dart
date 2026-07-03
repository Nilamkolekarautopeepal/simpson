import 'package:get/get.dart';

import '../controllers/dashboard15_controller.dart';

class Dashboard15Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Dashboard15Controller>(
      () => Dashboard15Controller(),
    );
  }
}
