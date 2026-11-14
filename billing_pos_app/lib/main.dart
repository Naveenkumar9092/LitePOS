import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "core/constants/app_constants.dart";
import "core/routing/app_router.dart";
import "core/storage/storage_service.dart";
import "core/theme/app_theme.dart";
import "features/company/data/company_repository.dart";

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storageService = await StorageService.create();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
      ],
      child: const LitePOSApp(),
    ),
  );
}

class LitePOSApp extends StatelessWidget {
  const LitePOSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
