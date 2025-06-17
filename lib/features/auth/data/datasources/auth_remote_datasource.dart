import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/user_model.dart';
import '../models/auth_tokens_model.dart';

part 'auth_remote_datasource.g.dart';

@RestApi()
abstract class AuthRemoteDataSource {
  factory AuthRemoteDataSource(Dio dio) = _AuthRemoteDataSource;

  @POST('/auth/login')
  Future<AuthTokensModel> loginWithUsername(@Body() Map<String, dynamic> credentials);

  @POST('/auth/logout')
  Future<void> logout();

  @POST('/auth/refresh')
  Future<AuthTokensModel> refreshToken(@Body() Map<String, dynamic> refreshData);

  @GET('/user/profile')
  Future<UserModel> getCurrentUser();

  @POST('/auth/password-reset/request')
  Future<void> requestPasswordReset(@Body() Map<String, dynamic> data);

  @POST('/auth/password-reset/confirm')
  Future<void> resetPassword(@Body() Map<String, dynamic> data);

  @POST('/auth/password/change')
  Future<void> changePassword(@Body() Map<String, dynamic> data);

  @GET('/auth/username/check')
  Future<Map<String, dynamic>> checkUsernameAvailability(@Query('username') String username);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthTokensModel> loginWithUsername(Map<String, dynamic> credentials) async {
    final response = await _dio.post('/auth/login', data: credentials);
    return AuthTokensModel.fromJson(response.data);
  }

  @override
  Future<void> logout() async {
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
  Future<void> requestPasswordReset(Map<String, dynamic> data) async {
    await _dio.post('/auth/password-reset/request', data: data);
  }

  @override
  Future<void> resetPassword(Map<String, dynamic> data) async {
    await _dio.post('/auth/password-reset/confirm', data: data);
  }

  @override
  Future<void> changePassword(Map<String, dynamic> data) async {
    await _dio.post('/auth/password/change', data: data);
  }

  @override
  Future<Map<String, dynamic>> checkUsernameAvailability(String username) async {
    final response = await _dio.get('/auth/username/check', queryParameters: {'username': username});
    return response.data;
  }
}