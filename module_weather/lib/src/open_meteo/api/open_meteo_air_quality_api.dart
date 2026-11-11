import '../../../models/location.dart';
import '../dto/open_meteo_air_quality_dto.dart';
import 'open_meteo_api_base.dart';

/// 附加 US AQI 请求；适配器会把它与核心天气并行发送并允许单独失败。
class OpenMeteoAirQualityApi extends OpenMeteoApi<OpenMeteoAirQualityDto> {
  /// 需要查询的统一地点模型，请求使用其中的经纬度和自动时区。
  final Location location;

  OpenMeteoAirQualityApi(
    super.client, {
    required this.location,
    super.cancelToken,
  }) : super(decoder: OpenMeteoAirQualityDto.fromJson);

  @override
  Uri get uri =>
      Uri.parse('https://air-quality-api.open-meteo.com/v1/air-quality');

  @override
  Map<String, dynamic> get params => {
    'latitude': location.latitude,
    'longitude': location.longitude,
    'current': 'us_aqi',
    'timezone': 'auto',
  };
}
