import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

part 'open_meteo_geocoding_dto.g.dart';

/// Open-Meteo 地名搜索响应；无匹配时 results 缺省，业务错误用 error 标识。
@JsonSerializable(checked: true, explicitToJson: true)
class OpenMeteoGeocodingDto extends JsonModel {
  /// 匹配的地名列表；无匹配结果时可能为 null，由适配器转为空列表。
  final List<OpenMeteoLocationDto>? results;

  /// Open-Meteo 业务错误标记；正常响应通常省略该字段。
  final bool? error;

  /// 服务端返回的错误原因，仅用于数据层诊断，不直接展示给用户。
  final String? reason;

  const OpenMeteoGeocodingDto({this.results, this.error, this.reason});

  factory OpenMeteoGeocodingDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoGeocodingDtoFromJson(json);

  @override
  OpenMeteoGeocodingDto copyWith({
    List<OpenMeteoLocationDto>? results,
    bool? error,
    String? reason,
  }) {
    return OpenMeteoGeocodingDto(
      results: results ?? this.results,
      error: error ?? this.error,
      reason: reason ?? this.reason,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoGeocodingDtoToJson(this);
}

/// 地名结果只保留统一地点模型所需字段，时区偏移由 Forecast 响应补全。
@JsonSerializable(checked: true)
class OpenMeteoLocationDto extends JsonModel {
  /// Open-Meteo 地名数据库中的稳定数字标识。
  final int id;

  /// 按搜索请求语言返回的地点名称。
  final String name;

  /// 地点纬度，单位为十进制度数。
  final double latitude;

  /// 地点经度，单位为十进制度数。
  final double longitude;

  /// 一级行政区名称；服务端未提供时为 null。
  final String? admin1;

  /// 国家或地区名称；服务端未提供时为 null。
  final String? country;

  /// IANA 时区名称；缺失时由适配器采用明确的回退策略。
  final String? timezone;

  const OpenMeteoLocationDto({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.admin1,
    this.country,
    this.timezone,
  });

  factory OpenMeteoLocationDto.fromJson(Map<String, dynamic> json) =>
      _$OpenMeteoLocationDtoFromJson(json);

  @override
  OpenMeteoLocationDto copyWith({
    int? id,
    String? name,
    double? latitude,
    double? longitude,
    String? admin1,
    String? country,
    String? timezone,
  }) {
    return OpenMeteoLocationDto(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      admin1: admin1 ?? this.admin1,
      country: country ?? this.country,
      timezone: timezone ?? this.timezone,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$OpenMeteoLocationDtoToJson(this);
}
