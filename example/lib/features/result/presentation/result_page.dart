import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
import 'package:path_provider/path_provider.dart';

class ResultPage extends StatefulWidget {
  const ResultPage({required this.analysisResponse, super.key});
  final AnalysisResponse analysisResponse;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final ResultController controller;
  final GlobalKey<_WebResultViewState> _webResultKey = GlobalKey<_WebResultViewState>();

  @override
  void initState() {
    super.initState();
    // Initialize controller only once when the widget is first created
    // Delete existing controller if it exists to ensure fresh data
    if (Get.isRegistered<ResultController>()) {
      Get.delete<ResultController>();
    }
    controller = Get.put(
      ResultController(analysisResponse: widget.analysisResponse),
    );
  }

  @override
  void dispose() {
    // Clean up controller when widget is disposed
    if (Get.isRegistered<ResultController>()) {
      Get.delete<ResultController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),

              // const Align(
              //   alignment: Alignment.topRight,
              //   child: Padding(
              //     padding: EdgeInsets.only(right: 18),
              //     child: SettingIconWidget(),
              //   ),
              // ),
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

              // Display Annotated Image with error handling
              if (controller.analysisResponse.analysis?.annotatedImage != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        base64Decode(
                          controller.analysisResponse.analysis!.annotatedImage!
                              .split(',')
                              .last,
                        ),
                        key: ValueKey(
                          controller.analysisResponse.analysis!.annotatedImage,
                        ),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[300],
                            child: const Center(
                              child: Text(
                                "Failed to load image",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        },
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
              // Text('analysis_summary'.tr, style: AppTextStyles.heading4),

              // Obx(
              //   () => Padding(
              //     padding: const EdgeInsets.all(20),
              //     child: Text(
              //       controller.resultLink.value,
              //       style: AppTextStyles.body2,
              //     ),
              //   ),
              // ),
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
                      Obx(
                        () => controller.resultUrl.value.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : WebResultView(
                                key: _webResultKey,
                                url: controller.resultUrl.value,
                                onDownloadStarted: () {
                                  controller.isDownloadingPdf.value = true;
                                },
                                onDownloadFinished: () {
                                  controller.isDownloadingPdf.value = false;
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextButton(
                        text: 'ask_a_question'.tr,
                        onTap: () {
                          // controller.analysisResponse.analysis = null;
                          _showAdvancedBottomSheet(context);
                          // Get.back();
                        },
                        paddingHorizontal: 40,
                        paddingVertical: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Row(
                  children: [
                    Expanded(
                      child: Obx(
                        () => CustomTextButton(
                          text: controller.isDownloadingPdf.value
                              ? 'processing_pdf'.tr
                              : 'download_pdf'.tr,
                          onTap: controller.isDownloadingPdf.value
                              ? () {} // Disable or ignore while processing
                              : () {
                                  _webResultKey.currentState?.triggerDownload();
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
      ),
    );
  }
}

void _showAdvancedBottomSheet(BuildContext context) {
  final size = MediaQuery.of(context).size;

  // Initialize controller for this bottom sheet instance
  // Using a unique tag to avoid conflicts
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
    // Delay disposal to ensure any navigation completes first
    // This prevents the TextEditingController from being disposed while still in use
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  Text(
                    'how_can_i_help_scan'.tr,
                    style: AppTextStyles.body2.copyWith(
                      color: AppColors.whiteColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'choose_question_or_formulate'.tr,
                    style: AppTextStyles.title1.copyWith(
                      color: AppColors.goldColor,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // FAQ Section
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'frequently_asked_questions'.tr,
                      style: AppTextStyles.body2.copyWith(
                        color: AppColors.whiteColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Obx(
                      () => _buildFAQButton(
                        context,
                        'faq_question_1'.tr,
                        () => controller.selectQuestion('faq_question_1'.tr),
                        isLoading: controller.isLoading.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _buildFAQButton(
                        context,
                        'faq_question_2'.tr,
                        () => controller.selectQuestion('faq_question_2'.tr),
                        isLoading: controller.isLoading.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _buildFAQButton(
                        context,
                        'faq_question_3'.tr,
                        () => controller.selectQuestion('faq_question_3'.tr),
                        isLoading: controller.isLoading.value,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Obx(
                      () => _buildFAQButton(
                        context,
                        'faq_question_4'.tr,
                        () => controller.selectQuestion('faq_question_4'.tr),
                        isLoading: controller.isLoading.value,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Input Field and Send Button
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

class WebResultView extends StatefulWidget {
  final String url;
  final VoidCallback? onDownloadStarted;
  final VoidCallback? onDownloadFinished;

  const WebResultView({
    required this.url,
    this.onDownloadStarted,
    this.onDownloadFinished,
    super.key,
  });

  @override
  State<WebResultView> createState() => _WebResultViewState();
}

class _WebResultViewState extends State<WebResultView> {
  static const MethodChannel _platformChannel = MethodChannel(
    'usb_camera_plugin',
  );
  late final WebViewController _controller;
  bool isLoading = true;
  double contentHeight = 150;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      // 🔹 Receive Base64 PDF from JS
      ..addJavaScriptChannel(
        'BlobPDF',
        onMessageReceived: (JavaScriptMessage message) async {
          try {
            widget.onDownloadFinished?.call();
            final base64 = message.message;
            // Decode Base64 into raw bytes
            final bytes = base64Decode(base64);

            // Persist PDF to a shareable directory
            // On Android: use temporary/cache directory so it's covered by FileProvider <cache-path>
            // On other platforms: fall back to application documents directory
            final dir = Platform.isAndroid
                ? await getTemporaryDirectory()
                : await getApplicationDocumentsDirectory();

            final file = File(
              '${dir.path}/Reporte_UltraScan_${DateTime.now().millisecondsSinceEpoch}.pdf',
            );
            await file.writeAsBytes(bytes, flush: true);

            // Ask native Android code (MainActivity) to open this PDF using FileProvider
            await _WebResultViewState._platformChannel.invokeMethod(
              'openPdf',
              file.path,
            );
          } catch (e, s) {
            widget.onDownloadFinished?.call();
            log('Failed to open PDF from WebView: $e\n$s');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          // 🔹 Inject interceptor EARLY
          onPageStarted: (_) async {
            setState(() => isLoading = true);
            await _injectBlobInterceptor();
          },
          onPageFinished: (_) async {
            await _updateHeight();
          },
          onWebResourceError: (error) {
            setState(() => isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  // 🔹 Trigger PDF Download via JS
  void triggerDownload() {
    widget.onDownloadStarted?.call();
    _controller.runJavaScript('''
      (function() {
        // Try to find the download button on the page
        // Common selectors for download buttons (adjust based on actual page structure if known)
        const selectors = [
          'button[id*="download"]',
          'button[class*="download"]',
          'a[id*="download"]',
          'a[class*="download"]',
           '[title*="Download"]',
           '[aria-label*="Download"]'
        ];
        
        for (const selector of selectors) {
          const btn = document.querySelector(selector);
          if (btn) {
            btn.click();
            return;
          }
        }
        
        // Fallback: If jsPDF is present, try calling save directly if we can find the instance
        // But since we patched jsPDF.save, it should work if we just trigger the UI button.
      })();
    ''');
  }

  // 🔹 JS: Intercept BLOB PDFs and send to Flutter
  Future<void> _injectBlobInterceptor() async {
    await _controller.runJavaScript('''
      (function () {
        if (window.__blobInterceptorInjected) return;
        window.__blobInterceptorInjected = true;

        // ================================
        // 1) INTERCEPT BLOB: URL CLICKS
        // ================================
        document.addEventListener('click', function(e) {
          const link = e.target.closest('a');
          if (!link || !link.href) return;

          if (link.href.startsWith('blob:')) {
            e.preventDefault();

            fetch(link.href)
              .then(res => res.blob())
              .then(blob => {
                const reader = new FileReader();
                reader.onloadend = function () {
                  const base64data = reader.result.split(',')[1];
                  BlobPDF.postMessage(base64data);
                };
                reader.readAsDataURL(blob);
              });
          }
        }, true);

        // ==========================================
        // 2) PATCH jsPDF.save() TO WORK IN WEBVIEW
        // ==========================================
        function patchJsPDF() {
          try {
            // Try to resolve jsPDF constructor from common globals
            var JsPDFCtor = (window.jspdf && window.jspdf.jsPDF) || window.jsPDF;
            if (!JsPDFCtor || JsPDFCtor.__ultraPatched) return;

            var proto = JsPDFCtor.API || JsPDFCtor.prototype;
            if (!proto) return;

            // Avoid double-patching
            if (proto.__originalSave) return;

            proto.__originalSave = proto.save;
            proto.save = function (fileName) {
              try {
                // Generate Data URI and send Base64 to Flutter
                var dataUri = this.output('datauristring');
                var base64 = String(dataUri).split(',')[1]; // strip "data:application/pdf;base64,"

                if (window.BlobPDF && typeof BlobPDF.postMessage === 'function') {
                  BlobPDF.postMessage(base64);
                } else if (typeof proto.__originalSave === 'function') {
                  // Fallback for normal browsers
                  proto.__originalSave.call(this, fileName || 'document.pdf');
                }
              } catch (err) {
                // If anything fails, fall back to original behavior
                if (typeof proto.__originalSave === 'function') {
                  proto.__originalSave.call(this, fileName || 'document.pdf');
                }
              }
            };

            JsPDFCtor.__ultraPatched = true;
          } catch (e) {
            // Silent fail – do not break page
          }
        }

        // Try patching once DOM is ready
        if (document.readyState === 'loading') {
          document.addEventListener('DOMContentLoaded', patchJsPDF);
        } else {
          patchJsPDF();
        }

        // Also poll a few times in case jsPDF loads late
        var tries = 0;
        var interval = setInterval(function () {
          tries++;
          if (window.jspdf || window.jsPDF || tries > 10) {
            patchJsPDF();
            clearInterval(interval);
          }
        }, 500);
      })();
    ''');
  }

  // 🔹 Auto height calculation
  Future<void> _updateHeight() async {
    try {
      final height = await _controller.runJavaScriptReturningResult(
        'Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)',
      );

      final h = double.tryParse(
        height.toString().replaceAll(RegExp(r'[^0-9.]'), ''),
      );

      if (mounted && h != null) {
        setState(() {
          contentHeight = h.clamp(150, 3000);
          isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          height: contentHeight,
          child: WebViewWidget(controller: _controller),
        ),
        if (isLoading)
          const Positioned.fill(
            child: Center(
              child: CircularProgressIndicator(color: AppColors.goldColor),
            ),
          ),
      ],
    );
  }
}
