import 'package:get/get.dart';

import '../controllers/jobcard_details_controller.dart';

class JobcardDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<JobCardDetailsController>(
      () => JobCardDetailsController(),
    );
  }
}
