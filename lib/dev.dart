import 'package:simpson/api/app_envirments.dart';
import 'package:simpson/app.dart';

void main() async {
  App.instance.initAndRunApp(
    devMode: false,
    appLog: false,
    apiLog: false,
    setDefault: true,
    samplePayment: true,
    baseURLType: AtomURLType.DEV,
  );
}