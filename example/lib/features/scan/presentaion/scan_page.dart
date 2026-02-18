import 'dart:developer';
import 'dart:io';

import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:usb_camera_plugin_example/core/constants/index.dart';
import 'package:usb_camera_plugin_example/features/scan/widgets/bottomsheet_cicular.dart';

import '../../../core/constants/app/app_assets.dart';
import '../../../core/widgets/background_container.dart';
import '../../../core/widgets/setting_icon.dart';
import '../../../core/widgets/ultrascan4d.dart';
import '../../../routes/app_pages.dart';
import '../controllers/scan_controller.dart';
import '../widgets/circule_container.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  late ScanController controller;

  @override
  void initState() {
    super.initState();
    // Get.put will reuse existing controller instance if it exists
    // This ensures state persists across hot reloads
    if (Get.isRegistered<ScanController>()) {
      controller = Get.find<ScanController>();
    } else {
      controller = Get.put(ScanController());
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    log(controller.selectedImage.value.toString());
    return Obx(
      () => Scaffold(
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        body: Stack(
          children: [
            BackgroundContainer(
              isImage: controller.selectedImage.value == null,
              child: Column(
                children: [
                  const SizedBox(height: 50),
                  const SizedBox(height: 10),
                  const Ultrascan4d(),
                  const Spacer(),

                  if (controller.selectedImage.value == null) ...[
                    const Spacer(),
                    CirculeContainer(
                      icon: AppAssets.cameraIcon,
                      title: 'start_scan'.tr,
                      onTap: () {
                        _showAdvancedBottomSheet(context);
                      },
                    ),
                    const Spacer(),
                    const Spacer(),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(bottom: 60),
                      child: Obx(
                        () => Image.file(
                          File(controller.selectedImage.value!.path),
                          height: controller.isFromUsb.value
                              ? null
                              : size.height * 0.75,
                          fit: BoxFit.fitWidth,
                          width: size.width,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text('Image load error'),
                            );
                          },
                        ),
                      ),
                    ),
                  // const SizedBox(height: 30),
                  const Spacer(),
                ],
              ),
            ),
            // Loading overlay
            if (controller.isLoading.value)
              Positioned.fill(
                child: ColoredBox(
                  color: Colors.black.withAlpha(110),
                  child: Center(
                    child: Text(
                      "processing".tr,
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: controller.selectedImage.value == null
            ? null
            : CirculeContainer(
                height: size.width * 0.35,
                width: size.width * 0.35,
                icon: AppAssets.scanIcon,
                title: 'analyze_with_ai'.tr,
                onTap: controller.isLoading.value
                    ? null
                    : controller.analyzeSelectedImage,
              ),
      ),
    );
  }
}

void _showAdvancedBottomSheet(BuildContext context) {
  final size = MediaQuery.of(context).size;
  final controller = Get.find<ScanController>();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return Container(
        height: size.height * 0.34,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.bottomsheetBg),
            fit: BoxFit.cover,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            children: [
              SizedBox(height: 45),
              Text('choose_how_to_scan'.tr, style: AppTextStyles.body2),
              SizedBox(height: 10),
              Text(
                'select_loading_method'.tr,
                style: AppTextStyles.body1.copyWith(color: AppColors.goldColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  BottomSheetCircular(
                    height: size.width * 0.27,
                    width: size.width * 0.27,
                    icon: AppAssets.usbConnection,
                    title: 'usb_conection'.tr,
                    iconSize: 30,
                    onTap: () async {
                      await controller.pickImage();
                      Get.back();
                    },
                  ),
                  BottomSheetCircular(
                    height: size.width * 0.27,
                    width: size.width * 0.27,
                    icon: AppAssets.cameraIcon,
                    title: 'camera'.tr,
                    iconSize: 40,
                    onTap: () {
                      Get.back(); // Close bottom sheet
                      Get.toNamed(AppPages.cameraScreen);
                    },
                  ),
                   BottomSheetCircular(
                    height: size.width * 0.27,
                    width: size.width * 0.27,
                    iconSize: 30,
                    icon: AppAssets.gallery,
                    title: 'galery'.tr,
                    onTap: () async {
                      Get.back(); // Close bottom sheet FIRST
                      await controller.pickImageFromGallery();
                    },
                  ),
                ],
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      );
    },
  );
}
