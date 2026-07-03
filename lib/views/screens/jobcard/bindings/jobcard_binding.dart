import 'package:get/get.dart';

import '../controllers/jobcard_controller.dart';

class JobcardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobCardController>(
      () => JobCardController(),
    );
  }
}
