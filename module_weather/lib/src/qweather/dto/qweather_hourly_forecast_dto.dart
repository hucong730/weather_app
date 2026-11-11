import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

import 'qweather_weather_dto.dart';

part 'qweather_hourly_forecast_dto.g.dart';

/// 24 小时预报响应，[hours] 必须最终映射为连续 24 条数据。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherHourlyForecastDto extends JsonModel {
  /// 按时间先后排列的小时预报；适配器负责校验并截取连续 24 条。
  final List<QWeatherHourlyDto> hours;

  const QWeatherHourlyForecastDto({required this.hours});

  factory QWeatherHourlyForecastDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherHourlyForecastDtoFromJson(json);

  @override
  QWeatherHourlyForecastDto copyWith({List<QWeatherHourlyDto>? hours}) {
    return QWeatherHourlyForecastDto(hours: hours ?? this.hours);
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherHourlyForecastDtoToJson(this);
}

/// 单个小时 DTO，forecastTime 先按 ISO 字符串保存，再由 mapper 转 UTC。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherHourlyDto extends JsonModel {
  /// 带地点偏移的 ISO 8601 预报时间字符串，由 mapper 解析为 UTC 时间。
  final String forecastTime;

  /// 该小时的天气现象及代码。
  final QWeatherConditionDto condition;

  /// 该小时的预报气温，统一模型转换为 °C。
  final QWeatherValueDto temperature;

  /// 该小时的降水量和可空降水概率。
  final QWeatherPrecipitationDto precipitation;

  const QWeatherHourlyDto({
    required this.forecastTime,
    required this.condition,
    required this.temperature,
    required this.precipitation,
  });

  factory QWeatherHourlyDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherHourlyDtoFromJson(json);

  @override
  QWeatherHourlyDto copyWith({
    String? forecastTime,
    QWeatherConditionDto? condition,
    QWeatherValueDto? temperature,
    QWeatherPrecipitationDto? precipitation,
  }) {
    return QWeatherHourlyDto(
      forecastTime: forecastTime ?? this.forecastTime,
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      precipitation: precipitation ?? this.precipitation,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherHourlyDtoToJson(this);
}
