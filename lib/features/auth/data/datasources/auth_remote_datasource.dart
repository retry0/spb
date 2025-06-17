import 'package:dio/dio.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokensModel> loginWithUsername(Map<String, dynamic> credentials);
  Future<void> logout();
  Future<AuthTokensModel> refreshToken(Map<String, dynamic> refreshData);
  Future<UserModel> getCurrentUser();
  Future<void> changePassword(Map<String, dynamic> data);
  Future<Map<String, dynamic>> checkUsernameAvailability(String username);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  @override
  Future<AuthTokensModel> loginWithUsername(
    Map<String, dynamic> credentials,
  ) async {
    final response = await _dio.post('/auth/login', data: credentials);
    return AuthTokensModel.fromJson(response.data);
  }

  @override
  Future logout() async {
    await _dio.post('/auth/logout');
  }

  @override
  Future<AuthTokensModel> refreshToken(Map<String, dynamic> refreshData) async {
    final response = await _dio.post('/auth/refresh', data: refreshData);
    return AuthTokensModel.fromJson(response.data);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get('/user/profile');
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> changePassword(Map<String, dynamic> data) async {
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
