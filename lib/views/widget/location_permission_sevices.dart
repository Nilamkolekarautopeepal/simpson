import 'package:simpson/common_widgets/ui_helper_widgets.dart';
import 'package:simpson/themes/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class CustomLocationPermissionDialog extends StatelessWidget {
  final VoidCallback onGrant;
  final VoidCallback onDeny;

  CustomLocationPermissionDialog({required this.onGrant, required this.onDeny});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 2,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Padding(
        padding:
            const EdgeInsets.only(left: 24.0, right: 24.0, top: 10, bottom: 10),
        child: Column(
          children: [
            Image.asset("asset/logo/images/vector.png"),
            C10(),
            Text(
              "We couldn’t locate you",
              style: TextStyle(
                  fontFamily: "Inter-Bold",
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1D2939)),
            ),
            C5(),
            Text(
              "Please enable the location access for us to serve you better.",
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF667085),
                  fontFamily: "Inter-Regular"),
            ),
            C20(),
            InkWell(
              onTap: onGrant,
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12)),
                child: Center(
                  child: Text(
                    "Allow Location Access",
                    style: TextStyle(
                        fontFamily: "Inter-SemiBold",
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                ),
              ),
            ),
            C20(),
            Row(
              children: [
                Expanded(
                    child: Divider(color: Color(0xFFEAECF0), thickness: 2)),
                Text(
                  "  Or  ",
                  style: TextStyle(
                      color: Color(0xFF667085),
                      fontSize: 14,
                      fontFamily: "Inter-Regular",
                      fontWeight: FontWeight.w400),
                ),
                Expanded(
                    child: Divider(color: Color(0xFFEAECF0), thickness: 2)),
              ],
            ),
            C20(),
            InkWell(
              onTap: () {
                Get.back();
              },
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                    // ignore: deprecated_member_use
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Enter Pincode Manually",
                        style: TextStyle(
                            fontFamily: "Inter-SemiBold",
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.primary,
                      )
                    ],
                  ),
                ),
              ),
            ),
            C10(),
          ],
        ),
      ),
    );
  }
}

class LocationPermissionController extends GetxController {
  RxString locationMessage = "Press button to get location".obs;
  RxBool isLoading = false.obs;
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;
    try {
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best);
        return position;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied.';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied, we cannot request permissions.';
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      return position;
    } catch (e) {
      throw 'Failed to get current location: $e';
    }
  }

// Permissions
  Rx<PermissionStatus> permissionStatus =
      Rx<PermissionStatus>(PermissionStatus.denied);

  Future<Position> checkPermission() async {
    isLoading.value = true;
    permissionStatus.value = await Permission.location.status;
    if (permissionStatus.value.isDenied ||
        permissionStatus.value.isPermanentlyDenied) {
      isLoading.value = false;
      _showPermissionDialog();
      throw 'Failed to get current location: ';
    } else if (permissionStatus.value.isGranted) {
      Position position = await getCurrentLocation();
      isLoading.value = false;
      return position;
    }

    throw 'Failed to get current location: Permission not granted.';
  }

  void _showPermissionDialog() {
    Get.bottomSheet(
      CustomLocationPermissionDialog(
        onGrant: () async {
          Get.back();
          permissionStatus.value = await Permission.location.request();
          if (permissionStatus.value.isGranted) {
            // Permission granted
          } else {
            // Permission denied
          }
        },
        onDeny: () {
          Get.back();
          // Handle the logic when permission is denied
        },
      ),
    );
  }
}
