import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../api/api_endpoints.dart';

enum ActivationStatus { allowed, denied, unknown }

class DeviceActivationService {
  DeviceActivationService({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  /// Activate device using MAC address and device ID (code)
  /// Returns an [ActivationStatus] based on response `Estado`: Allow/Denied
  /// Throws DioException on transport-level failure (>=500 or network)
  Future<ActivationStatus> activateDevice({
    required String macAddress,
    required String code,
  }) async {
    try {
      final response = await _dio.get(
        '${ApiEndpoints.deviceActivationBaseUrl}${ApiEndpoints.deviceActivation(macAddress: macAddress, code: code)}',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (kDebugMode) {
        debugPrint('🔗 Device Activation API Response: ${response.statusCode}');
        debugPrint('📥 Response Data: ${response.data}');
      }

      if (response.statusCode == 200) {
        final dynamic data = response.data;

        // The API may return JSON like {Estado: Allow} or a raw string
        String? estado;
        if (data is Map) {
          // Accept various casings
          if (data.containsKey('Estado')) estado = '${data['Estado']}';
          if (estado == null && data.containsKey('estado')) {
            estado = '${data['estado']}';
          }
        } else if (data is String) {
          final match = RegExp(
            '(Allow|Denied)',
            caseSensitive: false,
          ).firstMatch(data);
          if (match != null) {
            estado = match.group(0);
          }
        }

        if (estado != null) {
          final normalized = estado.toLowerCase();
          if (normalized == 'allow') return ActivationStatus.allowed;
          if (normalized == 'denied') return ActivationStatus.denied;
        }

        return ActivationStatus.unknown;
      }

      // Non-200 (<500 due to validateStatus) treated as bad response
      throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        message: 'Device activation failed with status ${response.statusCode}',
        type: DioExceptionType.badResponse,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Device Activation Error: $e');
      }
      if (e is DioException) {
        rethrow;
      }
      throw DioException(
        requestOptions: RequestOptions(),
        message: e.toString(),
      );
    }
  }
}
