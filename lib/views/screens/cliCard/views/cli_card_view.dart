import 'package:autopeepalApp/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';

class CliCard extends StatelessWidget {
  CliCard({super.key});

  final List<Map<String, String>> vciList = [
    {'title': 'CAN2X', 'image': 'asset/logo/image 7 (4).png'},
    {'title': 'CAN2xK', 'image': 'asset/logo/image 7 (3).png'},
    {'title': 'DOIP', 'image': 'asset/logo/image 7 (2).png'},
    {'title': 'CAN2xFD', 'image': 'asset/logo/image 7 (1).png'},
    {'title': 'CAN2XG', 'image': 'asset/logo/image 7.png'},
    {'title': 'CAN2XGK', 'image': 'asset/logo/image 10.png'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFED7D31),
        title: const Text(
          'Select VCI',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: vciList.length,
        itemBuilder: (context, index) {
          final item = vciList[index];

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Get.toNamed(
                  Routes.JOBCARD,
                  arguments: {
                    'vciName': item['title'],
                  },
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.09),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item['title']!,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Image.asset(
                      item['image']!,
                      height: 36,
                      fit: BoxFit.contain,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
