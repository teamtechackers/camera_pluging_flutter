import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:usb_camera_plugin_example/routes/app_pages.dart';

import 'core/api/api_client.dart';
import 'core/constants/app/app_assets.dart';
import 'core/constants/app/app_constants.dart';
import 'core/constants/ui/app_colors.dart';
import 'core/controllers/language_controller.dart';
import 'core/translations/app_translations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WebViewPlatform.instance = AndroidWebViewPlatform();
  await ApiClient().initialize();
  Get.put(LanguageController());
  runApp(const MyApp());
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
    return GetMaterialApp(
      title: AppConstants.appName,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
      ),
      translations: AppTranslations(),
      locale: const Locale('es', 'ES'),
      fallbackLocale: const Locale('es', 'ES'),
      getPages: AppPages.routes,
      initialRoute: AppPages.initial,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _precacheImages(context);
        });
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
