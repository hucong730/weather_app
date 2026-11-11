import 'package:flutter/material.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/features/weather/presentation/widgets/current_weather_card.dart';
import 'package:weather_app/features/weather/presentation/widgets/daily_forecast_list.dart';
import 'package:weather_app/features/weather/presentation/widgets/hourly_forecast_list.dart';

/// 主页与搜索预览共用的完整天气内容。
///
/// 只负责组合当前卡片、24 小时和 7 天预报，不持有网络、缓存或导航状态；
/// “今天”仍按报告中的地点 UTC 偏移计算，确保两个页面展示一致。
class WeatherReportContent extends StatelessWidget {
  /// 需要展示的完整天气报告，各子组件共享同一份地点与时间数据。
  final WeatherReport report;

  /// 主页使用独立悬浮城市头时关闭卡片内标题；搜索预览保持默认值 true。
  final bool showLocation;

  const WeatherReportContent({
    super.key,
    required this.report,
    this.showLocation = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CurrentWeatherCard(report: report, showLocation: showLocation),
        const SizedBox(height: 20),
        HourlyForecastList(
          items: report.hourly,
          utcOffsetSeconds: report.utcOffsetSeconds,
        ),
        const SizedBox(height: 20),
        DailyForecastList(
          items: report.daily,
          today: WeatherFormatters.locationToday(
            DateTime.now().toUtc(),
            report.utcOffsetSeconds,
          ),
        ),
      ],
    );
  }
}
