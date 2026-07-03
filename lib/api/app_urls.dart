class ApiUrls {
  ApiUrls._();

  static const String baseUrl = "http://4.224.248.152:3389/api/v1";

  // Auth
  static const String login = "$baseUrl/accounts/login/";
  static const String refreshToken = "$baseUrl/auth/refresh/";
  static const String logout = "$baseUrl/auth/logout/";
  static const String models = "${baseUrl}models/get-models/";
  static const String flashRecords = "${baseUrl}flash/flash/";
  static const String listNumber = "${baseUrl}variant/list/";
  static const String pidDataset = "${baseUrl}datasets/get-pid-datasets";
   static const String dtcDataset = "${baseUrl}datasets/get-dtc-datasets/";
}
