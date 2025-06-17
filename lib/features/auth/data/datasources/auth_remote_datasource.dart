import 'package:dio/dio.dart';
<<<<<<< HEAD
=======

>>>>>>> 51ee234352a17f5d388bc3b671fd5e5a8578b12a
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';

abstract class AuthRemoteDataSource {
<<<<<<< HEAD
  Future loginWithUsername(Map<String, dynamic> credentials);
  Future logout();
  Future refreshToken(Map<String, dynamic> refreshData);
  Future getCurrentUser();
  Future requestPasswordReset(Map<String, dynamic> data);
  Future resetPassword(Map<String, dynamic> data);
  Future changePassword(Map<String, dynamic> data);
=======
  Future<AuthTokensModel> loginWithUsername(Map<String, dynamic> credentials);
  Future<void> logout();
  Future<AuthTokensModel> refreshToken(Map<String, dynamic> refreshData);
  Future<UserModel> getCurrentUser();
  Future<void> changePassword(Map<String, dynamic> data);
>>>>>>> 51ee234352a17f5d388bc3b671fd5e5a8578b12a
  Future<Map<String, dynamic>> checkUsernameAvailability(String username);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future loginWithUsername(Map<String, dynamic> credentials) async {
    final response = await _dio.post('/auth/login', data: credentials);
    return AuthTokensModel.fromJson(response.data);
  }

  @override
  Future logout() async {
    await _dio.post('/auth/logout');
  }

  @override
  Future refreshToken(Map<String, dynamic> refreshData) async {
    final response = await _dio.post('/auth/refresh', data: refreshData);
    return AuthTokensModel.fromJson(response.data);
  }

  @override
  Future getCurrentUser() async {
    final response = await _dio.get('/user/profile');
    return UserModel.fromJson(response.data);
  }

  @override
<<<<<<< HEAD
  Future requestPasswordReset(Map<String, dynamic> data) async {
    await _dio.post('/auth/password-reset/request', data: data);
  }

  @override
  Future resetPassword(Map<String, dynamic> data) async {
    await _dio.post('/auth/password-reset/confirm', data: data);
  }

  @override
  Future changePassword(Map<String, dynamic> data) async {
=======
  Future<void> changePassword(Map<String, dynamic> data) async {
>>>>>>> 51ee234352a17f5d388bc3b671fd5e5a8578b12a
    await _dio.post('/auth/password/change', data: data);
  }

  @override
  Future<Map<String, dynamic>> checkUsernameAvailability(
    String username,
  ) async {
    final response = await _dio.get(
      '/auth/username/check',
      queryParameters: {'username': username},
    );
    return response.data;
  }
}
