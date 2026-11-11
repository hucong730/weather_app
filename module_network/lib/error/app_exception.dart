/// 可预期网络异常的通用基类。
///
/// 使用方可以继承该类型定义自己的业务配置异常；网络层和业务层只把
/// 该类型交给界面，界面据此选择国际化文案。message 仅用于开发诊断，
/// 禁止包含 API KEY、精确坐标或完整响应体。
abstract base class AppException implements Exception {
  /// 供开发诊断使用的安全摘要，不得包含凭据、精确坐标或原始响应体。
  final String message;

  const AppException(this.message);
}

/// 无有效响应时的网络连接异常，例如断网、DNS 或连接失败。
final class AppNetworkException extends AppException {
  const AppNetworkException([super.message = 'Network request failed']);
}

/// 连接、发送、接收或响应转换超过约定时限。
final class AppTimeoutException extends AppException {
  const AppTimeoutException([super.message = 'Network request timed out']);
}

/// 服务端返回了非预期 HTTP 状态码，并保留状态码便于诊断和测试。
final class AppHttpException extends AppException {
  /// 服务端实际返回的非预期 HTTP 状态码，供诊断和测试使用。
  final int statusCode;

  AppHttpException(this.statusCode)
    : super('HTTP request failed ($statusCode)');
}

/// 请求受到客户端或服务端限流，通常对应 HTTP 429。
final class AppRateLimitException extends AppException {
  const AppRateLimitException([super.message = 'Too many requests']);
}

/// 响应结构、字段类型、时间格式或业务数据不符合约定。
final class AppDataException extends AppException {
  const AppDataException([super.message = 'Response data is invalid']);
}
