import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:usb_camera_plugin_example/core/constants/app/app_assets.dart';
import 'package:usb_camera_plugin_example/core/widgets/inputs/send_text_field.dart';
import 'package:usb_camera_plugin_example/features/body_area/controllers/bottom_sheet_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../core/api/models/analysis_response.dart';
import '../../../core/constants/ui/app_colors.dart';
import '../../../core/constants/ui/app_text_styles.dart';
import '../../../core/widgets/background_container.dart';
import '../../../core/widgets/ultrascan4d.dart';
import '../../body_area/widget/text_button.dart';
import '../controller/result_controller.dart';

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
    if (Get.isRegistered<ResultController>()) {
      Get.delete<ResultController>();
    }
    controller = Get.put(ResultController(analysisResponse: widget.analysisResponse));
  }

  @override
  void dispose() {
    if (Get.isRegistered<ResultController>()) {
      Get.delete<ResultController>();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundContainer(
        child: Column(
          children: [
            const SizedBox(height: 30),

            /// HEADER
            Column(
              children: [
                Text('protocol'.tr, style: AppTextStyles.heading5),
                Transform.translate(
                  offset: const Offset(0, -8),
                  child: Text('and_result'.tr, style: AppTextStyles.heading4.copyWith(color: AppColors.yellowColor)),
                ),
                const Ultrascan4d(),
              ],
            ),

            /// IMAGE
            if (controller.analysisResponse.analysis?.annotatedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: AspectRatio(
                  aspectRatio: 4 / 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(base64Decode(controller.analysisResponse.analysis!.annotatedImage!.split(',').last), fit: BoxFit.cover),
                  ),
                ),
              ),

            /// WEBVIEW AREA (THIS IS THE KEY FIX)
            if (controller.analysisResponse.analysis != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      Text('analysis_summary'.tr, style: AppTextStyles.heading4.copyWith(color: AppColors.whiteColor, fontSize: 22)),

                      /// THIS Expanded is CRITICAL
                      Expanded(
                        child: Obx(
                          () => controller.resultUrl.value.isEmpty
                              ? const Center(child: CircularProgressIndicator())
                              : WebResultView(
                                  key: _webResultKey,
                                  url: controller.resultUrl.value,
                                  annotatedImage: controller.analysisResponse.analysis?.annotatedImage,
                                  onDownloadStarted: () => controller.isDownloadingPdf.value = true,
                                  onDownloadFinished: () => controller.isDownloadingPdf.value = false,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            /// FIXED BUTTON
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 10, 30, 30),
              child: CustomTextButton(text: 'ask_a_question'.tr, onTap: () => _showAdvancedBottomSheet(context), paddingHorizontal: 40, paddingVertical: 11),
            ),
          ],
        ),
      ),

      // body:
      //  BackgroundContainer(
      //   child: Column(
      //     children: [
      //       const SizedBox(height: 50),
      //       Column(
      //         mainAxisSize: MainAxisSize.min,
      //         children: [
      //           Text('protocol'.tr, style: AppTextStyles.heading4),
      //           Transform.translate(
      //             offset: const Offset(0, -8),
      //             child: Text('and_result'.tr, style: AppTextStyles.heading3.copyWith(color: AppColors.yellowColor)),
      //           ),
      //           const Ultrascan4d(),
      //         ],
      //       ),
      //       if (controller.analysisResponse.analysis?.annotatedImage != null)
      //         Padding(
      //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      //           child: AspectRatio(
      //             aspectRatio: 4 / 3,
      //             child: ClipRRect(
      //               borderRadius: BorderRadius.circular(8),
      //               child: Image.memory(
      //                 base64Decode(controller.analysisResponse.analysis!.annotatedImage!.split(',').last),
      //                 key: ValueKey(controller.analysisResponse.analysis!.annotatedImage),
      //                 fit: BoxFit.cover,
      //                 gaplessPlayback: true,
      //                 errorBuilder: (context, error, stackTrace) {
      //                   return Container(
      //                     color: Colors.grey[300],
      //                     child: const Center(
      //                       child: Text("Failed to load image", style: TextStyle(color: Colors.red)),
      //                     ),
      //                   );
      //                 },
      //               ),
      //             ),
      //           ),
      //         )
      //       else
      //         Padding(
      //           padding: const EdgeInsets.all(16.0),
      //           child: Container(
      //             height: 200,
      //             color: Colors.grey[300],
      //             child: const Center(child: Text("No detection image available")),
      //           ),
      //         ),
      //       if (controller.analysisResponse.analysis != null) ...[
      //         const SizedBox(height: 16),
      //         Padding(
      //           padding: const EdgeInsets.symmetric(horizontal: 20),
      //           child: Column(
      //             crossAxisAlignment: CrossAxisAlignment.start,
      //             children: [
      //               Align(
      //                 alignment: Alignment.center,
      //                 child: Text('analysis_summary'.tr, style: AppTextStyles.heading4.copyWith(color: AppColors.whiteColor, fontSize: 22)),
      //               ),
      //               const SizedBox(height: 16),
      //               Obx(
      //                 () => controller.resultUrl.value.isEmpty
      //                     ? const Center(child: CircularProgressIndicator())
      //                     : WebResultView(
      //                         key: _webResultKey,
      //                         url: controller.resultUrl.value,
      //                         annotatedImage: controller.analysisResponse.analysis?.annotatedImage,
      //                         onDownloadStarted: () {
      //                           controller.isDownloadingPdf.value = true;
      //                         },
      //                         onDownloadFinished: () {
      //                           controller.isDownloadingPdf.value = false;
      //                         },
      //                       ),
      //               ),
      //             ],
      //           ),
      //         ),
      //       ],
      //       const SizedBox(height: 20),
      //       Padding(
      //         padding: const EdgeInsets.symmetric(horizontal: 30),
      //         child: Row(
      //           children: [
      //             Expanded(
      //               child: CustomTextButton(
      //                 text: 'ask_a_question'.tr,
      //                 onTap: () {
      //                   _showAdvancedBottomSheet(context);
      //                 },
      //                 paddingHorizontal: 40,
      //                 paddingVertical: 11,
      //               ),
      //             ),
      //           ],
      //         ),
      //       ),
      //       const SizedBox(height: 50),
      //     ],
      //   ),
      // ),
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
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
          image: DecorationImage(image: AssetImage(AppAssets.bottomsheetBg), fit: BoxFit.cover),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('frequently_asked_questions'.tr, style: AppTextStyles.body2.copyWith(color: AppColors.whiteColor)),
                    const SizedBox(height: 16),
                    Obx(() => _buildFAQButton(context, 'faq_question_1'.tr, () => controller.selectQuestion('faq_question_1'.tr), isLoading: controller.isLoading.value)),
                    const SizedBox(height: 12),
                    Obx(() => _buildFAQButton(context, 'faq_question_2'.tr, () => controller.selectQuestion('faq_question_2'.tr), isLoading: controller.isLoading.value)),
                    const SizedBox(height: 12),
                    Obx(() => _buildFAQButton(context, 'faq_question_3'.tr, () => controller.selectQuestion('faq_question_3'.tr), isLoading: controller.isLoading.value)),
                    const SizedBox(height: 12),
                    Obx(() => _buildFAQButton(context, 'faq_question_4'.tr, () => controller.selectQuestion('faq_question_4'.tr), isLoading: controller.isLoading.value)),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Obx(() => SendTextField(controller: controller.questionController, enabled: !controller.isLoading.value, isLoading: controller.isLoading.value, onSend: controller.sendQuestion)),
            SizedBox(height: bottomPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQButton(BuildContext context, String text, VoidCallback onTap, {required bool isLoading}) {
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
  final String? annotatedImage;
  final VoidCallback? onDownloadStarted;
  final VoidCallback? onDownloadFinished;

  const WebResultView({required this.url, this.annotatedImage, this.onDownloadStarted, this.onDownloadFinished, super.key});

  @override
  State<WebResultView> createState() => _WebResultViewState();
}

class _WebResultViewState extends State<WebResultView> {
  late final WebViewController _controller;
  bool isLoading = true;
  bool hasError = false; // ⭐ NEW
  double contentHeight = 400;
  String? _lastDownloadedUrl;
  DateTime? _lastDownloadTime;

  @override
  void initState() {
    super.initState();
    print("URL${widget.url}");
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'BlobPDF',
        onMessageReceived: (JavaScriptMessage message) async {
          final msg = message.message;

          if (msg.startsWith('LOG: ')) {
            log('WebView: ${msg.substring(5)}');
            return;
          }

          if (msg.startsWith('HEIGHT: ')) {
            final hStr = msg.substring(8);
            final h = double.tryParse(hStr);
            if (mounted && h != null && h != contentHeight) {
              setState(() => contentHeight = h.clamp(150, 5500));
            }
            return;
          }

          if (msg.startsWith('DOWNLOAD_URL: ')) {
            final url = msg.substring(14);
            _downloadFileToPublicFolder(url);
            return;
          }

          if (msg.startsWith('FILE_PICKER:')) {
            final isMultiple = msg.contains('multiple');
            await _handleFilePicker(isMultiple);
            return;
          }

          _handleBlobContent(msg);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) async {
            setState(() {
              isLoading = true;
              hasError = false; // ⭐ reset error
            });
            await _injectInterceptors();
          },

          onPageFinished: (_) async => _updateHeight(),

          // ⭐ NETWORK ERRORS
          onWebResourceError: (_) {
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },

          // ⭐ HTTP ERRORS (404/500)
          onHttpError: (_) {
            setState(() {
              isLoading = false;
              hasError = true;
            });
          },

          onNavigationRequest: (request) async {
            if (request.url.toLowerCase().endsWith('.pdf')) {
              final Uri url = Uri.parse(request.url);
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  /// ⭐ ERROR UI (NEW)
  Widget _buildErrorUI() {
    return Container(
      height: 300,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, size: 60, color: Colors.white70),
          const SizedBox(height: 16),
          const Text("Unable to load page", style: TextStyle(fontSize: 18, color: Colors.white)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              setState(() {
                hasError = false;
                isLoading = true;
              });
              _controller.loadRequest(Uri.parse(widget.url));
            },
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// REST OF YOUR CODE — UNCHANGED
  /// =========================
  /// =========================
  /// HANDLE FILE PICKER FROM JS
  /// =========================
  Future<void> _handleFilePicker(bool isMultiple) async {
    final ImagePicker picker = ImagePicker();

    if (isMultiple) {
      // Multiple images select
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isEmpty) return;

      // Convert each image to base64 and send to JavaScript
      for (final image in images) {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);
        final fileName = image.name;
        final mimeType = image.mimeType ?? 'image/jpeg';

        // Inject file into the input field using JavaScript
        await _controller.runJavaScript('''
          (function() {
            const input = document.querySelector('input[type="file"]');
            if (!input) return;
            
            // Create a File object from base64
            const byteCharacters = atob("$base64");
            const byteNumbers = new Array(byteCharacters.length);
            for (let i = 0; i < byteCharacters.length; i++) {
              byteNumbers[i] = byteCharacters.charCodeAt(i);
            }
            const byteArray = new Uint8Array(byteNumbers);
            const file = new File([byteArray], "$fileName", { type: "$mimeType" });
            
            // Use DataTransfer to set files (supports multiple)
            const dataTransfer = new DataTransfer();
            // Get existing files if any (for multiple selection)
            if (input.files) {
              for (let i = 0; i < input.files.length; i++) {
                dataTransfer.items.add(input.files[i]);
              }
            }
            dataTransfer.items.add(file);
            input.files = dataTransfer.files;
            
            // Trigger change event
            input.dispatchEvent(new Event('change', { bubbles: true }));
          })();
        ''');
        // Small delay to avoid race conditions
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      // Single image select
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final fileName = image.name;
      final mimeType = image.mimeType ?? 'image/jpeg';

      await _controller.runJavaScript('''
        (function() {
          const input = document.querySelector('input[type="file"]');
          if (!input) return;
          
          const byteCharacters = atob("$base64");
          const byteNumbers = new Array(byteCharacters.length);
          for (let i = 0; i < byteCharacters.length; i++) {
            byteNumbers[i] = byteCharacters.charCodeAt(i);
          }
          const byteArray = new Uint8Array(byteNumbers);
          const file = new File([byteArray], "$fileName", { type: "$mimeType" });
          
          const dataTransfer = new DataTransfer();
          dataTransfer.items.add(file);
          input.files = dataTransfer.files;
          
          input.dispatchEvent(new Event('change', { bubbles: true }));
        })();
      ''');
    }
  }

  /// =========================
  /// JS INTERCEPTORS (UPDATED)
  /// =========================
  Future<void> _injectInterceptors() async {
    await _controller.runJavaScript('''
(function () {
  if (window.__interceptorsInjected) return;
  window.__interceptorsInjected = true;

  function log(m) { if (window.BlobPDF) BlobPDF.postMessage('LOG: ' + m); }

  // ========== BLOB INTERCEPT (unchanged) ==========
  document.addEventListener('click', function(e) {
    const link = e.target.closest('a');
    if (link && link.href && link.href.startsWith('blob:')) {
      e.preventDefault();
      fetch(link.href).then(r => r.blob()).then(b => {
        const reader = new FileReader();
        reader.onloadend = () => BlobPDF.postMessage(reader.result.split(',')[1]);
        reader.readAsDataURL(b);
      });
    }
  }, true);

  // ========== COPY LINK INTERCEPT (unchanged) ==========
  let lastUrl = '';
  let lastTime = 0;

  function handleCopyText(text) {
    const now = Date.now();
    const trimmed = text ? text.toString().trim() : '';
    if (trimmed.startsWith('http')) {
      if (trimmed === lastUrl && (now - lastTime) < 2000) return true;
      lastUrl = trimmed;
      lastTime = now;
      if (window.BlobPDF) {
        BlobPDF.postMessage('DOWNLOAD_URL: ' + trimmed);
      }
      return true;
    }
    return false;
  }

  if (navigator.clipboard) {
    const originalWrite = navigator.clipboard.writeText;
    navigator.clipboard.writeText = function(text) {
      if (handleCopyText(text)) return Promise.resolve();
      return originalWrite.apply(navigator.clipboard, arguments);
    };
  }

  document.addEventListener('copy', function(e) {
    let text = window.getSelection().toString();
    if (!text && e.clipboardData) {
      text = e.clipboardData.getData('text');
    }
    handleCopyText(text);
  });

  // ========== NEW: FILE INPUT INTERCEPT ==========
  document.addEventListener('click', function(e) {
    const input = e.target.closest('input[type="file"]');
    if (input) {
      e.preventDefault();  // Stop default file dialog
      const isMultiple = input.hasAttribute('multiple');
      if (window.BlobPDF) {
        BlobPDF.postMessage('FILE_PICKER:' + (isMultiple ? 'multiple' : 'single'));
      }
    }
  }, true);

  // ========== HEIGHT DETECTION (unchanged) ==========
  function sendHeight() {
    try {
      let maxBottom = 0;
      const elements = document.querySelectorAll('body *');
      for (let el of elements) {
        const rect = el.getBoundingClientRect();
        if (rect.width === 0 || rect.height === 0) continue;
        const style = window.getComputedStyle(el);
        if (style.display === 'none' || style.visibility === 'hidden' || parseFloat(style.opacity) === 0) continue;
        const bottom = rect.bottom + window.scrollY;
        if (bottom > maxBottom) maxBottom = bottom;
      }
      if (window.BlobPDF) {
        BlobPDF.postMessage('HEIGHT: ' + Math.ceil(maxBottom));
      }
    } catch(e) {}
  }

  new ResizeObserver(sendHeight).observe(document.body);
  new MutationObserver(sendHeight).observe(document.body, { childList: true, subtree: true });
  window.addEventListener('scroll', sendHeight);
  sendHeight();
})();
''');
  }

  /// =========================
  /// REST OF FILE — UNCHANGED
  /// =========================

  Future<void> _handleBlobContent(String base64) async {
    try {
      final bytes = base64Decode(base64);
      final dir = Platform.isAndroid ? await getTemporaryDirectory() : await getApplicationDocumentsDirectory();

      final file = File('${dir.path}/Reporte_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(bytes);
      await OpenFile.open(file.path);
    } catch (e) {
      log('Blob error: $e');
    }
  }

  Future<void> _downloadFileToPublicFolder(String url) async {
    final now = DateTime.now();

    if (_lastDownloadedUrl == url && _lastDownloadTime != null && now.difference(_lastDownloadTime!).inSeconds < 2) {
      return;
    }

    _lastDownloadedUrl = url;
    _lastDownloadTime = now;

    try {
      final dio = Dio();
      String savePath = '';

      if (Platform.isAndroid) {
        savePath = '/storage/emulated/0/Download/Reporte_UltraScan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      } else {
        final dir = await getApplicationDocumentsDirectory();
        savePath = '${dir.path}/Reporte_UltraScan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      }

      await dio.download(url, savePath);
      await OpenFile.open(savePath);
    } catch (e) {
      _lastDownloadedUrl = null;
      log('Download failed: $e');
    }
  }

  Future<void> _updateHeight() async {
    try {
      final res = await _controller.runJavaScriptReturningResult('Math.max(document.body.scrollHeight, document.documentElement.scrollHeight)');
      final h = double.tryParse(res.toString().replaceAll(RegExp(r'[^0-9.]'), ''));

      if (mounted && h != null) {
        setState(() {
          contentHeight = h.clamp(150, 5500);
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
        if (!hasError) // ⭐ hide webview on error
          SizedBox(
            height: contentHeight,
            child: WebViewWidget(controller: _controller),
          )
        else
          _buildErrorUI(),

        if (isLoading && !hasError)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator(color: AppColors.goldColor)),
          ),
      ],
    );
  }
}
