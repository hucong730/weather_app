import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:weather_app/features/weather/presentation/widgets/daily_forecast_list.dart';
import 'package:weather_app/features/weather/presentation/widgets/hourly_forecast_list.dart';
import 'package:weather_app/l10n/app_localizations.dart';

import '../../../helpers/weather_test_data.dart';

void main() {
  final report = buildTestWeatherReport(testLocation);

  testWidgets('hourly forecast uses official svg icons', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: HourlyForecastList(items: report.hourly, utcOffsetSeconds: 3600),
      ),
    );

    expect(find.byType(SvgPicture), findsAtLeastNWidgets(1));
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hourly_item_23')),
      200,
      scrollable: find.byType(Scrollable),
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('hourly_item_23')),
        matching: find.byType(SvgPicture),
      ),
      findsOneWidget,
    );
  });

  testWidgets('daily forecast shows localized dates conditions and svg icons', (
    tester,
  ) async {
    final items = [
      report.daily.first.copyWith(condition: WeatherCondition.partlyCloudy),
      ...report.daily.skip(1),
    ];
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: DailyForecastList(
          items: items,
          today: DateTime.utc(2024, 1, 1, 12),
        ),
      ),
    );

    expect(find.text('今天（1月1日）'), findsOneWidget);
    expect(find.text('局部多云'), findsOneWidget);
    expect(find.text('60%'), findsNothing);
    expect(find.byType(SvgPicture), findsNWidgets(7));

    // 温度必须右对齐到卡片内容边缘，不能收缩后停留在卡片中间。
    final contentRect = tester.getRect(
      find.byKey(const ValueKey('daily_item_content_0')),
    );
    final temperatureRect = tester.getRect(
      find.byKey(const ValueKey('daily_temperature_0')),
    );
    expect(temperatureRect.right, closeTo(contentRect.right - 12, 0.1));

    final temperature = tester.widget<Text>(
      find.byKey(const ValueKey('daily_temperature_0')),
    );
    final temperatureSpan = temperature.textSpan! as TextSpan;
    final temperatureSpans = temperatureSpan.children!;
    expect(
      (temperatureSpans[1] as TextSpan).style?.fontWeight,
      FontWeight.w600,
    );
  });
}
