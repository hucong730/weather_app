import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';

/// 当前定位解析阶段，与各城市自己的网络 LoadStatus 保持独立。
enum LocationResolutionStatus { idle, locating, manualRequired, ready }

/// 主页中的一个稳定页面条目。
///
/// key=current 表示固定定位页，其他 key 为主应用分配的稳定城市身份；
/// report 保存该页最近一次成功内容，isFromCache 用于首次可见时决定是否刷新。
class WeatherHomeEntry {
  /// 跨服务切换和缓存恢复后仍保持不变的页面身份。
  final String key;

  /// 页面目标地点；定位尚未完成或缓存缺失时可以为 null。
  final Location? location;

  /// 最近一次成功取得的完整天气，定位中或首次加载前可以为 null。
  final WeatherReport? report;

  /// 当前内容是否直接恢复自 SQLite，首次可见时需要据此触发后台刷新。
  final bool isFromCache;

  /// 语言变化后是否仍需重新解析城市名；网络成功后清除，失败保留待重试。
  final bool needsLocalization;

  const WeatherHomeEntry({
    required this.key,
    this.location,
    this.report,
    this.isFromCache = false,
    this.needsLocalization = false,
  });

  bool get isCurrent => key == 'current';

  WeatherHomeEntry copyWith({
    Location? location,
    WeatherReport? report,
    bool? isFromCache,
    bool? needsLocalization,
  }) {
    return WeatherHomeEntry(
      key: key,
      location: location ?? this.location,
      report: report ?? this.report,
      isFromCache: isFromCache ?? this.isFromCache,
      needsLocalization: needsLocalization ?? this.needsLocalization,
    );
  }
}

/// 多城市主页的协调状态，不包含任何城市自己的网络 loading/error。
class WeatherHomeState {
  /// 有序页面条目，index 0 永远是定位页，其余为搜索添加的城市。
  final List<WeatherHomeEntry> entries;

  /// 固定定位页的 GPS 解析阶段，与各城市网络 LoadState 独立。
  final LocationResolutionStatus currentLocationStatus;

  /// 当前实际可见页面下标，用于分页高亮和语言变化后的定向刷新。
  final int selectedPageIndex;

  const WeatherHomeState({
    required this.entries,
    required this.currentLocationStatus,
    required this.selectedPageIndex,
  });

  const WeatherHomeState.initial()
    : entries = const [WeatherHomeEntry(key: 'current')],
      currentLocationStatus = LocationResolutionStatus.idle,
      selectedPageIndex = 0;

  WeatherHomeEntry entryByKey(String key) {
    return entries.singleWhere((entry) => entry.key == key);
  }

  /// 删除城市时，旧 PageView 子树可能短暂存活，使用可空查询安全退出。
  WeatherHomeEntry? entryByKeyOrNull(String key) {
    for (final entry in entries) {
      if (entry.key == key) return entry;
    }
    return null;
  }

  WeatherHomeState copyWith({
    List<WeatherHomeEntry>? entries,
    LocationResolutionStatus? currentLocationStatus,
    int? selectedPageIndex,
  }) {
    return WeatherHomeState(
      entries: entries ?? this.entries,
      currentLocationStatus:
          currentLocationStatus ?? this.currentLocationStatus,
      selectedPageIndex: selectedPageIndex ?? this.selectedPageIndex,
    );
  }
}
