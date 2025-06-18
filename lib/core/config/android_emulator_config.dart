import 'dart:io';
import 'environment_config.dart';

/// Android emulator specific configuration
/// Handles the special case where Android emulators need to use 10.0.2.2
/// to access the host machine's localhost
class AndroidEmulatorConfig {
  /// Check if running on Android emulator
  static bool get isAndroidEmulator {
    return Platform.isAndroid && _isEmulator();
  }

  /// Check if the current Android device is an emulator
  static bool _isEmulator() {
    // Common indicators that we're running on an emulator
    // Note: This is a best-effort detection
    try {
      // Check for emulator-specific properties
      final brand = Platform.environment['ro.product.brand'] ?? '';
      final model = Platform.environment['ro.product.model'] ?? '';
      final device = Platform.environment['ro.product.device'] ?? '';

      return brand.toLowerCase().contains('generic') ||
          model.toLowerCase().contains('emulator') ||
          device.toLowerCase().contains('emulator') ||
          model.toLowerCase().contains('sdk');
    } catch (e) {
      // If we can't determine, assume it's a real device
      return false;
    }
  }

  /// Convert localhost URLs to emulator-accessible URLs
  static String convertUrlForEmulator(String url) {
    if (!isAndroidEmulator) {
      return url;
    }

    final uri = Uri.parse(url);

    // Convert localhost and 127.0.0.1 to 10.0.2.2 for Android emulator
    if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
      final newUri = uri.replace(host: '10.0.2.2');
      return newUri.toString();
    }

    return url;
  }

  /// Get the appropriate base URL for the current platform
  static String getBaseUrl() {
    String baseUrl = EnvironmentConfig.baseUrl;

    // Convert for Android emulator if needed
    if (isAndroidEmulator) {
      baseUrl = convertUrlForEmulator(baseUrl);
    }

    return baseUrl;
  }

  /// Get emulator-specific development configuration
  static Map<String, String> getEmulatorDevConfig() {
    return {
      'DEV_API_BASE_URL': 'http://10.0.2.2:8097/v1',
      'DEV_ENABLE_LOGGING': 'true',
      'DEV_TIMEOUT_SECONDS': '45', // Slightly longer for emulator
    };
  }

  /// Validate emulator configuration
  static List<String> validateEmulatorConfig() {
    final warnings = <String>[];

    if (isAndroidEmulator) {
      final baseUrl = EnvironmentConfig.baseUrl;
      final uri = Uri.parse(baseUrl);

      // Warn if using localhost in emulator
      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        warnings.add(
          'Android emulator detected with localhost URL. '
          'Consider using 10.0.2.2 instead of ${uri.host} for better connectivity.',
        );
      }

      // Check if port is commonly used for development
      if (uri.port == 8000 || uri.port == 3000 || uri.port == 8080) {
        warnings.add(
          'Using common development port ${uri.port}. '
          'Ensure your backend server is running on this port.',
        );
      }
    }

    return warnings;
  }

  /// Get debug information about emulator configuration
  static Map<String, dynamic> getDebugInfo() {
    return {
      'isAndroidEmulator': isAndroidEmulator,
      'platform': Platform.operatingSystem,
      'originalBaseUrl': EnvironmentConfig.baseUrl,
      'emulatorBaseUrl': isAndroidEmulator ? getBaseUrl() : null,
      'environment': EnvironmentConfig.environmentName,
    };
  }
}
