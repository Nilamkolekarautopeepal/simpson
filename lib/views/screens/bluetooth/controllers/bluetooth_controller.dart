// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:flutter_blue_plus/flutter_blue_plus.dart';
// import 'package:get/get.dart';
// import 'package:permission_handler/permission_handler.dart';

// class BlutoothdDevicesController extends GetxController {
//   late String vciName;

//   final devices = <ScanResult>[].obs;
//   final isScanning = false.obs;
//   StreamSubscription<List<ScanResult>>? scanSubscription;


//   @override
//   void onInit() {
//     super.onInit();

//     final args = Get.arguments as Map<String, dynamic>?;
//     vciName = args?['vciName'] ?? 'VCI';

//     startScan();
//     //getDeviceName();
//   }

// Future<void> connectToDevice(BluetoothDevice device) async {
//   try {
//     await device.connect(autoConnect: false);
//     await device.discoverServices();

//     // 🔥 forces UI refresh → name appears if available
//     devices.refresh();
//   } catch (e) {
//     debugPrint("Connection error: $e");
//   }
// }



//   void startScan() async {
//   await Permission.bluetoothScan.request();
//   await Permission.bluetoothConnect.request();
//   await Permission.location.request();

//   devices.clear();
//   isScanning.value = true;

//   // 🔴 Cancel previous listener
//   await scanSubscription?.cancel();

//   scanSubscription = FlutterBluePlus.scanResults.listen((results) {
//     devices.assignAll(results);
//   });

//   await FlutterBluePlus.startScan(
//     timeout: const Duration(seconds: 8),
//   );

//   isScanning.value = false;
// }


// String getDeviceName(ScanResult result, int index) {
//   // 1️⃣ BLE advertised name
//   if (result.advertisementData.localName.isNotEmpty) {
//     return result.advertisementData.localName;
//   }

//   // 2️⃣ Device name (after pairing)
//   if (result.device.name.isNotEmpty) {
//     return result.device.name;
//   }

//   // 3️⃣ Manufacturer data hint
//   if (result.advertisementData.manufacturerData.isNotEmpty) {
//     return "BLE Device";
//   }

//   // 4️⃣ Friendly unique fallback
//   return "Bluetooth Device ${index + 1}";
// }


// @override
// void onClose() {
//   scanSubscription?.cancel();
//   FlutterBluePlus.stopScan();
//   super.onClose();
// }



// }
import 'dart:async';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:get/get.dart';

class BlutoothdDevicesController extends GetxController {
  late String vciName;

  final devices = <BluetoothDiscoveryResult>[].obs;
  final isScanning = false.obs;

  StreamSubscription<BluetoothDiscoveryResult>? discoveryStream;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    vciName = args?['vciName'] ?? 'VCI';

    startScan();
  }

  void startScan() {
    isScanning.value = true;
    devices.clear();

    discoveryStream =
        FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
      // Avoid duplicates
      if (!devices.any(
          (d) => d.device.address == result.device.address)) {
        devices.add(result);
      }
    });

    discoveryStream?.onDone(() {
      isScanning.value = false;
    });
  }

  void connectToDevice(BluetoothDevice device) async {
  try {
    await FlutterBluetoothSerial.instance.requestEnable();

    final bonded =
        await FlutterBluetoothSerial.instance.bondDeviceAtAddress(
      device.address,
    );

    if (bonded == true) {
      // 🔁 restart scan to fetch real device name
      startScan();
    }
  } catch (e) {
    print("Connection error: $e");
  }
}

  String getDeviceName(BluetoothDiscoveryResult result, int index) {
  final name = result.device.name;

  if (name != null && name.isNotEmpty) {
    return name; // actual name (after pairing)
  }

  // fallback BEFORE pairing
  return "Bluetooth Device ${index + 1}";
}


  @override
  void onClose() {
    discoveryStream?.cancel();
    super.onClose();
  }
}
