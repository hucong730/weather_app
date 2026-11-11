import 'package:module_network/error/app_exception.dart';

import '../../models/location.dart';
import '../../models/weather_condition.dart';
import '../../models/weather_report.dart';
import '../../weather_provider.dart';
import 'dto/open_meteo_air_quality_dto.dart';
import 'dto/open_meteo_forecast_dto.dart';
import 'dto/open_meteo_geocoding_dto.dart';

/// 将 Open-Meteo 的字段、WMO 代码、时间和 US AQI 映射为统一模型。
///
/// 所有本地 ISO 时间都使用本次响应的 UTC 偏移换算，绝不读取设备时区；
/// 并行数组在索引取值前先完成等长、数量和连续性校验。
abstract final class OpenMeteoMapper {
  static List<Location> toLocations(OpenMeteoGeocodingDto dto) {
    return dto.results?.map((item) {
          return Location(
            id: item.id.toString(),
            name: item.name,
            admin1: item.admin1,
            country: item.country,
            latitude: item.latitude,
            longitude: item.longitude,
            timezone: item.timezone,
            origin: LocationOrigin.search,
          );
        }).toList() ??
        [];
  }

  static WeatherReport toWeatherReport({
    required OpenMeteoForecastDto dto,
    required Location location,
    required String languageCode,
    AirQuality? airQuality,
  }) {
    try {
      final offset = dto.utcOffsetSeconds;
      final resolvedLocation = location.copyWith(
        timezone: dto.timezone,
        utcOffsetSeconds: offset,
      );
      final hourly = _toHourly(dto.hourly, offset);
      final current = dto.current;
      return WeatherReport(
        location: resolvedLocation,
        timezone: dto.timezone,
        utcOffsetSeconds: offset,
        provider: WeatherProviderType.openMeteo,
        current: CurrentWeather(
          observedAtUtc: _localTimeToUtc(current.time, offset),
          temperature: current.temperature,
          apparentTemperature: current.apparentTemperature,
          humidity: current.humidity,
          precipitation: current.precipitation,
          windSpeed: current.windSpeed,
          condition: conditionFromWmoCode(current.weatherCode),
          isDay: current.isDay == 1,
          airQuality: airQuality,
        ),
        hourly: hourly,
        daily: _toDaily(dto.daily),
      );
    } on FormatException {
      throw const AppDataException('Open-Meteo timestamp is invalid');
    } on ArgumentError {
      throw const AppDataException('Open-Meteo timestamp is invalid');
    }
  }

  static AirQuality toAirQuality(
    OpenMeteoAirQualityDto dto,
    String languageCode,
  ) {
    final value = dto.current.usAqi;
    final chinese = languageCode.toLowerCase().startsWith('zh');
    final category = switch (value) {
      <= 50 => chinese ? '优' : 'Good',
      <= 100 => chinese ? '中等' : 'Moderate',
      <= 150 => chinese ? '对敏感人群不健康' : 'Unhealthy for Sensitive Groups',
      <= 200 => chinese ? '不健康' : 'Unhealthy',
      <= 300 => chinese ? '非常不健康' : 'Very Unhealthy',
      _ => chinese ? '危险' : 'Hazardous',
    };
    return AirQuality(
      displayValue: value.round().toString(),
      category: category,
    );
  }

  static List<HourlyForecast> _toHourly(
    OpenMeteoHourlyDto dto,
    int offsetSeconds,
  ) {
    final length = dto.time.length;
    if (length != 24 ||
        dto.temperature.length != length ||
        dto.precipitationProbability.length != length ||
        dto.weatherCode.length != length ||
        dto.isDay.length != length) {
      throw const AppDataException(
        'Expected 24 complete Open-Meteo hourly forecasts',
      );
    }
    final times = dto.time
        .map((value) => _localTimeToUtc(value, offsetSeconds))
        .toList();
    for (var index = 1; index < times.length; index++) {
      if (times[index].difference(times[index - 1]) !=
          const Duration(hours: 1)) {
        throw const AppDataException(
          'Open-Meteo hourly forecast is not consecutive',
        );
      }
    }
    return List.generate(length, (index) {
      return HourlyForecast(
        timeUtc: times[index],
        temperature: dto.temperature[index],
        precipitationProbability: dto.precipitationProbability[index],
        condition: conditionFromWmoCode(dto.weatherCode[index]),
        isDay: dto.isDay[index] == 1,
      );
    });
  }

  static List<DailyForecast> _toDaily(OpenMeteoDailyDto dto) {
    final length = dto.time.length;
    if (length != 7 ||
        dto.minTemperature.length != length ||
        dto.maxTemperature.length != length ||
        dto.precipitationProbability.length != length ||
        dto.weatherCode.length != length) {
      throw const AppDataException(
        'Expected 7 complete Open-Meteo daily forecasts',
      );
    }
    final dates = dto.time.map(_calendarDate).toList();
    for (var index = 1; index < dates.length; index++) {
      if (dates[index].difference(dates[index - 1]) !=
          const Duration(days: 1)) {
        throw const AppDataException(
          'Open-Meteo daily forecast is not consecutive',
        );
      }
    }
    return List.generate(length, (index) {
      return DailyForecast(
        date: dates[index],
        minTemperature: dto.minTemperature[index],
        maxTemperature: dto.maxTemperature[index],
        precipitationProbability: dto.precipitationProbability[index],
        condition: conditionFromWmoCode(dto.weatherCode[index]),
      );
    });
  }

  /// 带 Z/显式偏移的时间直接解析；无偏移文本按响应地点偏移换算 UTC。
  static DateTime _localTimeToUtc(String value, int offsetSeconds) {
    final hasExplicitZone = RegExp(r'(Z|[+-]\d{2}:?\d{2})$').hasMatch(value);
    if (hasExplicitZone) return DateTime.parse(value).toUtc();
    return DateTime.parse('${value}Z')
        .toUtc()
        .subtract(Duration(seconds: offsetSeconds));
  }

  static DateTime _calendarDate(String value) {
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Daily calendar date is invalid');
    }
    return DateTime.parse('${value}T00:00:00Z');
  }

  static WeatherCondition conditionFromWmoCode(int code) {
    return switch (code) {
      0 => WeatherCondition.clear,
      1 => WeatherCondition.mainlyClear,
      2 => WeatherCondition.partlyCloudy,
      3 => WeatherCondition.overcast,
      45 || 48 => WeatherCondition.fog,
      51 || 53 || 55 => WeatherCondition.drizzle,
      56 || 57 => WeatherCondition.freezingDrizzle,
      61 || 63 || 65 => WeatherCondition.rain,
      66 || 67 => WeatherCondition.freezingRain,
      71 || 73 || 75 => WeatherCondition.snow,
      77 => WeatherCondition.snowGrains,
      80 || 81 || 82 => WeatherCondition.showers,
      85 || 86 => WeatherCondition.snowShowers,
      95 => WeatherCondition.thunderstorm,
      96 || 99 => WeatherCondition.thunderstormHail,
      _ => WeatherCondition.unknown,
    };
  }
}
