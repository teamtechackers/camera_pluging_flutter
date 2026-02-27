import 'package:get/get.dart';

import '../core/api/models/analysis_response.dart';
import '../features/body_area/presentation/body_area_home.dart';
import '../features/result/presentation/result_page.dart';
import '../features/scan/presentaion/scan_page.dart';
import '../features/scan/presentaion/camera_screen.dart';
import '../features/setting/presentation/setting_page.dart';
import '../features/splash/presentation/splash_screen.dart';

class AppPages {
  static const initial = '/splash';
  static const scanPage = '/scanPage';
  static const cameraScreen = '/cameraScreen';
  static const settingPage = '/setting';
  static const bodyAreaHome = '/body-area-home';
  static const resultPage = '/result-page';

  static final routes = [
    GetPage(
      name: scanPage,
      page: () => const ScanPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: cameraScreen,
      page: () => const CameraScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: initial,
      page: () => const SplashScreen(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: resultPage,
      page: () {
        final analysisResponse = Get.arguments is AnalysisResponse
            ? Get.arguments as AnalysisResponse
            : throw ArgumentError('AnalysisResponse is required');
        return ResultPage(analysisResponse: analysisResponse);
      },
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: settingPage,
      page: () => const SettingPage(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
    GetPage(
      name: bodyAreaHome,
      page: () => const BodyAreaHome(),
      transition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 200),
    ),
  ];
}
