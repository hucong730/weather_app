import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:weather_app/features/weather/presentation/widgets/qweather_icon.dart';

void main() {
  test('clear weather selects day and night official svg assets', () {
    expect(
      QWeatherIcon.assetName(WeatherCondition.clear, true),
      'assets/weather_icons/100.svg',
    );
    expect(
      QWeatherIcon.assetName(WeatherCondition.clear, false),
      'assets/weather_icons/150.svg',
    );
  });

  test('every weather condition has an existing official svg asset', () {
    for (final condition in WeatherCondition.values) {
      for (final isDay in [true, false]) {
        final path = QWeatherIcon.assetName(condition, isDay);
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });

  testWidgets('renders official svg with semantics', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: QWeatherIcon(
          condition: WeatherCondition.rain,
          isDay: true,
          semanticLabel: '小雨',
        ),
      ),
    );

    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.bySemanticsLabel('小雨'), findsOneWidget);
  });

  testWidgets('dark theme applies light surface color to official svg', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const QWeatherIcon(
          condition: WeatherCondition.clear,
          isDay: false,
        ),
      ),
    );

    final context = tester.element(find.byType(QWeatherIcon));
    final svg = tester.widget<SvgPicture>(find.byType(SvgPicture));
    final loader = svg.bytesLoader as SvgAssetLoader;
    expect(loader.theme?.currentColor, Theme.of(context).colorScheme.onSurface);
    expect(loader.theme?.currentColor, isNot(Colors.black));
  });
}
