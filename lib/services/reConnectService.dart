// import 'package:simpson/modals/staticData.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:get/get.dart';
// import 'package:simpson/app.dart';
// import 'package:simpson/services/connectionWifiService.dart';

// class ReconnectService {
//   // ─────────────────────────────────────────────────────────
//   // Ask the user before reconnecting (only when disconnect
//   // was unexpected, e.g. after a flash-induced dongle reset)
//   // ─────────────────────────────────────────────────────────
//   Future<void> askAndReconnect({VoidCallback? onReconnected}) async {
//     final shouldReconnect = await Get.dialog<bool>(
//       AlertDialog(
//         title: const Text("Dongle Disconnected"),
//         content: const Text(
//           "Connection to the dongle was lost — this can happen right after "
//           "flashing while the ECU resets. Reconnect now?",
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(result: false),
//             child: const Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () => Get.back(result: true),
//             child: const Text("Reconnect"),
//           ),
//         ],
//       ),
//       barrierDismissible: false,
//     );

//     if (shouldReconnect == true) {
//       await reconnectDongle(onReconnected: onReconnected);
//     }
//   }

//   String? ipAddress;

//   // ─────────────────────────────────────────────────────────
//   // WIFI-only reconnect
//   // ─────────────────────────────────────────────────────────
//   Future<void> reconnectDongle({VoidCallback? onReconnected}) async {
//     Get.dialog(
//       const Center(
//         child: Card(
//           child: Padding(
//             padding: EdgeInsets.all(24),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 CircularProgressIndicator(),
//                 SizedBox(height: 16),
//                 Text("Reconnecting..."),
//               ],
//             ),
//           ),
//         ),
//       ),
//       barrierDismissible: false,
//     );

//     await Future.delayed(const Duration(milliseconds: 50));

//     try {
//       final connectionWifi = ConnectionWifi();

//       // NOTE: replace App.ipAddress below with whatever field actually
//       // holds the connected dongle's IP on your App class if it's named
//       // differently (e.g. App.IPAddress, App.currentIp, etc.)
//       final resp = await connectionWifi.getDongleMacID(
//         ipAddress??'',
//         channelId: "00",
//       );

//       bool propsOk = false;

//       if (resp.isNotEmpty) {
//         // App.dllFunctions was just re-initialized inside getDongleMacID,
//         // so this hits the fresh connection.
//         // setDongleProperties' return type isn't confirmed yet — treating
//         // it as void and relying on try/catch for success/failure.
//         try {
//           await App.dllFunctions!.setDongleProperties(
//             StaticData.ecuInfo[0].protocol!.autopeepal ?? '',
//             StaticData.ecuInfo[0].txHeader ?? '',
//             StaticData.ecuInfo[0].rxHeader ?? ''
//           );
//           propsOk = true;
//         } catch (e) {
//           debugPrint("setDongleProperties failed: $e");
//           propsOk = false;
//         }
//       }

//       _dismissLoading();

//       if (resp.isNotEmpty && propsOk) {
//         await _showAlert(
//           title: "Success",
//           message: "Dongle reconnected successfully",
//         );
//         onReconnected?.call(); // ← triggers DTC reload
//       } else {
//         await _showAlert(
//           title: "Alert",
//           message: "Failed to connect with dongle.",
//         );
//       }
//     } catch (ex) {
//       debugPrint("ReconnectDongle error: $ex");
//       _dismissLoading();
//       await _showAlert(
//         title: "Failed!",
//         message: "Please try once again.",
//       );
//     } finally {
//       _dismissLoading();
//     }
//   }

//   void _dismissLoading() {
//     if (Get.isDialogOpen == true) {
//       Get.back();
//     }
//   }

//   Future<void> _showAlert({
//     required String title,
//     required String message,
//   }) async {
//     await Get.dialog(
//       AlertDialog(
//         title: Text(title),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () => Get.back(),
//             child: const Text("OK", style: TextStyle(color: Colors.blue)),
//           ),
//         ],
//       ),
//     );
//   }
// }