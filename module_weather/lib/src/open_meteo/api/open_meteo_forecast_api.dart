import '../../../models/location.dart';
import '../dto/open_meteo_forecast_dto.dart';
import 'open_meteo_api_base.dart';

/// 一次获取当前、连续 24 小时与 7 天数据，并显式固定公制单位。
class OpenMeteoForecastApi extends OpenMeteoApi<OpenMeteoForecastDto> {
  /// 需要查询的统一地点模型，请求使用其中的经纬度并自动解析地点时区。
  final Location location;

  OpenMeteoForecastApi(
    super.client, {
    required this.location,
    super.cancelToken,
  }) : super(decoder: OpenMeteoForecastDto.fromJson);

  @override
  Uri get uri => Uri.parse('https://api.open-meteo.com/v1/forecast');

  @override
  Map<String, dynamic> get params => {
    'latitude': location.latitude,
    'longitude': location.longitude,
    'timezone': 'auto',
    'forecast_hours': 24,
    'forecast_days': 7,
    'temperature_unit': 'celsius',
    'wind_speed_unit': 'kmh',
    'precipitation_unit': 'mm',
    // time 由 Open-Meteo 自动返回，不是可请求的 current/hourly/daily 变量；
    // 显式传入会被上游判定为无效字段并返回 HTTP 400。
    'current': const [
      'temperature_2m',
      'apparent_temperature',
      'relative_humidity_2m',
      'precipitation',
      'wind_speed_10m',
      'weather_code',
      'is_day',
    ].join(','),
    'hourly': const [
      'temperature_2m',
      'precipitation_probability',
      'weather_code',
      'is_day',
    ].join(','),
    'daily': const [
      'temperature_2m_min',
      'temperature_2m_max',
      'precipitation_probability_max',
      'weather_code',
    ].join(','),
  };
}
