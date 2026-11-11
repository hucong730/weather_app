import 'package:dio/dio.dart';

/// 网络基础层支持的 HTTP 请求方式。
enum HttpMethod { get, post, put, patch, delete }

/// 将枚举转换为 Dio 所需的大写方法字符串。
extension HttpMethodValue on HttpMethod {
  String get value => switch (this) {
    HttpMethod.get => 'GET',
    HttpMethod.post => 'POST',
    HttpMethod.put => 'PUT',
    HttpMethod.patch => 'PATCH',
    HttpMethod.delete => 'DELETE',
  };
}

/// 纯网络传输客户端，只包装 Dio，不解析模型、不创建业务结果。
class ApiClient {
  /// 由调用方创建并管理生命周期的 Dio 实例，本类不额外创建全局单例。
  final Dio _dio;

  const ApiClient(this._dio);

  /// 通用请求入口。
  ///
  /// [uri] 为完整地址，[params] 为查询参数，[headers] 为额外请求头，
  /// [body] 为 POST/PUT 等请求的数据体，[cancelToken] 可中断未完成请求。
  /// 返回值始终是 Dio 原始响应。
  Future<Response<dynamic>> request(
    Uri uri, {
    HttpMethod method = HttpMethod.get,
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    Object? body,
    CancelToken? cancelToken,
  }) {
    return _dio.request<dynamic>(
      uri.toString(),
      queryParameters: params,
      data: body,
      cancelToken: cancelToken,
      options: Options(method: method.value, headers: headers),
    );
  }

  /// 发送 GET 请求，仅透传地址、查询参数、请求头和可选取消令牌。
  Future<Response<dynamic>> get(
    Uri uri, {
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    CancelToken? cancelToken,
  }) {
    return request(
      uri,
      method: HttpMethod.get,
      params: params,
      headers: headers,
      cancelToken: cancelToken,
    );
  }

  /// 发送 POST 请求，[body] 原样交给 Dio 编码，不在此解析业务响应。
  Future<Response<dynamic>> post(
    Uri uri, {
    Map<String, dynamic> params = const {},
    Map<String, String> headers = const {},
    Object? body,
    CancelToken? cancelToken,
  }) {
    return request(
      uri,
      method: HttpMethod.post,
      params: params,
      headers: headers,
      body: body,
      cancelToken: cancelToken,
    );
  }
}
