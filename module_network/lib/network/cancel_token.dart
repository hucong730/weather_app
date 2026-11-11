/// 通用网络请求取消令牌。
///
/// 由网络模块统一导出 Dio 的 [CancelToken]，业务 Controller 只依赖网络模块，
/// 即可在新请求开始或自身销毁时取消尚未完成的 HTTP 请求。
library;

export 'package:dio/dio.dart' show CancelToken;
