import 'dart:io';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'environment_config.dart';
import 'android_emulator_config.dart';
import '../utils/logger.dart';

/// Network troubleshooting utilities for diagnosing connection issues
class NetworkTroubleshooter {
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
    ),
  );

  /// Perform comprehensive network diagnostics
  static Future<NetworkDiagnostics> diagnoseNetwork() async {
    final diagnostics = NetworkDiagnostics();
    
    try {
      // Check connectivity
      diagnostics.connectivity = await _checkConnectivity();
      
      // Check if we can reach the internet
      diagnostics.internetAccess = await _checkInternetAccess();
      
      // Check backend server accessibility
      diagnostics.backendAccess = await _checkBackendAccess();
      
      // Android emulator specific checks
      if (Platform.isAndroid) {
        diagnostics.emulatorChecks = await _checkEmulatorSpecific();
      }
      
      // DNS resolution checks
      diagnostics.dnsResolution = await _checkDnsResolution();
      
    } catch (e) {
      AppLogger.error('Network diagnostics failed: $e');
      diagnostics.error = e.toString();
    }
    
    return diagnostics;
  }

  /// Check device connectivity status
  static Future<ConnectivityStatus> _checkConnectivity() async {
    try {
      final connectivityResults = await Connectivity().checkConnectivity();
      
      // Handle the new List<ConnectivityResult> return type
      final isConnected = connectivityResults.isNotEmpty && 
                         !connectivityResults.contains(ConnectivityResult.none);
      
      final connectionTypes = connectivityResults
          .where((result) => result != ConnectivityResult.none)
          .map((result) => result.toString().split('.').last)
          .join(', ');
      
      return ConnectivityStatus(
        isConnected: isConnected,
        connectionType: connectionTypes.isNotEmpty ? connectionTypes : 'none',
        details: _getConnectivityDetails(connectivityResults),
      );
    } catch (e) {
      return ConnectivityStatus(
        isConnected: false,
        connectionType: 'unknown',
        details: 'Failed to check connectivity: $e',
      );
    }
  }

  /// Check if we can reach the internet
  static Future<InternetAccessStatus> _checkInternetAccess() async {
    try {
      final response = await _dio.get('https://www.google.com');
      
      return InternetAccessStatus(
        hasAccess: response.statusCode == 200,
        responseTime: DateTime.now().millisecondsSinceEpoch,
        details: 'Successfully reached google.com',
      );
    } catch (e) {
      return InternetAccessStatus(
        hasAccess: false,
        responseTime: null,
        details: 'Failed to reach internet: $e',
      );
    }
  }

  /// Check backend server accessibility
  static Future<BackendAccessStatus> _checkBackendAccess() async {
    try {
      final baseUrl = EnvironmentConfig.baseUrl;
      final healthEndpoint = '$baseUrl/health';
      
      // Create a separate Dio instance with longer timeout for backend checks
      final backendDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          sendTimeout: const Duration(seconds: 10),
        ),
      );
      
      // Try to reach the health endpoint
      final response = await backendDio.get(healthEndpoint);
      
      return BackendAccessStatus(
        isAccessible: response.statusCode! >= 200 && response.statusCode! < 300,
        statusCode: response.statusCode,
        endpoint: healthEndpoint,
        details: 'Backend server is accessible',
        responseTime: DateTime.now().millisecondsSinceEpoch,
      );
    } catch (e) {
      final baseUrl = EnvironmentConfig.baseUrl;
      
      return BackendAccessStatus(
        isAccessible: false,
        statusCode: null,
        endpoint: '$baseUrl/health',
        details: 'Failed to reach backend: $e',
        responseTime: null,
      );
    }
  }

  /// Android emulator specific checks
  static Future<EmulatorChecks> _checkEmulatorSpecific() async {
    final checks = EmulatorChecks();
    
    try {
      checks.isEmulator = AndroidEmulatorConfig.isAndroidEmulator;
      checks.originalUrl = EnvironmentConfig.rawBaseUrl;
      checks.convertedUrl = EnvironmentConfig.baseUrl;
      
      if (checks.isEmulator) {
        // Test localhost accessibility (should fail)
        checks.localhostAccessible = await _testUrl('http://localhost:8000');
        
        // Test 10.0.2.2 accessibility
        checks.emulatorIpAccessible = await _testUrl('http://10.0.2.2:8000');
        
        // Check if URL was converted
        checks.urlWasConverted = checks.originalUrl != checks.convertedUrl;
      }
      
    } catch (e) {
      checks.error = e.toString();
    }
    
    return checks;
  }

  /// Check DNS resolution
  static Future<DnsResolutionStatus> _checkDnsResolution() async {
    try {
      final baseUrl = EnvironmentConfig.baseUrl;
      final uri = Uri.parse(baseUrl);
      
      // Try to resolve the hostname
      final addresses = await InternetAddress.lookup(uri.host);
      
      return DnsResolutionStatus(
        canResolve: addresses.isNotEmpty,
        hostname: uri.host,
        resolvedAddresses: addresses.map((addr) => addr.address).toList(),
        details: 'Successfully resolved ${uri.host}',
      );
    } catch (e) {
      final baseUrl = EnvironmentConfig.baseUrl;
      final uri = Uri.parse(baseUrl);
      
      return DnsResolutionStatus(
        canResolve: false,
        hostname: uri.host,
        resolvedAddresses: [],
        details: 'Failed to resolve ${uri.host}: $e',
      );
    }
  }

  /// Test if a specific URL is accessible
  static Future<bool> _testUrl(String url) async {
    try {
      final testDio = Dio(
        BaseOptions(
          connectTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      );
      
      final response = await testDio.get(url);
      return response.statusCode! >= 200 && response.statusCode! < 500;
    } catch (e) {
      return false;
    }
  }

  /// Get connectivity details
  static String _getConnectivityDetails(List<ConnectivityResult> results) {
    if (results.isEmpty || results.contains(ConnectivityResult.none)) {
      return 'No network connection';
    }
    
    final connectionTypes = <String>[];
    
    for (final result in results) {
      switch (result) {
        case ConnectivityResult.wifi:
          connectionTypes.add('WiFi');
          break;
        case ConnectivityResult.mobile:
          connectionTypes.add('Mobile Data');
          break;
        case ConnectivityResult.ethernet:
          connectionTypes.add('Ethernet');
          break;
        case ConnectivityResult.bluetooth:
          connectionTypes.add('Bluetooth');
          break;
        case ConnectivityResult.vpn:
          connectionTypes.add('VPN');
          break;
        case ConnectivityResult.other:
          connectionTypes.add('Other');
          break;
        case ConnectivityResult.none:
          // Skip none results
          break;
      }
    }
    
    if (connectionTypes.isEmpty) {
      return 'Unknown connection type';
    }
    
    return 'Connected via ${connectionTypes.join(', ')}';
  }

  /// Generate troubleshooting report
  static String generateTroubleshootingReport(NetworkDiagnostics diagnostics) {
    final buffer = StringBuffer();
    
    buffer.writeln('🔍 Network Diagnostics Report');
    buffer.writeln('Generated: ${DateTime.now()}');
    buffer.writeln('Platform: ${Platform.operatingSystem}');
    buffer.writeln('Environment: ${EnvironmentConfig.environmentName}');
    buffer.writeln('Base URL: ${EnvironmentConfig.baseUrl}');
    buffer.writeln();
    
    // Connectivity
    buffer.writeln('📶 Connectivity Status');
    buffer.writeln('Connected: ${diagnostics.connectivity.isConnected}');
    buffer.writeln('Type: ${diagnostics.connectivity.connectionType}');
    buffer.writeln('Details: ${diagnostics.connectivity.details}');
    buffer.writeln();
    
    // Internet Access
    buffer.writeln('🌐 Internet Access');
    buffer.writeln('Has Access: ${diagnostics.internetAccess.hasAccess}');
    buffer.writeln('Details: ${diagnostics.internetAccess.details}');
    buffer.writeln();
    
    // Backend Access
    buffer.writeln('🖥️ Backend Server Access');
    buffer.writeln('Accessible: ${diagnostics.backendAccess.isAccessible}');
    buffer.writeln('Endpoint: ${diagnostics.backendAccess.endpoint}');
    buffer.writeln('Status Code: ${diagnostics.backendAccess.statusCode ?? 'N/A'}');
    buffer.writeln('Details: ${diagnostics.backendAccess.details}');
    buffer.writeln();
    
    // Android Emulator Specific
    if (Platform.isAndroid && diagnostics.emulatorChecks != null) {
      final emulator = diagnostics.emulatorChecks!;
      buffer.writeln('📱 Android Emulator Checks');
      buffer.writeln('Is Emulator: ${emulator.isEmulator}');
      buffer.writeln('Original URL: ${emulator.originalUrl}');
      buffer.writeln('Converted URL: ${emulator.convertedUrl}');
      buffer.writeln('URL Was Converted: ${emulator.urlWasConverted}');
      buffer.writeln('Localhost Accessible: ${emulator.localhostAccessible}');
      buffer.writeln('10.0.2.2 Accessible: ${emulator.emulatorIpAccessible}');
      if (emulator.error != null) {
        buffer.writeln('Error: ${emulator.error}');
      }
      buffer.writeln();
    }
    
    // DNS Resolution
    buffer.writeln('🔍 DNS Resolution');
    buffer.writeln('Can Resolve: ${diagnostics.dnsResolution.canResolve}');
    buffer.writeln('Hostname: ${diagnostics.dnsResolution.hostname}');
    buffer.writeln('Resolved IPs: ${diagnostics.dnsResolution.resolvedAddresses.join(', ')}');
    buffer.writeln('Details: ${diagnostics.dnsResolution.details}');
    buffer.writeln();
    
    // Recommendations
    buffer.writeln('💡 Recommendations');
    buffer.writeln(_generateRecommendations(diagnostics));
    
    return buffer.toString();
  }

  /// Generate recommendations based on diagnostics
  static String _generateRecommendations(NetworkDiagnostics diagnostics) {
    final recommendations = <String>[];
    
    if (!diagnostics.connectivity.isConnected) {
      recommendations.add('• Check your device\'s network connection');
      recommendations.add('• Ensure WiFi or mobile data is enabled');
    }
    
    if (!diagnostics.internetAccess.hasAccess) {
      recommendations.add('• Verify internet connectivity');
      recommendations.add('• Check firewall or proxy settings');
    }
    
    if (!diagnostics.backendAccess.isAccessible) {
      recommendations.add('• Ensure your backend server is running');
      recommendations.add('• Verify the server is bound to 0.0.0.0, not just localhost');
      recommendations.add('• Check if the port number is correct');
      
      if (Platform.isAndroid && AndroidEmulatorConfig.isAndroidEmulator) {
        recommendations.add('• For Android emulator, use 10.0.2.2 instead of localhost');
        recommendations.add('• Test backend accessibility: curl http://10.0.2.2:YOUR_PORT/api');
      }
    }
    
    if (Platform.isAndroid && diagnostics.emulatorChecks != null) {
      final emulator = diagnostics.emulatorChecks!;
      
      if (emulator.isEmulator && !emulator.urlWasConverted) {
        recommendations.add('• URL conversion for emulator may have failed');
        recommendations.add('• Try setting DEV_API_BASE_URL=http://10.0.2.2:YOUR_PORT/api explicitly');
      }
      
      if (emulator.isEmulator && !emulator.emulatorIpAccessible) {
        recommendations.add('• Backend server may not be accessible from emulator');
        recommendations.add('• Ensure server binds to all interfaces (0.0.0.0)');
        recommendations.add('• Check CORS configuration for 10.0.2.2');
      }
    }
    
    if (!diagnostics.dnsResolution.canResolve) {
      recommendations.add('• DNS resolution failed for your backend hostname');
      recommendations.add('• Check if the hostname is correct');
      recommendations.add('• Try using an IP address instead');
    }
    
    if (recommendations.isEmpty) {
      recommendations.add('• Configuration appears correct');
      recommendations.add('• Check backend server logs for errors');
      recommendations.add('• Verify API endpoints are implemented');
    }
    
    return recommendations.join('\n');
  }
}

/// Network diagnostics result
class NetworkDiagnostics {
  late ConnectivityStatus connectivity;
  late InternetAccessStatus internetAccess;
  late BackendAccessStatus backendAccess;
  late DnsResolutionStatus dnsResolution;
  EmulatorChecks? emulatorChecks;
  String? error;
}

/// Connectivity status information
class ConnectivityStatus {
  final bool isConnected;
  final String connectionType;
  final String details;

  ConnectivityStatus({
    required this.isConnected,
    required this.connectionType,
    required this.details,
  });
}

/// Internet access status
class InternetAccessStatus {
  final bool hasAccess;
  final int? responseTime;
  final String details;

  InternetAccessStatus({
    required this.hasAccess,
    required this.responseTime,
    required this.details,
  });
}

/// Backend server access status
class BackendAccessStatus {
  final bool isAccessible;
  final int? statusCode;
  final String endpoint;
  final String details;
  final int? responseTime;

  BackendAccessStatus({
    required this.isAccessible,
    required this.statusCode,
    required this.endpoint,
    required this.details,
    required this.responseTime,
  });
}

/// Android emulator specific checks
class EmulatorChecks {
  bool isEmulator = false;
  String originalUrl = '';
  String convertedUrl = '';
  bool urlWasConverted = false;
  bool localhostAccessible = false;
  bool emulatorIpAccessible = false;
  String? error;
}

/// DNS resolution status
class DnsResolutionStatus {
  final bool canResolve;
  final String hostname;
  final List<String> resolvedAddresses;
  final String details;

  DnsResolutionStatus({
    required this.canResolve,
    required this.hostname,
    required this.resolvedAddresses,
    required this.details,
  });
}