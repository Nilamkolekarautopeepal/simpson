import 'package:simpson/common_widgets/app_loader.dart';
import 'package:simpson/themes/app_textstyles.dart';
import 'package:simpson/utils/app_logs.dart';
import 'package:simpson/utils/sizes.dart';
import 'package:simpson/utils/ui_helper_widgets.dart';
import 'package:flutter/material.dart';


enum WidgetState {
  LOADED,
  LOADING,
  ERROR,
}

extension getters on WidgetState {
  bool get enabled => this == WidgetState.LOADED || this == WidgetState.ERROR;
}

mixin WidgetWrapperMixin<T extends StatefulWidget> on State<T> {
  WidgetState screenState = WidgetState.LOADED;

  String widgetMessage = "";

  String get widgetName => '$T';

  showLoader() {
    if (mounted)
      setState(() {
        screenState = WidgetState.LOADING;
      });
    appLogs('$widgetName : showLoader');
  }

  hideLoader() {
    if (mounted)
      setState(() {
        screenState = WidgetState.LOADED;
      });
    appLogs('$widgetName : hideLoader');
  }

  showError(String errorMessage) {
    if (mounted)
      setState(() {
        screenState = WidgetState.ERROR;
        widgetMessage = errorMessage;
      });
    appLogs('$widgetName : showError $errorMessage');
  }

  Future<Null> loadData() async {
    appLogs('$widgetName loadData');
  }

  // ignore: non_constant_identifier_names
  Widget WidgetWrapper({required Widget child}) {
    switch (screenState) {
      case WidgetState.LOADED:
        return child;

      case WidgetState.LOADING:
        return LoadingWidget();

      case WidgetState.ERROR:

    }

    return C0();
  }

  // ignore: non_constant_identifier_names
  Widget WidgetErrorWidget({required String errorMessage}) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          '$errorMessage',
          style: TextStyles.defaultRegular.copyWith(
            fontSize: FontSizes.s25,
          ),
        ),
      ),
    );
  }
}
