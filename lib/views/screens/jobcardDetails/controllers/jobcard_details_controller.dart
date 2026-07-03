import 'package:get/get.dart';

class JobCardDetailsController extends GetxController{
  final jobCardNo = "Vec/7474675675/58585748754";
  final model = "E 637632 BSVI";
  final registrationNumber = "E 637632 BSVI";
  final kmCovered = "15000";
  final chassisId = "HGFFEEG6436436474";
  final complaints = "No";
  late String vciName;
   @override
  void onInit() {
    super.onInit();

    final args = Get.arguments as Map<String, dynamic>?;
    vciName = args?['vciName'] ?? 'VCI';
  }
}