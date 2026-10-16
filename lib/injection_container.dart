import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

import 'config/navigation/app_navigator.dart';
import 'core/services/external_link_service.dart';
import 'core/show/show.dart';
import 'data/datasources/connectivity/connectivity_data_source.dart';
import 'data/datasources/pack/curated_pack_data_source.dart';
import 'data/datasources/pack/exchange_rate_remote_data_source.dart';
import 'data/datasources/pack/pack_local_data_source.dart';
import 'data/datasources/pack/weather_remote_data_source.dart';
import 'data/datasources/theme/theme_data_source.dart';
import 'data/datasources/user/user_data_sources.dart';
import 'data/repositories/local/local_storage_repository.dart';
import 'data/repositories/network/dio/dio_network_repository.dart';
import 'data/repositories/network/errors/api_error_handler.dart';
import 'data/repositories/pack/country_pack_repository.dart';
import 'domain/repositories/local/local_storage_base_api_service.dart';
import 'domain/repositories/network/network_base_api_service.dart';
import 'domain/repositories/pack/pack_base_api_service.dart';
import 'domain/usecases/theme/get_theme_use_case.dart';
import 'domain/usecases/theme/update_theme_use_case.dart';
import 'features/bottom_nav/bottom_nav_cubit.dart';
import 'features/bottom_nav/bottom_nav_initial_params.dart';
import 'features/bottom_nav/bottom_nav_navigator.dart';
import 'features/pack_browser/pack_browser_cubit.dart';
import 'features/pack_browser/pack_browser_initial_params.dart';
import 'features/pack_browser/pack_browser_navigator.dart';
import 'features/pack_detail/pack_detail_cubit.dart';
import 'features/pack_detail/pack_detail_initial_params.dart';
import 'features/pack_detail/pack_detail_navigator.dart';
import 'features/settings/settings_cubit.dart';
import 'features/settings/settings_initial_params.dart';
import 'features/splash/splash_cubit.dart';
import 'features/splash/splash_initial_params.dart';
import 'features/splash/splash_navigator.dart';

final getIt = GetIt.instance;

Future<void> init() async {
  // Local storage comes first and is awaited: every pack screen reads from Hive,
  // so the boxes must be open before the first route resolves a cubit.
  getIt.registerSingleton<PackLocalDataSource>(PackLocalDataSource());
  await getIt<PackLocalDataSource>().init();

  getIt.registerSingleton<AppNavigator>(AppNavigator());
  getIt.registerSingleton<UserDataSources>(UserDataSources());
  getIt.registerSingleton<LocalStorageBaseApiService>(LocalStorageRepository());
  getIt.registerSingleton<ApiErrorHandler>(const ApiErrorHandler());
  getIt.registerSingleton<NetworkBaseApiService>(
    DioNetworkRepository(getIt(), getIt(), getIt()),
  );
  getIt.registerSingleton<ThemeDataSources>(ThemeDataSources());
  getIt.registerSingleton<GetThemeUseCase>(GetThemeUseCase(getIt(), getIt()));
  getIt.registerSingleton<UpdateThemeUseCase>(
    UpdateThemeUseCase(getIt(), getIt()),
  );
  getIt.registerSingleton<Show>(Show());
  getIt.registerSingleton<ExternalLinkService>(const ExternalLinkService());

  // Connectivity drives the "you are offline" banner only. Downloads always
  // attempt the network and treat a failed request as the real authority, so a
  // captive portal cannot block an install.
  getIt.registerSingleton<ConnectivityDataSource>(
    ConnectivityDataSource(Connectivity()),
  );

  // Country packs: bundled editorial content plus two keyless live sources.
  getIt.registerSingleton<CuratedPackDataSource>(CuratedPackDataSource());
  getIt.registerSingleton<WeatherRemoteDataSource>(
    WeatherRemoteDataSource(getIt()),
  );
  getIt.registerSingleton<ExchangeRateRemoteDataSource>(
    ExchangeRateRemoteDataSource(getIt()),
  );
  getIt.registerSingleton<PackBaseApiService>(
    CountryPackRepository(getIt(), getIt(), getIt(), getIt()),
  );

  getIt.registerSingleton<SplashNavigator>(SplashNavigator(getIt()));
  getIt.registerSingleton<BottomNavNavigator>(BottomNavNavigator(getIt()));
  getIt.registerSingleton<PackBrowserNavigator>(PackBrowserNavigator(getIt()));
  getIt.registerSingleton<PackDetailNavigator>(PackDetailNavigator(getIt()));

  getIt.registerFactoryParam<SplashCubit, SplashInitialParams, dynamic>(
    (params, _) => SplashCubit(params, getIt(), getIt()),
  );
  getIt.registerFactoryParam<BottomNavCubit, BottomNavInitialParams, dynamic>(
    (params, _) => BottomNavCubit(params, getIt()),
  );
  getIt.registerFactoryParam<
    PackBrowserCubit,
    PackBrowserInitialParams,
    dynamic
  >((params, _) => PackBrowserCubit(params, getIt(), getIt(), getIt(), getIt()));
  getIt.registerFactoryParam<PackDetailCubit, PackDetailInitialParams, dynamic>(
    (params, _) => PackDetailCubit(params, getIt(), getIt(), getIt()),
  );
  getIt.registerFactoryParam<SettingsCubit, SettingsInitialParams, dynamic>(
    (params, _) =>
        SettingsCubit(params, getIt(), getIt(), getIt(), getIt(), getIt()),
  );
}
