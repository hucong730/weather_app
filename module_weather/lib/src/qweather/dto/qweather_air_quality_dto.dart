import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

part 'qweather_air_quality_dto.g.dart';

/// 实时空气质量响应，[indexes] 可能同时包含当地标准、US EPA 和 QAQI。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherAirQualityResponseDto extends JsonModel {
  /// 服务端提供的各套空气质量指数，适配器按业务优先级选择其中一套。
  final List<QWeatherAirQualityIndexDto> indexes;

  const QWeatherAirQualityResponseDto({required this.indexes});

  factory QWeatherAirQualityResponseDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherAirQualityResponseDtoFromJson(json);

  @override
  QWeatherAirQualityResponseDto copyWith({
    List<QWeatherAirQualityIndexDto>? indexes,
  }) {
    return QWeatherAirQualityResponseDto(indexes: indexes ?? this.indexes);
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherAirQualityResponseDtoToJson(this);
}

/// 单套空气质量指数，code 决定标准，aqiDisplay 用于直接展示。
@JsonSerializable(checked: true)
class QWeatherAirQualityIndexDto extends JsonModel {
  /// 指数标准代码，例如 `cn-mee`、`us-epa` 或 `qaqi`。
  final String code;

  /// 和风格式化后的 AQI 展示值，保留字符串以避免擅自重算或取整。
  final String aqiDisplay;

  /// 当前指数标准下的空气质量类别描述。
  final String category;

  const QWeatherAirQualityIndexDto({
    required this.code,
    required this.aqiDisplay,
    required this.category,
  });

  factory QWeatherAirQualityIndexDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherAirQualityIndexDtoFromJson(json);

  @override
  QWeatherAirQualityIndexDto copyWith({
    String? code,
    String? aqiDisplay,
    String? category,
  }) {
    return QWeatherAirQualityIndexDto(
      code: code ?? this.code,
      aqiDisplay: aqiDisplay ?? this.aqiDisplay,
      category: category ?? this.category,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherAirQualityIndexDtoToJson(this);
}
