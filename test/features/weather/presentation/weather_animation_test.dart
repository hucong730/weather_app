import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:weather_app/features/weather/presentation/animations/weather_animation.dart';
import 'package:weather_app/l10n/app_localizations.dart';

Widget createTestApp(Widget child, {bool disableAnimations = false}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: MediaQuery(
      data: MediaQueryData(disableAnimations: disableAnimations),
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

AnimationController controllerOf(WidgetTester tester) {
  return tester
          .widget<AnimatedBuilder>(
            find.byKey(const ValueKey('weather_animation_builder')),
          )
          .listenable
      as AnimationController;
}

void main() {
  testWidgets('all weather conditions render finite frames and dispose', (
    tester,
  ) async {
    for (final condition in WeatherCondition.values) {
      await tester.pumpWidget(
        createTestApp(WeatherAnimation(condition: condition, isDay: true)),
      );
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 150));
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('scale grows then shrinks continuously without resetting', (
    tester,
  ) async {
    await tester.pumpWidget(
      createTestApp(
        const WeatherAnimation(condition: WeatherCondition.rain, isDay: true),
      ),
    );

    double currentScale() {
      final scaleTransition = find.descendant(
        of: find.byKey(const ValueKey('weather_animation_builder')),
        matching: find.byType(ScaleTransition),
      );
      return tester.widget<ScaleTransition>(scaleTransition).scale.value;
    }

    expect(currentScale(), closeTo(0.96, 0.001));
    await tester.pump(const Duration(seconds: 2));
    expect(currentScale(), closeTo(1.0, 0.001));
    await tester.pump(const Duration(seconds: 2));
    expect(currentScale(), closeTo(1.04, 0.001));
    await tester.pump(const Duration(seconds: 2));
    expect(currentScale(), closeTo(1.0, 0.001));
    await tester.pump(const Duration(seconds: 2));
    expect(currentScale(), closeTo(0.96, 0.001));
  });

  testWidgets(
    'disableAnimations uses static semantic icon without controller',
    (tester) async {
      await tester.pumpWidget(
        createTestApp(
          const WeatherAnimation(condition: WeatherCondition.rain, isDay: true),
          disableAnimations: true,
        ),
      );

      expect(
        find.byKey(const ValueKey('weather_animation_builder')),
        findsNothing,
      );
      expect(find.byType(SvgPicture), findsOneWidget);
      expect(find.bySemanticsLabel('Rain'), findsOneWidget);
    },
  );

  testWidgets('TickerMode disabled stops animation progress', (tester) async {
    await tester.pumpWidget(
      createTestApp(
        const TickerMode(
          enabled: false,
          child: WeatherAnimation(
            condition: WeatherCondition.rain,
            isDay: true,
          ),
        ),
      ),
    );
    final controller = controllerOf(tester);
    final before = controller.value;

    await tester.pump(const Duration(milliseconds: 500));

    expect(controller.value, before);
  });
}
