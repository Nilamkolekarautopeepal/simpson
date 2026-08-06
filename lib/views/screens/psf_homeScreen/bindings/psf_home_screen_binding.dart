import 'package:get/get.dart';
import 'package:simpson/services/plc/plc_service.dart';

import '../controllers/psf_home_screen_controller.dart';

class PsfHomeScreenBinding extends Bindings {
  @override
  void dependencies() {

    if (!Get.isRegistered<PlcService>()) {
      Get.put<PlcService>(PlcService(), permanent: true);
    }

    Get.lazyPut<PsfHomeScreenController>(
      () => PsfHomeScreenController(),
    );
  }
}
