import 'package:module_weather/models/location.dart';

/// 自动地点解析抽象，便于 Controller 在测试中替换真实 GPS。
///
/// 返回 null 表示当前无法取得位置，应展示手动搜索引导；
/// [languageCode] 保留给需要地点文本本地化的实现，GPS 实现可忽略。
abstract interface class LocationResolver {
  /// 解析一次自动地点；无法定位时返回 null，由上层回退到手动搜索。
  Future<Location?> resolve({String languageCode = 'en'});
}
