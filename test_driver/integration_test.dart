import 'package:flutter_driver/flutter_driver.dart';

/// 按真实渲染状态等待预览加载，不依赖屏幕外元素的 Finder 可见性。
///
/// 当前天气卡片与添加按钮同时出现才继续，避免加载期间点击禁用的添加。
Future<void> waitForPreviewLoaded(FlutterDriver driver) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (DateTime.now().isBefore(deadline)) {
    final tree = (await driver.getRenderTree()).toJson().toString();
    if (tree.contains('CurrentWeatherCard') &&
        tree.contains('add_location_button')) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }
  throw StateError('Weather preview did not finish loading');
}

/// 搜索并添加一个城市，返回主页后确认完整预报仍然可见。
Future<void> addCity(FlutterDriver driver, String query) async {
  await driver.tap(find.byValueKey('search_button'));
  await driver.waitFor(find.byType('TextField'));
  await driver.tap(find.byType('TextField'));
  // 不发送键盘提交动作，专门验证 500ms 防抖后的自动搜索。
  await driver.enterText(query);
  await driver.waitFor(
    find.byValueKey('location_item_0'),
    timeout: const Duration(seconds: 20),
  );
  await driver.tap(find.byValueKey('location_item_0'));
  await waitForPreviewLoaded(driver);
  // 网络可能快于全屏转场，等待 iOS 模态路由稳定后再点击顶部按钮。
  await Future<void>.delayed(const Duration(milliseconds: 500));
  await driver.tap(
    find.byValueKey('add_location_button'),
    timeout: const Duration(seconds: 10),
  );
  await Future<void>.delayed(const Duration(seconds: 2));

  final renderTree = (await driver.getRenderTree()).toJson().toString();
  if (!renderTree.contains('daily_item_6') ||
      !renderTree.contains('hourly_item_0')) {
    throw StateError(
      'Complete forecasts were not rendered after adding $query',
    );
  }
}

Future<void> main() async {
  final driver = await FlutterDriver.connect();

  try {
    await addCity(driver, '武汉');
    await addCity(driver, '北京');
    await driver.waitFor(find.byValueKey('weather_page_location_marker'));
    await driver.waitFor(find.byValueKey('weather_page_dot_1'));
    await driver.waitFor(find.byValueKey('weather_page_dot_2'));

    // 第二座城市之后依次滑回第一座城市和固定定位页，再滑回新增城市。
    await driver.scroll(
      find.byType('PageView'),
      400,
      0,
      const Duration(milliseconds: 300),
    );
    await driver.scroll(
      find.byType('PageView'),
      400,
      0,
      const Duration(milliseconds: 300),
    );
    await driver.scroll(
      find.byType('PageView'),
      -400,
      0,
      const Duration(milliseconds: 300),
    );

    await driver.tap(find.byValueKey('settings_button'));
    await driver.waitFor(find.byValueKey('settings_page'));
    await driver.tap(find.byValueKey('language_dropdown'));
    await driver.tap(find.text('简体中文'));
    await driver.tap(find.byValueKey('theme_dropdown'));
    await driver.tap(find.text('深色'));
    await driver.tap(find.byType('BackButton'));
    await driver.waitFor(find.byValueKey('weather_home_page'));

    final renderTree = (await driver.getRenderTree()).toJson().toString();
    if (!renderTree.contains('daily_item_6')) {
      throw StateError('Weather was lost after changing settings');
    }

    // 和风武汉/北京 id 分别为 101200101/101010100；验证真实拖拽和删除。
    await driver.tap(find.byValueKey('settings_button'));
    await driver.tap(find.byValueKey('city_management_entry'));
    await driver.waitFor(find.byValueKey('city_management_page'));
    await driver.scroll(
      find.byValueKey('reorder_city_101200101'),
      0,
      140,
      const Duration(milliseconds: 500),
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final reorderedTree = (await driver.getRenderTree()).toJson().toString();
    final wuhanPosition = reorderedTree.indexOf('managed_city_101200101');
    final beijingPosition = reorderedTree.indexOf('managed_city_101010100');
    if (wuhanPosition < 0 ||
        beijingPosition < 0 ||
        beijingPosition > wuhanPosition) {
      throw StateError('City drag did not update the management order');
    }
    await driver.tap(find.byValueKey('delete_city_101010100'));
    await driver.waitForAbsent(find.byValueKey('managed_city_101010100'));
    await driver.tap(find.byType('BackButton'));
    await driver.waitFor(find.byValueKey('settings_page'));
    await driver.tap(find.byType('BackButton'));
    await driver.waitFor(find.byValueKey('weather_home_page'));
    await driver.waitForAbsent(find.byValueKey('weather_page_dot_2'));
  } finally {
    await driver.close();
  }
}
