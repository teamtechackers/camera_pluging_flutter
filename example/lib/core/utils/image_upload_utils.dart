import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/api_endpoints.dart';

class ImageUploadUtils {
  static const String _macAddressKey = 'saved_mac_address';
  static final Dio _dio = Dio();

  static Future<void> uploadImageToServer(File imageFile) async {
    try {
      log('📤 Starting image upload process...');

      final prefs = await SharedPreferences.getInstance();
      final macAddress = prefs.getString(_macAddressKey) ?? '';

      if (macAddress.isEmpty) {
        log('⚠️ Image Upload: No MAC address found in storage.');
        return;
      }

      final bytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(bytes);
      final String dataUrl = 'data:image/jpeg;base64,$base64Image';

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
