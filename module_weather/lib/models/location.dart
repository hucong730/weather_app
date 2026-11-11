import 'package:module_network/models/json_model.dart';

/// 地点来源：用户搜索、设备 GPS 或历史 IP 缓存。
///
/// 新项目已不再请求 IP 定位，[ip] 仅用于兼容旧 SQLite 数据。
enum LocationOrigin { search, gps, ip }

/// 天气地点领域模型，不包含任何 DTO 字段或网络请求行为。
///
/// [timezone] 为 IANA 时区名，[utcOffsetSeconds] 用于把 UTC 时间转换为
/// 地点本地时间；两者可空是因为 GPS 初次返回时需要通过 GeoAPI 补全。
class Location extends JsonModel {
  /// 主应用分配并持久化的页面身份，与服务商地点 ID 无关。
  final String? clientId;

  /// 当前服务商的地点 ID；GPS 初次定位等场景可能尚未取得。
  final String? id;

  /// 服务商返回的城市或地点名称，按请求语言显示，不伪称已翻译。
  final String? name;

  /// 一级行政区名称，用于在搜索结果中区分同名城市。
  final String? admin1;

  /// 国家或地区名称，用于地点展示和跨区域同名城市区分。
  final String? country;

  /// 地点纬度，天气请求前由具体适配器按其精度规则处理。
  final double latitude;

  /// 地点经度，天气请求前由具体适配器按其精度规则处理。
  final double longitude;

  /// IANA 时区名称，例如 Asia/Shanghai；待地理编码补全时可以为 null。
  final String? timezone;

  /// 相对 UTC 的固定偏移秒数，用于本地时间和“今天”的计算。
  final int? utcOffsetSeconds;

  /// 地点来源，决定固定定位页、历史缓存兼容和城市判重行为。
  final LocationOrigin origin;

  const Location({
    this.clientId,
    this.id,
    this.name,
    this.admin1,
    this.country,
    required this.latitude,
    required this.longitude,
    this.timezone,
    this.utcOffsetSeconds,
    required this.origin,
  });

  @override
  Location copyWith({
    String? clientId,
    String? id,
    String? name,
    String? admin1,
    String? country,
    double? latitude,
    double? longitude,
    String? timezone,
    int? utcOffsetSeconds,
    LocationOrigin? origin,
  }) {
    return Location(
      clientId: clientId ?? this.clientId,
      id: id ?? this.id,
      name: name ?? this.name,
      admin1: admin1 ?? this.admin1,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezone: timezone ?? this.timezone,
      utcOffsetSeconds: utcOffsetSeconds ?? this.utcOffsetSeconds,
      origin: origin ?? this.origin,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'client_id': clientId,
    'id': id,
    'name': name,
    'admin1': admin1,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
    'timezone': timezone,
    'utc_offset_seconds': utcOffsetSeconds,
    'origin': origin.name,
  };
}
