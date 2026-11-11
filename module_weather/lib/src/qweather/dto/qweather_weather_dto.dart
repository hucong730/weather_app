import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

part 'qweather_weather_dto.g.dart';

/// 和风通用“数值 + 单位”对象，用于温度、风速、降水等字段。
///
/// mapper 根据 [unit] 做单位转换，checked 解析会在字段缺失或类型错误时失败。
@JsonSerializable(checked: true)
class QWeatherValueDto extends JsonModel {
  /// 原始数值，具体物理含义和单位由所在字段及 [unit] 共同确定。
  final double value;

  /// 和风返回的单位标识，例如 `c`、`m/s` 或 `mm`。
  final String unit;

  const QWeatherValueDto({required this.value, required this.unit});

  factory QWeatherValueDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherValueDtoFromJson(json);

  @override
  QWeatherValueDto copyWith({double? value, String? unit}) {
    return QWeatherValueDto(
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherValueDtoToJson(this);
}

/// 天气现象 DTO，text 为本地化描述，code 用于内部图标和动画映射。
@JsonSerializable(checked: true)
class QWeatherConditionDto extends JsonModel {
  /// 按请求语言返回的天气现象描述，可直接用于界面展示。
  final String text;

  /// 和风天气现象代码，用于映射统一的天气类别、图标和动画。
  final String code;

  const QWeatherConditionDto({required this.text, required this.code});

  factory QWeatherConditionDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherConditionDtoFromJson(json);

  @override
  QWeatherConditionDto copyWith({String? text, String? code}) {
    return QWeatherConditionDto(
      text: text ?? this.text,
      code: code ?? this.code,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherConditionDtoToJson(this);
}

/// 风数据 DTO，speed 通常为 m/s，mapper 转换为 km/h。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherWindDto extends JsonModel {
  /// 风速及其原始单位；统一模型会转换为 km/h。
  final QWeatherValueDto speed;

  const QWeatherWindDto({required this.speed});

  factory QWeatherWindDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherWindDtoFromJson(json);

  @override
  QWeatherWindDto copyWith({QWeatherValueDto? speed}) {
    return QWeatherWindDto(speed: speed ?? this.speed);
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherWindDtoToJson(this);
}

/// 降水 DTO，amount 为实际降水量，probability 为 0–1 的可空概率。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherPrecipitationDto extends JsonModel {
  /// 降水量及其原始单位，统一模型按 mm 处理。
  final QWeatherValueDto amount;

  /// 降水概率，取值范围为 0–1；服务端未提供时为 null，不按 0 处理。
  final double? probability;

  const QWeatherPrecipitationDto({required this.amount, this.probability});

  factory QWeatherPrecipitationDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherPrecipitationDtoFromJson(json);

  @override
  QWeatherPrecipitationDto copyWith({
    QWeatherValueDto? amount,
    double? probability,
  }) {
    return QWeatherPrecipitationDto(
      amount: amount ?? this.amount,
      probability: probability ?? this.probability,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherPrecipitationDtoToJson(this);
}

/// 实时天气 DTO，包含天气代码、温度、体感、湿度、风和降水等核心字段。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherCurrentWeatherDto extends JsonModel {
  /// 当前天气现象及其和风代码。
  final QWeatherConditionDto condition;

  /// 当前气温，统一模型转换为 °C。
  final QWeatherValueDto temperature;

  /// 当前体感温度，统一模型转换为 °C。
  final QWeatherValueDto feelsLike;

  /// 相对湿度，原始取值范围为 0–1，由 mapper 转为百分比。
  final double humidity;

  /// 当前风速数据。
  final QWeatherWindDto wind;

  /// 当前降水量及可能存在的降水概率。
  final QWeatherPrecipitationDto precipitation;

  const QWeatherCurrentWeatherDto({
    required this.condition,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.wind,
    required this.precipitation,
  });

  factory QWeatherCurrentWeatherDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherCurrentWeatherDtoFromJson(json);

  @override
  QWeatherCurrentWeatherDto copyWith({
    QWeatherConditionDto? condition,
    QWeatherValueDto? temperature,
    QWeatherValueDto? feelsLike,
    double? humidity,
    QWeatherWindDto? wind,
    QWeatherPrecipitationDto? precipitation,
  }) {
    return QWeatherCurrentWeatherDto(
      condition: condition ?? this.condition,
      temperature: temperature ?? this.temperature,
      feelsLike: feelsLike ?? this.feelsLike,
      humidity: humidity ?? this.humidity,
      wind: wind ?? this.wind,
      precipitation: precipitation ?? this.precipitation,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherCurrentWeatherDtoToJson(this);
}
