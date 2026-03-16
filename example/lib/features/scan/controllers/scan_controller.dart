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
import '../../../core/utils/image_upload_utils.dart';

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

        PermissionStatus status;
        if (sdkInt >= 33) {
          status = await Permission.photos.status;
          if (status.isDenied) {
            final result = await Permission.photos.request();
            if (result.isPermanentlyDenied) {
              // Open app settings if permanently denied
              await openAppSettings();
              return false;
            }
            return result.isGranted;
          }
          if (status.isPermanentlyDenied) {
            // Open app settings if permanently denied
            await openAppSettings();
            return false;
          }
        } else {
          status = await Permission.storage.status;
          if (status.isDenied) {
            final result = await Permission.storage.request();
            if (result.isPermanentlyDenied) {
              // Open app settings if permanently denied
              await openAppSettings();
              return false;
            }
            return result.isGranted;
          }
          if (status.isPermanentlyDenied) {
            // Open app settings if permanently denied
            await openAppSettings();
            return false;
          }
        }
        return status.isGranted;
      } catch (e) {
        log('Failed to get gallery permission: $e');
        return false;
      }
    } else if (Platform.isIOS) {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        final result = await Permission.photos.request();
        return result.isGranted || result.isLimited;
      }
      return status.isGranted || status.isLimited;
    }

    return true;
  }

  Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isDenied) {
      final result = await Permission.camera.request();
      return result.isGranted;
    }
    return status.isGranted;
  }

  Future<void> pickImageFromGallery() async {
    try {
      isLoading.value = true;
      log('Starting gallery image selection...');
      // Increased delay to ensure UI is ready for the native transition
      await Future.delayed(const Duration(milliseconds: 200));

      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;
        log('Android SDK Version: $sdkInt');

        // For Android 13+, image_picker usually handles things without manual photos permission
        // if using modern system picker. We'll still check but let it proceed if it fails.
        if (sdkInt < 33) {
          final status = await Permission.storage.status;
          if (status.isDenied) {
            log('Storage permission denied, requesting...');
            final result = await Permission.storage.request();
            if (result.isPermanentlyDenied) {
              log('Storage permission permanently denied');
              openAppSettings();
              return;
            }
          }
        }
      }

      log('Launching ImagePicker...');
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        log('Image selected: ${image.path}');
        selectedImage.value = File(image.path);
        isFromUsb.value = false;
      } else {
        log('No image selected (user cancelled)');
      }
    } catch (e) {
      log('Failed to select image from gallery: $e');
      showCustomSnackbar(
        title: 'Selection Error',
        message: 'Error: ${e.toString()}',
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
        selectedImage.value = File(image.path);
        isFromUsb.value = false;
        log('Photo taken successfully');
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

    if (Platform.isAndroid) {
      // Open USB camera and start a periodic non-blocking poll for captured image
      await _openCamera();
    } else {
      showCustomSnackbar(
        title: 'Not Supported',
        message: 'USB Camera is only supported on Android devices.',
        type: SnackbarType.warning,
      );
    }
  }

  Future<void> _checkForCapturedImage() async {
    if (!Platform.isAndroid) return;
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

          selectedImage.value = imageFile;
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
    if (!Platform.isAndroid) return;
    // Optional: we avoid forcing plugin init that might auto-open camera on some devices
    try {
      final v = await _usbCameraPlugin.getPlatformVersion();
      if (kDebugMode) print('UsbCameraPlugin version: $v');
    } catch (e) {
      if (kDebugMode) print('Usb camera init error: $e');
    }
  }

  Future<void> _openCamera() async {
    if (!Platform.isAndroid) return;
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
        if (Platform.isAndroid) {
          fixedFile = await FlutterExifRotation.rotateImage(
            path: selectedImage.value!.path,
          );
        } else {
          // Skip rotation on iOS for now to avoid potential native crashes
          fixedFile = selectedImage.value!;
        }
      } catch (e) {
        // If rotation fails, fall back to original
        log('Exif rotation failed, using original image: $e');
        fixedFile = selectedImage.value!;
      }

      // Call analysis service (this may be network or heavy)
      final analysisResponse = await _analysisService.analyzeImage(
        imageFile: File(fixedFile.path),
      );

      // Upload annotated image to server before navigation
      try {
        if (analysisResponse.analysis?.annotatedImage != null) {
          await ImageUploadUtils.uploadAnnotatedImageToServer(
            analysisResponse.analysis!.annotatedImage!,
          );
        }
      } catch (e) {
        log('⚠️ Image upload failed but proceeding to result: $e');
      }

      // Navigate to results screen
      await Get.toNamed(AppPages.resultPage, arguments: analysisResponse);
      await Future.delayed(const Duration(milliseconds: 50));

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
}
