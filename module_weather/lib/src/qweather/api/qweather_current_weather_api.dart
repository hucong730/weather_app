import '../../../models/location.dart';
import '../api/qweather_api_base.dart';
import '../dto/qweather_weather_dto.dart';

/// 获取指定地点的实时天气，路径坐标按官方限制保留两位小数。
class QWeatherCurrentWeatherApi extends QWeatherApi<QWeatherCurrentWeatherDto> {
  /// 需要查询的统一地点模型，路径只使用其中保留两位小数的经纬度。
  final Location location;

  /// 天气现象等文本的返回语言代码。
  final String languageCode;

  QWeatherCurrentWeatherApi(
    super.client, {
    required this.location,
    required this.languageCode,
    super.config,
    super.cancelToken,
  }) : super(decoder: QWeatherCurrentWeatherDto.fromJson);

  @override
  Uri get uri => config.resolve(
    '/weather/v1/current/${location.latitude.toStringAsFixed(2)}/${location.longitude.toStringAsFixed(2)}',
  );

  @override
  Map<String, dynamic> get params => {'lang': languageCode};
}
