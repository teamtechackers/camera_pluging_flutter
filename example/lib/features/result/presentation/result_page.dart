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
              SizedBox(
                height: 200,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: GestureDetector(
                      onTap: () {
                        // Fullscreen dialog pe image show karna
                        showDialog(
                          context: Get.context!,
                          builder: (_) => Dialog(
                            backgroundColor: Colors.transparent,
                            insetPadding: EdgeInsets.all(0),
                            child: InteractiveViewer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(0),
                                child: Image.memory(base64Decode(controller.analysisResponse.analysis!.annotatedImage!.split(',').last), fit: BoxFit.contain),
                              ),
                            ),
                          ),
                        );
                      },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.memory(base64Decode(controller.analysisResponse.analysis!.annotatedImage!.split(',').last), fit: BoxFit.cover),
                      ),
                    ),
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
  bool hasError = false;
  bool _showPermanentError = false;
  String? errorMessage;
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
          print("MSGGGGG ${msg}");

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
            final isCamera = msg.endsWith(':camera');
            await _handleFilePicker(isMultiple, isCamera);
            return;
          }
          if (msg.startsWith('DOWNLOAD_URL_SS:')) {
            final url = msg.substring(14);
            _downloadFileToPublicFolder(url);
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
              hasError = false;
            });
            await _injectInterceptors();
          },

          onPageFinished: (_) async => _updateHeight(),

          onWebResourceError: (WebResourceError error) {
            log("WebResourceError: ${error.description}, code: ${error.errorCode}, isMainFrame: ${error.isForMainFrame}");

            // Handle ERR_FILE_NOT_FOUND or any other main resource error immediately
            final bool isFatalError = error.isForMainFrame ?? true;
            final bool isFileNotFound = error.description.contains('ERR_FILE_NOT_FOUND') || error.errorCode == -6;

            if (isFatalError || isFileNotFound) {
              setState(() {
                hasError = true;
                _showPermanentError = true;
                isLoading = false;
                errorMessage = error.description;
              });
              return;
            }

            setState(() {
              hasError = true;
              errorMessage = error.description;
            });

            Future.delayed(const Duration(seconds: 2), () {
              if (mounted && hasError) {
                setState(() {
                  _showPermanentError = true;
                });
              }
            });
          },

          onHttpError: (error) {
            log("onHttpError: ${error.response?.statusCode}, url: ${error.response?.uri}");
            final failingUrl = error.response?.uri.toString();
            if (failingUrl == null || !failingUrl.startsWith(widget.url)) return;

            setState(() {
              isLoading = false;
              hasError = true;
              _showPermanentError = true; // Show error for main URL load failure
              errorMessage = "HTTP Error: ${error.response?.statusCode ?? 'Unknown'}";
            });
          },

          onNavigationRequest: (request) async {
            if (request.url.startsWith('blob:')) {
              log('❌ Blocked Flutter from navigating to a blob URL to prevent crash: ${request.url}');
              
              // Tell Javascript to fetch the specific Blob URL it just tried to navigate to and send to Flutter
              _controller.runJavaScript('''
                (function() {
                  const blobUrl = "${request.url}";
                  fetch(blobUrl).then(r => r.blob()).then(blob => {
                    const reader = new FileReader();
                    reader.onloadend = () => {
                      const base64 = reader.result.split(',')[1];
                      if (window.BlobPDF) window.BlobPDF.postMessage(base64);
                    };
                    reader.readAsDataURL(blob);
                  }).catch(e => console.log('Failed to fetch intercepted blob: ', e));
                })();
              ''');

              return NavigationDecision.prevent;
            }
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
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
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

  Future<void> _handleFilePicker(bool isMultiple, bool isCamera) async {
    final ImagePicker picker = ImagePicker();

    if (isMultiple) {
      final List<XFile> images = await picker.pickMultiImage();
      if (images.isEmpty) return;

      for (final image in images) {
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
            if (input.files) {
              for (let i = 0; i < input.files.length; i++) {
                dataTransfer.items.add(input.files[i]);
              }
            }
            dataTransfer.items.add(file);
            input.files = dataTransfer.files;
            
            input.dispatchEvent(new Event('change', { bubbles: true }));
          })();
        ''');
        await Future.delayed(const Duration(milliseconds: 100));
      }
    } else {
      final ImageSource source = isCamera ? ImageSource.camera : ImageSource.gallery;

      final XFile? image = await picker.pickImage(source: source);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64 = base64Encode(bytes);
      final fileName = image.name;
      final mimeType = image.mimeType ?? 'image/jpeg';

      await _controller.runJavaScript('''
        (function() {
          let input;
          if (${isCamera ? 'true' : 'false'}) {
            input = document.querySelector('input[type="file"][capture="environment"]') || document.querySelector('input[type="file"][capture="camera"]');
          } else {
            input = document.querySelector('input[type="file"]:not([capture])'); 
          }
          if (!input) { // fallback
              input = document.querySelector('input[type="file"]'); 
          }
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

  Future<void> _injectInterceptors() async {
    await _controller.runJavaScript('''
(function () {
  if (window.__interceptorsInjected) return;
  window.__interceptorsInjected = true;

  // Forward console.log to Flutter
  const originalConsoleLog = console.log;
  console.log = function(...args) {
    originalConsoleLog.apply(console, args);
    if (window.BlobPDF) {
      window.BlobPDF.postMessage('LOG: ' + args.join(' '));
    }
  };

  // ========== BLOB STORAGE ==========
  const blobMap = new Map();

  const originalCreateObjectURL = window.URL.createObjectURL;
  window.URL.createObjectURL = function(blob) {
    const url = originalCreateObjectURL.call(this, blob);
    blobMap.set(url, blob);
    console.log('📦 Blob created:', url);
    return url;
  };

  const originalRevokeObjectURL = window.URL.revokeObjectURL;
  window.URL.revokeObjectURL = function(url) {
    blobMap.delete(url);
    originalRevokeObjectURL.call(this, url);
  };

  // ========== INTERCEPT ANCHOR CLICK ==========
  const anchorProtoClick = HTMLAnchorElement.prototype.click;
  HTMLAnchorElement.prototype.click = function() {
    if (this.href && this.href.startsWith('blob:')) {
      console.log('📥 Anchor click with blob URL:', this.href);
      const blob = blobMap.get(this.href);
      if (blob) {
        sendBlobToFlutter(blob);
        // We MUST return and not call the original click to prevent WebView from trying to load the blob
        // which causes ERR_UNKNOWN_URL_SCHEME and crashes the page to "Webpage not available"
        return;
      } else {
        // If blob isn't in our map, try to fetch it and send it
        fetch(this.href).then(r => r.blob()).then(b => sendBlobToFlutter(b));
        return;
      }
    }
    return anchorProtoClick.call(this);
  };

  // ========== INTERCEPT LOCATION CHANGES ==========
  // location.href setter
  const desc = Object.getOwnPropertyDescriptor(window, 'location');
  if (desc && desc.configurable) {
    Object.defineProperty(window, 'location', {
      get: function() { return desc.get.call(this); },
      set: function(val) {
        if (typeof val === 'string' && val.startsWith('blob:')) {
          console.log('📍 location.href set to blob:', val);
          const blob = blobMap.get(val);
          if (blob) {
            sendBlobToFlutter(blob);
            return;
          } else {
             fetch(val).then(r => r.blob()).then(b => sendBlobToFlutter(b));
             return;
          }
        }
        desc.set.call(this, val);
      }
    });
  }

  // location.replace
  const originalReplace = window.location.replace;
  window.location.replace = function(url) {
    if (url && typeof url === 'string' && url.startsWith('blob:')) {
      console.log('🔄 location.replace with blob:', url);
      const blob = blobMap.get(url);
      if (blob) {
        sendBlobToFlutter(blob);
        return;
      } else {
         fetch(url).then(r => r.blob()).then(b => sendBlobToFlutter(b));
         return;
      }
    }
    return originalReplace.call(this, url);
  };

  // location.assign
  const originalAssign = window.location.assign;
  window.location.assign = function(url) {
    if (url && typeof url === 'string' && url.startsWith('blob:')) {
      console.log('🔀 location.assign with blob:', url);
      const blob = blobMap.get(url);
      if (blob) {
        sendBlobToFlutter(blob);
        return;
      } else {
         fetch(url).then(r => r.blob()).then(b => sendBlobToFlutter(b));
         return;
      }
    }
    return originalAssign.call(this, url);
  };


  // ========== INTERCEPT WINDOW.OPEN ==========
  const originalWindowOpen = window.open;
  window.open = function(url, name, features) {
    if (url && typeof url === 'string' && url.startsWith('blob:')) {
      console.log('🪟 window.open with blob URL:', url);
      const blob = blobMap.get(url);
      if (blob) {
        sendBlobToFlutter(blob);
        return null;
      } else {
         fetch(url).then(r => r.blob()).then(b => sendBlobToFlutter(b));
         return null;
      }
    }
    return originalWindowOpen.call(this, url, name, features);
  };

  // ========== INTERCEPT msSaveOrOpenBlob (Edge legacy) ==========
  if (window.navigator && window.navigator.msSaveOrOpenBlob) {
    const originalMsSave = window.navigator.msSaveOrOpenBlob;
    window.navigator.msSaveOrOpenBlob = function(blob, filename) {
      console.log('📁 msSaveOrOpenBlob called', filename);
      sendBlobToFlutter(blob);
      // Optionally call original? Usually we want to prevent default.
      // return originalMsSave.call(this, blob, filename);
    };
  }

  // ========== HELPER: send blob to Flutter ==========
  function sendBlobToFlutter(blob) {
    if (!blob) return;
    console.log('Got Blob to send, size:', blob.size, 'type:', blob.type);
    const reader = new FileReader();
    reader.onloadend = () => {
      if (reader.error) {
        console.error('FileReader error: ', reader.error);
        return;
      }
      const base64 = reader.result.split(',')[1];
      if (window.BlobPDF) {
        BlobPDF.postMessage(base64);
      }
    };
    reader.readAsDataURL(blob);
  }

  // ========== INTERCEPT CLICK ON BLOB LINKS (already present, but keep) ==========
  document.addEventListener('click', function(e) {
    const link = e.target.closest('a');
    if (link && link.href && link.href.startsWith('blob:')) {
      e.preventDefault();
      console.log('📦 Blob link clicked (intercepted):', link.href);
      fetch(link.href).then(r => r.blob()).then(b => sendBlobToFlutter(b));
    }
  }, true);

  // ========== INTERCEPT FETCH FOR PDF RESPONSES ==========
  const originalFetch = window.fetch;
  window.fetch = function(...args) {
    return originalFetch.apply(this, args).then(async response => {
      // Check if this is a PDF request (optional)
      const url = args[0];
      if (typeof url === 'string' && url.includes('.pdf')) {
        const cloned = response.clone();
        const blob = await cloned.blob();
        if (blob.type === 'application/pdf') {
          console.log('📄 Fetch intercepted PDF:', url);
          sendBlobToFlutter(blob);
        }
      }
      return response;
    });
  };

  // ========== INTERCEPT XMLHttpRequest FOR PDF RESPONSES ==========
  const XHROpen = XMLHttpRequest.prototype.open;
  const XHRSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function(method, url, ...rest) {
    this._url = url;
    return XHROpen.call(this, method, url, ...rest);
  };
  XMLHttpRequest.prototype.send = function(...args) {
    this.addEventListener('load', function() {
      if (this._url.includes('.pdf') && this.responseType === 'blob' && this.response) {
        console.log('📄 XHR intercepted PDF:', this._url);
        sendBlobToFlutter(this.response);
      }
    });
    return XHRSend.call(this, ...args);
  };

  // ========== REMAINING INTERCEPTORS (copy, file input, download button, height) ==========
  // ... (paste your existing copy, file input, download button, and height code here)
  // Make sure to include everything after this point exactly as you had it.
  // I'll include a placeholder – you need to copy the rest from your current code.

  // ========== COPY LINK INTERCEPT ==========
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

  // ========== FILE INPUT INTERCEPT ==========
  document.addEventListener('click', function(e) {
    const input = e.target.closest('input[type="file"]');
    if (input) {
      e.preventDefault();
      const isMultiple = input.hasAttribute('multiple');
      const isCamera = input.getAttribute('capture') === 'environment' || input.getAttribute('capture') === 'camera';
      if (window.BlobPDF) {
        BlobPDF.postMessage('FILE_PICKER:' + (isMultiple ? 'multiple' : 'single') + ':' + (isCamera ? 'camera' : 'gallery'));
      }
    }
  }, true);

  // ========== jsPDF INTERCEPT ==========
  if (typeof window !== 'undefined') {
    let checkJsPdf = setInterval(() => {
      if (window.jsPDF || (window.jspdf && window.jspdf.jsPDF)) {
        clearInterval(checkJsPdf);
        const jsPDFClass = window.jsPDF || window.jspdf.jsPDF;
        if (jsPDFClass && jsPDFClass.prototype.save) {
          const originalSave = jsPDFClass.prototype.save;
          jsPDFClass.prototype.save = function(filename, options) {
            console.log('📄 jsPDF.save intercepted for:', filename);
            try {
              const base64String = this.output('datauristring');
              if (window.BlobPDF) {
                // Remove the "data:application/pdf;base64," part
                const cleanBase64 = base64String.split(',')[1];
                window.BlobPDF.postMessage(cleanBase64);
              }
            } catch (err) {
              console.error('jsPDF intercept failed:', err);
              return originalSave.call(this, filename, options);
            }
          };
        }
      }
    }, 500);
  }

  // ========== DOWNLOAD BUTTON INTERCEPT ==========
  document.body.addEventListener('click', function(e) {
    console.log('🔧 Download interceptor RUNNING, phase =', e.eventPhase);
    const btn = e.target.closest(
      '#downloadBtn, button[data-download-url], button[data-url], ' +
      'button[data-href], a.download, button.download, ' +
      'a[download], #screenshotBtn, .download-btn, .screenshot-btn, ' +
      '[data-download-url], [data-url]'
    );

    if (btn) {
      e.preventDefault();
      console.log('🔥 Download button matched:', btn, 'tagName=' + btn.tagName, 'id=' + btn.id);
      let link = btn.getAttribute('data-download-url') ||
                 btn.getAttribute('data-url') ||
                 btn.getAttribute('data-href') ||
                 btn.getAttribute('href') ||
                 btn.dataset.url;
      if (link) {
        const absoluteUrl = new URL(link, window.location.href).href;
        console.log('📎 Found link:', absoluteUrl);
        if (window.BlobPDF) {
          BlobPDF.postMessage('DOWNLOAD_URL_SS: ' + absoluteUrl);
        }
      } else {
        console.log('🔍 No direct link – waiting for blob');
      }
    } else {
      console.log('❌ No button matched for this click. Target =', e.target);
    }
  }, true);

  // ========== HEIGHT DETECTION ==========
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

  Future<void> _handleBlobContent(String base64) async {
    try {
      // Sometimes base64 strings from standard JS output need padding or have "data:application/pdf;base64," prefix
      String cleanBase64 = base64;
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }
      
      final bytes = base64Decode(cleanBase64.replaceAll('\n', '').replaceAll('\r', ''));
      
      final dir = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationDocumentsDirectory();
      final targetDir = dir ?? await getTemporaryDirectory();

      final file = File('${targetDir.path}/Reporte_${DateTime.now().millisecondsSinceEpoch}.pdf');
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
        // Using app-specific directory to avoid storage permission issues
        final dir = await getExternalStorageDirectory();
        final targetDir = dir ?? await getTemporaryDirectory();
        savePath = '${targetDir.path}/Reporte_UltraScan_${DateTime.now().millisecondsSinceEpoch}.pdf';
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
        if (!_showPermanentError)
          SizedBox(
            height: contentHeight,
            child: WebViewWidget(controller: _controller),
          )
        else
          _buildErrorUI(),
        if (isLoading && !_showPermanentError)
          const Positioned.fill(
            child: Center(child: CircularProgressIndicator(color: AppColors.goldColor)),
          ),
      ],
    );
  }
}
