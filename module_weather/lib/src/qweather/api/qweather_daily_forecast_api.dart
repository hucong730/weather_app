import '../../../models/location.dart';
import '../api/qweather_api_base.dart';
import '../dto/qweather_daily_forecast_dto.dart';

/// 获取指定地点 7 天每日预报，固定 days=7，避免客户端任意放大配额消耗。
///
/// localTime=true 让每条预报携带自己的地点本地日历时间，跨夏令时时
/// 不会错误复用当前 UTC 偏移推算未来日期。
class QWeatherDailyForecastApi extends QWeatherApi<QWeatherDailyForecastDto> {
  /// 需要查询的统一地点模型，路径只使用其中保留两位小数的经纬度。
  final Location location;

  /// 天气现象等文本的返回语言代码。
  final String languageCode;

  QWeatherDailyForecastApi(
    super.client, {
    required this.location,
    required this.languageCode,
    super.config,
    super.cancelToken,
  }) : super(decoder: QWeatherDailyForecastDto.fromJson);

  @override
  Uri get uri => config.resolve(
    '/weather/v1/daily/${location.latitude.toStringAsFixed(2)}/${location.longitude.toStringAsFixed(2)}',
  );

  @override
  Map<String, dynamic> get params => {
    'days': 7,
    'lang': languageCode,
    'localTime': true,
  };
}
