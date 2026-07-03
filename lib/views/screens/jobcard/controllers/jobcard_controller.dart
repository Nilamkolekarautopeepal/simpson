import 'package:get/get.dart';

class JobCardController extends GetxController {
  late String vciName;

  @override
  void onInit() {
    super.onInit();

    // Get argument passed from previous screen
    final args = Get.arguments as Map<String, dynamic>?;

    vciName = args?['vciName'] ?? 'VCI';
  }
}
