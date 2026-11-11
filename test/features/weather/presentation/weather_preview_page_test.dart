import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/weather/presentation/weather_preview_page.dart';
import 'package:weather_app/l10n/app_localizations.dart';

import '../../../helpers/weather_test_data.dart';

class FakePreviewPageRepository implements WeatherRepository {
  Future<ApiResult<WeatherReport>> Function(Location location)? handler;

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) {
    return handler!(location);
  }

  @override
  Future<ApiResult<List<Location>>> searchLocations(
    String query,
    String languageCode, {
    CancelToken? cancelToken,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  late FakePreviewPageRepository repository;
  late WeatherReport report;

  setUp(() {
    repository = FakePreviewPageRepository();
    report = buildTestWeatherReport(testLocation);
  });

  Future<void> openPreview(
    WidgetTester tester, {
    Location location = testLocation,
    void Function(WeatherReport? report)? onResult,
  }) async {
    // 固定逻辑像素与 DPR，避免默认高 DPR 视图让 getRect/tap 坐标不一致。
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [weatherRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                final result = await Navigator.of(context)
                    .push<WeatherReport>(WeatherPreviewPage.route(location));
                onResult?.call(result);
              },
              child: const Text('Open preview'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open preview'));
    // 先启动转场，再推进 400ms；加载中的进度条会持续动画，不能用 pumpAndSettle。
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
  }

  TextButton addButton(WidgetTester tester) {
    return tester.widget<TextButton>(find.widgetWithText(TextButton, 'Add'));
  }

  testWidgets('loading preview disables add until weather succeeds', (
    tester,
  ) async {
    final response = Completer<ApiResult<WeatherReport>>();
    repository.handler = (_) => response.future;

    await openPreview(tester);

    expect(find.text('Loading weather…'), findsOneWidget);
    expect(addButton(tester).onPressed, isNull);

    response.complete(Success(report, 200));
    await tester.pumpAndSettle();

    expect(addButton(tester).onPressed, isNotNull);
    expect(find.byKey(const ValueKey('daily_item_6')), findsOneWidget);
  });

  testWidgets('successful add pops the already loaded report', (tester) async {
    repository.handler = (_) async => Success(report, 200);
    WeatherReport? result;
    var closed = false;

    await openPreview(
      tester,
      onResult: (value) {
        result = value;
        closed = true;
      },
    );
    await tester.tap(find.text('Add'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
    expect(result, report);
    expect(find.byType(WeatherPreviewPage), findsNothing);
  });

  testWidgets('failed preview disables add and retry recovers', (tester) async {
    var calls = 0;
    repository.handler = (_) async {
      calls++;
      if (calls == 1) return Failure(AppHttpException(500), 500);
      return Success(report, 200);
    };

    await openPreview(tester);

    expect(find.text('Weather service is unavailable'), findsOneWidget);
    expect(addButton(tester).onPressed, isNull);
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(calls, 2);
    expect(addButton(tester).onPressed, isNotNull);
  });

  testWidgets('cancel closes preview without returning a report', (
    tester,
  ) async {
    final response = Completer<ApiResult<WeatherReport>>();
    repository.handler = (_) => response.future;
    var closed = false;
    WeatherReport? result = report;

    await openPreview(
      tester,
      onResult: (value) {
        result = value;
        closed = true;
      },
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    response.complete(Success(report, 200));
    await tester.pump();

    expect(closed, isTrue);
    expect(result, isNull);
    expect(find.byType(WeatherPreviewPage), findsNothing);
  });

  testWidgets('double add closes only the preview route once', (tester) async {
    repository.handler = (_) async => Success(report, 200);
    var closeCount = 0;

    await openPreview(tester, onResult: (_) => closeCount++);
    final add = addButton(tester);
    add.onPressed!();
    add.onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(closeCount, 1);
    expect(find.text('Open preview'), findsOneWidget);
  });

  testWidgets('preview attribution follows the actual report provider', (
    tester,
  ) async {
    repository.handler = (_) async =>
        Success(report.copyWith(provider: WeatherProviderType.openMeteo), 200);

    await openPreview(tester);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('Weather data by Open-Meteo'),
      300,
      scrollable: find.byType(Scrollable).first,
    );

    expect(find.textContaining('Weather data by Open-Meteo'), findsOneWidget);
    expect(find.textContaining('Weather data by QWeather'), findsNothing);
  });

  testWidgets('each preview route keeps independent location state', (
    tester,
  ) async {
    final berlin = Completer<ApiResult<WeatherReport>>();
    final paris = Completer<ApiResult<WeatherReport>>();
    final parisLocation = testLocation.copyWith(id: 'paris', name: 'Paris');
    final parisReport = buildTestWeatherReport(parisLocation);
    repository.handler = (location) {
      return location.id == 'paris' ? paris.future : berlin.future;
    };

    await openPreview(tester);
    final firstContext = tester.element(find.byType(WeatherPreviewPage));
    final secondResult = Navigator.of(firstContext)
        .push<WeatherReport>(WeatherPreviewPage.route(parisLocation));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    paris.complete(Success(parisReport, 200));
    await tester.pump();
    await tester.pump();

    expect(find.text('Paris'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(await secondResult, parisReport);
    expect(find.text('Loading weather…'), findsOneWidget);
    expect(addButton(tester).onPressed, isNull);
    berlin.complete(Success(report, 200));
    await tester.pump();
    await tester.pump();
    expect(find.text('Berlin'), findsOneWidget);
    expect(addButton(tester).onPressed, isNotNull);
  });
}
