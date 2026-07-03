// ignore_for_file: unnecessary_null_comparison, duplicate_ignore

import 'dart:convert';
import 'package:autopeepalApp/api/dev/methods.dart';
import 'package:autopeepalApp/utils/app_logs.dart';
import 'package:flutter/material.dart';

const bool defaultBool = false;
const int defaultInt = 0;
const double defaultDouble = 0;
const String defaultString = '';
const Map<String, dynamic> defaultMap = {};

/// extension methods for Map
///
extension MapExtension on Map {
  /// Reads a [key] value of [bool] type from [Map].
  ///
  /// If value is NULL or not [bool] type return default value [defaultBool]
  ///
  // ignore: duplicate_ignore
  bool getBool(String key) {
    Map data = this;
    // ignore: unnecessary_null_comparison
    if (data == null) {
      data = {};
    }
    if (data.containsKey(key)) if (data[key] is bool)
      return this[key] ?? defaultBool;
    warningLogs("Map.getBool[$key] has incorrect data : ${data[key]}");
    return defaultBool;
  }

  /// Reads a [key] value of [int] type from [Map].
  ///
  /// If value is NULL or not [int] type return default value [defaultInt]
  ///
  int getInt(String key) {
    Map data = this;
    if (data == null) {
      data = {};
    }
    if (data.containsKey(key)) return toInt(data[key]);
    warningLogs("Map.getInt[$key] has incorrect data :${data[key]}");
    return defaultInt;
  }

  /// Reads a [key] value of [double] type from [Map].
  ///
  /// If value is NULL or not [double] type return default value [defaultDouble]
  ///
  double getDouble(String key) {
    Map data = this;
    if (data == null) {
      data = {};
    }
    if (data.containsKey(key)) return toDouble(data[key]);
    warningLogs("Map.getDouble[$key] has incorrect data : ${data[key]}");
    return defaultDouble;
  }

  /// Reads a [key] value of [String] type from [Map].
  ///
  /// If value is NULL or not [String] type return default value [defaultString]
  ///.

  String getString(String key, {String defaultValue = defaultString}) {
    Map data = this;
    if (data == null) {
      data = defaultMap;
    }
    if (data.containsKey(key)) {
      var value = data[key];
      if (value == null) return defaultValue;
      return '$value';
    }
    warningLogs("Map.getString[$key] has incorrect data : ${data[key]}");
    return defaultValue;
  }

  /// Reads a [key] value of [Map] type from [Map].
  ///
  /// If value is NULL or not [String] type return default value [defaultString]
  ///.
  Map<String, dynamic> getMap(String key) {
    Map data = this;
    if (data == null) {
      data = {};
    }
    if (data.containsKey(key)) if (data[key] is Map<String, dynamic>)
      return data[key] ?? defaultMap;
    warningLogs("Map.getMap[$key] has incorrect data : ${data[key]}");
    return defaultMap;
  }

  /// Reads a [key] value of [List] type from [Map].
  ///
  /// If value is NULL or not [List] type return default value [defaultString]
  ///
  List getList(String key) {
    Map data = this;
    if (data == null) {
      data = {};
    }
    if (data.containsKey(key)) if (data[key] is List) return data[key] ?? [];
    warningLogs("Map.getString[$key] has incorrect data : ${data[key]}");
    return [];
  }

  ///Add value to map if value is not null
  ///
  T add<T>({@required dynamic key, required T value}) {
    if (value is String) {
      if (value != null) this.putIfAbsent(key, () => value);
    } else if (value is int) {
      if (value != null && value != -1) this.putIfAbsent(key, () => value);
    } else {
      this.putIfAbsent(key, () => value);
    }
    return value;
  }

  ///Convert map to a String withIndent
  ///
  String toPretty() {
    String data = defaultString;
    try {
      JsonEncoder encoder = new JsonEncoder.withIndent('  ', toEncodable);
      data = encoder.convert(this);
    } catch (e, s) {
      errorLogs("Error in toPretty\n\n *$this* \n\n $e\n\n$s");
    }
    return data;
  }
}

toEncodable(object) {
  if (object is String ||
      object is num ||
      object is Map ||
      object is List ||
      object is bool) return object;
  return '$object';
}
