import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

part 'open_meteo_forecast_dto.g.dart';

/// Forecast 根节点同时携带当前、小时、每日和地点时区信息。
@JsonSerializable(checked: true, explicitToJson: true)
class OpenMeteoForecastDto extends JsonModel {
  /// 预报地点的 IANA 时区名称，用于解释响应中的本地时间。
  final String timezone;

  /// 预报地点相对 UTC 的当前偏移量，单位为秒。
  @JsonKey(name: 'utc_offset_seconds')
  final int utcOffsetSeconds;

  /// 当前天气数据。
  final OpenMeteoCurrentDto current;

  /// 以并行数组组织的小时预报数据。
  final OpenMeteoHourlyDto hourly;

  /// 以并行数组组织的每日预报数据。
  final OpenMeteoDailyDto daily;

  /// Open-Meteo 业务错误标记；正常响应通常省略该字段。
  final bool? error;

  /// 服务端错误原因，仅用于数据层诊断，不直接展示给用户。
  final String? reason;

  const OpenMeteoForecastDto({
    required this.timezone,
    required this.utcOffsetSeconds,
    required this.current,
    required this.hourly,
    required this.daily,
    this.error,
    this.reason,
  });

  factory OpenMeteoForecastDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoForecastDtoFromJson(json);

  @override
  OpenMeteoForecastDto copyWith({
    String? timezone,
    int? utcOffsetSeconds,
    OpenMeteoCurrentDto? current,
    OpenMeteoHourlyDto? hourly,
    OpenMeteoDailyDto? daily,
    bool? error,
    String? reason,
  }) {
    return OpenMeteoForecastDto(
      timezone: timezone ?? this.timezone,
      utcOffsetSeconds: utcOffsetSeconds ?? this.utcOffsetSeconds,
      current: current ?? this.current,
      hourly: hourly ?? this.hourly,
      daily: daily ?? this.daily,
      error: error ?? this.error,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoForecastDtoToJson(this);
}

/// 当前字段均为请求时显式指定的单位，时间按响应地点偏移解释。
@JsonSerializable(checked: true)
class OpenMeteoCurrentDto extends JsonModel {
  /// 不含时区后缀的地点本地时间字符串，必须结合根节点时区解释。
  final String time;

  /// 2 米高度的当前气温，单位为 °C。
  @JsonKey(name: 'temperature_2m')
  final double temperature;

  /// 当前体感温度，单位为 °C。
  @JsonKey(name: 'apparent_temperature')
  final double apparentTemperature;

  /// 2 米高度的相对湿度，单位为百分比，取值范围为 0–100。
  @JsonKey(name: 'relative_humidity_2m')
  final int humidity;

  /// 当前降水量，单位为 mm。
  final double precipitation;

  /// 10 米高度的当前风速，单位为 km/h。
  @JsonKey(name: 'wind_speed_10m')
  final double windSpeed;

  /// WMO 天气现象代码，由 mapper 转为统一天气类别和本地化描述。
  @JsonKey(name: 'weather_code')
  final int weatherCode;

  /// 是否处于白天：1 表示白天，0 表示夜间。
  @JsonKey(name: 'is_day')
  final int isDay;

  const OpenMeteoCurrentDto({
    required this.time,
    required this.temperature,
    required this.apparentTemperature,
    required this.humidity,
    required this.precipitation,
    required this.windSpeed,
    required this.weatherCode,
    required this.isDay,
  });

  factory OpenMeteoCurrentDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoCurrentDtoFromJson(json);

  @override
  OpenMeteoCurrentDto copyWith({
    String? time,
    double? temperature,
    double? apparentTemperature,
    int? humidity,
    double? precipitation,
    double? windSpeed,
    int? weatherCode,
    int? isDay,
  }) {
    return OpenMeteoCurrentDto(
      time: time ?? this.time,
      temperature: temperature ?? this.temperature,
      apparentTemperature: apparentTemperature ?? this.apparentTemperature,
      humidity: humidity ?? this.humidity,
      precipitation: precipitation ?? this.precipitation,
      windSpeed: windSpeed ?? this.windSpeed,
      weatherCode: weatherCode ?? this.weatherCode,
      isDay: isDay ?? this.isDay,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoCurrentDtoToJson(this);
}

/// 小时并行数组，mapper 必须校验等长、数量和连续性后才能取值。
@JsonSerializable(checked: true)
class OpenMeteoHourlyDto extends JsonModel {
  /// 各预报小时的地点本地时间字符串，与其他小时数组按相同下标一一对应。
  final List<String> time;

  /// 各小时的气温数组，单位为 °C，长度必须与 [time] 一致。
  @JsonKey(name: 'temperature_2m')
  final List<double> temperature;

  /// 各小时降水概率数组，单位为百分比；单项为 null 表示该小时未提供概率。
  @JsonKey(name: 'precipitation_probability')
  final List<int?> precipitationProbability;

  /// 各小时 WMO 天气现象代码数组，长度必须与 [time] 一致。
  @JsonKey(name: 'weather_code')
  final List<int> weatherCode;

  /// 各小时昼夜标记数组：1 表示白天，0 表示夜间。
  @JsonKey(name: 'is_day')
  final List<int> isDay;

  const OpenMeteoHourlyDto({
    required this.time,
    required this.temperature,
    required this.precipitationProbability,
    required this.weatherCode,
    required this.isDay,
  });

  factory OpenMeteoHourlyDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoHourlyDtoFromJson(json);

  @override
  OpenMeteoHourlyDto copyWith({
    List<String>? time,
    List<double>? temperature,
    List<int?>? precipitationProbability,
    List<int>? weatherCode,
    List<int>? isDay,
  }) {
    return OpenMeteoHourlyDto(
      time: time ?? this.time,
      temperature: temperature ?? this.temperature,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      weatherCode: weatherCode ?? this.weatherCode,
      isDay: isDay ?? this.isDay,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoHourlyDtoToJson(this);
}

/// 每日 time 是地点本地日历日，不允许转换为设备时区后再取日期。
@JsonSerializable(checked: true)
class OpenMeteoDailyDto extends JsonModel {
  /// 各预报日的地点本地日历日期，格式为 `yyyy-MM-dd`，与其他数组等长。
  final List<String> time;

  /// 各日最低气温数组，单位为 °C。
  @JsonKey(name: 'temperature_2m_min')
  final List<double> minTemperature;

  /// 各日最高气温数组，单位为 °C。
  @JsonKey(name: 'temperature_2m_max')
  final List<double> maxTemperature;

  /// 各日最大降水概率数组，单位为百分比；单项为 null 表示未提供概率。
  @JsonKey(name: 'precipitation_probability_max')
  final List<int?> precipitationProbability;

  /// 各日 WMO 天气现象代码数组，长度必须与 [time] 一致。
  @JsonKey(name: 'weather_code')
  final List<int> weatherCode;

  const OpenMeteoDailyDto({
    required this.time,
    required this.minTemperature,
    required this.maxTemperature,
    required this.precipitationProbability,
    required this.weatherCode,
  });

  factory OpenMeteoDailyDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoDailyDtoFromJson(json);

  @override
  OpenMeteoDailyDto copyWith({
    List<String>? time,
    List<double>? minTemperature,
    List<double>? maxTemperature,
    List<int?>? precipitationProbability,
    List<int>? weatherCode,
  }) {
    return OpenMeteoDailyDto(
      time: time ?? this.time,
      minTemperature: minTemperature ?? this.minTemperature,
      maxTemperature: maxTemperature ?? this.maxTemperature,
      precipitationProbability:
          precipitationProbability ?? this.precipitationProbability,
      weatherCode: weatherCode ?? this.weatherCode,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoDailyDtoToJson(this);
}
