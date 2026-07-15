import 'package:get/get.dart';

import '../views/screens/ecu_flashing_page/bindings/ecu_flashing_page_binding.dart';
import '../views/screens/ecu_flashing_page/views/ecu_flashing_page_view.dart';
import '../views/screens/homePage/bindings/home_page_binding.dart';
import '../views/screens/homePage/views/home_page_view.dart';
import '../views/screens/login/bindings/login_binding.dart';
import '../views/screens/login/views/login_view.dart';
import '../views/screens/psf_homeScreen/bindings/psf_home_screen_binding.dart';
import '../views/screens/psf_homeScreen/views/psf_home_screen_view.dart';
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
    ),
    GetPage(
      name: _Paths.LOGIN,
      page: () => LoginScreen(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: _Paths.HOME_PAGE,
      page: () => const HomePageView(),
      binding: HomePageBinding(),
    ),
    GetPage(
      name: _Paths.PSF_HOME_SCREEN,
      page: () => const PsfHomeScreenView(),
      binding: PsfHomeScreenBinding(),
    ),
    GetPage(
      name: _Paths.ECU_FLASHING_PAGE,
      page: () => const EcuFlashingPage(),
      binding: EcuFlashingPageBinding(),
    ),
  ];
}
