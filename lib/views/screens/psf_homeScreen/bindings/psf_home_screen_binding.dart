import 'package:get/get.dart';
import 'package:simpson/services/plc/plc_service.dart';

import '../controllers/psf_home_screen_controller.dart';

class PsfHomeScreenBinding extends Bindings {
  @override
  void dependencies() {
    // Safety net: register PlcService here too, in case InitialBinding
    // wasn't wired into app.dart for some reason. Won't double-register
    // if it's already there from app startup.
    if (!Get.isRegistered<PlcService>()) {
      Get.put<PlcService>(PlcService(), permanent: true);
    }

    Get.lazyPut<PsfHomeScreenController>(
      () => PsfHomeScreenController(),
    );
  }
}
