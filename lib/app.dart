import 'dart:async';
import 'dart:io';
import 'package:simpson/api/app_envirments.dart';
import 'package:simpson/common_widgets/app_error_widget.dart';
import 'package:simpson/services/api_log_service.dart'; // ← new import
import 'package:simpson/services/error_handler/error_handler_service.dart';
import 'package:simpson/themes/app_theme.dart';
import 'package:simpson/utils/app_logs.dart';
import 'package:simpson/routes/app_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart' hide Response; // ← needed for Get.put
import 'package:get_storage/get_storage.dart';
import 'package:simpson/utils/ui_helper.dart/dllFunctions.dart';
import 'package:window_manager/window_manager.dart';

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
  static DLLFunctions? dllFunctions;

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
          // if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
          //   final String appPath =
          //       '${Platform.environment['APPDATA']}\\autopeepal';
          //   final dir = Directory(appPath);
          //   if (!await dir.exists()) {
          //     await dir.create(recursive: true);
          //   }
          // }

          if (Platform.isWindows) {
            await windowManager.ensureInitialized();

            WindowOptions windowOptions = const WindowOptions(
              center: true,
              //backgroundColor: Colors.transparent,
              skipTaskbar: false,
              titleBarStyle: TitleBarStyle.normal,
              // This sets the window to full screen at startup
            );

            windowManager.waitUntilReadyToShow(windowOptions, () async {
              await windowManager.maximize();
              await windowManager.show();
              await windowManager.focus();
            });
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

        // ── Dev API log service (in-app request/response viewer) ──
        Get.put(ApiLogService(), permanent: true); // ← new line

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
      initialRoute: Routes.SPLASH_SCREEN_DART, // ✅ Initial route
      theme: appTheme,
      getPages: AppPages.routes, // ✅ All routes from AppPages
      builder: (context, child) {
        return child ??
            const Center(
              child: Text(
                'App failed to load',
                style: TextStyle(color: Colors.red, fontSize: 24),
              ),
            );
      },
    );
  }
}
