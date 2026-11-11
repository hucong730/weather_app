import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';

import '../../models/location.dart';
import '../../models/weather_report.dart';
import '../../weather_service.dart';
import 'api/qweather_air_quality_api.dart';
import 'api/qweather_city_lookup_api.dart';
import 'api/qweather_current_weather_api.dart';
import 'api/qweather_daily_forecast_api.dart';
import 'api/qweather_hourly_forecast_api.dart';
import 'dto/qweather_air_quality_dto.dart';
import 'dto/qweather_city_lookup_dto.dart';
import 'dto/qweather_daily_forecast_dto.dart';
import 'dto/qweather_hourly_forecast_dto.dart';
import 'dto/qweather_weather_dto.dart';
import 'qweather_config.dart';
import 'qweather_mapper.dart';

/// 和风天气适配器，负责具体 API 调用、地点补全和统一模型映射。
///
/// 当前、24 小时、7 天和空气质量并行请求；只有核心天气全部成功才生成报告。
/// 空气质量是附加信息，其失败仅降级为 null，不影响核心天气展示。
class QWeatherWeatherAdapter implements WeatherService {
  /// 通用网络客户端，仅负责传输，由具体请求对象定义接口和解码器。
  final ApiClient _client;

  /// 和风直连 Host 与认证配置，默认来自编译期环境变量。
  final QWeatherConfig _config;

  const QWeatherWeatherAdapter(
    this._client, {
    QWeatherConfig config = const QWeatherConfig.fromEnvironment(),
  }) : _config = config;

  @override
  Future<ApiResult<List<Location>>> searchLocations(
    String query,
    String languageCode, {
    CancelToken? cancelToken,
  }) async {
    final result = await QWeatherCityLookupApi(
      _client,
      query: query,
      languageCode: languageCode,
      config: _config,
      cancelToken: cancelToken,
    ).send();
    return switch (result) {
      Success<QWeatherCityLookupResponseDto>(:final data, :final statusCode) =>
        _mapLocations(data, statusCode),
      Failure<QWeatherCityLookupResponseDto>(:final error, :final statusCode) =>
        Failure<List<Location>>(error, statusCode),
    };
  }

  @override
  /// 获取完整天气报告。
  ///
  /// 先按当前语言补全地点，再并行发送四类请求。核心请求任一失败就返回
  /// 对应 Failure 和状态码，不拼接部分成功数据；映射异常保留 HTTP 200。
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) async {
    final locationResult = await _resolveLocation(
      location,
      languageCode,
      cancelToken,
      localizeLocation,
    );
    switch (locationResult) {
      case Failure<Location>(:final error, :final statusCode):
        return Failure<WeatherReport>(error, statusCode);
      case Success<Location>(:final data):
        location = data;
    }

    final currentFuture = QWeatherCurrentWeatherApi(
      _client,
      location: location,
      languageCode: languageCode,
      config: _config,
      cancelToken: cancelToken,
    ).send();
    final hourlyFuture = QWeatherHourlyForecastApi(
      _client,
      location: location,
      languageCode: languageCode,
      config: _config,
      cancelToken: cancelToken,
    ).send();
    final dailyFuture = QWeatherDailyForecastApi(
      _client,
      location: location,
      languageCode: languageCode,
      config: _config,
      cancelToken: cancelToken,
    ).send();
    final airQualityFuture = QWeatherAirQualityApi(
      _client,
      location: location,
      languageCode: languageCode,
      config: _config,
      cancelToken: cancelToken,
    ).send();

    final currentResult = await currentFuture;
    if (currentResult is Failure<QWeatherCurrentWeatherDto>) {
      return Failure<WeatherReport>(
        currentResult.error,
        currentResult.statusCode,
      );
    }
    final hourlyResult = await hourlyFuture;
    if (hourlyResult is Failure<QWeatherHourlyForecastDto>) {
      return Failure<WeatherReport>(
        hourlyResult.error,
        hourlyResult.statusCode,
      );
    }
    final dailyResult = await dailyFuture;
    if (dailyResult is Failure<QWeatherDailyForecastDto>) {
      return Failure<WeatherReport>(dailyResult.error, dailyResult.statusCode);
    }
    final airQualityResult = await airQualityFuture;
    final airQuality = switch (airQualityResult) {
      Success<QWeatherAirQualityResponseDto>(:final data) =>
        QWeatherMapper.toAirQuality(data),
      Failure<QWeatherAirQualityResponseDto>() => null,
    };

    try {
      final report = QWeatherMapper.toWeatherReport(
        current: (currentResult as Success<QWeatherCurrentWeatherDto>).data,
        hourly: (hourlyResult as Success<QWeatherHourlyForecastDto>).data,
        daily: (dailyResult as Success<QWeatherDailyForecastDto>).data,
        location: location,
        utcOffsetSeconds: location.utcOffsetSeconds!,
        airQuality: airQuality,
      );
      return Success<WeatherReport>(report, currentResult.statusCode);
    } on AppException catch (error) {
      return Failure<WeatherReport>(error, currentResult.statusCode);
    }
  }

  Future<ApiResult<Location>> _resolveLocation(
    Location location,
    String languageCode,
    CancelToken? cancelToken,
    bool localizeLocation,
  ) async {
    // 搜索城市在普通刷新时直接复用时区和名称。语言变化时按原城市名重新
    // 查询，不能用坐标反查：和风的最近地点可能是区县（例如武汉返回江岸区）。
    if (!localizeLocation &&
        location.origin == LocationOrigin.search &&
        location.timezone != null &&
        location.utcOffsetSeconds != null) {
      return Success<Location>(location, 200);
    }
    final originalName = location.name?.trim();
    final localizeByName =
        localizeLocation &&
        location.origin == LocationOrigin.search &&
        originalName?.isNotEmpty == true;
    final result = await QWeatherCityLookupApi(
      _client,
      query: localizeByName
          ? originalName!
          : '${location.longitude},${location.latitude}',
      languageCode: languageCode,
      resultLimit: localizeByName ? 20 : 1,
      config: _config,
      cancelToken: cancelToken,
    ).send();
    switch (result) {
      case Failure<QWeatherCityLookupResponseDto>(
        :final error,
        :final statusCode,
      ):
        return Failure<Location>(error, statusCode);
      case Success<QWeatherCityLookupResponseDto>(
        :final data,
        :final statusCode,
      ):
        if (data.code != '200' || data.location?.isEmpty != false) {
          return Failure<Location>(
            const AppDataException('Location could not be resolved'),
            statusCode,
          );
        }
        try {
          final candidates = QWeatherMapper.toLocations(data);
          var resolved = candidates.first;
          if (localizeByName) {
            // 优先匹配原服务 ID；跨天气服务时 ID 不通用，则选择原坐标附近
            // 的同名结果，防止切换到另一座城市。
            Location? sameCity;
            var nearestDistance = double.infinity;
            for (final candidate in candidates) {
              if (location.id != null && candidate.id == location.id) {
                sameCity = candidate;
                break;
              }
              final latitudeDelta = candidate.latitude - location.latitude;
              final longitudeDelta = candidate.longitude - location.longitude;
              final distance =
                  latitudeDelta * latitudeDelta +
                  longitudeDelta * longitudeDelta;
              if (distance < nearestDistance) {
                nearestDistance = distance;
                sameCity = candidate;
              }
            }
            if (sameCity == null ||
                (sameCity.id != location.id && nearestDistance > 0.0004)) {
              return Failure<Location>(
                const AppDataException('Original city could not be localized'),
                statusCode,
              );
            }
            resolved = sameCity;
          }
          return Success<Location>(
            resolved.copyWith(
              clientId: location.clientId,
              origin: location.origin,
            ),
            statusCode,
          );
        } on AppException catch (error) {
          return Failure<Location>(error, statusCode);
        }
    }
  }

  ApiResult<List<Location>> _mapLocations(
    QWeatherCityLookupResponseDto dto,
    int statusCode,
  ) {
    // 和风 GeoAPI 使用业务 404 表示没有匹配地点，这是正常空结果，
    // 不是网络或服务不可用；其他业务错误仍保留 Failure 与状态码。
    if (dto.code == '404') {
      return Success<List<Location>>(const [], statusCode);
    }
    if (dto.code != '200') {
      return Failure<List<Location>>(
        AppDataException('QWeather error code ${dto.code}'),
        statusCode,
      );
    }
    try {
      return Success<List<Location>>(
        QWeatherMapper.toLocations(dto),
        statusCode,
      );
    } on AppException catch (error) {
      return Failure<List<Location>>(error, statusCode);
    }
  }
}
