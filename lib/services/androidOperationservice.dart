import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:simpson/common_widgets/popup.dart'; // only used for Android/iOS

class AndroidOperationsService {
  static Future<bool> hasInternet() async {
    final ConnectivityResult connectivityResult =
        await Connectivity().checkConnectivity();

    if (connectivityResult == ConnectivityResult.none) {
      return false;
    }

    return connectivityResult == ConnectivityResult.mobile ||
        connectivityResult == ConnectivityResult.wifi ||
        connectivityResult == ConnectivityResult.ethernet ||
        connectivityResult == ConnectivityResult.vpn;
  }

  static Future<String> getVersionNumber() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      return '';
    }
  }

  // static Future<List<String>> getDeviceUniqueId() async {
  //   List<String> uniqueId = ["false", "Device id not found."];
  //   try {
  //     if (Platform.isWindows) {
  //       DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
  //       WindowsDeviceInfo windowsInfo = await deviceInfo.windowsInfo;
  //       String id = windowsInfo.deviceId;
  //       if (id.isNotEmpty) {
  //         String cleanId = id
  //             .replaceAll('{', '')
  //             .replaceAll('}', '')
  //             .replaceAll('-', '')
  //             .toUpperCase();
  //         String last16 = cleanId.substring(cleanId.length - 16);
  //         uniqueId = [last16];
  //       }
  //     } else {
  //       uniqueId = ["false", "Platform not supported."];
  //     }
  //   } catch (e) {}
  //   return uniqueId;
  // }

  // static Future<List<String>> getDeviceUniqueId() async {
  //   List<String> uniqueId = ["false", "Device id not found."];
  //   try {
  //     if (Platform.isWindows) {
  //       final mac = await _getWindowsMacAddress();
  //       if (mac != null && mac.isNotEmpty) {
  //         uniqueId = ["true", mac];
  //       }
  //     } else {
  //       uniqueId = ["false", "Platform not supported."];
  //     }
  //   } catch (e) {}
  //   return uniqueId;
  // }

  static Future<String> getDeviceUniqueId() async {
    if (Platform.isWindows) {
      return "1234567890"; // TODO: replace with real Windows machine ID
    } else if (Platform.isAndroid || Platform.isIOS) {
      // TODO: use device_info_plus to get real androidId / identifierForVendor
      return "1234567890";
    }
    return "1234567890"; // fallback for other platforms
  }

  /// Runs `getmac /fo csv /nh` and returns the first real (non-virtual,
  /// non-all-zero) physical MAC address formatted as "AA:BB:CC:DD:EE:FF".
  static Future<String?> _getWindowsMacAddress() async {
    try {
      final result = await Process.run('getmac', ['/fo', 'csv', '/nh']);
      if (result.exitCode != 0) return null;

      final output = result.stdout.toString();
      final lines = output.split('\n').where((line) => line.trim().isNotEmpty);

      final macPattern = RegExp(r'"([0-9A-Fa-f]{2}(-[0-9A-Fa-f]{2}){5})"');

      for (final line in lines) {
        final match = macPattern.firstMatch(line);
        if (match == null) continue;

        final formatted = match.group(1)!.replaceAll('-', ':').toUpperCase();

        // Skip disabled/virtual adapters reporting all zeros
        if (formatted == "00:00:00:00:00:00") continue;

        return formatted;
      }
    } catch (e) {
      // fall through to null below
    }
    return null;
  }

  static Future<String?> getData(String fileName) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, '$fileName.txt');
      final file = File(filePath);
      if (!await file.exists()) return null;
      List<String> lines = await file.readAsLines();
      if (lines.isNotEmpty) return lines.last;
      return "";
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveData(String fileName, [String data = ""]) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = p.join(directory.path, '$fileName.txt');
      final file = File(filePath);
      await file.writeAsString('$data\n', mode: FileMode.write, flush: true);
    } catch (e) {}
  }

  // ✅ Only called on Android/iOS — never on Windows
  static Future<bool> requestPermissionAsync() async {
    try {
      if (Platform.isWindows) return true; // skip on Windows

      PermissionStatus status = await Permission.locationWhenInUse.status;

      if (status.isDenied || status.isRestricted) {
        await Future.delayed(const Duration(milliseconds: 300));
        await Get.dialog(
          CustomPopup(
            title: "Location Permission",
            message:
                "This app needs location permission to fetch your current address.\n\nPlease allow location access when prompted.",
            confirmText: "Continue",
            onConfirm: () => Get.back(),
          ),
          barrierDismissible: false,
        );
        status = await Permission.locationWhenInUse.request();
      }

      if (status.isPermanentlyDenied) {
        await Future.delayed(const Duration(milliseconds: 300));
        await Get.dialog(
          CustomPopup(
            title: "Permission Denied",
            message:
                "Location permission is permanently denied.\n\nPlease enable it manually in App Settings.",
            confirmText: "Open Settings",
            onConfirm: () async {
              Get.back();
              await openAppSettings();
            },
          ),
          barrierDismissible: false,
        );
        return false;
      }

      if (!status.isGranted) {
        await Future.delayed(const Duration(milliseconds: 300));
        await Get.dialog(
          CustomPopup(
            title: "Permission Required",
            message:
                "Location permission was not granted.\n\nAddress feature will not be available.",
            confirmText: "OK",
            onConfirm: () => Get.back(),
          ),
          barrierDismissible: false,
        );
        return false;
      }

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Future.delayed(const Duration(milliseconds: 300));
        await Get.dialog(
          CustomPopup(
            title: "Location Service Off",
            message: "Please enable GPS/Location on your device.",
            confirmText: "Open Settings",
            onConfirm: () async {
              Get.back();
              await Geolocator.openLocationSettings();
            },
          ),
          barrierDismissible: false,
        );

        int waitCount = 0;
        while (!(await Geolocator.isLocationServiceEnabled())) {
          await Future.delayed(const Duration(milliseconds: 500));
          waitCount++;
          if (waitCount > 20) return false;
        }
      }

      return true;
    } catch (e) {
      Get.dialog(
        CustomPopup(
          title: "Permission Error",
          message: e.toString(),
          confirmText: "OK",
          onConfirm: () => Get.back(),
        ),
        barrierDismissible: false,
      );
      return false;
    }
  }

//  static Future<String> getCurrentAddress() async {
//   print("👉 getCurrentAddress started");

//   try {
//     // ✅ Check if location service is enabled first
//     bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

//     if (!serviceEnabled) {
//       // Guide user to enable location
//       await Get.dialog(
//         CustomPopup(
//           title: "Location Required",
//           message:
//               "Location service is disabled.\n\nPlease enable it:\n"
//               "• Open Windows Settings\n"
//               "• Go to Privacy & Security → Location\n"
//               "• Turn ON 'Location services'\n"
//               "• Turn ON 'Let desktop apps access your location'",
//           confirmText: "Open Settings",
//           onConfirm: () {
//             Get.back();
//             Geolocator.openLocationSettings();
//           },
//         ),
//         barrierDismissible: false,
//       );

//       // Wait for user to enable it
//       int waited = 0;
//       while (!(await Geolocator.isLocationServiceEnabled())) {
//         await Future.delayed(const Duration(seconds: 1));
//         waited++;
//         if (waited > 30) {
//           // 30 seconds timeout
//           await Get.dialog(
//             CustomPopup(
//               title: "Location Timeout",
//               message:
//                   "Location was not enabled in time.\n\nPlease try again after enabling location in Windows Settings.",
//               confirmText: "OK",
//               onConfirm: () => Get.back(),
//             ),
//             barrierDismissible: false,
//           );
//           return "";
//         }
//       }
//     }

//     // ✅ Location service is ON — request permission
//     LocationPermission permission = await Geolocator.checkPermission();

//     if (permission == LocationPermission.denied) {
//       permission = await Geolocator.requestPermission();
//     }

//     if (permission == LocationPermission.deniedForever ||
//         permission == LocationPermission.denied) {
//       await Get.dialog(
//         CustomPopup(
//           title: "Permission Denied",
//           message:
//               "Location permission is denied.\n\nPlease enable it:\n"
//               "• Open Windows Settings\n"
//               "• Go to Privacy & Security → Location\n"
//               "• Turn ON 'Let desktop apps access your location'",
//           confirmText: "Open Settings",
//           onConfirm: () {
//             Get.back();
//             Geolocator.openLocationSettings();
//           },
//         ),
//         barrierDismissible: false,
//       );
//       return "";
//     }

//     // ✅ Permission granted — get position
//     print("📍 Getting position...");
//     Position position = await Geolocator.getCurrentPosition(
//       desiredAccuracy: LocationAccuracy.high,
//     ).timeout(
//       const Duration(seconds: 15),
//       onTimeout: () => throw TimeoutException("Location timed out after 15s"),
//     );

//     print("📍 Got position: ${position.latitude}, ${position.longitude}");
//     return await getAddressByCoords(position.latitude, position.longitude);

//   } on TimeoutException {
//     await Get.dialog(
//       CustomPopup(
//         title: "Location Timeout",
//         message: "Could not get location in time.\n\nMake sure:\n"
//             "• Location is enabled in Windows Settings\n"
//             "• 'Let desktop apps access your location' is ON",
//         confirmText: "OK",
//         onConfirm: () => Get.back(),
//       ),
//       barrierDismissible: false,
//     );
//     return "";

//   } catch ( e) {
//     await Get.dialog(
//       CustomPopup(
//         title: "Location Error",
//         message: e.toString(),
//         confirmText: "OK",
//         onConfirm: () => Get.back(),
//       ),
//       barrierDismissible: false,
//     );
//     return "";
//   }
// }

  static Future<String> getCurrentAddress() async {
    print("👉 getCurrentAddress started");

    try {
      // ✅ Check service
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print("❌ Location service disabled");
        return ""; // ✅ just return empty — controller handles dialog
      }

      // ✅ Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        print("❌ Location permission denied");
        return ""; // ✅ just return empty — controller handles dialog
      }

      // ✅ Get position
      print("📍 Getting position...");
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException("Location timed out"),
      );

      print("📍 Got position: ${position.latitude}, ${position.longitude}");
      final address =
          await getAddressByCoords(position.latitude, position.longitude);
      print("✅ Address: $address");
      return address;
    } catch (e) {
      print("❌ getCurrentAddress error: $e");
      return ""; // ✅ just return empty — controller handles dialog
    }
  }

  // // ✅ WINDOWS ONLY — pure HTTP, no Geolocator at all
  // static Future<String> _getAddressByIP() async {
  //   try {
  //     print("🌐 Getting location by IP...");

  //     final response = await http.get(
  //       Uri.parse("http://ip-api.com/json"),
  //       headers: {"User-Agent": "FlutterApp"},
  //     ).timeout(const Duration(seconds: 5));

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       if (data["status"] == "success") {
  //         double lat = data["lat"];
  //         double lon = data["lon"];

  //         String address = await getAddressByCoords(lat, lon);
  //         if (address == "Location unavailable") {
  //           address =
  //               "${data["city"] ?? ""}, ${data["regionName"] ?? ""}, ${data["country"] ?? ""}";
  //         }
  //         return "$address (Estimated Location)";
  //       }
  //     }

  //     return "Location unavailable";

  //   } catch ( e) {
  //     Get.dialog(
  //       CustomPopup(
  //         title: "Location Error",
  //         message: e.toString(),
  //         confirmText: "OK",
  //         onConfirm: () => Get.back(),
  //       ),
  //       barrierDismissible: false,
  //     );
  //     return "Location unavailable";
  //   }
  // }

  // // ✅ OSM reverse geocoding — used by both Windows and Android/iOS
  static Future<String> getAddressByCoords(double lat, double lon) async {
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?format=json"
        "&lat=$lat"
        "&lon=$lon"
        "&zoom=18"
        "&addressdetails=1",
      );

      final response = await http.get(
        url,
        headers: {"User-Agent": "FlutterApp"},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final displayName = data["display_name"];
        if (displayName != null && displayName.toString().isNotEmpty) {
          print("✅ Address: $displayName");
          return displayName;
        }
      }

      return "";
    } catch (e) {
      Get.dialog(
        CustomPopup(
          title: "Address Error",
          message: e.toString(),
          confirmText: "OK",
          onConfirm: () => Get.back(),
        ),
        barrierDismissible: false,
      );
      return "";
    }
  }
}

extension ToastExtension on String {
  Future<void> showMessage() async {
    try {
      await Fluttertoast.showToast(
        msg: this,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        fontSize: 14.0,
        backgroundColor: Colors.black87,
        textColor: Colors.white,
      );
    } catch (e) {}
  }
}
