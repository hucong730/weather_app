import 'package:dio/dio.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/models/json_model.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/base_api.dart';

import '../qweather_config.dart';
import '../qweather_error.dart';

/// 和风 API 的共同基类，统一注入配置并生成认证请求头。
///
/// 测试可传入 fake Host/KEY；生产默认从编译期环境变量读取。
/// 所有请求都通过 [config.headers] 携带当前开发者的和风认证 KEY。
abstract class QWeatherApi<T extends JsonModel> extends BaseApi<T> {
  /// 当前请求使用的和风配置，可在测试中替换，生产环境默认读取编译期变量。
  final QWeatherConfig config;

  QWeatherApi(
    super.client, {
    required super.decoder,
    super.cancelToken,
    QWeatherConfig? config,
  }) : config = config ?? const QWeatherConfig.fromEnvironment();

  @override
  Map<String, String> get headers => config.headers;

  /// 按和风官方错误码列表识别非成功响应，见
  /// https://dev.qweather.com/docs/resource/error-code/。
  ///
  /// 限流类错误（too-many-requests/over-monthly-limit）映射为通用限流异常，
  /// 保持界面既有提示；其余可识别错误码保留在 [QWeatherServiceException] 中，
  /// 供界面区分凭据/额度被拒与普通服务错误。无法识别的结构返回 null，
  /// 继续走通用 HTTP 错误路径；只保留错误码和状态码，不泄漏 KEY、坐标、
  /// `detail` 或 `invalidParams` 等原始响应内容。
  @override
  ApiResult<T>? mapErrorResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;
    if (statusCode == null) return null;
    final code = parseQWeatherErrorCode(response.data);
    if (code == null) return null;
    if (code == QWeatherErrorCode.tooManyRequests ||
        code == QWeatherErrorCode.overMonthlyLimit) {
      return Failure(const AppRateLimitException(), statusCode);
    }
    return Failure(QWeatherServiceException(code, statusCode), statusCode);
  }
}
