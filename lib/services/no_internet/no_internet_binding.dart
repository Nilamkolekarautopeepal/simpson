import 'package:simpson/services/no_internet/no_internet_controller.dart';
import 'package:get/get.dart';

class ControllerBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ConnectionManagerController());
  }
}
