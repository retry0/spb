import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../network/dio_client.dart';
import '../storage/secure_storage.dart';
import '../storage/local_storage.dart';
import '../storage/database_helper.dart';
import '../storage/data_repository.dart';
import '../utils/jwt_token_manager.dart';
import '../utils/session_manager.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/refresh_token_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/theme/presentation/bloc/theme_bloc.dart';
import '../../features/home/data/datasources/home_remote_datasource.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/presentation/bloc/home_bloc.dart';
import '../../features/profile/data/datasources/profile_remote_datasource.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/change_password_usecase.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/qr_code/data/datasources/qr_code_remote_datasource.dart';
import '../../features/qr_code/data/datasources/qr_code_local_datasource.dart';
import '../../features/qr_code/data/repositories/qr_code_repository_impl.dart';
import '../../features/qr_code/domain/repositories/qr_code_repository.dart';
import '../../features/qr_code/domain/usecases/generate_qr_code_usecase.dart';
import '../../features/qr_code/domain/usecases/save_qr_code_usecase.dart';
import '../../features/qr_code/domain/usecases/get_saved_qr_codes_usecase.dart';
import '../../features/qr_code/domain/usecases/export_qr_code_usecase.dart';
import '../../features/qr_code/domain/usecases/share_qr_code_usecase.dart';
import '../../features/qr_code/presentation/bloc/qr_code_bloc.dart';

final getIt = GetIt.instance;

@InjectableInit()
Future<void> configureDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(sharedPreferences);
  
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );
  getIt.registerSingleton<FlutterSecureStorage>(secureStorage);
  
  // Database
  getIt.registerSingleton<DatabaseHelper>(DatabaseHelper.instance);
  
  // Core services
  getIt.registerLazySingleton<SecureStorage>(
    () => SecureStorageImpl(getIt<FlutterSecureStorage>()),
  );
  
  getIt.registerLazySingleton<LocalStorage>(
    () => LocalStorageImpl(
      getIt<SharedPreferences>(),
      getIt<DatabaseHelper>(),
    ),
  );
  
  getIt.registerLazySingleton<DataRepository>(
    () => DataRepository(getIt<DatabaseHelper>()),
  );

  // JWT Token Manager
  getIt.registerLazySingleton<JwtTokenManager>(
    () => JwtTokenManager(getIt<FlutterSecureStorage>()),
  );
  
  // Session Manager
  getIt.registerLazySingleton<SessionManager>(
    () => SessionManager(
      getIt<SharedPreferences>(),
      getIt<FlutterSecureStorage>(),
      getIt<JwtTokenManager>(),
      sessionTimeoutMinutes: 30,
    ),
  );
  
  getIt.registerLazySingleton<Dio>(() => DioClient.createDio());
  
  // Utilities
  getIt.registerLazySingleton<Uuid>(() => const Uuid());
  
  // Data sources
  getIt.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(
      getIt<SecureStorage>(),
      getIt<DatabaseHelper>(),
    ),
  );
  
  getIt.registerLazySingleton<HomeRemoteDataSource>(
    () => HomeRemoteDataSourceImpl(getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<ProfileRemoteDataSource>(
    () => ProfileRemoteDataSourceImpl(getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<QrCodeRemoteDataSource>(
    () => QrCodeRemoteDataSourceImpl(dio: getIt<Dio>()),
  );
  
  getIt.registerLazySingleton<QrCodeLocalDataSource>(
    () => QrCodeLocalDataSourceImpl(
      dbHelper: getIt<DatabaseHelper>(),
      prefs: getIt<SharedPreferences>(),
    ),
  );
  
  // Repositories
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remoteDataSource: getIt<AuthRemoteDataSource>(),
      localDataSource: getIt<AuthLocalDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<HomeRepository>(
    () => HomeRepositoryImpl(
      remoteDataSource: getIt<HomeRemoteDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<ProfileRepository>(
    () => ProfileRepositoryImpl(
      authRepository: getIt<AuthRepository>(),
      remoteDataSource: getIt<ProfileRemoteDataSource>(),
    ),
  );
  
  getIt.registerLazySingleton<QrCodeRepository>(
    () => QrCodeRepositoryImpl(
      remoteDataSource: getIt<QrCodeRemoteDataSource>(),
      localDataSource: getIt<QrCodeLocalDataSource>(),
      uuid: getIt<Uuid>(),
    ),
  );
  
  // Use cases
  getIt.registerLazySingleton(() => LoginUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => LogoutUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => RefreshTokenUseCase(getIt<AuthRepository>()));
  getIt.registerLazySingleton(() => ChangePasswordUseCase(getIt<ProfileRepository>()));
  
  // QR Code use cases
  getIt.registerLazySingleton(() => GenerateQrCodeUseCase(getIt<QrCodeRepository>()));
  getIt.registerLazySingleton(() => SaveQrCodeUseCase(getIt<QrCodeRepository>()));
  getIt.registerLazySingleton(() => GetSavedQrCodesUseCase(getIt<QrCodeRepository>()));
  getIt.registerLazySingleton(() => ExportQrCodeUseCase(getIt<QrCodeRepository>()));
  getIt.registerLazySingleton(() => ShareQrCodeUseCase(getIt<QrCodeRepository>()));
  
  // BLoCs
  getIt.registerFactory(
    () => AuthBloc(
      loginUseCase: getIt<LoginUseCase>(),
      logoutUseCase: getIt<LogoutUseCase>(),
      refreshTokenUseCase: getIt<RefreshTokenUseCase>(),
      sessionManager: getIt<SessionManager>(),
    ),
  );
  
  getIt.registerFactory(() => ThemeBloc(getIt<LocalStorage>()));
  getIt.registerFactory(() => HomeBloc(getIt<HomeRepository>()));
  getIt.registerFactory(
    () => ProfileBloc(
      profileRepository: getIt<ProfileRepository>(),
      changePasswordUseCase: getIt<ChangePasswordUseCase>(),
    ),
  );
  
  getIt.registerFactory(
    () => QrCodeBloc(
      generateQrCodeUseCase: getIt<GenerateQrCodeUseCase>(),
      saveQrCodeUseCase: getIt<SaveQrCodeUseCase>(),
      getSavedQrCodesUseCase: getIt<GetSavedQrCodesUseCase>(),
      exportQrCodeUseCase: getIt<ExportQrCodeUseCase>(),
      shareQrCodeUseCase: getIt<ShareQrCodeUseCase>(),
    ),
  );
}