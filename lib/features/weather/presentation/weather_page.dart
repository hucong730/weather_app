import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/presentation/settings_page.dart';
import 'package:weather_app/features/weather/application/weather_home_controller.dart';
import 'package:weather_app/features/weather/application/weather_home_state.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/presentation/search_page.dart';
import 'package:weather_app/features/weather/presentation/weather_city_page.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_page_indicator.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 多城市天气主页，底栏提供设置、分页指示和搜索，内容使用 PageView 横向切页。
///
/// 每页自行处理垂直刷新与网络状态；本页只协调启动、路由和选中页动画。
class WeatherPage extends ConsumerStatefulWidget {
  const WeatherPage({super.key});

  @override
  ConsumerState<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends ConsumerState<WeatherPage> {
  /// 多城市横向分页控制器，负责指示器点击和添加城市后的平滑切页。
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(weatherHomeControllerProvider.notifier)
          .bootstrap(
            languageCode: Localizations.localeOf(context).languageCode,
          );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final homeState = ref.watch(weatherHomeControllerProvider);

    // 添加或重复添加城市后，等待当前帧完成再滑动到目标页。
    ref.listen<WeatherHomeState>(weatherHomeControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.selectedPageIndex == next.selectedPageIndex) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        // 跨页动画经过中间页时，onPageChanged 会同步 selectedPageIndex。
        // 此时 PageView 已经到达该状态，不应再次启动动画并取消原目标页。
        if (_pageController.page?.round() == next.selectedPageIndex) return;
        _pageController.animateToPage(
          next.selectedPageIndex,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      });
    });

    // 语言或服务变化只刷新定位页与当前可见城市，保留全部页面与旧报告。
    ref.listen<AppSettings>(settingsControllerProvider, (previous, next) {
      if (previous?.language == next.language &&
          previous?.weatherProvider == next.weatherProvider) {
        return;
      }
      final languageCode = switch (next.language) {
        LanguagePreference.en => 'en',
        LanguagePreference.zh => 'zh',
        LanguagePreference.system => Localizations.localeOf(
          context,
        ).languageCode,
      };
      ref
          .read(weatherHomeControllerProvider.notifier)
          .refreshVisible(
            languageCode: languageCode,
            localizeLocations: previous?.language != next.language,
          );
    });

    return Scaffold(
      key: const Key('weather_home_page'),
      body: SafeArea(
        bottom: false,
        child: PageView.builder(
          controller: _pageController,
          itemCount: homeState.entries.length,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            final entry = homeState.entries[index];
            return WeatherCityPage(
              key: ValueKey('weather_city_${entry.key}'),
              pageKey: entry.key,
            );
          },
        ),
      ),
      // 设置与搜索固定在底部分页器两侧，中间仍可按城市数量横向滚动。
      bottomNavigationBar: Material(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: SafeArea(
          top: false,
          child: SizedBox(
            key: const Key('weather_bottom_bar'),
            height: 52,
            child: Row(
              children: [
                IconButton(
                  key: const Key('settings_button'),
                  onPressed: _openSettings,
                  tooltip: l10n.settings,
                  icon: const Icon(Icons.settings),
                ),
                Expanded(
                  child: WeatherPageIndicator(
                    pageCount: homeState.entries.length,
                    currentIndex: homeState.selectedPageIndex,
                    onSelected: _onIndicatorSelected,
                  ),
                ),
                IconButton(
                  key: const Key('search_button'),
                  onPressed: _openSearch,
                  tooltip: l10n.searchButton,
                  icon: const Icon(Icons.search),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 点击底部分页标记时平滑切换；选中状态由 onPageChanged 统一更新。
  void _onIndicatorSelected(int index) {
    if (index == ref.read(weatherHomeControllerProvider).selectedPageIndex) {
      return;
    }
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  /// 记录实际可见页，并只在该页首次显示或语言过期时刷新缓存城市。
  ///
  /// 新增城市已经带有预览报告，isFromCache=false，因此跳转到新页不会重复请求。
  void _onPageChanged(int index) {
    final home = ref.read(weatherHomeControllerProvider.notifier);
    home.selectPage(index);
    final entry = ref.read(weatherHomeControllerProvider).entries[index];
    if (entry.isCurrent || !entry.isFromCache) return;
    final location = entry.location;
    if (location == null) return;
    ref
        .read(weatherCityControllerProvider(entry.key).notifier)
        .load(
          location,
          languageCode: Localizations.localeOf(context).languageCode,
          localizeLocation: entry.needsLocalization,
        );
  }

  /// 打开独立设置页；返回后保留当前城市页和全部分页状态。
  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const SettingsPage()));
  }

  /// 搜索预览确认后，复用已加载报告添加/更新城市并跳转到对应页面。
  Future<void> _openSearch() async {
    final report = await Navigator.of(context).push<WeatherReport>(
      MaterialPageRoute(builder: (_) => const SearchPage()),
    );
    if (report == null || !mounted) return;
    await ref.read(weatherHomeControllerProvider.notifier).addReport(report);
  }
}
