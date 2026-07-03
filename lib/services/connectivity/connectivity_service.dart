import 'package:connectivity_wrapper/connectivity_wrapper.dart';

class ConnectivityService {
  static ConnectivityService instance = ConnectivityService();
  ConnectivityStatus lastConnectivityStatus = ConnectivityStatus.CONNECTED;

  init() async {
    lastConnectivityStatus =
        await ConnectivityWrapper.instance.connectionStatus;
    ConnectivityWrapper.instance.onStatusChange.listen((data) {
      lastConnectivityStatus = data;
    });
  }
}
