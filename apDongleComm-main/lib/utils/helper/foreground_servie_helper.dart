
// import 'package:flutter_foreground_task/flutter_foreground_task.dart';
// import 'package:flutter_foreground_task/task_handler.dart';

// class MyTaskHandler extends TaskHandler {
//   // Called when the task is started.
//   @override
//   Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
//     print('onStart(starter: ${starter.name})');
//   }

//   // Called based on the eventAction set in ForegroundTaskOptions.
//   @override
//   void onRepeatEvent(DateTime timestamp) {
//     // // Send data to main isolate.
//     // final Map<String, dynamic> data = {
//     //   "timestampMillis": timestamp.millisecondsSinceEpoch,
//     // };
//     // FlutterForegroundTask.sendDataToMain(data);
//   }

//   // Called when the task is destroyed.
//   @override
//   Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
//     print('onDestroy(isTimeout: $isTimeout)');
//   }

//   // Called when data is sent using `FlutterForegroundTask.sendDataToTask`.
//   @override
//   void onReceiveData(Object data) {
//     print('onReceiveData: $data');
//   }

//   // Called when the notification button is pressed.
//   @override
//   void onNotificationButtonPressed(String id) {
//     print('onNotificationButtonPressed: $id');
//   }

//   // Called when the notification itself is pressed.
//   @override
//   void onNotificationPressed() {
//     print('onNotificationPressed');
//   }

//   // Called when the notification itself is dismissed.
//   @override
//   void onNotificationDismissed() {
//     print('onNotificationDismissed');
//   }
// }

// Future<void> startForegroundService() async {
//   FlutterForegroundTask.init(
//     androidNotificationOptions: AndroidNotificationOptions(
//       channelId: 'socket_channel_id',
//       channelName: 'Socket Channel',
//       channelDescription: 'To keep socket alive',
//       priority: NotificationPriority.HIGH,
//     ),
//     iosNotificationOptions: const IOSNotificationOptions(),
//     foregroundTaskOptions: ForegroundTaskOptions(
//       eventAction: ForegroundTaskEventAction.once(),
//     ),
//   );

//   await FlutterForegroundTask.startService(
//     notificationTitle: 'Socket Running',
//     notificationText: 'Keeping socket alive in background',

//     callback: startCallback,
//   );
// }

// void startCallback() {
//   FlutterForegroundTask.setTaskHandler(MyTaskHandler());
// }

import 'dart:io';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_foreground_task/task_handler.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    print('onStart(starter: ${starter.name})');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    print('onDestroy(isTimeout: $isTimeout)');
  }

  @override
  void onReceiveData(Object data) {
    print('onReceiveData: $data');
  }

  @override
  void onNotificationButtonPressed(String id) {}

  @override
  void onNotificationPressed() {}

  @override
  void onNotificationDismissed() {}
}

/// Keeps the dongle socket alive across device sleep.
/// - Android/iOS: real foreground service (flutter_foreground_task)
/// - Windows/macOS/Linux: no foreground-service concept, so use a
///   wakelock (SetThreadExecutionState under the hood) instead.
Future<void> startForegroundService() async {
  if (Platform.isAndroid || Platform.isIOS) {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'socket_channel_id',
        channelName: 'Socket Channel',
        channelDescription: 'To keep socket alive',
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.once(),
      ),
    );

    await FlutterForegroundTask.startService(
      notificationTitle: 'Socket Running',
      notificationText: 'Keeping socket alive in background',
      callback: startCallback,
    );
  } else {
    // Windows / macOS / Linux — prevent system sleep instead.
    try {
      await WakelockPlus.enable();
      print('🔋 WakelockPlus enabled (desktop) — system will not sleep');
    } catch (e) {
      print('⚠️ Could not enable wakelock: $e');
    }
  }
}

Future<void> stopForegroundService() async {
  if (Platform.isAndroid || Platform.isIOS) {
    await FlutterForegroundTask.stopService();
  } else {
    try {
      await WakelockPlus.disable();
      print('🔋 WakelockPlus disabled — system can sleep again');
    } catch (e) {
      print('⚠️ Could not disable wakelock: $e');
    }
  }
}

void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}