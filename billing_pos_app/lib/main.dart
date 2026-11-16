import "dart:convert";
import "dart:ui";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";
import "package:google_fonts/google_fonts.dart";
import "package:sqflite_common_ffi/sqflite_ffi.dart";
import "package:sqflite_common_ffi_web/sqflite_ffi_web.dart";
import "core/constants/app_constants.dart";
import "core/routing/app_router.dart";
import "core/routing/route_names.dart";
import "core/storage/storage_service.dart";
import "core/theme/app_theme.dart";
import "features/authentication/models/user_model.dart";
import "features/company/data/company_repository.dart";

class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics());
  }
}

void _initDatabaseFactory() {
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWebNoWebWorker;
  } else if (defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.macOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = true;
  _initDatabaseFactory();
  final storageService = await StorageService.create();

  // Persistent login: auto-detect saved session so app restart never logs out
  String initialRoute = RouteNames.login;
  final userJson = await storageService.read("current_user_json");
  final token = await storageService.read(AppConstants.tokenKey);

  if (userJson != null && userJson.isNotEmpty && token != null && token.isNotEmpty) {
    try {
      final map = jsonDecode(userJson) as Map<String, dynamic>;
      final user = UserModel.fromJson(map);
      if (user.isCashier) {
        initialRoute = RouteNames.posBilling;
      } else if (user.isSAdmin) {
        initialRoute = RouteNames.sadminDashboard;
      } else {
        initialRoute = RouteNames.adminDashboard;
      }
    } catch (_) {
      initialRoute = RouteNames.login;
    }
  }

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: LitePOSApp(initialRoute: initialRoute),
    ),
  );
}

class LitePOSApp extends StatefulWidget {
  final String initialRoute;
  const LitePOSApp({super.key, this.initialRoute = RouteNames.login});

  @override
  State<LitePOSApp> createState() => _LitePOSAppState();
}

class _LitePOSAppState extends State<LitePOSApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = createAppRouter(initialLocation: widget.initialRoute);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}
