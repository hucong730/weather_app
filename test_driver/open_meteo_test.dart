import 'package:flutter_driver/flutter_driver.dart';

import 'integration_test.dart' as shared;

/// 在设置页切换服务，下拉项与当前选中值不会重名。
Future<void> selectWeatherProvider(
  FlutterDriver driver,
  String providerName,
) async {
  await driver.tap(find.byValueKey('weather_provider_dropdown'));
  await driver.tap(find.text(providerName));
  await Future<void>.delayed(const Duration(milliseconds: 500));
}

Future<void> openSettings(FlutterDriver driver) async {
  await driver.tap(find.byValueKey('settings_button'));
  await driver.waitFor(find.byValueKey('settings_page'));
}

Future<void> main() async {
  final driver = await FlutterDriver.connect();

  try {
    // 固定中文便于跨模拟器配置定位菜单项，再切换到 Open-Meteo。
    await openSettings(driver);
    await driver.tap(find.byValueKey('language_dropdown'));
    await driver.tap(find.text('简体中文'));
    await selectWeatherProvider(driver, 'Open-Meteo');
    final sourceTree = (await driver.getRenderTree()).toJson().toString();
    if (!sourceTree.contains('https://open-meteo.com/')) {
      throw StateError('Open-Meteo attribution was not rendered');
    }
    await driver.tap(find.byType('BackButton'));

    // 单字与无匹配名称都完成真实搜索并显示空结果；数字邮编只显示
    // 城市名称校验，不进入 Geocoding 请求或误报服务不可用。
    await driver.tap(find.byValueKey('search_button'));
    await driver.waitFor(find.byType('TextField'));
    final hintTree = (await driver.getRenderTree()).toJson().toString();
    if (!hintTree.contains('输入城市名称') || hintTree.contains('邮政编码')) {
      throw StateError('City-only search hint was not rendered');
    }
    await driver.enterText('我');
    await driver.waitFor(
      find.text('未找到匹配城市'),
      timeout: const Duration(seconds: 20),
    );
    await driver.enterText('我想');
    await Future<void>.delayed(const Duration(milliseconds: 700));
    await driver.waitFor(
      find.text('未找到匹配城市'),
      timeout: const Duration(seconds: 20),
    );
    await driver.enterText('10001');
    await driver.waitFor(find.text('请输入城市名称，不支持邮政编码或坐标'));
    final emptyTree = (await driver.getRenderTree()).toJson().toString();
    if (emptyTree.contains('天气服务暂不可用')) {
      throw StateError('Empty city search was misreported as service failure');
    }
    await driver.tap(find.byType('BackButton'));

    // 使用真实 Geocoding、Forecast 和 Air Quality API 添加两座城市。
    await shared.addCity(driver, '武汉');
    await shared.addCity(driver, '北京');
    await driver.waitFor(find.byValueKey('weather_page_location_marker'));
    await driver.waitFor(find.byValueKey('weather_page_dot_1'));
    await driver.waitFor(find.byValueKey('weather_page_dot_2'));

    // 切回未配置凭据的和风时允许显示配置错误，但不得清空城市和旧天气。
    await openSettings(driver);
    await selectWeatherProvider(driver, '和风天气');
    await driver.tap(find.byType('BackButton'));
    await Future<void>.delayed(const Duration(seconds: 2));
    final retainedTree = (await driver.getRenderTree()).toJson().toString();
    if (!retainedTree.contains('weather_page_dot_2') ||
        !retainedTree.contains('daily_item_6')) {
      throw StateError('Provider switching removed cities or cached weather');
    }

    // 再切回 Open-Meteo，确认相同城市身份能取得并展示新服务报告。
    await openSettings(driver);
    await selectWeatherProvider(driver, 'Open-Meteo');
    await driver.tap(find.byType('BackButton'));
    await Future<void>.delayed(const Duration(seconds: 3));
    final refreshedTree = (await driver.getRenderTree()).toJson().toString();
    if (!refreshedTree.contains('weather_page_dot_2') ||
        !refreshedTree.contains('hourly_item_0') ||
        !refreshedTree.contains('daily_item_6')) {
      throw StateError('Open-Meteo weather did not recover after switching');
    }

    // 实际上滑天气内容，pinned 城市标题必须继续存在，底部入口保持可用。
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
