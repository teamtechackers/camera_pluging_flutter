import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:usb_camera_plugin_example/features/body_area/presentation/pages/back_page.dart';
import 'package:usb_camera_plugin_example/features/body_area/presentation/pages/face_page.dart';
import 'package:usb_camera_plugin_example/features/body_area/presentation/pages/frontal.dart';

import '../../../core/constants/app/app_assets.dart';
import '../../../core/constants/ui/app_colors.dart';
import '../../../core/constants/ui/app_text_styles.dart';
import '../../../core/widgets/background_container.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/widgets/setting_icon.dart';
import '../../../core/widgets/ultrascan4d.dart';
import '../../../routes/app_pages.dart';
import '../controllers/back_controller.dart';
import '../controllers/body_area_controller.dart';
import '../controllers/face_controller.dart';
import '../controllers/frontal_controller.dart';
import '../widget/text_button.dart';

class BodyAreaHome extends StatelessWidget {
  const BodyAreaHome({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(BodyAreaController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: BackgroundContainer(
        child: Stack(
          children: [
            Positioned(
              top: 50,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('area'.tr, style: AppTextStyles.heading4),
                  Transform.translate(
                    offset: const Offset(0, -8),
                    child: Text(
                      'bodily'.tr,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.yellowColor,
                      ),
                    ),
                  ),
                  const Ultrascan4d(),
                ],
              ),
            ),

            PageView(
              controller: controller.pageController,
              onPageChanged: controller.onPageChanged,
              children: const [FrontalPage(), BackPage(), FacePage()],
            ),

            Positioned(
              bottom: size.height * 0.08,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  InkWell(
                    child: Image.asset(
                      AppAssets.leftMoveIcon,
                      width: 25,
                      height: 25,
                    ),
                    onTap: () {
                      controller.pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                  const SizedBox(width: 5),
                  Obx(
                    () => CustomTextButton(
                      text: controller.currentPage.value == 1
                          ? 'dorsal'.tr
                          : controller.currentPage.value == 0
                          ? 'frontal'.tr
                          : 'face'.tr,
                      onTap: () async {
                        // Enforce a selection based on current tab
                        final page = controller.currentPage.value;

                        // Quick synchronous check first
                        bool hasSelection;
                        switch (page) {
                          case 0:
                            hasSelection = Get.find<FrontalController>()
                                .selectedButton
                                .value
                                .isNotEmpty;
                            break;
                          case 1:
                            hasSelection = Get.find<BackController>()
                                .selectedButton
                                .value
                                .isNotEmpty;
                            break;
                          case 2:
                            hasSelection = Get.find<FaceController>()
                                .selectedButton
                                .value
                                .isNotEmpty;
                            break;
                          default:
                            hasSelection = false;
                        }
                        if (!hasSelection) {
                          showCustomSnackbar(
                            title: '',
                            message: 'select_body_zone_before_scanning',
                            type: SnackbarType.error,
                          );
                          return;
                        }

                        final prefs = await SharedPreferences.getInstance();
                        prefs.setString('saved_mac_address', '4E:4F:DA:1C:21:11');
                        final mac = prefs.getString('saved_mac_address');
                        if (mac == null || mac.isEmpty) {
                          Get.toNamed(AppPages.settingPage, arguments: true);
                        } else {
                          Get.toNamed(AppPages.scanPage);
                        }
                      },
                      paddingHorizontal: 40,
                      paddingVertical: 11,
                    ),
                  ),
                  const SizedBox(width: 5),
                  InkWell(
                    child: Image.asset(
                      AppAssets.rightMoveIcon,
                      width: 25,
                      height: 25,
                    ),
                    onTap: () {
                      controller.pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                  ),
                ],
              ),
            ),
            // const Positioned(top: 50, right: 20, child: SettingIconWidget()),
          ],
        ),
      ),
    );
  }
}
