import 'package:dio/dio.dart';
import '../../../../core/config/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokensModel> loginWithUserName(Map<String, dynamic> credentials);
  Future<void> logout();
  Future<UserModel> getCurrentUser();
  Future<void> changePassword(Map<String, dynamic> data);
  Future<Map<String, dynamic>> checkUserNameAvailability(String userName);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthTokensModel> loginWithUserName(
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
  Future<UserModel> getCurrentUser() async {
    final response = await _dio.get(ApiEndpoints.profile);
    return UserModel.fromJson(response.data);
  }

  @override
  Future<void> changePassword(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.changePassword, data: data);
  }

  @override
  Future<Map<String, dynamic>> checkUserNameAvailability(
    String userName,
  ) async {
    final endpoint = ApiEndpoints.withQuery(ApiEndpoints.userNameCheck, {
      'userName': userName,
    });
    final response = await _dio.get(endpoint);
    return response.data;
  }
}