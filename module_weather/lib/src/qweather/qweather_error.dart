import 'package:module_network/error/app_exception.dart';

/// 和风天气官方错误码，对应 https://dev.qweather.com/docs/resource/error-code/。
///
/// 和风错误响应使用 RFC 7807 problem+json 结构，通过 `error.type` URL 的
/// fragment（例如 `#no-such-location`）标识具体错误类型；本枚举把全部官方
/// 错误码收敛为类型安全的值，供适配器和界面按类别处理。
enum QWeatherErrorCode {
  /// HTTP 400：传入了错误的参数值，具体参数见响应的 `error.invalidParams`。
  invalidParameters,

  /// HTTP 400：缺少必选参数。
  missingParameter,

  /// HTTP 400：没有查询到地点信息或不支持的位置。
  noSuchLocation,

  /// HTTP 400：查询的数据暂不可用，例如该地点不支持的空气质量数据。
  dataNotAvailable,

  /// HTTP 401：身份认证失败，通常是 KEY 无效；和风出于安全不返回细节。
  unauthorized,

  /// HTTP 403：账户可用额度不足，请求被拒绝。
  noCredit,

  /// HTTP 403：账户存在逾期未支付账单，请求被拒绝。
  overdue,

  /// HTTP 403：请求违反了用户设置的请求限制，可能意味着凭据已泄露。
  securityRestriction,

  /// HTTP 403：使用了错误的 API Host。
  invalidHost,

  /// HTTP 403：账户被冻结，请求被拒绝。
  accountSuspension,

  /// HTTP 403：请求的 API 已弃用，需要改用最新版本。
  deprecated,

  /// HTTP 403：暂时无权限请求该数据，需向服务方了解详情。
  forbidden,

  /// HTTP 404：路径或路径参数错误，无法找到该资源。
  notFound,

  /// HTTP 405：使用了 GET 以外的请求方法。
  methodNotAllowed,

  /// HTTP 429：短时间内请求过多，超过 QPM 限制或累积大量错误请求。
  tooManyRequests,

  /// HTTP 429：包年包月订阅本月请求量超过限额。
  overMonthlyLimit,

  /// HTTP 500：服务端未知故障。
  unknownError;

  /// 按错误响应 `error.type` URL fragment 解析官方错误码。
  ///
  /// [errorType] 形如
  /// `https://dev.qweather.com/docs/resource/error-code/#no-such-location`，
  /// 大小写不敏感；无法识别时返回 null，由调用方走通用错误路径。
  static QWeatherErrorCode? fromErrorType(String? errorType) {
    if (errorType == null) return null;
    final fragment = errorType.substring(errorType.lastIndexOf('#') + 1);
    return _byFragment[fragment.toLowerCase()];
  }

  /// 按错误响应 `error.title` 解析官方错误码，兼容缺失 `type` 的响应。
  static QWeatherErrorCode? fromErrorTitle(String? errorTitle) {
    if (errorTitle == null) return null;
    return _byTitle[errorTitle];
  }
}

/// type fragment 小写值到错误码的映射表，仅在此处维护官方 kebab-case 拼写。
const Map<String, QWeatherErrorCode> _byFragment = {
  'invalid-parameters': QWeatherErrorCode.invalidParameters,
  'missing-parameter': QWeatherErrorCode.missingParameter,
  'no-such-location': QWeatherErrorCode.noSuchLocation,
  'data-not-available': QWeatherErrorCode.dataNotAvailable,
  'unauthorized': QWeatherErrorCode.unauthorized,
  'no-credit': QWeatherErrorCode.noCredit,
  'overdue': QWeatherErrorCode.overdue,
  'security-restriction': QWeatherErrorCode.securityRestriction,
  'invalid-host': QWeatherErrorCode.invalidHost,
  'account-suspension': QWeatherErrorCode.accountSuspension,
  'deprecated': QWeatherErrorCode.deprecated,
  'forbidden': QWeatherErrorCode.forbidden,
  'not-found': QWeatherErrorCode.notFound,
  'method-not-allowed': QWeatherErrorCode.methodNotAllowed,
  'too-many-requests': QWeatherErrorCode.tooManyRequests,
  'over-monthly-limit': QWeatherErrorCode.overMonthlyLimit,
  'unknown-error': QWeatherErrorCode.unknownError,
};

/// 官方错误 `title` 到错误码的映射表，取值与文档中的标题一致。
const Map<String, QWeatherErrorCode> _byTitle = {
  'Invalid Parameters': QWeatherErrorCode.invalidParameters,
  'Missing Parameter': QWeatherErrorCode.missingParameter,
  'No Such Location': QWeatherErrorCode.noSuchLocation,
  'Data Not Available': QWeatherErrorCode.dataNotAvailable,
  'Unauthorized': QWeatherErrorCode.unauthorized,
  'No Credit': QWeatherErrorCode.noCredit,
  'Overdue': QWeatherErrorCode.overdue,
  'Security Restriction': QWeatherErrorCode.securityRestriction,
  'Invalid Host': QWeatherErrorCode.invalidHost,
  'Account Suspension': QWeatherErrorCode.accountSuspension,
  'Deprecated': QWeatherErrorCode.deprecated,
  'Forbidden': QWeatherErrorCode.forbidden,
  'Not Found': QWeatherErrorCode.notFound,
  'Method Not Allowed': QWeatherErrorCode.methodNotAllowed,
  'Too Many Requests': QWeatherErrorCode.tooManyRequests,
  'Over Monthly Limit': QWeatherErrorCode.overMonthlyLimit,
  'Unknown Error': QWeatherErrorCode.unknownError,
};

/// 和风服务端按官方错误码明确拒绝请求时抛出的业务异常。
///
/// 属于和风适配器而非通用网络层；界面据此区分“凭据/额度被拒”与普通服务
/// 错误。message 仅包含错误码名称和状态码，供开发诊断使用，不得写入
/// KEY、坐标、`detail` 或 `invalidParams` 等原始响应内容。
final class QWeatherServiceException extends AppException {
  /// 官方错误码列表中的具体类型，见 [QWeatherErrorCode]。
  final QWeatherErrorCode code;

  /// 服务端返回的 HTTP 状态码，与错误码类别保持一致，供诊断和测试。
  final int statusCode;

  QWeatherServiceException(this.code, this.statusCode)
    : super('QWeather service error: ${code.name} ($statusCode)');

  /// 是否属于凭据、Host 或账户额度被拒类别，界面可给出检查配置的提示。
  ///
  /// unauthorized/invalidHost 与 KEY 或 Host 配置直接相关；noCredit/overdue/
  /// accountSuspension/securityRestriction 表示账户额度或安全状态不允许请求。
  bool get isCredentialOrQuota =>
      code == QWeatherErrorCode.unauthorized ||
      code == QWeatherErrorCode.invalidHost ||
      code == QWeatherErrorCode.noCredit ||
      code == QWeatherErrorCode.overdue ||
      code == QWeatherErrorCode.accountSuspension ||
      code == QWeatherErrorCode.securityRestriction;
}

/// 从和风 problem+json 错误响应体中解析官方错误码。
///
/// [body] 为 Dio 解码后的响应数据；结构不符合约定（非对象、无 error 字段、
/// 无法识别 type/title）时返回 null，调用方继续使用通用 HTTP 错误路径，
/// 不得把未知结构伪装成具体错误码。
QWeatherErrorCode? parseQWeatherErrorCode(dynamic body) {
  if (body is! Map) return null;
  final error = body['error'];
  if (error is! Map) return null;
  return QWeatherErrorCode.fromErrorType(error['type'] as String?) ??
      QWeatherErrorCode.fromErrorTitle(error['title'] as String?);
}
