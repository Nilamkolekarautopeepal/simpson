// import 'dart:async';
// import 'package:autopeepalApp/routes/routes_string.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get_navigation/src/root/get_material_app.dart';
// import 'package:get_storage/get_storage.dart';
// import 'package:autopeepalApp/api/app_envirments.dart';
// import 'package:autopeepalApp/routes/routes.dart';
// import 'package:autopeepalApp/services/error_handler/error_handler_service.dart';
// import 'package:autopeepalApp/themes/app_theme.dart';
// import 'package:autopeepalApp/utils/app_logs.dart';
// import 'package:autopeepalApp/views/widget/app_error_widget.dart';

// class App {
//   static App instance = App();

//   /// [_appName] app display Named
//   ///
//   final String _appName = 'Autopeepal App';

//   String? _version;

//   String? _buildNumber;

//   bool? _devMode;

//   ///***** DO NOT USE `print` TO LOG ******
//   ///
//   /// [_appLog] to print log
//   bool? _appLog;

//   /// [_apiLog] to print api log
//   bool? _apiLog;

//   /// [_baseURLType] to get base url type
//   String? _baseURLType;

//   /// [_setDefault] to set Default vales
//   bool? _setDefault;

//   /// [_samplePayment] to set Default true
//   bool? _samplePayment;

//   static const String countryCode = "INDIA";

//   ///[appName] getter for [_appLog] default  value  is  ''
//   String get appName => _appName;

//   ///[devMode] getter for [_devMode] default  value  is  false
//   bool get devMode => _devMode ?? false;

//   ///[appLog] getter for [_appLog] default  value  is  false
//   bool get appLog => _appLog ?? false;

//   ///[apiLog] getter for [_apiLog] default  value  is  false
//   bool get apiLog => _apiLog ?? false;

//   ///[apiLog] getter for [_setDefault] default  value  is  false
//   bool get setDefault => _setDefault ?? false;

//   ///[version] getter for [_version] default  value  is  ''

//   ///[buildNumber] getter for [_baseURLType] default  value  is  [AtomURLType.PROD]
//   String get baseURLType => _baseURLType ?? AtomURLType.DEV;

//   ///[samplePayment] getter for [_samplePayment] default  value  is  [true]
//   bool get samplePayment => _samplePayment ?? true;

//   bool get isProd => _baseURLType == AtomURLType.DEV;

//   ///initialize App variables and run app
//   void initAndRunApp({
//     required bool appLog,
//     required bool apiLog,
//     required bool devMode,
//     required bool setDefault,
//     required bool samplePayment,
//     required String baseURLType,
//   }) {
//     runZonedGuarded(
//       () async {
//         WidgetsFlutterBinding.ensureInitialized();
//         /* -------- Get Storage Initialize -----------   */
//         await GetStorage.init();
//         /* --------Setting configuration parameters-----------   */
//         _devMode = devMode;
//         _appLog = appLog;
//         _apiLog = apiLog;
//         _setDefault = setDefault;
//         _baseURLType = baseURLType;
//         _samplePayment = samplePayment;

//         /* --------Setting View Orientation Portrait-----------   */
//         SystemChrome.setPreferredOrientations([
//           DeviceOrientation.portraitUp,
//           DeviceOrientation.portraitDown,
//         ]);
//         /* --------Setting View Orientation Portrait-----------   */

//         /* --------ErrorWidget-----------   */
//         ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
//           return AppErrorWidget(errorDetails: errorDetails);
//         };

//         initLogger();
//         appLogs('''
//         Appgurations
//         Orientation : Portrait
//         version : $_version
//         buildNumber : $_buildNumber
//         devMode : $_devMode
//         appLog : $_appLog
//         apiLog : $_apiLog
//         baseURLType : $baseURLType
//                ''');

//         runApp(const MyApp());
//       },
//       ErrorHandlerService.instance.appRecordError,
//     );
//   }
// }

// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
// //  Stripe.publishableKey = "pk_live_51KtX0NJERonFdt9jEpp3RWq3SJKreTEtBMxXYJxsQTG4sAkt58TCrQ8sSjZdnoYAj3RIW8TeHLKRKRfx86b56g7G00GI9mLZVz";
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     var config = App.instance;

//     return GetMaterialApp(
//       debugShowCheckedModeBanner: false,
//       title: config.appName,
//       initialRoute: Routes.splashScreen,
//       theme: appTheme,
//       getPages: AppRoutes.routes,
//     );
//   }
// }
import 'dart:async';
import 'dart:io';
import 'package:autopeepalApp/api/app_envirments.dart';
import 'package:autopeepalApp/common_widgets/app_error_widget.dart';
import 'package:autopeepalApp/services/error_handler/error_handler_service.dart';
import 'package:autopeepalApp/themes/app_theme.dart';
import 'package:autopeepalApp/utils/app_logs.dart';
import 'package:autopeepalApp/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:get_storage/get_storage.dart';

class App {
  static App instance = App();
  static const MethodChannel platform = MethodChannel('autopeepal/native');

  final String _appName = 'Autopeepal App';
  static String jwtToken = '';
  static String connectedVia = '';
  static int oemId = 0;
  static int subModelId = 0;
  static String firmwareVersion = '';
  static String sessionId = '';
  
  String? _version;
  String? _buildNumber;
  bool? _devMode;
  bool? _appLog;
  bool? _apiLog;
  String? _baseURLType;
  bool? _setDefault;
  bool? _samplePayment;

  static const String countryCode = "INDIA";

  String get appName => _appName;
  bool get devMode => _devMode ?? false;
  bool get appLog => _appLog ?? false;
  bool get apiLog => _apiLog ?? false;
  bool get setDefault => _setDefault ?? false;
  String get baseURLType => _baseURLType ?? AtomURLType.DEV;
  bool get samplePayment => _samplePayment ?? true;
  bool get isProd => _baseURLType == AtomURLType.DEV;

  void initAndRunApp({
    required bool appLog,
    required bool apiLog,
    required bool devMode,
    required bool setDefault,
    required bool samplePayment,
    required String baseURLType,
  }) {
    runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        // ── GetStorage (Windows safe) ─────────────────────────
        try {
          if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
            final String appPath =
                '${Platform.environment['APPDATA']}\\autopeepal';
            final dir = Directory(appPath);
            if (!await dir.exists()) {
              await dir.create(recursive: true);
            }
          }
          await GetStorage.init();
          print('✅ GetStorage initialized');
        } catch (e) {
          print('⚠️ GetStorage error: $e');
        }

        // ── App config ────────────────────────────────────────
        _devMode = devMode;
        _appLog = appLog;
        _apiLog = apiLog;
        _setDefault = setDefault;
        _baseURLType = baseURLType;
        _samplePayment = samplePayment;

        // ── Mobile only ───────────────────────────────────────
        if (Platform.isAndroid || Platform.isIOS) {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
            DeviceOrientation.portraitDown,
          ]);
        }

        // ── Error widget ──────────────────────────────────────
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          print('❌ Flutter Error: ${errorDetails.exception}');
          return AppErrorWidget(errorDetails: errorDetails);
        };

        initLogger();
        appLogs('''
        Configurations
        version : $_version
        buildNumber : $_buildNumber
        devMode : $_devMode
        appLog : $_appLog
        apiLog : $_apiLog
        baseURLType : $baseURLType
        ''');

        runApp(const MyApp());
      },
      (error, stack) {
        print('❌ FATAL ERROR: $error');
        print('❌ STACK: $stack');
        ErrorHandlerService.instance.appRecordError(error, stack);
      },
    );
  }
}

// ── Single entry point ────────────────────────────────────────────────────────
Future<void> main() async {
  App.instance.initAndRunApp(
    appLog: true,
    apiLog: false,
    devMode: true,
    setDefault: true,
    samplePayment: true,
    baseURLType: AtomURLType.PROD,
  );
}

// ── Root widget ───────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = App.instance;
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: config.appName,
      initialRoute: Routes.SPLASH_SCREEN_DART,  // ✅ Initial route
      theme: appTheme,
      getPages: AppPages.routes,                // ✅ All routes from AppPages
      builder: (context, child) {
        return child ?? const Center(
          child: Text(
            'App failed to load',
            style: TextStyle(color: Colors.red, fontSize: 24),
          ),
        );
      },
    );
  }
}