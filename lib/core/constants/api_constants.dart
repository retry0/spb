class ApiConstants {
  static const String baseUrl = 'http://10.0.2.2:8000/api';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String logout = '/auth/logout';
  static const String refresh = '/auth/refresh';
  static const String register = '/auth/register';

  // User endpoints
  static const String profile = '/user/profile';
  static const String updateProfile = '/user/profile';

  // Data endpoints
  static const String data = '/data';
  static const String dataExport = '/data/export';

  // Dashboard endpoints
  static const String dashboard = '/dashboard';
  static const String metrics = '/dashboard/metrics';
  static const String activities = '/dashboard/activities';
}
