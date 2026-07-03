import 'package:http/http.dart' as http;

Future<void> registerDevice(String hotspotIp, String deviceName) async {
  final url = Uri.parse('http://$hotspotIp:8080/register?name=$deviceName');
  try {
    final response = await http.post(url);
    if (response.statusCode == 200) {
      print('✅ Registered to hotspot server');
    } else {
      print('⚠️ Failed to register: ${response.statusCode}');
    }
  } catch (e) {
    print('❌ Error registering device: $e');
  }
}
