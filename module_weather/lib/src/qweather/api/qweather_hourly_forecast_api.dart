import '../../../models/location.dart';
import '../api/qweather_api_base.dart';
import '../dto/qweather_hourly_forecast_dto.dart';

/// 获取指定地点连续 24 小时预报，固定 hours=24 并携带界面语言。
class QWeatherHourlyForecastApi extends QWeatherApi<QWeatherHourlyForecastDto> {
  /// 需要查询的统一地点模型，路径只使用其中保留两位小数的经纬度。
  final Location location;

  /// 天气现象等文本的返回语言代码。
  final String languageCode;

  QWeatherHourlyForecastApi(
    super.client, {
    required this.location,
    required this.languageCode,
    super.config,
    super.cancelToken,
  }) : super(decoder: QWeatherHourlyForecastDto.fromJson);

  @override
  Uri get uri => config.resolve(
    '/weather/v1/hourly/${location.latitude.toStringAsFixed(2)}/${location.longitude.toStringAsFixed(2)}',
  );

  @override
  Map<String, dynamic> get params => {'hours': 24, 'lang': languageCode};
}
