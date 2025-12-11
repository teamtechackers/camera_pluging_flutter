import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../controller/result_controller.dart';
import '../../../core/widgets/ultrascan4d.dart';
import '../../body_area/widget/text_button.dart';
import '../../../core/constants/ui/app_colors.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/api/models/analysis_response.dart';
import '../../../core/constants/ui/app_text_styles.dart';
import '../../../core/widgets/background_container.dart';
import 'package:usb_camera_plugin_example/core/constants/app/app_assets.dart';
import 'package:usb_camera_plugin_example/core/widgets/inputs/send_text_field.dart';
import 'package:usb_camera_plugin_example/features/body_area/controllers/bottom_sheet_controller.dart';

class ResultPage extends StatelessWidget {
  const ResultPage({required this.analysisResponse, super.key});
  final AnalysisResponse analysisResponse;

  @override
  Widget build(BuildContext context) {
    // Delete existing controller if it exists
    if (Get.isRegistered<ResultController>()) {
      Get.delete<ResultController>();
    }
    final controller = Get.put(
      ResultController(analysisResponse: analysisResponse),
    );

    return Scaffold(
      body: BackgroundContainer(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 50),

                    /// HEADER
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('protocol'.tr, style: AppTextStyles.heading4),
                        Transform.translate(
                          offset: const Offset(0, -8),
                          child: Text(
                            'and_result'.tr,
                            style: AppTextStyles.heading3.copyWith(
                              color: AppColors.yellowColor,
                            ),
                          ),
                        ),
                        const Ultrascan4d(),
                      ],
                    ),

                    /// IMAGE
                    if (controller.analysisResponse.analysis?.annotatedImage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.memory(
                              base64Decode(
                                controller.analysisResponse.analysis!.annotatedImage!.split(',').last,
                              ),
                              fit: BoxFit.cover,
                              gaplessPlayback: true,
                            ),
                          ),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Center(
                            child: Text("No detection image available"),
                          ),
                        ),
                      ),

                    /// ANALYSIS SUMMARY
                    if (controller.analysisResponse.analysis != null) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'analysis_summary'.tr,
                              style: AppTextStyles.heading4.copyWith(
                                color: AppColors.whiteColor,
                                fontSize: 32,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ],

                    /// WEBVIEW
                    Obx(
                          () => controller.resultUrl.value.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          height: 450,
                          child: WebResultView(url: controller.resultUrl.value),
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),
            // Button outside scrollview so it's always visible
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Row(
                children: [
                  Expanded(
                    child: CustomTextButton(
                      text: 'ask_a_question'.tr,
                      onTap: () => _showAdvancedBottomSheet(context),
                      paddingHorizontal: 40,
                      paddingVertical: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _showAdvancedBottomSheet(BuildContext context) {
  final size = MediaQuery.of(context).size;

  final tag = 'bottom_sheet_${DateTime.now().millisecondsSinceEpoch}';
  final controller = Get.put(BottomSheetController(), tag: tag);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    backgroundColor: Colors.transparent,
    builder: (BuildContext context) {
      return _BottomSheetContent(size: size, controller: controller);
    },
  ).then((_) {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (Get.isRegistered<BottomSheetController>(tag: tag)) {
        Get.delete<BottomSheetController>(tag: tag);
      }
    });
  });
}

class _BottomSheetContent extends StatelessWidget {
  final Size size;
  final BottomSheetController controller;

  const _BottomSheetContent({required this.size, required this.controller});

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        constraints: BoxConstraints(maxHeight: size.height * 0.53),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(AppAssets.bottomsheetBg),
            fit: BoxFit.cover,
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'how_can_i_help_scan'.tr,
                    style: AppTextStyles.body2.copyWith(color: AppColors.whiteColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'choose_question_or_formulate'.tr,
                    style: AppTextStyles.title1.copyWith(color: AppColors.goldColor, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      'frequently_asked_questions'.tr,
                      style: AppTextStyles.body2.copyWith(color: AppColors.whiteColor),
                    ),
                    const SizedBox(height: 16),
                    Obx(() => _buildFAQButton(
                      context,
                      'faq_question_1'.tr,
                          () => controller.selectQuestion('faq_question_1'.tr),
                      isLoading: controller.isLoading.value,
                    )),
                    const SizedBox(height: 12),
                    Obx(() => _buildFAQButton(
                      context,
                      'faq_question_2'.tr,
                          () => controller.selectQuestion('faq_question_2'.tr),
                      isLoading: controller.isLoading.value,
                    )),
                    const SizedBox(height: 12),
                    Obx(() => _buildFAQButton(
                      context,
                      'faq_question_3'.tr,
                          () => controller.selectQuestion('faq_question_3'.tr),
                      isLoading: controller.isLoading.value,
                    )),
                    const SizedBox(height: 12),
                    Obx(() => _buildFAQButton(
                      context,
                      'faq_question_4'.tr,
                          () => controller.selectQuestion('faq_question_4'.tr),
                      isLoading: controller.isLoading.value,
                    )),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Obx(
                  () => SendTextField(
                controller: controller.questionController,
                enabled: !controller.isLoading.value,
                isLoading: controller.isLoading.value,
                onSend: controller.sendQuestion,
              ),
            ),
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQButton(
      BuildContext context,
      String text,
      VoidCallback onTap, {
        required bool isLoading,
      }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.transparentColor,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: AppColors.gold300Color, width: 1),
        ),
        child: Text(text, style: AppTextStyles.title1.copyWith(fontSize: 12)),
      ),
    );
  }
}

class WebResultView extends StatelessWidget {
  final String url;

  const WebResultView({required this.url, super.key});

  @override
  Widget build(BuildContext context) {
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadRequest(Uri.parse(url));

    return SizedBox(
      height: 450,
      child: WebViewWidget(
        controller: controller,
        gestureRecognizers: {
          Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
        },
      ),
    );
  }
}
