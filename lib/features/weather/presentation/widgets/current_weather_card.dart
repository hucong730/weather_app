import 'package:flutter/material.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/presentation/animations/weather_animation.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 当前天气卡片，展示动画、温度及各项详情。
///
/// 预览页通过 [showLocation] 保留卡片内城市名；主页把它交给滚动悬浮头，
/// 避免同一页面出现两个城市标题。空气质量固定位于体感温度上方。
class CurrentWeatherCard extends StatelessWidget {
  /// 已统一单位和地点时区的完整天气报告。
  final WeatherReport report;

  /// 是否显示卡片内城市名；主页使用悬浮城市头时应关闭。
  final bool showLocation;

  const CurrentWeatherCard({
    super.key,
    required this.report,
    this.showLocation = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);
    final current = report.current;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (showLocation) ...[
              Text(
                WeatherFormatters.locationName(
                  report.location,
                  l10n,
                  includeDetails: false,
                ),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            WeatherAnimation(
              condition: current.condition,
              isDay: current.isDay,
            ),
            Text(
              '${WeatherFormatters.temperature(current.temperature, locale)}°C',
              style: Theme.of(context).textTheme.displayMedium,
            ),
            Text(
              WeatherFormatters.conditionLabel(current.condition, l10n),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _DetailRow(
              label: l10n.airQuality,
              value: current.airQuality == null
                  ? '--'
                  : '${current.airQuality!.displayValue} ${current.airQuality!.category}',
            ),
            _DetailRow(
              label: l10n.feelsLike,
              value:
                  '${WeatherFormatters.temperature(current.apparentTemperature, locale)}°C',
            ),
            _DetailRow(label: l10n.humidity, value: '${current.humidity}%'),
            _DetailRow(
              label: l10n.precipitation,
              value:
                  '${WeatherFormatters.decimal(current.precipitation, locale)} mm',
            ),
            _DetailRow(
              label: l10n.wind,
              value:
                  '${WeatherFormatters.decimal(current.windSpeed, locale)} km/h',
            ),
          ],
        ),
      ),
    );
  }
}

/// 当前天气详情中的单行标签和值，统一间距与长文本布局。
class _DetailRow extends StatelessWidget {
  /// 已国际化的详情名称，例如湿度或体感温度。
  final String label;

  /// 已格式化并带单位的详情值；缺失数据由调用方显示为 `--`。
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(value, textAlign: TextAlign.right),
        ],
      ),
    );
  }
}
