// ignore_for_file: unnecessary_null_comparison

import 'dart:convert';
import 'dart:math';
import 'package:simpson/utils/app_logs.dart';
import 'package:crossplat_objectid/crossplat_objectid.dart'
    as crossplat_objectid;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';


String getId() {
  return crossplat_objectid.ObjectId().toHexString();
}

setFocus(BuildContext context, {FocusNode? focusNode}) {
  FocusScope.of(context).requestFocus(focusNode ?? FocusNode());
}

String getJsonFromMap(Map<String, dynamic> mapData) {
  String data = "";
  try {
    data = json.encode(mapData);
  } catch (e, s) {
    errorLogs("Error in getJsonFromMap\n\n *$mapData* \n\n $e\n\n$s");
  }
  return data;
}

// Map getMapFromJson(String mapData) {
//   Map<String, dynamic> data = Map();
//   try {
//     if (mapData == null || mapData == "") return data;
//     data = json.decode(mapData);
//   } catch (e, s) {
//     errorLogs("Error in getMapFromJson\n\n *$mapData* \n\n $e\n\n$s");
//   }
//   return data;
// }

Map getMapFromJson(String mapData) {
  Map<String, dynamic> data = Map();
  try {
    if (mapData == "") return data;
    data = json.decode(mapData);
  } catch (e, s) {
    errorLogs("Error in getMapFromJson\n\n *$mapData* \n\n $e\n\n$s");
  }
  return data;
}

int toInt(Object value) {
  if ('$value' != '') {
    try {
      int number = int.parse('$value');
      return number;
      // ignore: unused_catch_stack
    } on Exception catch (e, s) {
      // errorLogs("toInt Exception[$value] : $e\n$s");
    }
  }
  errorLogs("Invalid value in toInt[$value]");
  return 0;
}

// ignore: duplicate_ignore
double toDouble(Object value) {
  if (value != null) {
    try {
      double number = double.parse('$value');
      return number;
      // ignore: unused_catch_stack
    } on Exception catch (e, s) {
      // errorLogs("toDouble Exception : $e");
    }
  }
  return 0;
}

DateTime toDateTimeFromString(String value) {
  apiLogs("toDateTimeFromString value is $value");
  DateTime tempDateTime = DateTime.now();
  try {
    if (value == null) {
      return DateTime.now();
    } else {
      value = value.toString().replaceAll("/", "-");
    }
    tempDateTime = DateTime.parse(value);
  } catch (e, s) {
    errorLogs("Error in toDateTimeFromString ${e.toString()}\n$s");
    return tempDateTime;
  }
  errorLogs("Error in toDateTimeFromString $value");
  return tempDateTime;
}

String getPrettyMap(Map data) {
  try {
    // ignore: unnecessary_type_check
    if (data is Map) {
      JsonEncoder encoder = new JsonEncoder.withIndent('  ');
      String prettyPrint = encoder.convert(data);
      return prettyPrint;
    }
  } catch (e, s) {
    errorLogs('prettyPrintMap Error : $e: \n$s');
  }
  return '';
}

String toSimpleCurrency(value, {bool addSymbol = true}) {
  NumberFormat simpleCurrency = NumberFormat.simpleCurrency(
    name: addSymbol ? 'INR' : '',
    decimalDigits: 2,
  );
  String result = '$value';
  try {
    result = simpleCurrency.format(toDouble(value));
    if (result.endsWith('.00')) result = result.replaceFirst('.00', '');
  } catch (e, s) {
    errorLogs('toSimpleCurrency $e\n$s');
  }
  return result;
}

String toDiscountFormat(value) {
  NumberFormat simpleCurrency =
      NumberFormat.simpleCurrency(name: '', decimalDigits: 0);
  String result = '$value';
  try {
    result = simpleCurrency.format(toDouble(value));
    if (result.endsWith('.00')) result = result.replaceFirst('.00', '');
  } catch (e, s) {
    errorLogs('string2Uint8List $e,\n $s');
  }
  return result;
}

String generateTransactionReference() {
  return Random.secure().nextInt(1 << 32).toString();
}


