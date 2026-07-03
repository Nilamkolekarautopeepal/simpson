// ignore_for_file: constant_identifier_names

import 'package:logger/logger.dart';
import 'package:simpson/app.dart';

class AppLogTag {
  static const String INFO = 'ℹ️️NFO️';
  static const String API = 'API🌐';
  static const String ERROR = '❌ERROR❌';
  static const String WARNING = '⚠️WARNING⚠️';
  static const String MODEL = 'MODEL';
  static const String OPEN_SCREEN = 'OPEN_SCREEN';
  static const String CLOSE_SCREEN = 'CLOSE_SCREEN';
}

Logger logger = Logger();

initLogger() {
  logger = Logger(
    filter: DevelopmentFilter(),
    printer: PrettyPrinter(
        methodCount: 0, //
        colors: true, // Colorful log messages
        printEmojis: true, // Print an emoji for each log message
        // ignore: deprecated_member_use
        printTime: true // Should each log print contain a timestamp
        ),
  );
}

openScreenAppLog(String viewName) {
   if (App.instance.appLog) {
 logger.i('${AppLogTag.OPEN_SCREEN} : $viewName');
   }
 
}

closeScreenAppLog(String viewName) {
if (App.instance.appLog) {
  logger.i('${AppLogTag.CLOSE_SCREEN} : $viewName');
}
}

appLogs(
  Object object, {
  String tag = AppLogTag.INFO,
}) {
  if (App.instance.appLog) {
    String message = "$object";
    logger.i('$tag : $message');
  }
}

apiLogs(
  Object object, {
  String tag = AppLogTag.API,
}) {
  if (App.instance.apiLog) {
    String message = "$object";

    logger.d('$tag : $message');
  }
}

errorLogs(
  Object object, {
  String tag = AppLogTag.ERROR,
}) {
  if (App.instance.devMode) {
    String message = "$object";
    logger.e('$tag : $message');
  }
}

warningLogs(
  Object object, {
  String tag = AppLogTag.WARNING,
}) {
  return;
  // ignore: dead_code
  String message = "$object";
  if (App.instance.devMode) {
    logger.w('$tag : $message');
  }
}

modelLogs(
  Object object, {
  String tag = AppLogTag.MODEL,
}) {
  return;
  // ignore: dead_code
  String message = "$object";
  if (App.instance.appLog) {
  logger.i('$tag : $message');
 }
}
