import 'package:flutter/material.dart';
import 'package:get/get.dart';


void showConfirmationDialog() {
  Get.defaultDialog(
    title: "Confirmation",
    content: Text("Are you sure you want to proceed?"),
    actions: [
      TextButton(
        onPressed: () {
          // Your code for when the user confirms
          Get.back(); // Close the dialog
        },
        child: Text("Yes"),
      ),
      TextButton(
        onPressed: () {
          // Your code for when the user cancels
          Get.back(); // Close the dialog
        },
        child: Text("No"),
      ),
    ],
  );
}
