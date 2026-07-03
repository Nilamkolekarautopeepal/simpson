import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:simpson/utils/app_logs.dart';

///[ErrorHandlerService] which  logs any exception occurred at run time
///
class ErrorHandlerService {
  static ErrorHandlerService instance = ErrorHandlerService();

  Future<void> appRecordError(dynamic e, StackTrace s,
      {dynamic context}) async {
    String errorTitle = "";
    errorLogs('ErrorHandlerService $errorTitle \nexception: $e \n stack: $s');

    if (e is PlatformException) {
      // if (App.instance.devMode) AppToast.showMessage(e.message);
    }
  }

  Future<Null> showErrorAlert(
    BuildContext context, {
    String message = "",
    bool isAlert = true,
  }) async {
    if (message.isEmpty) {
      message = "sdsd"; //Strings.defaultErrorMessage;
    }
    if (isAlert) {
      // await AppAlerts.show(
      //   context,
      //   message: message,
      //   title: AlertTitle.alert,
      // );
    } else {
      // AppFlushBar.show(
      //   context,
      //   message: message,
      //   title: AlertTitle.alert,
      // );
    }
  }
}
