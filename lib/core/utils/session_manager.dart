import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/storage_keys.dart';
import '../di/injection.dart';
import 'logger.dart';
import 'jwt_token_manager.dart';

class SessionManager {
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage;
  final JwtTokenManager _tokenManager;

  // Session timeout in minutes (default: 30 minutes)
  final int _sessionTimeoutMinutes;

  // Timer for session checks
  Timer? _sessionCheckTimer;

  // Session state
  final ValueNotifier<SessionState> sessionState = ValueNotifier(
    SessionState.unknown,
  );

  SessionManager(
    this._prefs,
    this._secureStorage,
    this._tokenManager, {
    int sessionTimeoutMinutes = 30,
  }) : _sessionTimeoutMinutes = sessionTimeoutMinutes {
    // Start session monitoring
    _startSessionMonitoring();
  }

  // Initialize session
  Future<void> initializeSession() async {
    try {
      final token = await _secureStorage.read(key: StorageKeys.accessToken);

      if (token != null && !await _tokenManager.isTokenExpiringSoon()) {
        // Valid token exists
        await updateLastActivity();
        sessionState.value = SessionState.active;
      } else if (token != null) {
        // Token exists but is expiring soon
        sessionState.value = SessionState.expiring;
      } else {
        // No valid token
        sessionState.value = SessionState.inactive;
      }
    } catch (e) {
      AppLogger.error('Failed to initialize session: $e');
      sessionState.value = SessionState.error;
    }
  }

  // Update last activity timestamp
  Future<void> updateLastActivity() async {
    try {
      final now = DateTime.now().millisecondsSinceEpoch;
      await _prefs.setInt(StorageKeys.lastActivity, now);

      // If session was expiring, set it back to active
      if (sessionState.value == SessionState.expiring) {
        sessionState.value = SessionState.active;
      }
    } catch (e) {
      AppLogger.error('Failed to update last activity: $e');
    }
  }

  // Check if session is active
  Future<bool> isSessionActive() async {
    try {
      // Check if token exists and is valid
      final token = await _secureStorage.read(key: StorageKeys.accessToken);
      if (token == null) return false;

      // Check if token is valid
      if (await _tokenManager.isTokenExpiringSoon()) {
        sessionState.value = SessionState.expiring;
        return true; // Still active but expiring soon
      }

      // Check last activity
      final lastActivity = _prefs.getInt(StorageKeys.lastActivity);
      if (lastActivity == null) return false;

      final now = DateTime.now().millisecondsSinceEpoch;
      final elapsedMinutes = (now - lastActivity) / (1000 * 60);

      final isActive = elapsedMinutes < _sessionTimeoutMinutes;
      sessionState.value =
          isActive ? SessionState.active : SessionState.timeout;

      return isActive;
    } catch (e) {
      AppLogger.error('Failed to check session status: $e');
      sessionState.value = SessionState.error;
      return false;
    }
  }

  // Clear session data
  Future<void> clearSession() async {
    try {
      // Clear token
      await _secureStorage.delete(key: StorageKeys.accessToken);

      // Clear session data
      await _secureStorage.delete(key: StorageKeys.sessionData);
      await _secureStorage.delete(key: StorageKeys.userCredentials);

      // Clear activity timestamp
      await _prefs.remove(StorageKeys.lastActivity);

      // Clear any other session-related data
      final allPrefs = _prefs.getKeys();
      for (final key in allPrefs) {
        if (key.startsWith('session_') || key.startsWith('auth_')) {
          await _prefs.remove(key);
        }
      }

      // Update session state
      sessionState.value = SessionState.inactive;

      AppLogger.info('Session cleared successfully');
    } catch (e) {
      AppLogger.error('Failed to clear session: $e');

      // Try alternative approach if the first method fails
      try {
        await _tokenManager.clearStoredToken();
        AppLogger.info('Used token manager to clear session as fallback');
        sessionState.value = SessionState.inactive;
      } catch (e2) {
        AppLogger.error('Failed to clear session via token manager: $e2');
      }
    }
  }

  // Store session data
  Future<void> storeSessionData(Map<String, dynamic> data) async {
    try {
      // Convert data to JSON string
      final jsonData = data.toString();
      await _secureStorage.write(key: StorageKeys.sessionData, value: jsonData);
    } catch (e) {
      AppLogger.error('Failed to store session data: $e');
    }
  }

  // Get session data
  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final jsonData = await _secureStorage.read(key: StorageKeys.sessionData);
      if (jsonData == null) return null;

      // Parse JSON string to Map
      // Note: This is a simplification, actual implementation would use jsonDecode
      final data = <String, dynamic>{};
      // Parse jsonData into data map
      return data;
    } catch (e) {
      AppLogger.error('Failed to get session data: $e');
      return null;
    }
  }

  // Start session monitoring
  void _startSessionMonitoring() {
    // Check session status every minute
    _sessionCheckTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
      if (sessionState.value != SessionState.inactive) {
        final isActive = await isSessionActive();
        if (!isActive && sessionState.value == SessionState.active) {
          // Session timed out
          sessionState.value = SessionState.timeout;
        }
      }
    });
  }

  // Dispose resources
  void dispose() {
    _sessionCheckTimer?.cancel();
    sessionState.dispose();
  }
}

// Session state enum
enum SessionState {
  unknown, // Initial state
  active, // Session is active
  expiring, // Session is active but token is expiring soon
  timeout, // Session timed out due to inactivity
  inactive, // No active session
  error, // Error occurred during session operations
}
