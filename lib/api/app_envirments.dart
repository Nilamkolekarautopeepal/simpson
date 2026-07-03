import 'package:autopeepalApp/app.dart';

class AtomURLType {
  static const String LOCAL = "LOCAL";
  static const String DEV = 'DEV';
  static const String PROD = 'PROD';
}

class AppEnvironment {
  static const String _localUrl = "https://hr-ess-uat.frappe.cloud/api";
  static const String _devUrl = 'https://hr-ess-uat.frappe.cloud/api';
  static const String _prodUrl = 'https://hr-ess-uat.frappe.cloud/api';

  static bool get baseProdInstance {
    if (baseUrl == _prodUrl) {
      return true;
    } else {
      return false;
    }
  }

  static String get baseUrl {
    switch (App.instance.baseURLType) {
      case AtomURLType.DEV:
        return _devUrl;
      case AtomURLType.PROD:
        return _prodUrl;
      case AtomURLType.LOCAL:
        return _localUrl;
    }

    return "http://43.204.117.226:3000/api/v1";
  }

  
}
