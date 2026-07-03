// ignore_for_file: dead_code, duplicate_ignore

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'app_logs.dart';

const String emptyDateString = "1970-01-01";
final DateTime firstDate = DateTime(2000);

class DateFormats {
  static const String inTime = 'jm';
  static const String inMonth = 'MMM';
  static const String inYear = 'yyyy';
  static const String inMonthYear = 'MMM yyyy';
  static const String inDayMonthYear = 'dd MMM, yyyy';
  static const String inDayMonthYearTime = 'dd MMM yyyy HH:mm';
  static const String inDayOfWeek = 'EEEE';
  static const String inDayMonth = 'MMMM dd';
  static const String inDay = 'dd';
  static const String inHourMin = 'HH:mm';
  static const String inTimeDate = 'HH:mm:ss dd MMM yyyy';
  static const String inSendFormat = 'yyyy-dd-MM';
  static const String inSendFormat11 = 'yyyy-MM-dd';
  static const String inSendFormat1 = 'yyyy-MM-dd HH:mm:ss';
  static const String inSendFormatYY = 'MM-dd-yyyy';
}

// ignore: duplicate_ignore, duplicate_ignore
class AppDateTime {
  static DateTime pickFirstDate() {
    return today().add(const Duration(days: 1));
  }

  static DateTime pickLastDate() {
    return today().add(const Duration(days: 1000));
  }

  // ignore: dead_code, dead_code
  static DateTime toDateTime(String value) {
    // ignore: null_check_always_fails
    DateTime tempDateTime = null!;
    try {
      tempDateTime = DateTime.parse(value);
    } catch (e, s) {
      appLogs(" toDateTime-->   $value : $e\n$s");
    }
    return tempDateTime;
  }

  static String getDateTime() {
    return toSendFormat(dateTime: DateTime.now());
  }

  static String getDD() {
    return toSendFormat(dateTime: today().add(const Duration(days: 1)));
  }

  static DateTime today() {
    return toDateTime(toSendFormat(dateTime: DateTime.now()));
  }

  static DateTime today1() {
    return toDateTime(toSendFormat1(dateTime: DateTime.now()));
  }

  static String setDD(String dd) {
    DateTime dateTime = toDateTime(dd);
    DateTime minDate = today().add(const Duration(days: 1));
    if (dateTime.isBefore(minDate)) {
      dateTime = minDate;
    }
    return toSendFormat(dateTime: dateTime);
  }

  static String getOD() {
    return toSendFormat(dateTime: DateTime.now());
  }

  static String formatDateFromString({
    required String format,
    required String dateTime,
  }) {
    try {
      DateTime tempDateTime = toDateTime(dateTime);
      DateFormat dateFormatter = DateFormat(format);
      return dateFormatter.format(tempDateTime);
    } catch (e, s) {
      appLogs(
          " formatDateFromString--> format:$format  dateTime:$dateTime : $e\n$s");
    }
    return emptyDateString;
  }

  static String formatDateFromDateTime({
    required String format,
    required DateTime dateTime,
  }) {
    try {
      DateFormat dateFormatter = DateFormat(format);
      return dateFormatter.format(dateTime);
    } catch (e, s) {
      appLogs(
          " formatDateFromDateTime --> format$format  dateTime:$dateTime : $e\n$s");
    }
    return emptyDateString;
  }

  static String toSendFormat({
    @required dynamic dateTime,
  }) {
    try {
      if (dateTime != null) {
        DateTime tempDateTime;
        if (dateTime is String) {
          tempDateTime = toDateTime(dateTime);
        } else if (dateTime is DateTime) {
          tempDateTime = dateTime;
        } else {
          return emptyDateString;
        }

        return formatDateFromDateTime(
          format: DateFormats.inSendFormat11,
          dateTime: tempDateTime,
        );
      }
    } catch (e, s) {
      errorLogs(" toSendFormat--> dateTime:$dateTime : $e\n$s");
    }
    return emptyDateString;
  }

/////
  static String toSendFormat1({
    @required dynamic dateTime,
  }) {
    try {
      if (dateTime != null) {
        DateTime tempDateTime;
        if (dateTime is String) {
          tempDateTime = toDateTime(dateTime);
        } else if (dateTime is DateTime) {
          tempDateTime = dateTime;
        } else {
          return emptyDateString;
        }

        return formatDateFromDateTime(
          format: DateFormats.inSendFormat1,
          dateTime: tempDateTime,
        );
      }
    } catch (e, s) {
      errorLogs(" toSendFormat--> dateTime:$dateTime : $e\n$s");
    }
    return emptyDateString;
  }

  ///
  static String formatDate({
    required String format,
    required dynamic dateTime,
  }) {
    try {
      if (dateTime != null) {
        DateTime tempDateTime;
        if (dateTime is String) {
          tempDateTime = toDateTime(dateTime);
        } else if (dateTime is DateTime)
          // ignore: curly_braces_in_flow_control_structures
          tempDateTime = dateTime;
        else
          // ignore: curly_braces_in_flow_control_structures
          return emptyDateString;
        DateFormat dateFormatter = DateFormat(format);
        return dateFormatter.format(tempDateTime);
      }
    } catch (e, s) {
      errorLogs(" formatDate--> format:$format  dateTime:$dateTime : $e\n$s");
    }
    return emptyDateString;
  }
}
