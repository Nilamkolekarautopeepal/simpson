import 'package:get/get.dart';

import '../views/screens/WifiScreen/bindings/wifi_screen_binding.dart';
import '../views/screens/WifiScreen/views/wifi_screen_view.dart';
import '../views/screens/bluetooth/bindings/bluetooth_binding.dart';
import '../views/screens/bluetooth/views/bluetooth_view.dart';
import '../views/screens/cliCard/bindings/cli_card_binding.dart';
import '../views/screens/cliCard/views/cli_card_view.dart';
import '../views/screens/dashboard13/bindings/dashboard13_binding.dart';
import '../views/screens/dashboard13/views/dashboard13_view.dart';
import '../views/screens/dashboard15/bindings/dashboard15_binding.dart';
import '../views/screens/dashboard15/views/dashboard15_view.dart';
import '../views/screens/jobcard/bindings/jobcard_binding.dart';
import '../views/screens/jobcard/views/jobcard_view.dart';
import '../views/screens/jobcardDetails/bindings/jobcard_details_binding.dart';
import '../views/screens/jobcardDetails/views/jobcard_details_view.dart';
import '../views/screens/login/bindings/login_binding.dart';
import '../views/screens/login/views/login_view.dart';
import '../views/screens/splash_screen.dart/bindings/splash_screen_dart_binding.dart';
import '../views/screens/splash_screen.dart/views/splash_screen_dart_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH_SCREEN_DART;

  static final routes = [
    GetPage(
      name: _Paths.SPLASH_SCREEN_DART,
      page: () => SplashScreenDartView(),
      binding: SplashScreenDartBinding(),
      transitionDuration: Duration(seconds: 5),
      transition: Transition.zoom,
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginScreen(),
      binding: LoginBinding(),
      transitionDuration: Duration(seconds: 1),
      transition: Transition.zoom,
    ),
    GetPage(
      name: _Paths.BLUETOOTH,
      page: () => BluetoothDevicesPage(),
      binding: BluetoothBinding(),
    ),
    GetPage(
      name: _Paths.JOBCARD,
      page: () => JobCardPage(),
      binding: JobcardBinding(),
    ),
    GetPage(
      name: _Paths.JOBCARD_DETAILS,
      page: () => JobCardDetailsPage(),
      binding: JobcardDetailsBinding(),
    ),
    GetPage(
      name: _Paths.CLI_CARD,
      page: () => CliCard(),
      binding: CliCardBinding(),
    ),
    GetPage(
      name: _Paths.WIFI_SCREEN,
      page: () => WifiIpPage(),
      binding: WifiScreenBinding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD13,
      page: () => const Dashboard13View(),
      binding: Dashboard13Binding(),
    ),
    GetPage(
      name: _Paths.DASHBOARD15,
      page: () => const Dashboard15View(),
      binding: Dashboard15Binding(),
    ),
  ];
}
