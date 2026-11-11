import 'package:module_network/models/json_model.dart';

import '../weather_provider.dart';
import 'location.dart';
import 'weather_condition.dart';

/// 一份完整的地点天气报告，也是 SQLite 缓存的基本单元。
///
/// 包含地点、当前天气、连续 24 小时预报和 7 天预报；时间统一以 UTC
/// 保存，展示时根据 [utcOffsetSeconds] 转换，避免受设备时区影响。
class WeatherReport extends JsonModel {
  /// 报告对应的统一地点，包含稳定页面身份和来源信息。
  final Location location;

  /// 服务商最终确认的 IANA 时区名称，可能与初始地点补全结果不同。
  final String timezone;

  /// 报告地点相对 UTC 的偏移秒数，供所有时间展示统一换算。
  final int utcOffsetSeconds;

  /// 当前观测天气及可选空气质量。
  final CurrentWeather current;

  /// 从当前小时开始、连续排列的 24 条小时预报。
  final List<HourlyForecast> hourly;

  /// 按地点本地日历顺序排列的连续 7 天预报。
  final List<DailyForecast> daily;

  /// 实际生成本报告的数据来源，用于缓存兼容和正确来源声明。
  final WeatherProviderType provider;

  const WeatherReport({
    required this.location,
    required this.timezone,
    required this.utcOffsetSeconds,
    required this.current,
    required this.hourly,
    required this.daily,
    this.provider = WeatherProviderType.qweather,
  });

  @override
  WeatherReport copyWith({
    Location? location,
    String? timezone,
    int? utcOffsetSeconds,
    CurrentWeather? current,
    List<HourlyForecast>? hourly,
    List<DailyForecast>? daily,
    WeatherProviderType? provider,
  }) {
    return WeatherReport(
      location: location ?? this.location,
      timezone: timezone ?? this.timezone,
      utcOffsetSeconds: utcOffsetSeconds ?? this.utcOffsetSeconds,
      current: current ?? this.current,
      hourly: hourly ?? this.hourly,
      daily: daily ?? this.daily,
      provider: provider ?? this.provider,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'location': location.toJson(),
    'timezone': timezone,
    'utc_offset_seconds': utcOffsetSeconds,
    'current': current.toJson(),
    'hourly': hourly.map((item) => item.toJson()).toList(),
    'daily': daily.map((item) => item.toJson()).toList(),
    'provider': provider.name,
  };
}

/// 空气质量的展示模型。
///
/// [displayValue] 使用和风推荐的 aqiDisplay，可能包含非数字字符；
/// [category] 为接口已本地化的等级文本，例如“良”或“Good”。
class AirQuality extends JsonModel {
  /// 页面直接展示的 AQI 数值文本，保留服务商可能返回的非纯数字形式。
  final String displayValue;

  /// 已按请求语言本地化的空气质量等级，例如“良”或“Good”。
  final String category;

  const AirQuality({required this.displayValue, required this.category});

  @override
  AirQuality copyWith({String? displayValue, String? category}) {
    return AirQuality(
      displayValue: displayValue ?? this.displayValue,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'display_value': displayValue,
    'category': category,
  };
}

/// 当前天气详情。
///
/// 温度使用 °C、降水使用 mm、风速使用 km/h，湿度为整数百分比；
/// [airQuality] 可空，用于空气质量接口失败或读取旧缓存时的降级展示。
class CurrentWeather extends JsonModel {
  /// 当前观测对应的 UTC 时刻，展示前按地点偏移换算。
  final DateTime observedAtUtc;

  /// 当前气温，单位为摄氏度。
  final double temperature;

  /// 当前体感温度，单位为摄氏度。
  final double apparentTemperature;

  /// 当前相对湿度，取值为 0–100 的整数百分比。
  final int humidity;

  /// 当前降水量，单位为毫米。
  final double precipitation;

  /// 当前风速，单位为千米每小时。
  final double windSpeed;

  /// 由具体服务商天气代码映射出的统一类别。
  final WeatherCondition condition;

  /// 当前是否为白天，用于选择对应 SVG 图标。
  final bool isDay;

  /// 可选空气质量；请求失败或旧缓存无此数据时为 null。
  final AirQuality? airQuality;

  const CurrentWeather({
    required this.observedAtUtc,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.condition,
    required this.isDay,
    this.airQuality,
  });

  @override
  CurrentWeather copyWith({
    DateTime? observedAtUtc,
    double? temperature,
    double? apparentTemperature,
    int? humidity,
    double? precipitation,
    double? windSpeed,
    WeatherCondition? condition,
    bool? isDay,
    AirQuality? airQuality,
  }) {
    return CurrentWeather(
      observedAtUtc: observedAtUtc ?? this.observedAtUtc,
      temperature: temperature ?? this.temperature,
      apparentTemperature: apparentTemperature ?? this.apparentTemperature,
      humidity: humidity ?? this.humidity,
      precipitation: precipitation ?? this.precipitation,
      windSpeed: windSpeed ?? this.windSpeed,
      condition: condition ?? this.condition,
      isDay: isDay ?? this.isDay,
      airQuality: airQuality ?? this.airQuality,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'observed_at_utc': observedAtUtc.toIso8601String(),
    'temperature': temperature,
    'apparent_temperature': apparentTemperature,
    'humidity': humidity,
    'precipitation': precipitation,
    'wind_speed': windSpeed,
    'condition': condition.name,
    'is_day': isDay,
    'air_quality': airQuality?.toJson(),
  };
}

/// 单个小时预报，[timeUtc] 始终保存 UTC 时刻。
///
/// [precipitationProbability] 可空，空值在 UI 显示为 `--`，不伪造为 0%。
class HourlyForecast extends JsonModel {
  /// 该预报小时的 UTC 起始时刻。
  final DateTime timeUtc;

  /// 该小时预报气温，单位为摄氏度。
  final double temperature;

  /// 该小时降水概率，取值为 0–100；未知时为 null。
  final int? precipitationProbability;

  /// 该小时的统一天气类别。
  final WeatherCondition condition;

  /// 该小时是否属于白天，用于选择昼夜图标。
  final bool isDay;

  const HourlyForecast({
    required this.timeUtc,
    required this.temperature,
    required this.precipitationProbability,
    required this.condition,
    required this.isDay,
  });

  @override
  HourlyForecast copyWith({
    DateTime? timeUtc,
    double? temperature,
    int? precipitationProbability,
    WeatherCondition? condition,
    bool? isDay,
  }) {
    return HourlyForecast(
      timeUtc: timeUtc ?? this.timeUtc,
      temperature: temperature ?? this.temperature,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      condition: condition ?? this.condition,
      isDay: isDay ?? this.isDay,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'time_utc': timeUtc.toIso8601String(),
    'temperature': temperature,
    'precipitation_probability': precipitationProbability,
    'condition': condition.name,
    'is_day': isDay,
  };
}

/// 单个日历日预报。
///
/// [date] 是地点本地日历对应的 UTC 零点，已消除时区偏移歧义；
/// 同时保留最低/最高温度、天气类别和可空降水概率。
class DailyForecast extends JsonModel {
  /// 地点本地日历日对应的 UTC 零点，不表示设备本地日期。
  final DateTime date;

  /// 当日最低预报气温，单位为摄氏度。
  final double minTemperature;

  /// 当日最高预报气温，单位为摄氏度。
  final double maxTemperature;

  /// 当日降水概率，取值为 0–100；未知时为 null。
  final int? precipitationProbability;

  /// 当日主导天气的统一类别。
  final WeatherCondition condition;

  const DailyForecast({
    required this.date,
    required this.minTemperature,
    required this.maxTemperature,
    required this.precipitationProbability,
    required this.condition,
  });

  @override
  DailyForecast copyWith({
    DateTime? date,
    double? minTemperature,
    double? maxTemperature,
    int? precipitationProbability,
    WeatherCondition? condition,
  }) {
    return DailyForecast(
      date: date ?? this.date,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      condition: condition ?? this.condition,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'min_temperature': minTemperature,
    'max_temperature': maxTemperature,
    'precipitation_probability': precipitationProbability,
    'condition': condition.name,
  };
}
