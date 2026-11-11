import 'package:module_network/error/app_exception.dart';

/// Open-Meteo 服务端按官方错误协议返回错误时抛出的业务异常。
///
/// Open-Meteo 没有和风式的错误码枚举；各 API 文档（Forecast、Geocoding、
/// Air Quality 等）的 Errors 章节约定：出错时返回非 2xx 状态码，响应体为
/// `{"error": true, "reason": "..."}`，HTTP 400 表示参数错误，404 表示路径
/// 不存在，429 表示请求频率或每日限额超限。`reason` 是面向开发者的诊断
/// 字符串，可能回显请求参数（包括坐标），因此本异常只保留状态码，不把
/// 原始 `reason` 写入 message，避免向界面或日志泄漏。
final class OpenMeteoServiceException extends AppException {
  /// 服务端返回的 HTTP 状态码（400/404/429 等），供诊断和测试。
  final int statusCode;

  OpenMeteoServiceException(this.statusCode)
    : super('Open-Meteo service error (HTTP $statusCode)');
}

/// 判断响应体是否符合 Open-Meteo 官方错误对象结构。
///
/// [body] 为 Dio 解码后的响应数据；仅当其为 JSON 对象且 `error` 字段为
/// 布尔 true 时视为服务端明确返回的错误。不校验 `reason` 的内容，也
/// 不把 `reason` 回传给调用方，防止诊断字符串泄漏参数细节。
bool isOpenMeteoErrorBody(dynamic body) {
  return body is Map && body['error'] == true;
}
