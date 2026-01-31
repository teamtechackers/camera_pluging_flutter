// ignore_for_file: eol_at_end_of_file, document_ignores
import 'dart:io';
import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../../routes/app_pages.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/widgets/custom_snackbar.dart';
import '../../../core/services/analysis_service.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:usb_camera_plugin/usb_camera_plugin.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class ScanController extends GetxController with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final AnalysisService _analysisService = Get.put(AnalysisService());

  final Rx<File?> selectedImage = Rx<File?>(null);
  final RxBool isLoading = false.obs;
  final RxBool isFromUsb = false.obs;

  static const String _macAddressKey = 'saved_mac_address';
  final _usbCameraPlugin = UsbCameraPlugin();

  Timer? _cameraPollTimer;

  @override
  void onInit() {
    super.onInit();
    _ensureMacAddress();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void onClose() {
    _cameraPollTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When app resumes (comes back from camera) check for captured image
    if (state == AppLifecycleState.resumed) {
      // Check immediately when app resumes
      _checkForCapturedImage();
    }
  }

  Future<void> _ensureMacAddress() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_macAddressKey);
    if (mac == null || mac.isEmpty) {
      showCustomSnackbar(
        title: '',
        message: 'activate_device_before_scanning',
        type: SnackbarType.warning,
      );
      Get.toNamed(AppPages.settingPage);
    }
  }

  Future<bool> requestGalleryPermission() async {
    if (Platform.isAndroid) {
      try {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        Permission permission;
        if (sdkInt >= 33) {
          permission = Permission.photos;
        } else {
          permission = Permission.storage;
        }

        var status = await permission.status;
        
        if (status.isGranted) {
          return true;
        }

        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }

        // Specifically request if denied or not determined
        status = await permission.request();
        
        if (status.isPermanentlyDenied) {
          await openAppSettings();
          return false;
        }

        return status.isGranted;
      } catch (e) {
        log('Failed to get gallery permission: $e');
        return false;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.request();
      return status.isGranted;
    }

    return true;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isPermanentlyDenied) {
      await openAppSettings();
    }
    return status.isGranted;
  }

  Future<void> pickImageFromGallery() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 50));

      final hasPermission = await requestGalleryPermission();
      if (!hasPermission) {
        showCustomSnackbar(
          title: '',
          message: 'grant_photo_permission',
          type: SnackbarType.warning,
        );
        return;
      }

      // Add delay after permission is granted
      await Future.delayed(const Duration(milliseconds: 100));

      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        File originalFile = File(image.path);
        // Harmonize image before showing
        selectedImage.value = await _harmonizeImage(originalFile);
        isFromUsb.value = false;
      }
    } catch (e) {
      log('Failed to select image: $e');
      showCustomSnackbar(
        title: '',
        message: 'failed_select_image',
        type: SnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImageFromCamera() async {
    try {
      isLoading.value = true;
      await Future.delayed(const Duration(milliseconds: 50));

      final hasPermission = await requestCameraPermission();
      if (!hasPermission) {
        showCustomSnackbar(
          title: '',
          message: 'grant_camera_permission',
          type: SnackbarType.warning,
        );
        return;
      }

      final image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        File originalFile = File(image.path);
        // Harmonize image before showing
        selectedImage.value = await _harmonizeImage(originalFile);
        isFromUsb.value = false;
        log('Photo taken and harmonized successfully');
      }
    } catch (e) {
      log('Failed to take photo: $e');
      showCustomSnackbar(
        title: '',
        message: 'failed_take_photo',
        type: SnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> pickImage() async {
    final prefs = await SharedPreferences.getInstance();
    final mac = prefs.getString(_macAddressKey);
    if (mac == null || mac.isEmpty) {
      showCustomSnackbar(
        title: 'Activation required',
        message: 'Please activate d evice in settings before scanning',
        type: SnackbarType.warning,
      );
      Get.toNamed(AppPages.settingPage);
      return;
    }

    // Open USB camera and start a periodic non-blocking poll for captured image
    await _openCamera();
  }

  Future<void> _checkForCapturedImage() async {
    try {
      if (kDebugMode) {
        print('🔍 Checking for captured image...');
      }

      final imagePath = await _usbCameraPlugin.getLastCapturedImage();

      if (kDebugMode) {
        print('📸 Image path received: $imagePath');
      }

      if (imagePath != null && imagePath.isNotEmpty) {
        final imageFile = File(imagePath);

        if (await imageFile.exists()) {
          if (kDebugMode) {
            print('✅ Image file exists: $imagePath');
            print('✅ File size: ${await imageFile.length()} bytes');
          }

          // Harmonize USB image before showing
          selectedImage.value = await _harmonizeImage(imageFile);
          isFromUsb.value = true;

          if (kDebugMode) {
            print('✅ Image set to selectedImage - Ready for analysis');
          }

          // stop periodic polling if running
          _cameraPollTimer?.cancel();
        } else {
          if (kDebugMode) {
            print('❌ Image file does not exist: $imagePath');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ No image path found');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error getting captured image: $e');
      }
    }
  }

  Future<void> _initPlatformState() async {
    // Optional: we avoid forcing plugin init that might auto-open camera on some devices
    try {
      final v = await _usbCameraPlugin.getPlatformVersion();
      if (kDebugMode) print('UsbCameraPlugin version: $v');
    } catch (e) {
      if (kDebugMode) print('Usb camera init error: $e');
    }
  }

  Future<void> _openCamera() async {
    try {
      await _usbCameraPlugin.openCamera();

      // Start a non-blocking periodic timer to check for captured image.
      // This won't block the UI and will stop as soon as image is found or after timeout.
      _cameraPollTimer?.cancel();
      int attempts = 0;
      const maxAttempts =
          60; // 60 * 500ms = 30 seconds max (user needs time to capture)
      _cameraPollTimer = Timer.periodic(const Duration(milliseconds: 500), (
        timer,
      ) async {
        attempts++;
        await _checkForCapturedImage();

        if (selectedImage.value != null || attempts >= maxAttempts) {
          timer.cancel();
          if (kDebugMode) {
            if (selectedImage.value != null) {
              print('✅ Image captured and loaded after $attempts attempts.');
            } else {
              print(
                '⚠️ No image found after $attempts attempts — stopping poll.',
              );
            }
          }
        }
      });

      // Also check immediately after a short delay (in case image is already available)
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (selectedImage.value == null) {
          _checkForCapturedImage();
        }
      });
    } catch (e) {
      if (kDebugMode) print('Error opening camera: $e');
      showCustomSnackbar(
        title: '',
        message: 'failed_open_camera',
        type: SnackbarType.error,
      );
    }
  }

  void showImageSourceDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose how you want to select an image'),
        actions: [
          TextButton(
            onPressed: () {
              Get.back();
              pickImageFromCamera();
            },
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              pickImageFromGallery();
            },
            child: const Text('Gallery'),
          ),
        ],
      ),
    );
  }

  void clearSelectedImage() {
    selectedImage.value = null;
    isFromUsb.value = false;
  }

  Future<void> analyzeSelectedImage() async {
    if (selectedImage.value == null) {
      log('Please select an image first');
      return;
    }

    try {
      isLoading.value = true;
      // Give framework a moment to show the loading indicator
      await Future.delayed(const Duration(milliseconds: 50));

      // Check if analysis service is ready
      if (_analysisService.isAnalyzerReady.isFalse) {
        showCustomSnackbar(
          title: 'Analyzer Not Ready',
          message: 'The analysis engine is still loading. Please wait.',
          type: SnackbarType.warning,
        );
        return;
      }

      // Rotate image according to EXIF (this uses native plugin)
      File fixedFile;
      try {
        fixedFile = await FlutterExifRotation.rotateImage(
          path: selectedImage.value!.path,
        );
      } catch (e) {
        // If rotation fails, fall back to original
        log('Exif rotation failed, using original image: $e');
        fixedFile = selectedImage.value!;
      }

      // Call analysis service (this may be network or heavy)
      final analysisResponse = await _analysisService.analyzeImage(
        imageFile: File(fixedFile.path),
      );

      // Navigate to results screen
      Get.toNamed(AppPages.resultPage, arguments: analysisResponse);

      // Clear selected image after navigation (optional)
      selectedImage.value = null;
    } catch (e) {
      log('Failed to analyze image: $e');
      showCustomSnackbar(
        title: '',
        message: 'failed_analyze_image',
        type: SnackbarType.error,
      );
    } finally {
      isLoading.value = false;
    }
  }

  Future<File> _harmonizeImage(File originalFile) async {
    try {
      // 1. Load image
      final bytes = await originalFile.readAsBytes();
      img.Image? image = img.decodeImage(bytes);
      if (image == null) return originalFile;

      // 2. Analyze Skin Tone (Logic from JS)
      double rTotal = 0, gTotal = 0, bTotal = 0;
      int count = 0;

      // Sample pixels for speed (every 4th pixel)
      for (int y = 0; y < image.height; y += 4) {
        for (int x = 0; x < image.width; x += 4) {
          int pixel = image.getPixel(x, y);
          int r = img.getRed(pixel);
          int g = img.getGreen(pixel);
          int b = img.getBlue(pixel);

          double luma = 0.299 * r + 0.587 * g + 0.114 * b;

          // Exclude hair and extreme highlights
          if (luma > 60 && luma < 230) {
            if (r > g && r > b) {
              rTotal += r;
              gTotal += g;
              bTotal += b;
              count++;
            }
          }
        }
      }

      int baseR = 200, baseG = 180, baseB = 160;
      if (count > 0) {
        baseR = (rTotal / count).round();
        baseG = (gTotal / count).round();
        baseB = (bTotal / count).round();
      }
      double baseLuma = 0.299 * baseR + 0.587 * baseG + 0.114 * baseB;

      // 3. Apply Correction (Logic from JS)
      const double strength = 0.5;
      for (int y = 0; y < image.height; y++) {
        for (int x = 0; x < image.width; x++) {
          int pixel = image.getPixel(x, y);
          int r = img.getRed(pixel);
          int g = img.getGreen(pixel);
          int b = img.getBlue(pixel);

          double pixelLuma = 0.299 * r + 0.587 * g + 0.114 * b;

          // Selective correction for highlights relative to base skin tone
          if (pixelLuma > baseLuma) {
            int newR = (r + (baseR - r) * strength).round();
            int newG = (g + (baseG - g) * strength).round();
            int newB = (b + (baseB - b) * strength).round();
            image.setPixel(x, y, img.getColor(newR, newG, newB, img.getAlpha(pixel)));
          }
        }
      }

      // 4. Save to temp file
      final tempDir = await getTemporaryDirectory();
      final harmonizedFile = File(
        '${tempDir.path}/harmonized_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await harmonizedFile.writeAsBytes(img.encodeJpg(image, quality: 90));

      return harmonizedFile;
    } catch (e) {
      log('Image harmonization failed: $e');
      return originalFile;
    }
  }
}
