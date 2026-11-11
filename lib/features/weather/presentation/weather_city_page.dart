import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/weather_home_controller.dart';
import 'package:weather_app/features/weather/application/weather_home_state.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_error_view.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_report_content.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_status_message.dart';
import 'package:weather_app/l10n/app_localizations.dart';
import 'package:easy_refresh/easy_refresh.dart';

/// PageView 中的单个天气页面，观察自己 key 对应的独立城市 Provider。
class WeatherCityPage extends ConsumerStatefulWidget {
  /// 主页分配的稳定页面 key，用于读取对应条目和独立城市 Provider。
  final String pageKey;

  const WeatherCityPage({super.key, required this.pageKey});

  @override
  ConsumerState<WeatherCityPage> createState() => _WeatherCityPageState();
}

class _WeatherCityPageState extends ConsumerState<WeatherCityPage> {
  /// 下拉只刷新当前页；定位页重新获取 GPS，其他城市复用其地点。
  Future<void> _refresh() {
    final entry = ref
        .read(weatherHomeControllerProvider)
        .entryByKey(widget.pageKey);
    if (entry.isCurrent) {
      return ref
          .read(weatherHomeControllerProvider.notifier)
          .refreshCurrent(reacquire: true);
    }
    final location = entry.location;
    if (location == null) return Future<void>.value();
    return ref
        .read(weatherCityControllerProvider(widget.pageKey).notifier)
        .load(
          location,
          languageCode: Localizations.localeOf(context).languageCode,
          localizeLocation: entry.needsLocalization,
        );
  }

  @override
  Widget build(BuildContext context) {
    // 页面可能先于缓存读取创建空 Provider；home 恢复报告后只填补空状态，
    // 不覆盖该城市已经开始的新加载或错误状态。
    ref.listen<WeatherHomeState>(weatherHomeControllerProvider, (_, next) {
      final report = next.entryByKeyOrNull(widget.pageKey)?.report;
      final cityState = ref.read(weatherCityControllerProvider(widget.pageKey));
      if (report != null && cityState.data == null) {
        ref
            .read(weatherCityControllerProvider(widget.pageKey).notifier)
            .acceptReport(report);
      }
    });
    final homeState = ref.watch(weatherHomeControllerProvider);
    final entry = homeState.entryByKeyOrNull(widget.pageKey);
    // 删除操作会先在 home 移除条目，再卸载旧的 PageView 子树。
    if (entry == null) return const SizedBox.shrink();
    final state = ref.watch(weatherCityControllerProvider(widget.pageKey));

    return EasyRefresh(
      triggerAxis: Axis.vertical,
      // 刷新区域位于列表内部，下拉时推动后续内容，而不是悬浮遮挡城市标题。
      header: const ClassicHeader(
        showText: false,
        position: IndicatorPosition.locator,
      ),
      onRefresh: _refresh,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final content = _content(entry, state);
              final report = state.data;
              if (report != null) {
                return CustomScrollView(
                  key: const Key('weather_city_scroll_view'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // 定位器让天气内容随下拉下移；固定标题不会自动响应反向
                    // 滚动，因此额外监听相同偏移，避免刷新箭头盖住标题。
                    const HeaderLocator.sliver(),
                    ValueListenableBuilder(
                      valueListenable: EasyRefresh.of(
                        context,
                      ).headerNotifier.listenable(),
                      builder: (context, notifier, _) {
                        return SliverPersistentHeader(
                          pinned: true,
                          delegate: _CityNameHeaderDelegate(
                            name: WeatherFormatters.locationName(
                              report.location,
                              AppLocalizations.of(context),
                              includeDetails: false,
                            ),
                            refreshOffset: notifier.offset,
                          ),
                        );
                      },
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([content]),
                      ),
                    ),
                  ],
                );
              }
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                children: [
                  const HeaderLocator(),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight > 32
                          ? constraints.maxHeight - 32
                          : 0,
                    ),
                    // 无天气数据时让加载、空状态和错误整体位于页面中央，
                    // 同时保留 ListView 的垂直下拉刷新能力。
                    child: Center(child: content),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _content(WeatherHomeEntry entry, LoadState state) {
    final l10n = AppLocalizations.of(context);
    final homeState = ref.read(weatherHomeControllerProvider);

    if (entry.isCurrent &&
        state.data == null &&
        state.status != LoadStatus.error) {
      if (homeState.currentLocationStatus ==
          LocationResolutionStatus.manualRequired) {
        return Column(
          key: const Key('current_location_placeholder'),
          children: [
            WeatherStatusMessage(
              icon: Icons.location_searching,
              text: l10n.locationPrompt,
            ),
            TextButton(
              key: const Key('retry_location_button'),
              onPressed: _refresh,
              child: Text(l10n.retry),
            ),
          ],
        );
      }
      return WeatherStatusMessage(
        icon: Icons.my_location,
        text: l10n.locating,
        showProgress: true,
      );
    }

    return switch (state.status) {
      LoadStatus.idle => WeatherStatusMessage(
        icon: Icons.cloud_download,
        text: l10n.loading,
        showProgress: true,
      ),
      LoadStatus.loading => WeatherStatusMessage(
        icon: Icons.cloud_download,
        text: l10n.loading,
        showProgress: true,
      ),
      LoadStatus.empty => WeatherStatusMessage(
        icon: Icons.search,
        text: l10n.searchPrompt,
      ),
      LoadStatus.error => Column(
        children: [
          if (state.data != null) ...[
            WeatherReportContent(report: state.data!, showLocation: false),
            _cachedLocationWarning(entry),
          ],
          WeatherErrorView(error: state.error!, onRetry: _refresh),
        ],
      ),
      LoadStatus.success => Column(
        children: [
          WeatherReportContent(report: state.data!, showLocation: false),
          _cachedLocationWarning(entry),
        ],
      ),
    };
  }

  /// 有缓存但重新定位失败时保留天气，并显示独立的授权/重试提示。
  Widget _cachedLocationWarning(WeatherHomeEntry entry) {
    if (!entry.isCurrent) return const SizedBox.shrink();
    final status = ref
        .read(weatherHomeControllerProvider)
        .currentLocationStatus;
    if (status != LocationResolutionStatus.manualRequired) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    return Padding(
      key: const Key('current_location_warning'),
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          Text(l10n.cachedLocationWarning, textAlign: TextAlign.center),
          TextButton(
            key: const Key('retry_location_button'),
            onPressed: _refresh,
            child: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}

/// 每个城市页独立的固定城市标题，不使用 Scaffold 的全局 AppBar。
///
/// 上滑覆盖内容后显示细分隔线；下拉刷新时按相同偏移随内容下移。
/// PageView 水平切页时各自保存滚动位置，不会串用其他城市的标题或偏移。
class _CityNameHeaderDelegate extends SliverPersistentHeaderDelegate {
  /// 当前页面显示的城市名称，不包含省和国家等搜索区分信息。
  final String name;

  /// 当前下拉刷新偏移，让固定标题与天气内容同步下移。
  final double refreshOffset;

  const _CityNameHeaderDelegate({
    required this.name,
    required this.refreshOffset,
  });

  @override
  double get minExtent => 52;

  @override
  double get maxExtent => 52;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final theme = Theme.of(context);
    return Transform.translate(
      offset: Offset(0, refreshOffset),
      child: Semantics(
        header: true,
        child: Container(
          key: const Key('weather_city_sticky_header'),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: overlapsContent
                ? Border(
                    bottom: BorderSide(
                      color: theme.dividerColor.withValues(alpha: 0.45),
                    ),
                  )
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_CityNameHeaderDelegate oldDelegate) {
    return oldDelegate.name != name ||
        oldDelegate.refreshOffset != refreshOffset;
  }
}
