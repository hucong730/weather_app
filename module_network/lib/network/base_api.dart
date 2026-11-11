import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../error/app_exception.dart';
import '../models/json_model.dart';
import 'api_client.dart';
import 'api_result.dart';

/// 各类业务请求的统一模板，封装请求配置、发送和异常转换。
///
/// 子类通常只需提供 [uri] 与 [decoder]，并按需重写方法、参数、请求头、
/// 请求体和成功状态码。ApiClient 不处理业务，本类才负责生成 ApiResult。
abstract class BaseApi<T extends JsonModel> {
  /// 纯传输客户端，由具体业务模块通过依赖注入提供。
  final ApiClient client;

  /// 当前请求成功响应的模型构造函数，确保返回准确的 T 类型。
  final ModelDecoder<T> decoder;

  /// 可选取消令牌；取消后 Dio 会中断请求，上层可据此丢弃过期结果。
  final CancelToken? cancelToken;

  BaseApi(this.client, {required this.decoder, this.cancelToken});

  /// 当前 API 的完整请求地址，必须由具体子类实现。
  Uri get uri;

  /// HTTP 方法，默认 GET，可按请求语义重写。
  HttpMethod get method => HttpMethod.get;

  /// URL 查询参数，默认空集合。
  Map<String, dynamic> get params => const {};

  /// 额外请求头，默认空集合，认证信息由具体业务 API 注入。
  Map<String, String> get headers => const {};

  /// 可选请求体，GET 请求通常保持 null。
  Object? get body => null;

  /// 预期成功 HTTP 状态码，默认 200，可按接口约定重写。
  int get successStatusCode => 200;

  /// 发送请求并把响应或异常统一转换为 [ApiResult]。
  ///
  /// Dio 带响应的异常保留原 HTTP 状态码；无响应的异常状态码为 null；
  /// 配置校验等 AppException 也在此转换为 Failure，避免泄漏到 Controller。
  Future<ApiResult<T>> send() async {
    try {
      final response = await _sendRequest();
      return _fromResponse(response);
    } on DioException catch (error) {
      final response = error.response;
      if (response != null) {
        return _fromResponse(response);
      }
      return Failure(_mapDioException(error), null);
    } on AppException catch (error) {
      return Failure(error, null);
    }
  }

  /// 非成功 HTTP 状态先交给具体业务 API 识别，再执行通用错误映射。
  ///
  /// 默认返回 null，保持原有行为。只有响应类型具有明确业务语义时，子类才
  /// 应返回自定义结果；不得借此把全部 HTTP 错误伪装成成功。
  ApiResult<T>? mapErrorResponse(Response<dynamic> response) => null;

  ApiResult<T> _fromResponse(Response<dynamic> response) {
    if (response.statusCode != successStatusCode) {
      final mapped = mapErrorResponse(response);
      if (mapped != null) return mapped;
    }
    return ApiResult.fromResponse(
      response,
      successStatusCode: successStatusCode,
      decoder: decoder,
    );
  }

  Future<Response<dynamic>> _sendRequest() {
    return switch (method) {
      HttpMethod.get => client.get(
        uri,
        params: params,
        headers: headers,
        cancelToken: cancelToken,
      ),
      HttpMethod.post => client.post(
        uri,
        params: params,
        headers: headers,
        body: body,
        cancelToken: cancelToken,
      ),
      _ => client.request(
        uri,
        method: method,
        params: params,
        headers: headers,
        body: body,
        cancelToken: cancelToken,
      ),
    };
  }

  AppException _mapDioException(DioException error) {
    final type = error.type;

    if (type == DioExceptionType.connectionTimeout ||
        type == DioExceptionType.sendTimeout ||
        type == DioExceptionType.receiveTimeout ||
        type == DioExceptionType.transformTimeout) {
      return const AppTimeoutException();
    }
    if (error.error is FormatException) {
      return const AppDataException();
    }
    if (type == DioExceptionType.connectionError ||
        error.error is SocketException) {
      return const AppNetworkException();
    }
    return const AppNetworkException();
  }
}
