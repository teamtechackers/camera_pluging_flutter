class ApiEndpoints {
  // Base URL - Change this to your actual API base URL
  static const String baseUrl = 'https://api.gydcustomer.com/api/v1';

  // Analysis API Base URL
  static const String analysisBaseUrl =
      'https://149c035b-3ac8-45d8-b89c-45f20b767dc4-00-14lqsbf2fotbd.kirk.replit.dev';

  // Scan endpoints
  static const String scan = '/scan';
  static const String scanHistory = '/scan/history';

  // Analysis endpoints
  static const String analyze = '/analyze';

  // User endpoints
  static const String userProfile = '/user/profile';
  static const String updateProfile = '/user/profile/update';

  // Device activation endpoints
  static const String deviceActivationBaseUrl = 'http://www.medicompras.com';
  static String deviceActivation({
    required String macAddress,
    required String code,
  }) => '/UltraScan.php?Activacion=$macAddress&Code=$code';

  // UltraScan API endpoints
  static const String ultraScanApiBaseUrl = 'https://www.medicompras.com';
  static String ultraScanApi({required String macAddress}) =>
      '/UltraScan.php?API=$macAddress';

  // Image Upload endpoint
  static String uploadImage({required String macAddress}) =>
      '/upload.php?MAC_Address=$macAddress';

  // Add more endpoints as needed for your features
  // static const String bookings = '/bookings';
  // static const String drivers = '/drivers';
  // static const String payments = '/payments';
}
