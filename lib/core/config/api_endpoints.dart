import 'environment_config.dart';

/// API endpoints configuration that adapts based on environment
class ApiEndpoints {
  static String get baseUrl => EnvironmentConfig.baseUrl;

  // Auth endpoints
  static String get login => '$baseUrl/Account/LoginUser';
  static String get logout => '$baseUrl/auth/logout';
  static String get refresh => '$baseUrl/auth/refresh';
  static String get register => '$baseUrl/auth/register';
  static String get changePassword => '$baseUrl/Account/api/ChangePassword';

  // User endpoints
  static String get profile => '$baseUrl/user/profile';
  static String get updateProfile => '$baseUrl/user/profile';

  // Data endpoints
  static String get data => '$baseUrl/data';
  static String get dataExport => '$baseUrl/data/export';

  // Dashboard endpoints
  static String get dashboard => '$baseUrl/dashboard';
  static String get metrics => '$baseUrl/dashboard/metrics';
  static String get activities => '$baseUrl/dashboard/activities';

  // Password management
  static String get requestPasswordReset => '$baseUrl/auth/password/reset-request';
  static String get resetPassword => '$baseUrl/auth/password/reset';

  /// Get endpoint with query parameters
  static String withQuery(String endpoint, Map<String, String> params) {
    if (params.isEmpty) return endpoint;

    final uri = Uri.parse(endpoint);
    final newUri = uri.replace(
      queryParameters: {...uri.queryParameters, ...params},
    );

    return newUri.toString();
  }

  /// Get all endpoints for debugging
  static Map<String, String> getAllEndpoints() {
    return {
      'baseUrl': baseUrl,
      'login': login,
      'logout': logout,
      'refresh': refresh,
      'register': register,
      'profile': profile,
      'updateProfile': updateProfile,
      'data': data,
      'dataExport': dataExport,
      'dashboard': dashboard,
      'metrics': metrics,
      'activities': activities,
      'changePassword': changePassword,
      'requestPasswordReset': requestPasswordReset,
      'resetPassword': resetPassword,
    };
  }
}