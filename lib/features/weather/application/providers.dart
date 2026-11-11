import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:module_network/network/api_client.dart';
import 'package:weather_app/features/weather/data/cache/sqflite_weather_cache.dart';
import 'package:weather_app/features/weather/data/datasources/device_location_data_source.dart';
import 'package:weather_app/features/weather/data/repositories/app_location_resolver.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_cache.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

/// 全局唯一的 Dio 实例，统一 JSON 响应、10 秒超时和状态码处理。
///
/// validateStatus 允许所有状态码通过，以便 BaseApi 将 4xx/5xx 转为 Failure；
/// Provider 销毁时同步关闭连接，避免资源泄漏。
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      validateStatus: (_) => true,
    ),
  );
  ref.onDispose(() => dio.close(force: true));
  return dio;
});

/// 共享 Dio 的纯传输客户端，具体天气 API 均通过它发出请求。
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(ref.watch(dioProvider)),
);

/// 当前天气服务，可在测试中替换为 Fake，避免真实网络。
final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  final provider = ref.watch(
    settingsControllerProvider.select((settings) => settings.weatherProvider),
  );
  return WeatherServiceFactory.create(
    ref.watch(apiClientProvider),
    provider: provider,
  );
});

/// 异步创建 SQLite 缓存，并在 Provider 销毁时关闭数据库连接。
final weatherCacheProvider = FutureProvider<WeatherCache>((ref) async {
  final cache = SqfliteWeatherCache();
  ref.onDispose(() => cache.close());
  return cache;
});

/// 共享定位数据源，供 GPS 解析与设置页权限状态使用同一平台边界。
final deviceLocationDataSourceProvider = Provider<DeviceLocationDataSource>(
  (ref) => DeviceLocationDataSource(),
);

/// 设置页的真实定位权限状态；返回页面时可 invalidate 重新读取。
final locationPermissionProvider =
    FutureProvider.autoDispose<LocationPermission>(
      (ref) => ref.watch(deviceLocationDataSourceProvider).checkPermission(),
    );

/// 前台 GPS 地点解析器，不包含 IP 回退。
final locationResolverProvider = Provider<LocationResolver>(
  (ref) => AppLocationResolver(
    deviceLocation: ref.watch(deviceLocationDataSourceProvider),
  ),
);
