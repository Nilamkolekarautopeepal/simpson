import 'package:flutter/services.dart';
import 'package:get/get.dart';

class HotspotController extends GetxController {
  static const platform = MethodChannel('hotspot/devices');
  var connectedDevices = <String>[].obs;

  Future<void> fetchConnectedDevices() async {
    try {
      final List<dynamic> devices =
          await platform.invokeMethod('getConnectedDevices');
      connectedDevices.value = devices.cast<String>();
    } catch (e) {
      print("Error fetching devices: $e");
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchConnectedDevices();
  }
}
