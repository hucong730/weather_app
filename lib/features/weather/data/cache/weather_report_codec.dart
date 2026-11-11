import 'dart:convert';

import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:module_weather/weather_provider.dart';

/// WeatherReport 的 SQLite JSON 编解码器。
///
/// 不使用 json_serializable 是因为领域模型需要显式、稳定的缓存契约；
/// 解码时校验嵌套结构、枚举、数字和 UTC 时间，旧版本缺少可选字段可继续读取。
abstract final class WeatherReportCodec {
  /// 将完整报告编码为单个 JSON 字符串，不包含 KEY 或搜索历史。
  static String encode(WeatherReport report) => jsonEncode(report.toJson());

  /// 尝试恢复报告。
  ///
  /// JSON 损坏、根节点错误、字段类型错误或时间/枚举非法时返回 null，
  /// 让启动流程回退到 GPS/手动搜索，而不是让缓存异常导致 App 崩溃。
  static WeatherReport? tryDecode(String payload) {
    try {
      final json = jsonDecode(payload);
      if (json is! Map<String, dynamic>) return null;
      final location = _location(json['location']);
      return WeatherReport(
        location: location,
        timezone: json['timezone'] as String,
        utcOffsetSeconds: (json['utc_offset_seconds'] as num).toInt(),
        current: _current(json['current']),
        hourly: _hourly(json['hourly']),
        daily: _daily(json['daily']),
        // 旧缓存没有 provider，迁移前所有报告都由和风生成。
        provider: WeatherProviderType.values.byName(
          json['provider'] as String? ?? WeatherProviderType.qweather.name,
        ),
      );
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    } on ArgumentError {
      return null;
    }
  }

  static Location _location(Object? value) {
    final json = _object(value);
    return Location(
      // 旧缓存以原服务 ID 初始化一次 clientId，之后跨服务保持不变。
      clientId: json['client_id'] as String? ?? json['id'] as String?,
      id: json['id'] as String?,
      name: json['name'] as String?,
      admin1: json['admin1'] as String?,
      country: json['country'] as String?,
      latitude: _double(json['latitude']),
      longitude: _double(json['longitude']),
      timezone: json['timezone'] as String?,
      utcOffsetSeconds: (json['utc_offset_seconds'] as num?)?.toInt(),
      origin: LocationOrigin.values.byName(json['origin'] as String),
    );
  }

  static CurrentWeather _current(Object? value) {
    final json = _object(value);
    return CurrentWeather(
      observedAtUtc: _time(json['observed_at_utc']),
      temperature: _double(json['temperature']),
      apparentTemperature: _double(json['apparent_temperature']),
      humidity: (json['humidity'] as num).toInt(),
      precipitation: _double(json['precipitation']),
      windSpeed: _double(json['wind_speed']),
      condition: WeatherCondition.values.byName(json['condition'] as String),
      isDay: json['is_day'] as bool,
      airQuality: _airQuality(json['air_quality']),
    );
  }

  static AirQuality? _airQuality(Object? value) {
    if (value == null) return null;
    final json = _object(value);
    return AirQuality(
      displayValue: json['display_value'] as String,
      category: json['category'] as String,
    );
  }

  static List<HourlyForecast> _hourly(Object? value) {
    return _list(value).map((item) {
      final json = _object(item);
      return HourlyForecast(
        timeUtc: _time(json['time_utc']),
        temperature: _double(json['temperature']),
        precipitationProbability: (json['precipitation_probability'] as num?)
            ?.toInt(),
        condition: WeatherCondition.values.byName(json['condition'] as String),
        isDay: json['is_day'] as bool,
      );
    }).toList();
  }

  static List<DailyForecast> _daily(Object? value) {
    return _list(value).map((item) {
      final json = _object(item);
      return DailyForecast(
        date: _time(json['date']),
        minTemperature: _double(json['min_temperature']),
        maxTemperature: _double(json['max_temperature']),
        precipitationProbability: (json['precipitation_probability'] as num?)
            ?.toInt(),
        condition: WeatherCondition.values.byName(json['condition'] as String),
      );
    }).toList();
  }

  static Map<String, dynamic> _object(Object? value) {
    return (value as Map).cast<String, dynamic>();
  }

  static List<dynamic> _list(Object? value) => value as List<dynamic>;

  static double _double(Object? value) => (value as num).toDouble();

  static DateTime _time(Object? value) =>
      DateTime.parse(value as String).toUtc();
}
