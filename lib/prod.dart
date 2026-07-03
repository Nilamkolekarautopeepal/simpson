import 'package:autopeepalApp/api/app_envirments.dart';
import 'package:autopeepalApp/app.dart';

void main() async {
  App.instance.initAndRunApp(
    devMode: false,
    appLog: false,
    apiLog: true,
    setDefault: true,
    samplePayment: true,
    baseURLType: AtomURLType.PROD,
  );
}
