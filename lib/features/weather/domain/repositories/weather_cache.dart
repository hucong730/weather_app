import 'package:module_weather/models/weather_report.dart';

/// 有序天气缓存抽象，隔离主页/城市 Controller 与 SQLite 的具体实现。
abstract interface class WeatherCache {
  /// 按页面顺序读取全部有效报告；无记录返回空列表，单条损坏仅跳过该条。
  Future<List<WeatherReport>> loadAll();

  /// 保存指定页面位置的报告；相同定位/城市 key 替换，其他城市互不覆盖。
  Future<void> save(WeatherReport report, {required int position});

  /// 删除指定报告并压缩其后的城市位置，固定定位页的位置不受影响。
  Future<void> delete(WeatherReport report, {required int position});

  /// 按主页城市顺序原子更新缓存位置；列表不包含固定定位页。
  Future<void> saveCityOrder(List<WeatherReport> cities);
}
