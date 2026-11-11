import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/application/weather_home_state.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';

part 'weather_city_controller.dart';

/// 多城市主页协调 Provider，只管理页面顺序、定位阶段和当前选中页。
final weatherHomeControllerProvider =
    NotifierProvider.autoDispose<WeatherHomeController, WeatherHomeState>(
      WeatherHomeController.new,
    );

/// 协调缓存恢复、GPS 重新获取、城市添加和可见页语言刷新。
class WeatherHomeController extends Notifier<WeatherHomeState> {
  /// 定位流程编号，手动选择和后续刷新可使尚未完成的自动定位失效。
  int _requestId = 0;

  /// 是否已经启动过冷启动流程，避免主页重建后重复恢复缓存和定位。
  bool _bootstrapStarted = false;

  /// 是否正在恢复启动缓存，用于吸收此期间到达的语言或服务设置变化。
  bool _isBootstrapping = false;

  /// 持久化语言若在缓存读取期间到达，恢复城市后仍需本地化旧地名。
  bool _localizeCachedCities = false;

  /// 当前天气请求使用的语言代码，启动及设置变化时更新。
  String _languageCode = 'en';

  @override
  WeatherHomeState build() {
    ref.onDispose(() => _requestId++);
    return const WeatherHomeState.initial();
  }

  /// 启动只执行一次：先恢复全部有效报告，再后台重新获取当前 GPS。
  Future<void> bootstrap({String languageCode = 'en'}) async {
    if (_bootstrapStarted) return;
    _bootstrapStarted = true;
    _isBootstrapping = true;
    _languageCode = languageCode;
    final requestId = ++_requestId;
    try {
      final reports = await ref
          .read(weatherCacheProvider.future)
          .then((cache) => cache.loadAll())
          .onError((error, stackTrace) => <WeatherReport>[]);
      if (requestId != _requestId) return;

      WeatherReport? current;
      final cities = <WeatherReport>[];
      for (final report in reports) {
        if (report.location.origin == LocationOrigin.gps && current == null) {
          current = report;
        } else {
          cities.add(report);
        }
      }
      state = WeatherHomeState(
        entries: [
          WeatherHomeEntry(
            key: 'current',
            location: current?.location,
            report: current,
            isFromCache: current != null,
          ),
          for (final report in cities)
            WeatherHomeEntry(
              key: _cityKey(report.location),
              location: report.location,
              report: report,
              isFromCache: true,
              needsLocalization: _localizeCachedCities,
            ),
        ],
        currentLocationStatus: LocationResolutionStatus.locating,
        selectedPageIndex: 0,
      );
      // 设置加载在此期间只更新语言和服务，不再并发使缓存恢复失效；
      // 这里读取的是最新 Repository 与语言，一次完成首次定位刷新。
      await refreshCurrent(reacquire: true);
    } finally {
      _isBootstrapping = false;
    }
  }

  /// 刷新固定定位页；冷启动和主动下拉默认重新获取 GPS。
  ///
  /// 定位失败只更新定位阶段，绝不清除已有缓存报告。语言刷新传
  /// reacquire=false，复用现有坐标但仍重新请求本地化天气内容。
  Future<void> refreshCurrent({required bool reacquire}) async {
    final requestId = ++_requestId;
    var entry = state.entryByKey('current');
    var location = entry.location;
    if (reacquire || location == null) {
      state = state.copyWith(
        currentLocationStatus: LocationResolutionStatus.locating,
      );
      location = await ref
          .read(locationResolverProvider)
          .resolve(languageCode: _languageCode);
      if (requestId != _requestId) return;
      if (location == null) {
        state = state.copyWith(
          currentLocationStatus: LocationResolutionStatus.manualRequired,
        );
        return;
      }
      _replaceEntry(entry.copyWith(location: location));
    }
    state = state.copyWith(
      currentLocationStatus: LocationResolutionStatus.ready,
    );
    await ref
        .read(weatherCityControllerProvider('current').notifier)
        .load(location, languageCode: _languageCode);
  }

  /// 记录用户滑动后的可见页面，用于后续语言变更的定向刷新。
  void selectPage(int index) {
    if (index < 0 || index >= state.entries.length) return;
    state = state.copyWith(selectedPageIndex: index);
  }

  /// 添加或更新预览报告，并返回应滑动到的页面下标。
  ///
  /// 新城市追加到末尾；重复城市只更新原条目。活跃 Provider 立即接受报告，
  /// 新页面则可从 home entry 初始化。缓存位置与列表下标保持一致。
  Future<int> addReport(WeatherReport report) async {
    final entries = List<WeatherHomeEntry>.of(state.entries);
    var index = entries.indexWhere((entry) {
      if (entry.isCurrent) return false;
      final existing = entry.location;
      if (existing == null) return false;
      final existingId = existing.id;
      final newId = report.location.id;
      final sameProvider = entry.report?.provider == report.provider;
      // 同一服务内不同 ID 即使测试坐标相同也视为不同城市；只有跨服务或
      // 缺少服务 ID 时才使用小范围坐标容差补充同城判重。
      if (sameProvider && existingId != null && existingId.isNotEmpty) {
        return existingId == newId;
      }
      // 两家地点 ID 不直接比较；0.01° 容差兼容和风两位小数与
      // Open-Meteo 高精度坐标，同时避免把相距较远的城市合并。
      return (existing.latitude - report.location.latitude).abs() <= 0.01 &&
          (existing.longitude - report.location.longitude).abs() <= 0.01;
    });

    final clientId = index >= 0
        ? entries[index].location?.clientId ?? entries[index].key
        : report.location.clientId ??
              _availableClientId(report.location, entries);
    final location = report.location.copyWith(clientId: clientId);
    final normalizedReport = report.copyWith(location: location);
    final key = _cityKey(location);
    final entry = WeatherHomeEntry(
      key: key,
      location: location,
      report: normalizedReport,
    );
    if (index < 0) {
      entries.add(entry);
      index = entries.length - 1;
    } else {
      entries[index] = entry;
    }
    state = state.copyWith(entries: entries, selectedPageIndex: index);
    ref
        .read(weatherCityControllerProvider(key).notifier)
        .acceptReport(normalizedReport);
    await _save(normalizedReport, index);
    return index;
  }

  /// 城市网络成功后更新 home 快照，供页面重建和下次启动使用。
  Future<void> updateReport(String key, WeatherReport report) async {
    final entries = List<WeatherHomeEntry>.of(state.entries);
    final index = entries.indexWhere((entry) => entry.key == key);
    if (index < 0) return;
    entries[index] = entries[index].copyWith(
      location: report.location,
      report: report,
      isFromCache: false,
      needsLocalization: false,
    );
    state = state.copyWith(entries: entries);
    await _save(report, index);
  }

  /// 删除搜索城市并同步缓存；定位页不允许删除。
  ///
  /// 若删除当前选中城市则显示原位置的下一城市（末项则显示前一项）；
  /// 删除其他城市时按稳定 key 保留当前选中城市，不被下标变化打断。
  Future<void> deleteCity(String key) async {
    if (key == 'current') return;
    final entries = List<WeatherHomeEntry>.of(state.entries);
    final index = entries.indexWhere((entry) => entry.key == key);
    if (index < 0) return;
    final selectedKey = state.entries[state.selectedPageIndex].key;
    final removed = entries.removeAt(index);
    var selectedIndex = entries.indexWhere((entry) => entry.key == selectedKey);
    if (selectedIndex < 0) {
      selectedIndex = index < entries.length ? index : entries.length - 1;
    }
    state = state.copyWith(entries: entries, selectedPageIndex: selectedIndex);

    final report = removed.report;
    if (report == null) return;
    try {
      final cache = await ref.read(weatherCacheProvider.future);
      await cache.delete(report, position: index);
    } on Exception {
      // 缓存删除失败不影响当前会话；旧请求也无法通过 updateReport 写回。
    }
  }

  /// 按 onReorder 已修正的目标下标调整城市，定位页固定在第 0 页。
  ///
  /// 缓存排序在单个事务中完成；当前选中城市按 key 跟踪而非沿用旧下标。
  Future<void> reorderCities(int oldIndex, int newIndex) async {
    final cityCount = state.entries.length - 1;
    if (oldIndex < 0 || oldIndex >= cityCount) return;
    if (newIndex < 0 || newIndex >= cityCount) return;
    if (oldIndex == newIndex) return;

    final selectedKey = state.entries[state.selectedPageIndex].key;
    final entries = List<WeatherHomeEntry>.of(state.entries);
    final moved = entries.removeAt(oldIndex + 1);
    entries.insert(newIndex + 1, moved);
    final selectedIndex = entries.indexWhere(
      (entry) => entry.key == selectedKey,
    );
    state = state.copyWith(entries: entries, selectedPageIndex: selectedIndex);

    final cities = entries
        .skip(1)
        .map((entry) => entry.report)
        .whereType<WeatherReport>()
        .toList(growable: false);
    try {
      final cache = await ref.read(weatherCacheProvider.future);
      await cache.saveCityOrder(cities);
    } on Exception {
      // 排序先作用于当前会话；缓存异常不破坏已经展示的城市页面。
    }
  }

  /// 语言变化后刷新定位页和当前可见城市，其余页面标记为待刷新。
  ///
  /// 非可见城市保留旧报告供立即展示，等用户实际滑到该页时再按新语言请求，
  /// 避免一次语言切换同时消耗所有城市的 API 配额。
  Future<void> refreshVisible({
    required String languageCode,
    bool localizeLocations = false,
  }) async {
    _languageCode = languageCode;
    // 冷启动读取缓存时，持久化设置可能随后才加载完成。此次变化由
    // bootstrap 的首次刷新统一吸收，避免 requestId 递增后误丢弃城市缓存；
    // 地名本地化标记则随缓存条目恢复，等对应城市可见时执行。
    if (_isBootstrapping) {
      _localizeCachedCities = _localizeCachedCities || localizeLocations;
      return;
    }
    final selectedKey = state.entries[state.selectedPageIndex].key;
    state = state.copyWith(
      entries: [
        for (final entry in state.entries)
          entry.copyWith(
            isFromCache: true,
            needsLocalization:
                entry.needsLocalization ||
                (localizeLocations && !entry.isCurrent),
          ),
      ],
    );

    final tasks = <Future<void>>[refreshCurrent(reacquire: false)];
    if (selectedKey != 'current') {
      final selectedEntry = state.entryByKey(selectedKey);
      final location = selectedEntry.location;
      if (location != null) {
        tasks.add(
          ref
              .read(weatherCityControllerProvider(selectedKey).notifier)
              .load(
                location,
                languageCode: languageCode,
                localizeLocation: selectedEntry.needsLocalization,
              ),
        );
      }
    }
    await Future.wait(tasks);
  }

  void _replaceEntry(WeatherHomeEntry entry) {
    final entries = List<WeatherHomeEntry>.of(state.entries);
    final index = entries.indexWhere((item) => item.key == entry.key);
    if (index >= 0) {
      entries[index] = entry;
      state = state.copyWith(entries: entries);
    }
  }

  Future<void> _save(WeatherReport report, int position) async {
    try {
      final cache = await ref.read(weatherCacheProvider.future);
      await cache.save(report, position: position);
    } on Exception {
      // 缓存异常不影响已展示的报告；SQLite 实现负责全局写入顺序。
    }
  }

  /// 新页面由主应用分配稳定身份；初值沿用当前服务 ID 以兼容既有缓存，
  /// 若跨服务 ID 冲突则追加序号。后续比较只使用 clientId，不解释其内容。
  static String _availableClientId(
    Location location,
    List<WeatherHomeEntry> entries,
  ) {
    final base = location.id ?? '${location.latitude},${location.longitude}';
    var candidate = base;
    var suffix = 1;
    while (entries.any((entry) => entry.key == candidate)) {
      candidate = '$base-${suffix++}';
    }
    return candidate;
  }

  static String _cityKey(Location location) {
    if (location.origin == LocationOrigin.gps) return 'current';
    return location.clientId ??
        location.id ??
        '${location.latitude},${location.longitude}';
  }
}
