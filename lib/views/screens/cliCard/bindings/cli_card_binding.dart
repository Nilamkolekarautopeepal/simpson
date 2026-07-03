import 'package:get/get.dart';

import '../controllers/cli_card_controller.dart';

class CliCardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CliCardController>(
      () => CliCardController(),
    );
  }
}
