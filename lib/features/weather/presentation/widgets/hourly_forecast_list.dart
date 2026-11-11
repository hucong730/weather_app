import 'package:flutter/material.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/features/weather/presentation/widgets/qweather_icon.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 横向 24 小时预报列表。
///
/// 每项使用稳定 ValueKey 供测试和 Driver 定位；时间按地点 UTC 偏移转换，
/// 不使用设备本地时区。
class HourlyForecastList extends StatelessWidget {
  /// 从当前小时开始、按时间连续排列的 24 条分时预报。
  final List<HourlyForecast> items;

  /// 报告地点相对 UTC 的偏移秒数，用于显示正确的当地时间。
  final int utcOffsetSeconds;

  const HourlyForecastList({
    super.key,
    required this.items,
    required this.utcOffsetSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.hourlyForecast,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 156,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                key: ValueKey('hourly_item_$index'),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        index == 0
                            ? l10n.now
                            : WeatherFormatters.hour(
                                item.timeUtc,
                                utcOffsetSeconds,
                                locale,
                              ),
                      ),
                      const SizedBox(height: 8),
                      QWeatherIcon(
                        condition: item.condition,
                        isDay: item.isDay,
                        size: 28,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${WeatherFormatters.temperature(item.temperature, locale)}°C',
                      ),
                      Text(
                        WeatherFormatters.probability(
                          item.precipitationProbability,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
