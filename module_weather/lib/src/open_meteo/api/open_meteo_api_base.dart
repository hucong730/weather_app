import 'package:dio/dio.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/models/json_model.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/base_api.dart';

import '../open_meteo_error.dart';

/// Open-Meteo 各 API 的共同基类，统一识别官方错误响应。
///
/// Open-Meteo 不使用错误码枚举，错误结构为
/// `{"error": true, "reason": "..."}`（HTTP 400 参数错误、404 路径不存在、
/// 429 频率或每日限额超限，见各 API 文档的 Errors 章节）。限流类映射为
/// 通用限流异常，保持界面既有提示；其余可识别错误收敛为
/// [OpenMeteoServiceException]，界面按通用服务错误展示。无法识别的结构
/// 返回 null 继续走通用 HTTP 错误路径，且不把原始 `reason` 写入异常，
/// 避免向界面或日志泄漏参数细节。
abstract class OpenMeteoApi<T extends JsonModel> extends BaseApi<T> {
  OpenMeteoApi(super.client, {required super.decoder, super.cancelToken});

  @override
  ApiResult<T>? mapErrorResponse(Response<dynamic> response) {
    final statusCode = response.statusCode;
    if (statusCode == null) return null;
    if (!isOpenMeteoErrorBody(response.data)) return null;
    if (statusCode == 429) {
      return Failure(const AppRateLimitException(), statusCode);
    }
    return Failure(OpenMeteoServiceException(statusCode), statusCode);
  }
}
