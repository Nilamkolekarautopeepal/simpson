// import 'package:simpson/api/app_api.dart';
// import 'package:simpson/utils/extension/extension/map_extensions.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class AppSettingsManager {
//   static final AppSettingsManager _instance = AppSettingsManager._internal();

//   factory AppSettingsManager() {
//     return _instance;
//   }

//   AppSettingsManager._internal();

//   Future<void> saveSetting(AppSetting setting) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString(setting.key, setting.value);
//   }

//   Future<AppSetting?> getSetting(String key) async {
//     final prefs = await SharedPreferences.getInstance();
//     final value = prefs.getString(key);
//     if (value != null) {
//       return AppSetting(key: key, value: value);
//     } else {
//       return null;
//     }
//   }

//   Future<void> saveAllSettings(List<AppSetting> settings) async {
//     final prefs = await SharedPreferences.getInstance();
//     for (var setting in settings) {
//       await prefs.setString(setting.key, setting.value);
//     }
//   }

//   Future<List<AppSetting>> getAllSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     final keys = prefs.getKeys();
//     List<AppSetting> settings = [];
//     for (var key in keys) {
//       final value = prefs.getString(key);
//       if (value != null) {
//         settings.add(AppSetting(key: key, value: value));
//       }
//     }
//     return settings;
//   }

//   callAppSettingData() async {
//     Map<String, dynamic> postData = Map();
//     Map<String, dynamic> responseData = await AppAPIs.post(
//         "api/AppSettings/GetAppSettingValues",
//         data: postData);

//     if (responseData.getBool("success")) {
//       List<dynamic> rawList1 = responseData.getMap("response").getList("Table");
//       List<AppSetting> appSettingList =
//           rawList1.map((e) => AppSetting.fromJson(e)).toList();
//       await AppSettingsManager().saveAllSettings(appSettingList);
//     }
//   }
// }

// class AppSetting {
//   final String key;
//   final String value;

//   AppSetting({required this.key, required this.value});

//   factory AppSetting.fromJson(Map<String, dynamic> json) {
//     return AppSetting(
//       key: json['AppSettingKey'],
//       value: json['AppSettingValue'],
//     );
//   }

//   Map<String, dynamic> toJson() {
//     return {
//       'AppSettingKey': key,
//       'AppSettingValue': value,
//     };
//   }
// }
