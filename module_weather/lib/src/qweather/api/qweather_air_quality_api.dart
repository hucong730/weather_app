import '../../../models/location.dart';
import '../api/qweather_api_base.dart';
import '../dto/qweather_air_quality_dto.dart';

/// 获取指定地点的实时空气质量。
///
/// 该请求在仓库中属于附加信息，失败不会使整份天气报告失败。
class QWeatherAirQualityApi extends QWeatherApi<QWeatherAirQualityResponseDto> {
  /// 需要查询的统一地点模型，路径只使用其中保留两位小数的经纬度。
  final Location location;

  /// 空气质量类别等文本的返回语言代码。
  final String languageCode;

  QWeatherAirQualityApi(
    super.client, {
    required this.location,
    required this.languageCode,
    super.config,
    super.cancelToken,
  }) : super(decoder: QWeatherAirQualityResponseDto.fromJson);

  @override
  Uri get uri => config.resolve(
    '/airquality/v1/current/${location.latitude.toStringAsFixed(2)}/${location.longitude.toStringAsFixed(2)}',
  );

  @override
  Map<String, dynamic> get params => {'lang': languageCode};
}
