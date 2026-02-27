import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app/app_assets.dart';
import '../../../core/constants/ui/app_text_styles.dart';
import '../../../routes/app_pages.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3));
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('saved_mac_address', '4E:4F:DA:1C:21:11');
    Get.offNamed(AppPages.bodyAreaHome);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage(AppAssets.bg), context);
    precacheImage(AssetImage(AppAssets.bottomsheetBg), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage(AppAssets.splashBg),
              fit: BoxFit.cover,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                flex: 2,
                child: Center(
                  child: Image.asset(AppAssets.banner, fit: BoxFit.contain),
                ),
              ),

              Expanded(
                flex: 5,
                child: Image.asset(
                  AppAssets.ultraScanMachine,
                  fit: BoxFit.contain,
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Container(
                  height: 40,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(AppAssets.initializingBanner),
                      fit: BoxFit.contain,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('initializing'.tr, style: AppTextStyles.title1),
                      const SizedBox(width: 8),
                      Text('loading_dots'.tr, style: AppTextStyles.title1),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
