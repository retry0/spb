import '../../../../core/storage/secure_storage.dart';
import '../../../../core/storage/database_helper.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/utils/logger.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> saveToken(String token);
  Future<String?> getAccessToken();
  Future<void> clearToken();
  Future<void> saveUser(UserModel user);
  Future<UserModel?> getUser(String userName);
  Future<UserModel?> getUserById(String userId);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String userName);
  Future<bool> isUserNameAvailable(String userName);
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final SecureStorage _secureStorage;
  final DatabaseHelper _dbHelper;

  AuthLocalDataSourceImpl(this._secureStorage, this._dbHelper);

  @override
  Future<void> saveToken(String token) async {
    await _secureStorage.write(StorageKeys.accessToken, token);
  }

  @override
  Future<String?> getAccessToken() async {
    return await _secureStorage.read(StorageKeys.accessToken);
  }

  @override
  Future<void> clearToken() async {
    await _secureStorage.delete(StorageKeys.accessToken);
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
  Future<UserModel?> getUser(String userName) async {
    try {
      final results = await _dbHelper.query(
        'users',
        where: 'username = ?',
        whereArgs: [userName],
        limit: 1,
      );

      if (results.isNotEmpty) {
        return UserModel.fromDatabase(results.first);
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get user by userName', e);
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
        whereArgs: [user.Id],
      );
    } catch (e) {
      AppLogger.error('Failed to update user', e);
      rethrow;
    }
  }

  @override
  Future<void> deleteUser(String userName) async {
    try {
      await _dbHelper.delete(
        'users',
        where: 'username = ?',
        whereArgs: [userName],
      );
    } catch (e) {
      AppLogger.error('Failed to delete user', e);
      rethrow;
    }
  }

  @override
  Future<bool> isUserNameAvailable(String userName) async {
    try {
      final results = await _dbHelper.query(
        'users',
        columns: ['id'],
        where: 'username = ?',
        whereArgs: [userName],
        limit: 1,
      );

      return results.isEmpty;
    } catch (e) {
      AppLogger.error('Failed to check userName availability', e);
      return false;
    }
  }
}
