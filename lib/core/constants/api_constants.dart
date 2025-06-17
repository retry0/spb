import '../config/api_endpoints.dart';

/// Legacy API constants class - now delegates to ApiEndpoints
/// Kept for backward compatibility
@Deprecated('Use ApiEndpoints instead')
class ApiConstants {
  static String get baseUrl => ApiEndpoints.baseUrl;
  
  // Auth endpoints
  static String get login => ApiEndpoints.login;
  static String get logout => ApiEndpoints.logout;
  static String get refresh => ApiEndpoints.refresh;
  static String get register => ApiEndpoints.register;
  
  // User endpoints
  static String get profile => ApiEndpoints.profile;
  static String get updateProfile => ApiEndpoints.updateProfile;
  
  // Data endpoints
  static String get data => ApiEndpoints.data;
  static String get dataExport => ApiEndpoints.dataExport;
  
  // Dashboard endpoints
  static String get dashboard => ApiEndpoints.dashboard;
  static String get metrics => ApiEndpoints.metrics;
  static String get activities => ApiEndpoints.activities;
}