import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_endpoints.dart';
import '../../../core/api/models/analysis_response.dart';
import '../../../core/controllers/base_controller.dart';
import '../../../core/controllers/selection_controller.dart';

class ResultController extends BaseController {
  ResultController({required this.analysisResponse});
  final AnalysisResponse analysisResponse;

  static const String _macAddressKey = 'saved_mac_address';
  RxString resultUrl = ''.obs;
  RxBool isDownloadingPdf = false.obs;

  @override
  void onInit() {
    super.onInit();
    _buildResultUrl();
  }

  Future<void> _buildResultUrl() async {
    try {
      final selection = Get.put(SelectionController());
      final zone = selection.selectedZone.value;
      if (zone.isEmpty || analysisResponse.analysis == null) {
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final mac = prefs.getString(_macAddressKey);
      if (mac == null || mac.isEmpty) {
        return;
      }

      final piel = analysisResponse.analysis!.skinColor?.value ?? 0;
      final color = analysisResponse.analysis!.hairColor?.value ?? 0;
      final thickNum = analysisResponse.analysis!.hairThickness?.value ?? 0.0;
      final thick = double.parse(thickNum.toStringAsFixed(2));

      final url =
          '${ApiEndpoints.deviceActivationBaseUrl}/UltraScan.php'
          '?MAC_Address=$mac'
          '&Piel=${piel.round()}'
          '&Color=${color.round()}'
          '&Thick=$thick'
          '&Zone=$zone';

      debugPrint('Result URL: $url');
      resultUrl.value = url;
    } catch (e) {
      debugPrint('Error building URL: $e');
    }
  }
}
