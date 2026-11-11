import 'package:dio/dio.dart';
import 'package:json_annotation/json_annotation.dart';

import '../error/app_exception.dart';
import '../models/json_model.dart';

/// 网络请求结果的密封类型，保证调用方只能得到 [Success] 或 [Failure]。
///
/// 无论成功、HTTP 错误还是响应后解析失败，只要收到响应就保留状态码；
/// 无响应的网络异常则由 BaseApi 创建 Failure，状态码为 null。
sealed class ApiResult<T> {
  const ApiResult();

  /// 收到响应时保留 HTTP 状态码；未收到响应的网络异常为 null。
  int? get statusCode;

  /// 根据原始响应创建结果。
  ///
  /// [successStatusCode] 默认由具体 API 指定，[decoder] 负责构造具体模型。
  /// 429 单独映射为限流；非 JSON 对象和解析异常统一转为数据错误。
  factory ApiResult.fromResponse(
    Response<dynamic> response, {
    required int successStatusCode,
    required ModelDecoder<T> decoder,
  }) {
    final statusCode = response.statusCode;

    if (statusCode == null) {
      return Failure(
        const AppNetworkException('Missing HTTP status code'),
        null,
      );
    }
    if (statusCode == 429) {
      return Failure(const AppRateLimitException(), statusCode);
    }
    if (statusCode != successStatusCode) {
      return Failure(AppHttpException(statusCode), statusCode);
    }

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      return Failure(
        const AppDataException('JSON root must be an object'),
        statusCode,
      );
    }

    try {
      return Success(JsonModel.fromJson(body, decoder), statusCode);
    } on AppException catch (error) {
      return Failure(error, statusCode);
    } on CheckedFromJsonException {
      return Failure(const AppDataException(), statusCode);
    } on FormatException {
      return Failure(const AppDataException(), statusCode);
    } on TypeError {
      return Failure(const AppDataException(), statusCode);
    } on ArgumentError {
      return Failure(const AppDataException(), statusCode);
    }
  }
}

/// 请求及模型解析均成功的结果。
final class Success<T> extends ApiResult<T> {
  /// 由具体 decoder 构造并保留泛型类型的成功模型。
  final T data;

  /// 实际成功的 HTTP 状态码，支持业务 API 自定义非 200 成功码。
  @override
  final int statusCode;

  const Success(this.data, this.statusCode);
}

/// 网络、HTTP、限流、配置或数据解析失败的结果。
final class Failure<T> extends ApiResult<T> {
  /// 已分类的安全异常，供上层映射错误提示或执行降级。
  final AppException error;

  /// 收到响应时保留原 HTTP 状态码；无响应的连接或超时错误为 null。
  @override
  final int? statusCode;

  const Failure(this.error, this.statusCode);
}
