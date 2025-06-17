import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/database_helper.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/security/password_security.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveTokens(String accessToken, String refreshToken);
  Future<String?> getAccessToken();
  Future<String?> getRefreshToken();
  Future<void> clearTokens();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String username);
  Future<UserModel?> getUserById(String userId);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String username);
  Future<bool> verifyPassword(String username, String password);
  Future<void> updatePassword(String username, String newPassword);
  Future<void> incrementFailedAttempts(String username);
  Future<void> resetFailedAttempts(String username);
  Future<void> lockUser(String username, DateTime until);
  Future<void> logAuthAttempt(String username, String action, bool success, {String? errorMessage, String? ipAddress, String? userAgent});
  Future<bool> isUsernameAvailable(String username);
  Future<void> savePasswordResetToken(String username, String token, DateTime expiresAt);
  Future<Map<String, dynamic>?> getPasswordResetToken(String token);
  Future<void> markPasswordResetTokenUsed(String token);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage _secureStorage;
  final DatabaseHelper _dbHelper;

  AuthLocalDataSourceImpl(this._secureStorage, this._dbHelper);

  @override
  Future<void> saveTokens(String accessToken, String refreshToken) async {
    await _secureStorage.write(StorageKeys.accessToken, accessToken);
    await _secureStorage.write(StorageKeys.refreshToken, refreshToken);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(StorageKeys.accessToken);
  }

  @override
  Future<String?> getRefreshToken() async {
    return await _secureStorage.read(StorageKeys.refreshToken);
  }

  @override
  Future<void> clearTokens() async {
    await _secureStorage.delete(StorageKeys.accessToken);
    await _secureStorage.delete(StorageKeys.refreshToken);
  }

  @override
  Future<void> saveUser(UserModel user) async {
    try {
      await _dbHelper.insert('users', user.toDatabase());
    } catch (e) {
      AppLogger.error('Failed to save user', e);
      rethrow;
    }
  }

  @override
  Future<UserModel?> getUser(String username) async {
    try {
      final results = await _dbHelper.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return UserModel.fromDatabase(results.first);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get user by username', e);
      return null;
    }
  }

  @override
  Future<UserModel?> getUserById(String userId) async {
    try {
      final results = await _dbHelper.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return UserModel.fromDatabase(results.first);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get user by ID', e);
      return null;
    }
  }

  @override
  Future<void> updateUser(UserModel user) async {
    try {
      await _dbHelper.update(
        'users',
        user.toDatabase(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      AppLogger.error('Failed to update user', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String username) async {
    try {
      await _dbHelper.delete('users', where: 'username = ?', whereArgs: [username]);
    } catch (e) {
      AppLogger.error('Failed to delete user', e);
      rethrow;
    }
  }

  @override
  Future<bool> verifyPassword(String username, String password) async {
    try {
      final results = await _dbHelper.query(
        'users',
        columns: ['password_hash', 'salt'],
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );
      
      if (results.isEmpty) return false;
      
      final passwordHash = results.first['password_hash'] as String?;
      final salt = results.first['salt'] as String?;
      
      if (passwordHash == null || salt == null) return false;
      
      return PasswordSecurity.verifyPassword(password, passwordHash, salt);
    } catch (e) {
      AppLogger.error('Failed to verify password', e);
      return false;
    }
  }

  @override
  Future<void> updatePassword(String username, String newPassword) async {
    try {
      final salt = PasswordSecurity.generateSalt();
      final passwordHash = PasswordSecurity.hashPassword(newPassword, salt);
      
      await _dbHelper.update(
        'users',
        {
          'password_hash': passwordHash,
          'salt': salt,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'username = ?',
        whereArgs: [username],
      );
    } catch (e) {
      AppLogger.error('Failed to update password', e);
      rethrow;
    }
  }

  @override
  Future<void> incrementFailedAttempts(String username) async {
    try {
      await _dbHelper.database.then((db) => db.rawUpdate(
        'UPDATE users SET failed_login_attempts = failed_login_attempts + 1, updated_at = ? WHERE username = ?',
        [DateTime.now().millisecondsSinceEpoch ~/ 1000, username],
      ));
    } catch (e) {
      AppLogger.error('Failed to increment failed attempts', e);
    }
  }

  @override
  Future<void> resetFailedAttempts(String username) async {
    try {
      await _dbHelper.update(
        'users',
        {
          'failed_login_attempts': 0,
          'locked_until': null,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'username = ?',
        whereArgs: [username],
      );
    } catch (e) {
      AppLogger.error('Failed to reset failed attempts', e);
    }
  }

  @override
  Future<void> lockUser(String username, DateTime until) async {
    try {
      await _dbHelper.update(
        'users',
        {
          'locked_until': until.millisecondsSinceEpoch ~/ 1000,
          'updated_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        },
        where: 'username = ?',
        whereArgs: [username],
      );
    } catch (e) {
      AppLogger.error('Failed to lock user', e);
    }
  }

  @override
  Future<void> logAuthAttempt(String username, String action, bool success, {String? errorMessage, String? ipAddress, String? userAgent}) async {
    try {
      await _dbHelper.insert('auth_audit_logs', {
        'username': username,
        'action': action,
        'success': success ? 1 : 0,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'error_message': errorMessage,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    } catch (e) {
      AppLogger.error('Failed to log auth attempt', e);
      // Don't rethrow for logging failures
    }
  }

  @override
  Future<bool> isUsernameAvailable(String username) async {
    try {
      final results = await _dbHelper.query(
        'users',
        columns: ['id'],
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );
      
      return results.isEmpty;
    } catch (e) {
      AppLogger.error('Failed to check username availability', e);
      return false;
    }
  }

  @override
  Future<void> savePasswordResetToken(String username, String token, DateTime expiresAt) async {
    try {
      await _dbHelper.insert('password_reset_tokens', {
        'username': username,
        'token': token,
        'expires_at': expiresAt.millisecondsSinceEpoch ~/ 1000,
        'used': 0,
        'created_at': DateTime.now().millisecondsSinceEpoch ~/ 1000,
      });
    } catch (e) {
      AppLogger.error('Failed to save password reset token', e);
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getPasswordResetToken(String token) async {
    try {
      final results = await _dbHelper.query(
        'password_reset_tokens',
        where: 'token = ? AND used = 0 AND expires_at > ?',
        whereArgs: [token, DateTime.now().millisecondsSinceEpoch ~/ 1000],
        limit: 1,
      );
      
      return results.isNotEmpty ? results.first : null;
    } catch (e) {
      AppLogger.error('Failed to get password reset token', e);
      return null;
    }
  }

  @override
  Future<void> markPasswordResetTokenUsed(String token) async {
    try {
      await _dbHelper.update(
        'password_reset_tokens',
        {'used': 1},
        where: 'token = ?',
        whereArgs: [token],
      );
    } catch (e) {
      AppLogger.error('Failed to mark password reset token as used', e);
      rethrow;
    }
  }
}