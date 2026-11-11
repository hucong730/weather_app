import 'package:module_network/error/app_exception.dart';

/// 天气服务缺少必要配置，在请求发出前由对应适配器返回。
///
/// 该类型属于天气模块而非通用网络层；业务 UI 可统一映射配置错误文案。
final class AppConfigException extends AppException {
  const AppConfigException([super.message = 'Weather API is not configured']);
}
