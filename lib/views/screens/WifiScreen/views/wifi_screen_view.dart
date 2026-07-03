import 'package:simpson/views/screens/WifiScreen/controllers/wifi_screen_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class WifiIpPage extends StatelessWidget {
  final HotspotController controller = Get.put(HotspotController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Connected Devices")),
      body: Obx(() {
        if (controller.connectedDevices.isEmpty) {
          return const Center(
            child: Text(
              "No devices connected",
              style: TextStyle(fontSize: 18),
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.connectedDevices.length,
          separatorBuilder: (_, __) => Divider(),
          itemBuilder: (context, index) {
            final deviceIp = controller.connectedDevices[index];
            return ListTile(
              leading: const Icon(Icons.devices, color: Colors.blue),
              title: Text("Device ${index + 1}"),
              subtitle: Text("IP: $deviceIp"),
              trailing: const Icon(Icons.wifi, color: Colors.green),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await controller.fetchConnectedDevices();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Device list refreshed")),
          );
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
