import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';

import 'models/location.dart';
import 'models/weather_report.dart';

/// 统一天气服务契约，调用方无需了解具体服务商的请求与 DTO。
abstract interface class WeatherService {
  /// 按关键词和语言搜索地点，保持服务商排序并最多返回 20 条。
  ///
  /// 传入 [cancelToken] 后，调用方可真正中断尚未完成的搜索请求。
  Future<ApiResult<List<Location>>> searchLocations(
    String query,
    String languageCode, {
    CancelToken? cancelToken,
  });

  /// 获取统一单位的当前天气、连续 24 小时和 7 天完整报告。
  ///
  /// 同一报告的并行请求共享 [cancelToken]，取消时全部中断。
  /// [localizeLocation] 仅在界面语言变化时传入 true，让支持地名本地化的
  /// 服务商重新解析已有城市名称；普通刷新不增加额外地理编码请求。
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  });
}
