import 'package:get/get.dart';

import '../controllers/dashboard13_controller.dart';

class Dashboard13Binding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<Dashboard13Controller>(
      () => Dashboard13Controller(),
    );
  }
}
