import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_endpoints.dart';

class ImageUploadUtils {
  static const String _macAddressKey = 'saved_mac_address';
  static final Dio _dio = Dio();

  /// Uploads a base64 data URL string to the server.
  /// The upload is associated with the saved MAC address.
  static Future<void> uploadAnnotatedImageToServer(String dataUrl) async {
    try {
      log('📤 Starting image upload process...');

      // 1. Retrieve saved MAC address
      final prefs = await SharedPreferences.getInstance();
      final macAddress = prefs.getString(_macAddressKey) ?? '';

      if (macAddress.isEmpty) {
        log('⚠️ Image Upload: No MAC address found in storage.');
        return;
      }

      // 2. Prepare payload
      final Map<String, dynamic> body = {
        'imagen_base64': dataUrl,
      };

      final url = '${ApiEndpoints.ultraScanApiBaseUrl}${ApiEndpoints.uploadImage(macAddress: macAddress)}';
      
      log('🔗 Uploading to: $url');

      final response = await _dio.post(
        url,
        data: body,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      log('📥 Server Response: ${response.statusCode}');
      log('📄 Response Data: ${response.data}');
      
    } catch (e) {
      log('❌ Error during image upload: $e');
      if (e is DioException) {
        log('❌ Dio Error details: ${e.response?.data}');
      }
    }
  }
}
