import 'package:flutter/material.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/features/weather/presentation/widgets/qweather_icon.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 7 天纵向预报列表，嵌套在主页滚动视图中。
///
/// shrinkWrap + NeverScrollableScrollPhysics 防止与外层滚动冲突；
/// 日期、天气描述和最低/最高温度均来自领域模型。[today] 由调用方按
/// 地点 UTC 偏移换算，保证“今天”不受设备所在时区影响。
class DailyForecastList extends StatelessWidget {
  /// 按地点本地日历顺序排列的 7 天预报。
  final List<DailyForecast> items;

  /// 按报告地点 UTC 偏移计算出的本地“今天”，不使用设备日期替代。
  final DateTime today;

  const DailyForecastList({
    super.key,
    required this.items,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.dailyForecast,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(height: 4),
          itemBuilder: (context, index) {
            final item = items[index];
            final colorScheme = Theme.of(context).colorScheme;
            return Card(
              key: ValueKey('daily_item_$index'),
              child: Padding(
                key: ValueKey('daily_item_content_$index'),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    QWeatherIcon(
                      condition: item.condition,
                      isDay: true,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            WeatherFormatters.dailyDate(
                              item.date,
                              today,
                              locale,
                              l10n,
                            ),
                          ),
                          // 文本与左侧 SVG 表达同一天气状况，避免用户只能
                          // 依靠图标猜测“多云”“小雨”等具体天气。
                          Text(
                            WeatherFormatters.conditionLabel(
                              item.condition,
                              l10n,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // 温度列必须占满分配到的宽度，右对齐才能贴齐卡片内边距；
                    // 宽松 Flexible 会收缩到文字宽度，把温度留在卡片中间。
                    Flexible(
                      fit: FlexFit.tight,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text:
                                  '${WeatherFormatters.temperature(item.minTemperature, locale)}° / ',
                              style: TextStyle(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            TextSpan(
                              text:
                                  '${WeatherFormatters.temperature(item.maxTemperature, locale)}°',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        key: ValueKey('daily_temperature_$index'),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
