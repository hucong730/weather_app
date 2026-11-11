import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:module_weather/models/weather_condition.dart';

/// 和风官方 SVG 天气图标，按内部天气类别和昼夜选择本地资源。
///
/// 资源只包含应用支持的代码，未知天气统一使用 999；不在运行时下载图标。
class QWeatherIcon extends StatelessWidget {
  /// 统一天气类别，内部映射到对应的和风官方 SVG 代码。
  final WeatherCondition condition;

  /// 是否使用白天图标；仅对具有昼夜区分的天气代码生效。
  final bool isDay;

  /// 图标显示边长，SVG 始终保持原始比例缩放。
  final double size;

  /// 可选无障碍语义；调用方提供本地化天气文本，避免只依赖图形表达。
  final String? semanticLabel;

  const QWeatherIcon({
    super.key,
    required this.condition,
    required this.isDay,
    this.size = 96,
    this.semanticLabel,
  });

  /// 返回指定天气与昼夜对应的官方 SVG 资源路径。
  static String assetName(WeatherCondition condition, bool isDay) {
    final code = switch (condition) {
      WeatherCondition.clear => isDay ? 100 : 150,
      WeatherCondition.mainlyClear => isDay ? 101 : 151,
      WeatherCondition.partlyCloudy => isDay ? 103 : 153,
      WeatherCondition.overcast => 104,
      WeatherCondition.fog => 500,
      WeatherCondition.drizzle => 305,
      WeatherCondition.freezingDrizzle => 316,
      WeatherCondition.rain => 307,
      WeatherCondition.freezingRain => 310,
      WeatherCondition.snow => 400,
      WeatherCondition.snowGrains => 407,
      WeatherCondition.showers => isDay ? 300 : 350,
      WeatherCondition.snowShowers => isDay ? 456 : 457,
      WeatherCondition.thunderstorm => 302,
      WeatherCondition.thunderstormHail => 304,
      WeatherCondition.unknown => 999,
    };
    return 'assets/weather_icons/$code.svg';
  }

  @override
  Widget build(BuildContext context) {
    final label = semanticLabel;
    return SizedBox(
      width: size,
      height: size,
      child: Semantics(
        label: label,
        child: SvgPicture.asset(
          assetName(condition, isDay),
          width: size,
          height: size,
          fit: BoxFit.contain,
          // 官方资源使用 currentColor；显式跟随主题，避免深色下仍为黑色。
          theme: SvgTheme(
            currentColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
