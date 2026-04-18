import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/catalog/catalog_service.dart';
import '../../features/company/company_service.dart';
import '../../features/dashboard/data/dashboard_service.dart';
import '../../features/products/data/product_service.dart';
import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/plans/data/datasources/plans_remote_datasource.dart';
import '../../features/plans/data/repositories/plans_repository_impl.dart';
import '../../features/plans/domain/repositories/plans_repository.dart';
import '../config/flavor_config.dart';
import '../network/api_client.dart';
import '../network/dio_factory.dart';
import '../network/network_info.dart';
import '../storage/preferences_storage.dart';
import '../storage/secure_storage.dart';
import '../storage/token_storage.dart';

final GetIt sl = GetIt.instance;

/// Registers every dependency the app needs.
///
/// Called exactly once from `AppBootstrap.init`. Keeping the registrations
/// in one file gives a single source of truth for the object graph —
/// features stay easy to mock and swap.
Future<void> configureDependencies() async {
  // ─── Config ──────────────────────────────────────────────────────────
  sl.registerSingleton<FlavorConfig>(FlavorConfig.instance);

  // ─── Storage ─────────────────────────────────────────────────────────
  final prefs = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(prefs);
  sl.registerSingleton<PreferencesStorage>(PreferencesStorage(prefs));

  sl.registerSingleton<FlutterSecureStorage>(const FlutterSecureStorage());
  sl.registerSingleton<SecureStorage>(SecureStorageImpl(sl()));
  sl.registerSingleton<TokenStorage>(TokenStorage(sl()));

  // ─── Network ─────────────────────────────────────────────────────────
  sl.registerSingleton<Connectivity>(Connectivity());
  sl.registerSingleton<NetworkInfo>(NetworkInfoImpl(sl()));

  final factory = DioFactory(config: sl(), tokens: sl());
  sl.registerSingleton<DioFactory>(factory);

  // `onAuthFailed` is wired from the auth feature so the router can redirect
  // to /login. Kept as a mutable hook that the auth layer fills in at boot.
  final dio = factory.buildApiClient(onAuthFailed: runAuthFailedCallback);
  sl.registerSingleton<Dio>(dio);
  sl.registerSingleton<ApiClient>(ApiClient(dio));

  // ─── Features: Auth ──────────────────────────────────────────────────
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(
      remote: sl(),
      tokens: sl(),
      networkInfo: sl(),
    ),
  );
  sl.registerFactory(() => LoginUseCase(sl()));
  sl.registerFactory(() => RegisterUseCase(sl()));
  sl.registerFactory(() => LogoutUseCase(sl()));
  sl.registerFactory(() => GetCurrentUserUseCase(sl()));

  // ─── Features: Plans ─────────────────────────────────────────────────
  sl.registerLazySingleton<PlansRemoteDataSource>(
    () => PlansRemoteDataSourceImpl(sl()),
  );
  sl.registerLazySingleton<PlansRepository>(
    () => PlansRepositoryImpl(remote: sl(), networkInfo: sl()),
  );

  // ─── Shared catalog + company services ───────────────────────────────
  sl.registerLazySingleton<CatalogService>(() => CatalogService(sl()));
  sl.registerLazySingleton<CompanyService>(() => CompanyService(sl()));
  sl.registerLazySingleton<ProductService>(() => ProductService(sl()));
  sl.registerLazySingleton<DashboardService>(() => DashboardService(sl()));
}

/// Replaced at runtime by the auth layer so the refresh interceptor can
/// trigger a clean sign-out + router redirect without a circular import.
Future<void> Function() _onAuthFailed = () async {};

void setAuthFailedCallback(Future<void> Function() cb) {
  _onAuthFailed = cb;
}

Future<void> runAuthFailedCallback() => _onAuthFailed();
