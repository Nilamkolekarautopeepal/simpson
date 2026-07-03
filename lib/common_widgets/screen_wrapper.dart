
import 'dart:async';

import 'package:autopeepalApp/common_widgets/app_loader.dart';
import 'package:autopeepalApp/common_widgets/load_more_listview.dart';
import 'package:autopeepalApp/themes/app_textstyles.dart';
import 'package:autopeepalApp/utils/app_constants.dart';
import 'package:autopeepalApp/utils/app_logs.dart';
import 'package:autopeepalApp/utils/sizes.dart';
import 'package:autopeepalApp/utils/ui_helper_widgets.dart';
import 'package:connectivity_wrapper/connectivity_wrapper.dart';

import 'package:flutter/material.dart';

enum ScreenState {
  LOADED,
  LOADING,
  ERROR,
  INTERNET_ERROR,
}

mixin ScreenWrapperMixin<T extends StatefulWidget> on State<T> {
  ScreenState screenState = ScreenState.LOADED;
  StreamSubscription? _connectivitySubscription;

  bool _showOfflineWidget = false;

  String screenMessage = "";

  String get screenName => '$T';

  @override
  void initState() {
    super.initState();
    openScreenAppLog(screenName);
    init();
    _connectivitySubscription = ConnectivityWrapper.instance.onStatusChange
        .listen(_connectivityListener);
  }

  init() async {
    _showOfflineWidget = !(await ConnectivityWrapper.instance.isConnected);

    appLogs('$screenName init _showOfflineWidget:$_showOfflineWidget');

    setState(() {});
  }

  @override
  void dispose() {
    closeScreenAppLog(screenName);
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  _connectivityListener(dataConnectionStatus) async {
    appLogs('$screenName _connectivityListener $dataConnectionStatus');
    setState(() {
      _showOfflineWidget = dataConnectionStatus != ConnectivityStatus.CONNECTED;
    });
    if (!_showOfflineWidget && screenName == 'HomeScreen') {
      // AppRefreshService.instance.updateStream(AppRefreshKeys.order);
    }
  }

  refreshState() {
    if (mounted)
      setState(() {
        appLogs('$screenName refreshState');
      });
  }

  showLoader() {
    if (mounted)
      setState(() {
        screenState = ScreenState.LOADING;
      });
    appLogs('$screenName : showLoader');
  }

  hideLoader() {
    if (mounted)
      setState(() {
        screenState = ScreenState.LOADED;
      });
    appLogs('$screenName : hideLoader');
  }

  showError(String errorMessage) {
    if (mounted)
      setState(() {
        screenState = ScreenState.ERROR;
        screenMessage = errorMessage;
      });
    appLogs('$screenName : showError $errorMessage');
  }

  Future<Null> loadData() async {
    appLogs('$screenName loadData');
  }

  Future<Null> loadMoreData() async {
    appLogs('$screenName loadMoreData');
  }

  Map<String, dynamic> getLoadParams() {
    appLogs('$screenName getLoadParams');
    return Map<String, dynamic>();
  }

  // ignore: non_constant_identifier_names
  Widget LoaderWrapper({Widget? child}) {
    return Stack(
      children: <Widget>[
        child ?? Container(),
        if (screenState == ScreenState.LOADING) FullScreenLoaderWidget(),
        if (screenState == ScreenState.ERROR)
          ScreenErrorWidget(
            errorMessage: screenMessage,
          ),
        Positioned(
          top: 0,
          child: AnimatedContainer(
            decoration: BoxDecoration(
              color: Colors.black38,
            ),
            duration: Duration(
              milliseconds: Constants.delayMedium,
            ),
            height: _showOfflineWidget ? Sizes.s20 : Sizes.s0,
            width: screenWidth,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    "youAreOffline",
                    style: TextStyles.defaultRegular.copyWith(
                      color: Colors.white,
                      fontSize: FontSizes.s10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ignore: non_constant_identifier_names
  Widget ScreenErrorWidget({String? errorMessage}) {
    return Container(
      color: Colors.white,
      child: LoadMoreListView(
        loadData: () => loadData(),
        loadMoreData: () => loadMoreData(),
        children: <Widget>[
          C50(),
          Center(
            child: Text(
              '$errorMessage',
              style: TextStyles.defaultRegular.copyWith(
                fontSize: FontSizes.s25,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          C50(),
          // Image(
          //   image: AssetImage(Assets.EmptyCart),
          //   height: Sizes.s200 + Sizes.s50,
          // ),
        ],
      ),
    );
  }
}
