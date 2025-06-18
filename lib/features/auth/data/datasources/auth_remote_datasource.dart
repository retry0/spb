import 'package:dio/dio.dart';
import '../../../../core/config/api_endpoints.dart';
import '../models/auth_tokens_model.dart';
import '../../../../core/utils/logger.dart';

abstract class AuthRemoteDataSource {
  Future<AuthTokensModel> loginWithUserName(Map<String, dynamic> credentials);
  Future<void> logout();
  Future<void> changePassword(Map<String, dynamic> data);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio _dio;

  AuthRemoteDataSourceImpl(this._dio);

  @override
  Future<AuthTokensModel> loginWithUserName(
    Map<String, dynamic> credentials,
  ) async {
    final response = await _dio.post(ApiEndpoints.login, data: credentials);
    AppLogger.info('RES encode ${response.data['data']}');
    return AuthTokensModel.fromJson(response.data['data']);
  }

  @override
  Future<void> logout() async {
    await _dio.post(ApiEndpoints.logout);
  }

  @override
  Future<void> changePassword(Map<String, dynamic> data) async {
    await _dio.post(ApiEndpoints.changePassword, data: data);
  }

  // @override
  // Future<Map<String, dynamic>> checkUserNameAvailability(
  //   String userName,
  // ) async {
  //   final endpoint = ApiEndpoints.withQuery(ApiEndpoints.userNameCheck, {
  //     'userName': userName,
  //   });
  //   final response = await _dio.get(endpoint);
  //   return response.data;
  // }
}
