// ignore_for_file: unnecessary_null_comparison, unnecessary_this, prefer_collection_literals, null_check_always_fails

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:autopeepalApp/themes/app_colors.dart';
import 'package:autopeepalApp/utils/app_logs.dart';

extension StringExtensions on String {
  ///JSON String to Map using[json.decode]
  ///
  Map toMap() {
    Map data = Map();
    try {
      if (this == null || this == "") return data;
      data = json.decode(this);
    } catch (e, s) {
      appLogs("Error in toMap\n\n *$this* \n\n $e\n\n$s");
    }
    return data;
  }

  ///JSON String to List using[json.decode]
  ///
  List toList() {
    List data = [];
    try {
      data = json.decode(this);
    } catch (e, s) {
      appLogs("ERROR in toList $e \n $s");
    }
    return data;
  }

  /// Return a bool if the string is null or empty
  ///
  bool get isEmptyOrNull => isEmpty;

  /// Return a null if the string is null or empty
  ///
  String get asNullIfEmpty => isEmptyOrNull ? null! : this;

  /// Return a empty if the string is null or empty
  ///
  String get asEmptyIfEmptyOrNull => isEmptyOrNull ? '' : this;

  /// Returns true if s is neither null, empty nor is solely made of whitespace characters.
  ///
  bool get isNotBlank => this != null && trim().isNotEmpty;

  String get addSpaceAndCommaIfNotEmpty => isNotBlank ? '$this, ' : '';

  /// Parses the string as an int or 0 [defaultInt].
  ///
  // int get toINT => toInt(this);

  /// Parses the string as an int or 0 [defaultDouble].
  ///
  // double get toDOUBLE => toDouble(this);

  /// Convert this string into boolean.
  ///
  /// Returns `true` if this string is any of these
  /// values: `"true"`, `"yes"`, `"1"`,
  /// or if the string is a number and greater than 0, `false`
  /// if less than 1. This is also case insensitive.
  ///
  bool get asBool {
    var s = this.trim().toLowerCase();
    num n;
    try {
      n = num.parse(s);
    } catch (e) {
      n = -1;
    }
    return s == 'true' || s == 'yes' || n > 0;
  }

  /// Parse string to [DateTime] or [Null]
  ///
  DateTime toDateTime({dynamic context}) {
    String value = this;
    DateTime tempDateTime = DateTime(2023);

    if (value.isEmptyOrNull) {
      appLogs('toDateTime invalid $value context:$context');
      return tempDateTime;
    }
    if (value.startsWith('-00')) {
      appLogs('toDateTime invalid $value context:$context');
      value = value.replaceFirst('-00', '');
    }
    try {
      tempDateTime = DateTime.parse(value);
    } catch (e, s) {
      appLogs("toDateTime $context  $value : $e\n$s");
    }
    return tempDateTime;
  }

  toColor() {
    Color color = AppColors.random;
    try {
      var hexColor = replaceAll("#", "");
      if (hexColor.length == 6) {
        hexColor = "0xFF$hexColor";
      }
      if (hexColor.length == 10) {
        color = Color(int.parse(hexColor));
      }
    } catch (e) {
      errorLogs(
        'toColor $e',
      );
    }
    return color;
  }
}
