import 'package:get/get.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:usb_camera_plugin_example/routes/app_pages.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'core/api/api_client.dart';
import 'core/constants/app/app_assets.dart';
import 'core/constants/app/app_constants.dart';
import 'core/constants/ui/app_colors.dart';
import 'core/controllers/language_controller.dart';
import 'core/translations/app_translations.dart';

import 'dart:async';

void main() {
  runZonedGuarded(() async {
    print("🚀 APP_START: WidgetsFlutterBinding...");
    WidgetsFlutterBinding.ensureInitialized();

    if (Platform.isAndroid) {
      print("🚀 APP_START: Setting Android WebView Platform...");
      WebViewPlatform.instance = AndroidWebViewPlatform();
    }

    print("🚀 APP_START: ApiClient initialize...");
    await ApiClient().initialize();

    print("🚀 APP_START: Putting LanguageController...");
    Get.put(LanguageController());

    print("🚀 APP_START: Running MyApp...");
    runApp(const MyApp());
  }, (error, stack) {
    print("❌ FATAL_INITIALIZATION_ERROR: $error");
    print(stack);
  });
}

Future<void> _precacheImages(BuildContext context) async {
  final imageCache = PaintingBinding.instance.imageCache;
  final imagesToPrecache = [
    AppAssets.bg,
    AppAssets.splashBg,

    AppAssets.dorsal,
    AppAssets.glutes,
    AppAssets.back,
    AppAssets.dorsalNeck,
    AppAssets.sholders,

    AppAssets.face,
    AppAssets.down,
    AppAssets.cheeks,
    AppAssets.faceNeck,

    AppAssets.arms,
    AppAssets.peco,
    AppAssets.thighs,
    AppAssets.bikini,
    AppAssets.frontal,
    AppAssets.abdomen,
    AppAssets.armpits,
    AppAssets.lowerLeg,

    AppAssets.banner,
    AppAssets.ultraScanMachine,
  ];

  for (final imagePath in imagesToPrecache) {
    try {
      await precacheImage(AssetImage(imagePath), context);
    } catch (e) {
      debugPrint('Failed to precache image: $imagePath - Error: $e');
    }
  }

  debugPrint(
    'Image precaching completed. Cache size: ${imageCache.currentSize}',
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure background image is precached before building
    precacheImage(const AssetImage(AppAssets.bg), context);

    return GetMaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        scaffoldBackgroundColor:
            AppColors.black, // Prevent white flash during navigation
        useMaterial3: true,
      ),
      translations: AppTranslations(),
      locale: const Locale('es', 'ES'),
      fallbackLocale: const Locale('es', 'ES'),
      getPages: AppPages.routes,
      initialRoute: AppPages.initial,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return ScreenUtilInit(
          designSize: const Size(360, 690),
          minTextAdapt: true,
          splitScreenMode: true,
          builder: (context, _) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _precacheImages(context);
            });
            return child ?? const SizedBox.shrink();
          },
        );
      },
    );
  }
}
