import 'package:flutter_driver/flutter_driver.dart';

/// 复用上一次在线流程的 SQLite/SharedPreferences，验证冷启动恢复。
Future<void> main() async {
  final driver = await FlutterDriver.connect();

  try {
    // 定位页没有缓存，但两座搜索城市和底部分页必须从 SQLite 恢复。
    await driver.waitFor(
      find.byValueKey('weather_page_dot_2'),
      timeout: const Duration(seconds: 15),
    );
    await driver.tap(find.byValueKey('weather_page_dot_1'));
    await driver.waitFor(
      find.byValueKey('daily_item_6'),
      timeout: const Duration(seconds: 20),
    );
    await driver.waitFor(find.byValueKey('hourly_item_0'));

    // 服务选择也必须跨启动保留，不能把恢复的报告误标为和风。
    await driver.tap(find.byValueKey('settings_button'));
    await driver.waitFor(find.byValueKey('settings_page'));
    final sourceTree = (await driver.getRenderTree()).toJson().toString();
    if (!sourceTree.contains('https://open-meteo.com/')) {
      throw StateError('Open-Meteo preference or attribution was not restored');
    }
    await driver.tap(find.byType('BackButton'));
    await driver.waitFor(find.byValueKey('weather_page_dot_2'));
    await driver.scroll(
      find.byValueKey('weather_city_scroll_view'),
      0,
      -500,
      const Duration(milliseconds: 500),
    );
    await driver.waitFor(find.byValueKey('weather_city_sticky_header'));
    await driver.waitFor(find.byValueKey('weather_bottom_bar'));
  } finally {
    await driver.close();
  }
}
