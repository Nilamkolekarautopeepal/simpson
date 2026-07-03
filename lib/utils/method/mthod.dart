import 'package:autopeepalApp/utils/ui_helper.dart/app_tost.dart';
import 'package:flutter/services.dart';

class Methods {
  static copyToClipBoard({
    required String value,
  }) async {
    await Clipboard.setData(
      ClipboardData(text: value),
    );

    AppTostMassage.showTostMassage(massage: 'Value copied to Clipboard');
  }
}
