import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/dashboard13_controller.dart';

class Dashboard13View extends GetView<Dashboard13Controller> {
  const Dashboard13View({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard13View'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text(
          'Dashboard13View is working',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
