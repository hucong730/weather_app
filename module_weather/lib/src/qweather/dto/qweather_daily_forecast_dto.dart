import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

import 'qweather_weather_dto.dart';

part 'qweather_daily_forecast_dto.g.dart';

/// 每日预报响应，[days] 必须恰好为 7 条，避免错位展示未来日期。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherDailyForecastDto extends JsonModel {
  /// 按地点本地日历顺序排列的每日预报，适配器要求恰好包含 7 天。
  final List<QWeatherDailyDto> days;

  const QWeatherDailyForecastDto({required this.days});

  factory QWeatherDailyForecastDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherDailyForecastDtoFromJson(json);

  @override
  QWeatherDailyForecastDto copyWith({List<QWeatherDailyDto>? days}) {
    return QWeatherDailyForecastDto(days: days ?? this.days);
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherDailyForecastDtoToJson(this);
}

/// 单日 DTO，包含起止时间、最高/最低温度及白天状况。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherDailyDto extends JsonModel {
  /// 该预报日在地点时区中的起始时间，保留显式日期避免设备时区造成错位。
  final String forecastStartTime;

  /// 当日最高气温，统一模型转换为 °C。
  final QWeatherValueDto temperatureMax;

  /// 当日最低气温，统一模型转换为 °C。
  final QWeatherValueDto temperatureMin;

  /// 当日白天的天气现象与降水信息。
  final QWeatherDaytimeDto daytime;

  const QWeatherDailyDto({
    required this.forecastStartTime,
    required this.temperatureMax,
    required this.temperatureMin,
    required this.daytime,
  });

  factory QWeatherDailyDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherDailyDtoFromJson(json);

  @override
  QWeatherDailyDto copyWith({
    String? forecastStartTime,
    QWeatherValueDto? temperatureMax,
    QWeatherValueDto? temperatureMin,
    QWeatherDaytimeDto? daytime,
  }) {
    return QWeatherDailyDto(
      forecastStartTime: forecastStartTime ?? this.forecastStartTime,
      temperatureMax: temperatureMax ?? this.temperatureMax,
      temperatureMin: temperatureMin ?? this.temperatureMin,
      daytime: daytime ?? this.daytime,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherDailyDtoToJson(this);
}

/// 白天天气 DTO，当前 UI 使用天气类别；降水概率仍保留在数据与缓存模型中。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherDaytimeDto extends JsonModel {
  /// 白天时段的天气现象及代码。
  final QWeatherConditionDto condition;

  /// 白天时段的降水量和可空降水概率。
  final QWeatherPrecipitationDto precipitation;

  const QWeatherDaytimeDto({
    required this.condition,
    required this.precipitation,
  });

  factory QWeatherDaytimeDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherDaytimeDtoFromJson(json);

  @override
  QWeatherDaytimeDto copyWith({
    QWeatherConditionDto? condition,
    QWeatherPrecipitationDto? precipitation,
  }) {
    return QWeatherDaytimeDto(
      condition: condition ?? this.condition,
      precipitation: precipitation ?? this.precipitation,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherDaytimeDtoToJson(this);
}
