import 'dart:developer';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app/app_assets.dart';
import '../../../core/controllers/base_controller.dart';
import '../../../core/services/device_activation_service.dart';

class SettingController extends BaseController {
  static const String _macAddressKey = 'saved_mac_address';
  static const String _deviceIdKey = 'saved_device_id';

  final DeviceActivationService _activationService = DeviceActivationService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final TextEditingController macAddressController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void onInit() {
    super.onInit();
    _loadSavedMacAddress();
  }

  @override
  void onClose() {
    macAddressController.dispose();
    super.onClose();
  }

  Future<void> _loadSavedMacAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedMacAddress = prefs.getString(_macAddressKey);

      if (savedMacAddress != null && savedMacAddress.isNotEmpty) {
        macAddressController.text = savedMacAddress;
        if (kDebugMode) {
          debugPrint('📱 Loaded saved MAC address: $savedMacAddress');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error loading saved MAC address: $e');
      }
    }
  }

  /// Get device ID automatically based on platform
  Future<String> _getDeviceId() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? '';
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ Unsupported platform for device ID');
        }
        return '';
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error getting device ID: $e');
      }
      return '';
    }
  }

  Future<void> _saveMacAddress(String macAddress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_macAddressKey, macAddress);
      if (kDebugMode) {
        debugPrint('💾 Saved MAC address: $macAddress');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving MAC address: $e');
      }
    }
  }

  Future<void> _saveDeviceId(String deviceId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_deviceIdKey, deviceId);
      if (kDebugMode) {
        debugPrint('💾 Saved device ID: $deviceId');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Error saving device ID: $e');
      }
    }
  }

  Future<void> activateDevice() async {
    try {
      if (formKey.currentState != null && !formKey.currentState!.validate()) {
        return;
      }

      final macAddress = macAddressController.text.trim();

      // Get device ID first (this will show loading)
      final deviceId = await safeApiCall(() async {
        return await _getDeviceId();
      });

      if (deviceId == null || deviceId.isEmpty) {
        showError('Unable to retrieve device ID. Please try again.');
        return;
      }

      if (kDebugMode) {
        debugPrint('📱 Device ID: $deviceId');
      }

      // Make activation API call
      final result = await safeApiCall(() async {
        log('api called');
        return _activationService.activateDevice(
          macAddress: macAddress,
          code: deviceId,
        );
      });

      if (result != null) {
        // Save MAC address and device ID to SharedPreferences if activation is allowed
        if (result == ActivationStatus.allowed) {
          await _saveMacAddress(macAddress);
          await _saveDeviceId(deviceId);
        }
        showActivateDialog(status: result);
      } else {
        showError('Device activation failed. Please try again.');
      }
    } catch (e) {
      handleApiError(e);
    }
  }

  String? macValidator(String? value) {
    final input = (value ?? '').trim();
    if (input.isEmpty) {
      return 'Please enter a MAC address';
    }
    final macRegex = RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$');
    if (!macRegex.hasMatch(input)) {
      return 'Invalid MAC address. Use format XX:XX:XX:XX:XX:XX';
    }
    return null;
  }

  void showActivateDialog({required ActivationStatus status}) {
    final size = MediaQuery.of(Get.context!).size;
    showDialog(
      context: Get.context!,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent, // keep transparent edges
        contentPadding: EdgeInsets.zero,
        insetPadding: const EdgeInsets.all(24), // prevents full-screen
        content: Center(
          child: SizedBox(
            height: 300,
            width: size.width * 0.8,
            child: Material(
              type: MaterialType.transparency,
              child: Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(AppAssets.deviceActivationBg),
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 50, right: 30),
                      child: Align(
                        alignment: Alignment.topRight,
                        child: InkWell(
                          onTap: () {
                            Navigator.of(context).pop();
                            Get.back();
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Image.asset(
                              AppAssets.closeIcon,
                              width: 20,
                              height: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Image.asset(
                      status == ActivationStatus.denied
                          ? AppAssets.rejectIcon
                          : AppAssets.activateIcon,
                      height: 80,
                    ),
                    Center(
                      child: Text(
                        status == ActivationStatus.denied
                            ? 'device_denied'.tr
                            : 'device_activated'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
