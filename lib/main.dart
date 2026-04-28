import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_service.dart';
import 'core/theme/app_theme.dart';
import 'data/models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initHive();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  await MobileAds.instance.initialize();
  AdService.preload();

  runApp(const ProviderScope(child: AlbumMundialApp()));
}

Future<void> _initHive() async {
  await Hive.initFlutter();
  Hive.registerAdapter(UserModelAdapter());
  await Hive.openBox<UserModel>(AppConstants.userBox);
  await Hive.openBox<int>(AppConstants.stickerQuantitiesBox);
  await Hive.openBox<int>(AppConstants.personalBackupBox);
  await Hive.openBox(AppConstants.settingsBox);
}

class AlbumMundialApp extends ConsumerWidget {
  const AlbumMundialApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
