import 'package:dio/dio.dart';
import '../../../../core/config/api_endpoints.dart';
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
  Future<AuthTokensModel> loginWithUsername(
    Map<String, dynamic> credentials,
  ) async {
    final response = await _dio.post(ApiEndpoints.login, data: credentials);
    return AuthTokensModel.fromJson(response.data);
  }

  @override
  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
  }

  @override
  Future<AuthTokensModel> refreshToken(Map<String, dynamic> refreshData) async {
    final response = await _dio.post(ApiEndpoints.refresh, data: refreshData);
    return AuthTokensModel.fromJson(response.data);
  }

  @override
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> changePassword(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.changePassword, data: data);
  }

  @override
  Future<Map<String, dynamic>> checkUsernameAvailability(
    String username,
  ) async {
    final endpoint = ApiEndpoints.withQuery(
      ApiEndpoints.usernameCheck,
      {'username': username},
    );
    final response = await _dio.get(endpoint);
    return response.data;
  }
}