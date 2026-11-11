import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

part 'open_meteo_air_quality_dto.g.dart';

/// 空气质量响应，首版只请求并解析 US AQI。
@JsonSerializable(checked: true, explicitToJson: true)
class OpenMeteoAirQualityDto extends JsonModel {
  /// 当前时刻的空气质量数据。
  final OpenMeteoAirQualityCurrentDto current;

  const OpenMeteoAirQualityDto({required this.current});

  factory OpenMeteoAirQualityDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoAirQualityDtoFromJson(json);

  @override
  OpenMeteoAirQualityDto copyWith({OpenMeteoAirQualityCurrentDto? current}) {
    return OpenMeteoAirQualityDto(current: current ?? this.current);
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoAirQualityDtoToJson(this);
}

/// Open-Meteo 当前空气质量字段，仅保留统一模型使用的 US AQI。
@JsonSerializable(checked: true)
class OpenMeteoAirQualityCurrentDto extends JsonModel {
  /// 美国 EPA 标准的当前空气质量指数，类别由适配器统一换算。
  @JsonKey(name: 'us_aqi')
  final double usAqi;

  const OpenMeteoAirQualityCurrentDto({required this.usAqi});

  factory OpenMeteoAirQualityCurrentDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoAirQualityCurrentDtoFromJson(json);

  @override
  OpenMeteoAirQualityCurrentDto copyWith({double? usAqi}) {
    return OpenMeteoAirQualityCurrentDto(usAqi: usAqi ?? this.usAqi);
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoAirQualityCurrentDtoToJson(this);
}
