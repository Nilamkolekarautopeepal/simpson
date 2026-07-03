import 'package:simpson/app.dart';
import 'package:simpson/utils/app_logs.dart';
import 'package:simpson/utils/strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get_core/get_core.dart';
import 'package:get/get_navigation/get_navigation.dart';

int get _maxTapCount => App.instance.isProd ? 5 : 5;

const int _maxAPICount = 5;

class DevService {
  static DevService instance = DevService();

  int _count = 0;
  List<AppAPIsCall> apiCalls = [];
  String appSignature = Strings.empty;

  incrementCount() {
    _count++;
  }

  resetCount() {
    _count = 0;
  }

  void openDevScreen(BuildContext context) {
    incrementCount();
    appLogs('openDevScreen _count:$_count');
    if (_count >= _maxTapCount) {
      resetCount();
      Get.toNamed('/devScreen');
    }
  }

  insertAPICall(AppAPIsCall data) {
    apiCalls.insert(0, data);
    if (apiCalls.length >= _maxAPICount) {
      apiCalls.removeLast();
    }
  }
}

class AppAPIsCall {
  String id;
  String type;
  String path;
  DateTime dateTime;
  Map<String, dynamic> data;
  Map<String, dynamic> response;

  AppAPIsCall({
    required this.id,
    required this.type,
    required this.path,
    required this.dateTime,
    required this.data,
    required this.response,
  });
}
