import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/dashboard15_controller.dart';

class Dashboard15View extends GetView<Dashboard15Controller> {
  const Dashboard15View({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard15View'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Dashboard15View is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
