import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:usb_camera_plugin_example/routes/app_pages.dart';

import '../../../core/constants/ui/app_colors.dart';
import '../../../core/constants/ui/app_text_styles.dart';
import '../../../core/widgets/background_container.dart';
import '../../../core/widgets/setting_icon.dart';
import '../../../core/widgets/ultrascan4d.dart';
import '../../body_area/widget/text_button.dart';
import '../controller/setting_controller.dart';

class SettingPage extends StatelessWidget {
  const SettingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SettingController());
    final isFromHome = Get.arguments ?? false;
    return Scaffold(
      body: Stack(
        children: [
          BackgroundContainer(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: SettingIconWidget(
                      haveArrowIcon: true,
                      onTap: () async {
                        if (isFromHome) {
                          final prefs = await SharedPreferences.getInstance();
                          final mac = prefs.getString('saved_mac_address');
                          if (mac == null || mac.isEmpty) {
                            Get.back();
                          } else {
                            Get.toNamed(AppPages.scanPage);
                          }
                        } else {
                          Get.back();
                        }
                      },
                    ),
                  ),
                ),

                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('device'.tr, style: AppTextStyles.heading4),
                    Transform.translate(
                      offset: const Offset(0, -8),
                      child: Text(
                        'activation'.tr,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.yellowColor,
                        ),
                      ),
                    ),
                    const Ultrascan4d(),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Form(
                    key: controller.formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('enterMacAddress'.tr, style: AppTextStyles.body2),
                        const SizedBox(height: 10),
                        MacAddress(
                          controller: controller.macAddressController,
                          paddingVertical: 11,
                          validator: controller.macValidator,
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Row(
                    children: [
                      Expanded(
                        child: Obx(
                          () => CustomTextButton(
                            text: 'activate'.tr,
                            onTap: controller.isLoading.value
                                ? () {}
                                : () async {
                                    FocusScope.of(context).unfocus();
                                    await controller.activateDevice();
                                  },
                            paddingHorizontal: 40,
                            paddingVertical: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          // Loading overlay
          Obx(
            () => controller.isLoading.value
                ? Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withAlpha(110),
                      child: const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.goldColor,
                          ),
                        ),
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class MacAddress extends StatelessWidget {
  const MacAddress({
    required this.controller,
    super.key,
    this.paddingVertical,
    this.validator,
  });
  final double? paddingVertical;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.yellowColor.withValues(alpha: 0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.goldColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.goldColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.goldColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.goldColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: const BorderSide(color: AppColors.goldColor),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 5,
          vertical: paddingVertical ?? 0,
        ),
        hintText: '4D:45:F2:AA:1C:CC',
        hintStyle: AppTextStyles.body1.copyWith(color: AppColors.blackColor),
      ),
      style: AppTextStyles.body1.copyWith(color: AppColors.blackColor),
      validator: validator,
    );
  }
}
