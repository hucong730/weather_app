import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// iOS 天气风格的主页分页指示器。
///
/// 第 0 页固定使用定位箭头，其他城市使用圆点；当前页使用完整亮色，
/// 其余页面降低不透明度。点击标记可直接切换到对应天气页。
class WeatherPageIndicator extends StatelessWidget {
  /// 页面总数，包含固定在 index 0 的当前定位页。
  final int pageCount;

  /// 当前高亮页面下标，必须位于 0 到 pageCount - 1 之间。
  final int currentIndex;

  /// 用户点击定位箭头或城市圆点时的切页回调。
  final ValueChanged<int> onSelected;

  const WeatherPageIndicator({
    super.key,
    required this.pageCount,
    required this.currentIndex,
    required this.onSelected,
  }) : assert(pageCount > 0),
       assert(currentIndex >= 0 && currentIndex < pageCount);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final activeColor = Theme.of(context).colorScheme.onSurface;
    final inactiveColor = activeColor.withValues(alpha: 0.35);

    return SizedBox(
      height: 44,
      child: Center(
        // 两侧按钮由主页底栏提供；中间区域在城市较多时独立横向滚动。
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var index = 0; index < pageCount; index++)
                _pageMarker(
                  context: context,
                  index: index,
                  semanticLabel: index == 0
                      ? l10n.currentLocationPage(index + 1, pageCount)
                      : l10n.cityPage(index + 1, pageCount),
                  activeColor: activeColor,
                  inactiveColor: inactiveColor,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pageMarker({
    required BuildContext context,
    required int index,
    required String semanticLabel,
    required Color activeColor,
    required Color inactiveColor,
  }) {
    final selected = index == currentIndex;
    final color = selected ? activeColor : inactiveColor;
    return Semantics(
      label: semanticLabel,
      button: true,
      selected: selected,
      child: InkResponse(
        key: Key('weather_page_indicator_$index'),
        onTap: () => onSelected(index),
        // iOS 风格分页标记点击时只切页，不显示 Material 水波纹和按压高亮。
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        radius: 20,
        child: SizedBox(
          width: index == 0 ? 32 : 28,
          height: 36,
          child: Center(
            child: index == 0
                ? Transform.rotate(
                    key: const Key('weather_page_location_rotation'),
                    // 与 Apple 天气一致，定位箭头朝右上倾斜 45°。
                    angle: math.pi / 4,
                    child: Icon(
                      Icons.navigation,
                      key: const Key('weather_page_location_marker'),
                      size: 17,
                      color: color,
                    ),
                  )
                : AnimatedContainer(
                    key: Key('weather_page_dot_$index'),
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 9 : 7,
                    height: selected ? 9 : 7,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
