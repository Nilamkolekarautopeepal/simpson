class ApiUrls {
  ApiUrls._();

  static const String baseUrl = "https://sidia.simpsons.in/api/v1";
  // static const String baseUrl1 = "http://192.168.1.184:8080/api/v1";

  // Auth
  static const String login = "$baseUrl/accounts/new1/login/";
  static const String refreshToken = "$baseUrl/auth/refresh/";
  static const String logout = "$baseUrl/auth/logout/";

  // Data
  static const String models = "$baseUrl/models/get-models/";
  static const String flashRecords = "$baseUrl/flash/flash/";
  static const String listNumber = "$baseUrl/variant/prodbud-variant/list";
  static const String pidDataset = "$baseUrl/datasets/get-pid-datasets/";
  static const String dtcDataset = "$baseUrl/datasets/get-dtc-datasets/";
  static const String engineSerialNumber =
      "$baseUrl/analyze_prodbud/engslno/list/";
  static const String harnessNumber = "$baseUrl/analyze_prodbud/harness/list/";
}
