import 'package:module_network/error/app_exception.dart';

import '../../models/location.dart';
import '../../models/weather_condition.dart';
import '../../models/weather_report.dart';
import 'dto/qweather_air_quality_dto.dart';
import 'dto/qweather_city_lookup_dto.dart';
import 'dto/qweather_daily_forecast_dto.dart';
import 'dto/qweather_hourly_forecast_dto.dart';
import 'dto/qweather_weather_dto.dart';

/// 和风 DTO 到领域模型的集中映射器。
///
/// 负责坐标/时区解析、单位换算、天气代码归一化、预报数量与时间连续性校验。
/// 所有关键数据异常统一抛出 AppDataException，防止不完整数据进入 UI。
abstract final class QWeatherMapper {
  /// 按中国标准、美国 EPA、和风通用 QAQI 的优先级选择空气质量。
  ///
  /// 使用官方推荐的 aqiDisplay 和本地化 category；没有可用指数时返回 null。
  static AirQuality? toAirQuality(QWeatherAirQualityResponseDto dto) {
    for (final code in const ['cn-mee', 'us-epa', 'qaqi']) {
      for (final item in dto.indexes) {
        if (item.code == code) {
          return AirQuality(
            displayValue: item.aqiDisplay,
            category: item.category,
          );
        }
      }
    }
    return null;
  }

  static List<Location> toLocations(QWeatherCityLookupResponseDto dto) {
    return dto.location?.map(toLocation).toList() ?? [];
  }

  static Location toLocation(
    QWeatherLocationDto dto, {
    LocationOrigin origin = LocationOrigin.search,
  }) {
    final latitude = double.tryParse(dto.lat);
    final longitude = double.tryParse(dto.lon);
    final timezone = dto.tz;
    final utcOffset = dto.utcOffset;
    if (latitude == null ||
        longitude == null ||
        timezone == null ||
        utcOffset == null) {
      throw const AppDataException('Location data is incomplete');
    }
    return Location(
      id: dto.id,
      name: dto.name,
      admin1: dto.adm1 ?? dto.adm2,
      country: dto.country,
      latitude: latitude,
      longitude: longitude,
      timezone: timezone,
      utcOffsetSeconds: parseUtcOffset(utcOffset),
      origin: origin,
    );
  }

  static int parseUtcOffset(String value) {
    final match = RegExp(r'^([+-])(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) {
      throw const AppDataException('Location UTC offset is invalid');
    }
    final hours = int.parse(match.group(2)!);
    final minutes = int.parse(match.group(3)!);
    if (minutes > 59) {
      throw const AppDataException('Location UTC offset is invalid');
    }
    final seconds = (hours * 3600) + (minutes * 60);
    return match.group(1) == '-' ? -seconds : seconds;
  }

  /// 合并当前、小时、每日和可选空气质量为领域报告。
  ///
  /// 当前接口不提供观测时间时，使用首条小时预报作为时间基准；
  /// 湿度/概率从 0–1 转为百分比，风速从 m/s 转为 km/h。
  static WeatherReport toWeatherReport({
    required QWeatherCurrentWeatherDto current,
    required QWeatherHourlyForecastDto hourly,
    required QWeatherDailyForecastDto daily,
    required Location location,
    required int utcOffsetSeconds,
    AirQuality? airQuality,
  }) {
    try {
      final hours = _mapHourly(hourly);
      return WeatherReport(
        location: location.copyWith(utcOffsetSeconds: utcOffsetSeconds),
        timezone: location.timezone!,
        utcOffsetSeconds: utcOffsetSeconds,
        current: CurrentWeather(
          observedAtUtc: hours.first.timeUtc,
          temperature: current.temperature.value,
          apparentTemperature: current.feelsLike.value,
          humidity: _percentage(current.humidity)!,
          precipitation: current.precipitation.amount.value,
          windSpeed: current.wind.speed.value * 3.6,
          condition: conditionFromCode(current.condition.code),
          isDay: isDayCode(current.condition.code),
          airQuality: airQuality,
        ),
        hourly: hours,
        daily: _mapDaily(daily, utcOffsetSeconds),
      );
    } on FormatException {
      throw const AppDataException('Forecast timestamp is invalid');
    }
  }

  static List<HourlyForecast> _mapHourly(QWeatherHourlyForecastDto dto) {
    if (dto.hours.length != 24) {
      throw const AppDataException('Expected exactly 24 hourly forecasts');
    }
    final times = dto.hours
        .map((item) => DateTime.parse(item.forecastTime).toUtc())
        .toList();
    for (var index = 1; index < times.length; index++) {
      if (times[index].difference(times[index - 1]) !=
          const Duration(hours: 1)) {
        throw const AppDataException('Hourly forecast is not consecutive');
      }
    }
    return List.generate(24, (index) {
      final item = dto.hours[index];
      return HourlyForecast(
        timeUtc: times[index],
        temperature: item.temperature.value,
        precipitationProbability: _percentage(item.precipitation.probability),
        condition: conditionFromCode(item.condition.code),
        isDay: isDayCode(item.condition.code),
      );
    });
  }

  static List<DailyForecast> _mapDaily(
    QWeatherDailyForecastDto dto,
    int utcOffsetSeconds,
  ) {
    if (dto.days.length != 7) {
      throw const AppDataException('Expected exactly 7 daily forecasts');
    }
    return dto.days.map((item) {
      return DailyForecast(
        date: _dailyCalendarDate(item.forecastStartTime, utcOffsetSeconds),
        minTemperature: item.temperatureMin.value,
        maxTemperature: item.temperatureMax.value,
        precipitationProbability: _percentage(
          item.daytime.precipitation.probability,
        ),
        condition: conditionFromCode(item.daytime.condition.code),
      );
    }).toList();
  }

  /// 从每日预报时间提取地点本地日历日，并统一保存为该日 UTC 零点。
  ///
  /// 当前请求使用 localTime=true，非 Z 时间直接采用原文的年月日，避免
  /// 夏令时切换日错误复用地点当前偏移。对旧测试或历史数据中的 Z 时间，
  /// 仍按调用方提供的偏移换算，保持原有兼容行为；完整时间先由 parse 校验。
  static DateTime _dailyCalendarDate(String value, int fallbackOffsetSeconds) {
    final timestamp = DateTime.parse(value);
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(value);
    if (match == null) {
      throw const FormatException('Daily forecast date is invalid');
    }
    if (!value.endsWith('Z')) {
      return DateTime.utc(
        int.parse(match.group(1)!),
        int.parse(match.group(2)!),
        int.parse(match.group(3)!),
      );
    }
    final localDate = timestamp.toUtc().add(
      Duration(seconds: fallbackOffsetSeconds),
    );
    return DateTime.utc(localDate.year, localDate.month, localDate.day);
  }

  static int? _percentage(double? ratio) {
    return ratio == null ? null : (ratio * 100).round();
  }

  static bool isDayCode(String code) {
    return !const {
      '150',
      '151',
      '152',
      '153',
      '350',
      '351',
      '456',
      '457',
    }.contains(code);
  }

  static WeatherCondition conditionFromCode(String code) {
    return switch (code) {
      '100' || '150' => WeatherCondition.clear,
      '101' || '151' => WeatherCondition.mainlyClear,
      '102' || '152' || '103' || '153' => WeatherCondition.partlyCloudy,
      '104' => WeatherCondition.overcast,
      '300' || '301' || '350' || '351' => WeatherCondition.showers,
      '302' || '303' => WeatherCondition.thunderstorm,
      '304' => WeatherCondition.thunderstormHail,
      '305' ||
      '306' ||
      '307' ||
      '308' ||
      '309' ||
      '314' ||
      '318' ||
      '399' => WeatherCondition.rain,
      '310' ||
      '311' ||
      '312' ||
      '313' ||
      '316' ||
      '317' => WeatherCondition.freezingRain,
      '400' ||
      '401' ||
      '402' ||
      '403' ||
      '404' ||
      '405' ||
      '406' ||
      '407' ||
      '408' ||
      '409' ||
      '410' ||
      '499' => WeatherCondition.snow,
      '456' || '457' => WeatherCondition.snowShowers,
      '500' ||
      '501' ||
      '509' ||
      '510' ||
      '514' ||
      '515' => WeatherCondition.fog,
      _ => WeatherCondition.unknown,
    };
  }
}
