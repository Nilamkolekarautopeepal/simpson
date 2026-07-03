import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class AppPreferences {
  
  static const _tokenKey = 'token';
  static const _userDataKey = 'user_data';
  

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }



  /// Store user data map as JSON string
  static Future<void> setUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(userData);
    await prefs.setString(_userDataKey, jsonString);
  }

  /// Retrieve user data map
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_userDataKey);
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  /// Clear all stored preferences
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  // 🔹 GET: Load Permission Data
  static Future<Map<String, dynamic>?> getPermissionData() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('permission_data');
    if (jsonString != null) {
      return jsonDecode(jsonString);
    }
    return null;
  }

  // 🔹 SAVE: Save Permission Data
  static Future<void> savePermissionData(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = jsonEncode(data);
    await prefs.setString('permission_data', jsonString);
  }

  // 🔹 CLEAR: Remove Permission Data
  static Future<void> clearPermissionData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('permission_data');
  }
}