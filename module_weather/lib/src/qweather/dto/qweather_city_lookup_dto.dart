import 'package:json_annotation/json_annotation.dart';
import 'package:module_network/models/json_model.dart';

part 'qweather_city_lookup_dto.g.dart';

/// GeoAPI 城市搜索响应。
///
/// [code] 是和风业务状态码，HTTP 200 时也需要校验；[location] 可空，
/// 无匹配结果时由 mapper 转为空列表，不视为服务异常。
@JsonSerializable(checked: true, explicitToJson: true)
class QWeatherCityLookupResponseDto extends JsonModel {
  /// 和风业务状态码；即使 HTTP 成功，也需据此判断请求是否有效。
  final String code;

  /// 匹配的地点列表；无结果时服务端可能省略该字段，由 mapper 转为空列表。
  final List<QWeatherLocationDto>? location;

  const QWeatherCityLookupResponseDto({required this.code, this.location});

  factory QWeatherCityLookupResponseDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherCityLookupResponseDtoFromJson(json);

  @override
  QWeatherCityLookupResponseDto copyWith({
    String? code,
    List<QWeatherLocationDto>? location,
  }) {
    return QWeatherCityLookupResponseDto(
      code: code ?? this.code,
      location: location ?? this.location,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherCityLookupResponseDtoToJson(this);
}

/// GeoAPI 地点字段，经纬度和 utcOffset 按官方字符串类型保留，
/// 由 mapper 显式转换为 double 和秒数，避免隐式类型转换。
@JsonSerializable(checked: true)
class QWeatherLocationDto extends JsonModel {
  /// 按请求语言返回的地点名称。
  final String name;

  /// 和风 LocationID，用于区分不同地区的同名地点。
  final String id;

  /// 纬度字符串，单位为十进制度数，由 mapper 显式解析为 double。
  final String lat;

  /// 经度字符串，单位为十进制度数，由 mapper 显式解析为 double。
  final String lon;

  /// 二级行政区名称，通常用于区分同名城市；未提供时为 null。
  final String? adm2;

  /// 一级行政区名称，例如省或州；未提供时为 null。
  final String? adm1;

  /// 国家或地区名称；未提供时为 null。
  final String? country;

  /// IANA 时区名称；未提供时为 null，由适配器决定后续处理。
  final String? tz;

  /// 带符号的 UTC 偏移字符串，由 mapper 显式换算为秒数；缺失时为 null。
  final String? utcOffset;

  const QWeatherLocationDto({
    required this.name,
    required this.id,
    required this.lat,
    required this.lon,
    this.adm2,
    this.adm1,
    this.country,
    this.tz,
    this.utcOffset,
  });

  factory QWeatherLocationDto.fromJson(Map<String, dynamic> json) =>
      _$QWeatherLocationDtoFromJson(json);

  @override
  QWeatherLocationDto copyWith({
    String? name,
    String? id,
    String? lat,
    String? lon,
    String? adm2,
    String? adm1,
    String? country,
    String? tz,
    String? utcOffset,
  }) {
    return QWeatherLocationDto(
      name: name ?? this.name,
      id: id ?? this.id,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      adm2: adm2 ?? this.adm2,
      adm1: adm1 ?? this.adm1,
      country: country ?? this.country,
      tz: tz ?? this.tz,
      utcOffset: utcOffset ?? this.utcOffset,
    );
  }

  @override
  Map<String, dynamic> toJson() => _$QWeatherLocationDtoToJson(this);
}
