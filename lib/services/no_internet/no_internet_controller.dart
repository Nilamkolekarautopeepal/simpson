import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class ConnectionManagerController extends GetxController {
  var connectionType = 0.obs;

  final Connectivity _connectivity = Connectivity();
  late StreamSubscription _streamSubscription;

  @override
  void onInit() {
    super.onInit();

    getConnectivityType();
    // _streamSubscription =
    //     _connectivity.onConnectivityChanged.listen(_updateState);
  }

  Future<void> getConnectivityType() async {
    late ConnectivityResult connectivityResult;
    try {
      connectivityResult = (await (_connectivity.checkConnectivity())) as ConnectivityResult;
    } on PlatformException {}
    return _updateState(connectivityResult);
  }

  _updateState(ConnectivityResult result) {
    switch (result) {
      case ConnectivityResult.wifi:
        connectionType.value = 1;

        break;
      case ConnectivityResult.mobile:
        connectionType.value = 2;

        break;
      case ConnectivityResult.none:
        connectionType.value = 0;
        // Get.dialog(
        //   Container(
        //       height: MediaQuery.of(Get.context!).size.height,
        //       child: NoInternetView(
        //         onTap: () async {
        //           if (connectionType.value != 0) {
        //             await Get.offAllNamed(Routes.homeScreen, arguments: 0);
        //           }
        //         },
        //       )),
        // );

        break;
      default:
        // AppToast.showMessage(message: "Failed to get connection type");
        break;
    }
  }

  @override
  void onClose() {
    _streamSubscription.cancel();
    super.onClose();
  }
}
