import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';

import '../../models/location.dart';
import '../../models/weather_report.dart';
import '../../weather_service.dart';
import 'api/open_meteo_air_quality_api.dart';
import 'api/open_meteo_forecast_api.dart';
import 'api/open_meteo_geocoding_api.dart';
import 'dto/open_meteo_air_quality_dto.dart';
import 'dto/open_meteo_forecast_dto.dart';
import 'dto/open_meteo_geocoding_dto.dart';
import 'open_meteo_mapper.dart';

/// Open-Meteo 适配器，内部处理搜索、Forecast 与空气质量服务差异。
///
/// GPS 不经过和风或第三方反向地理编码；Forecast 直接接收坐标并补全时区。
/// 核心天气失败返回 Failure，空气质量失败仅让报告的 AQI 保持 null。
class OpenMeteoWeatherAdapter implements WeatherService {
  /// 通用网络客户端，供搜索、天气预报和空气质量请求共享。
  final ApiClient _client;

  const OpenMeteoWeatherAdapter(this._client);

  @override
  Future<ApiResult<List<Location>>> searchLocations(
    String query,
    String languageCode, {
    CancelToken? cancelToken,
  }) async {
    final result = await OpenMeteoGeocodingApi(
      _client,
      query: query,
      languageCode: languageCode,
      cancelToken: cancelToken,
    ).send();
    return switch (result) {
      Failure<OpenMeteoGeocodingDto>(:final error, :final statusCode) =>
        Failure<List<Location>>(error, statusCode),
      Success<OpenMeteoGeocodingDto>(:final data, :final statusCode) =>
        _mapLocations(data, statusCode),
    };
  }

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) async {
    if (localizeLocation && location.origin != LocationOrigin.gps) {
      location = await _localizeLocation(location, languageCode, cancelToken);
    }
    final forecastFuture = OpenMeteoForecastApi(
      _client,
      location: location,
      cancelToken: cancelToken,
    ).send();
    final airQualityFuture = OpenMeteoAirQualityApi(
      _client,
      location: location,
      cancelToken: cancelToken,
    ).send();

    final forecastResult = await forecastFuture;
    if (forecastResult is Failure<OpenMeteoForecastDto>) {
      return Failure<WeatherReport>(
        forecastResult.error,
        forecastResult.statusCode,
      );
    }
    final forecast = (forecastResult as Success<OpenMeteoForecastDto>).data;
    if (forecast.error == true) {
      return Failure<WeatherReport>(
        const AppDataException('Open-Meteo forecast returned an error'),
        forecastResult.statusCode,
      );
    }

    final airQualityResult = await airQualityFuture;
    final airQuality = switch (airQualityResult) {
      Success<OpenMeteoAirQualityDto>(:final data) =>
        OpenMeteoMapper.toAirQuality(data, languageCode),
      Failure<OpenMeteoAirQualityDto>() => null,
    };
    try {
      return Success<WeatherReport>(
        OpenMeteoMapper.toWeatherReport(
          dto: forecast,
          location: location,
          languageCode: languageCode,
          airQuality: airQuality,
        ),
        forecastResult.statusCode,
      );
    } on AppException catch (error) {
      return Failure<WeatherReport>(error, forecastResult.statusCode);
    }
  }

  /// Open-Meteo 没有反向地理编码，语言变化时按原城市名重新搜索，
  /// 并选择与原坐标最接近的结果。地名服务失败不阻断核心天气请求。
  Future<Location> _localizeLocation(
    Location location,
    String languageCode,
    CancelToken? cancelToken,
  ) async {
    final name = location.name?.trim();
    if (name == null || name.isEmpty) return location;
    final result = await OpenMeteoGeocodingApi(
      _client,
      query: name,
      languageCode: languageCode,
      cancelToken: cancelToken,
    ).send();
    if (result is! Success<OpenMeteoGeocodingDto> ||
        result.data.error == true) {
      return location;
    }
    final candidates = OpenMeteoMapper.toLocations(result.data);
    if (candidates.isEmpty) return location;

    var nearest = candidates.first;
    var nearestDistance = double.infinity;
    for (final candidate in candidates) {
      final latitudeDelta = candidate.latitude - location.latitude;
      final longitudeDelta = candidate.longitude - location.longitude;
      final distance =
          latitudeDelta * latitudeDelta + longitudeDelta * longitudeDelta;
      if (distance < nearestDistance) {
        nearest = candidate;
        nearestDistance = distance;
      }
    }
    // 约 0.02° 的容差只用于确认同名结果仍是原城市，避免误换成远处同名地。
    if (nearestDistance > 0.0004) return location;
    return nearest.copyWith(
      clientId: location.clientId,
      origin: location.origin,
    );
  }

  ApiResult<List<Location>> _mapLocations(
    OpenMeteoGeocodingDto dto,
    int statusCode,
  ) {
    if (dto.error == true) {
      return Failure<List<Location>>(
        const AppDataException('Open-Meteo geocoding returned an error'),
        statusCode,
      );
    }
    return Success<List<Location>>(
      OpenMeteoMapper.toLocations(dto),
      statusCode,
    );
  }
}
