import 'package:simpson/views/screens/bluetooth/controllers/bluetooth_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BluetoothDevicesPage extends StatelessWidget {
  BluetoothDevicesPage({super.key});
  final BlutoothdDevicesController controller =
      Get.put(BlutoothdDevicesController());
  final Color primaryColor = const Color(0xFFF47A1F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        title: const Text(
          "Bluetooth Devices",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                controller.vciName,
                style:
                    TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          )
        ],
      ),

      /// BODY
      body: Obx(() {
        if (controller.isScanning.value && controller.devices.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }

        if (controller.devices.isEmpty) {
          return const Center(child: Text("No nearby Bluetooth devices"));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.devices.length,
          itemBuilder: (context, index) {
            final result = controller.devices[index];
            final device = result.device;

            final name = controller.getDeviceName(result, index);

            return _bluetoothDeviceCard(
              name: name,
              macId: device.address,
              onTap: () {
                controller.connectToDevice(device);
              },
            );
          },
        );
      }),
    );
  }

  /// DEVICE CARD (matches screenshot)
  Widget _bluetoothDeviceCard({
    required String name,
    required String macId,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8), // smaller spacing
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        dense: true, // 👈 KEY: reduces vertical height
        visualDensity: const VisualDensity(vertical: -2), // 👈 even tighter
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        title: Text(
          name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          macId,
          style: const TextStyle(fontSize: 12),
        ),
        trailing: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(6), // smaller icon padding
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: primaryColor, width: 2),
            ),
            child: Icon(
              Icons.bluetooth,
              color: primaryColor,
              size: 18, // smaller icon
            ),
          ),
        ),
      ),
    );
  }
}
