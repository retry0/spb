import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/database_helper.dart';
import '../../../../core/constants/storage_keys.dart';
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
  Future<bool> isUsernameAvailable(String username);
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
}