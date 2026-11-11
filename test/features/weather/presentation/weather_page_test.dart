import 'dart:async';
import 'dart:math' as math;

import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/app.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';
import 'package:weather_app/features/weather/presentation/widgets/hourly_forecast_list.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_status_message.dart';

import '../../../helpers/fake_weather_cache.dart';
import '../../../helpers/weather_test_data.dart';

class FakeWeatherRepository implements WeatherRepository {
  Future<ApiResult<List<Location>>> Function(String, String)? searchHandler;
  Future<ApiResult<WeatherReport>> Function(Location)? weatherHandler;
  int weatherCalls = 0;
  final List<bool> localizationRequests = [];

  @override
  Future<ApiResult<List<Location>>> searchLocations(
    String query,
    String languageCode, {
    CancelToken? cancelToken,
  }) {
    return searchHandler!(query, languageCode);
  }

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) {
    weatherCalls++;
    localizationRequests.add(localizeLocation);
    return weatherHandler!(location);
  }
}

class FakeLocationResolver implements LocationResolver {
  Future<Location?> Function(String)? handler;

  @override
  Future<Location?> resolve({String languageCode = 'en'}) {
    return handler!(languageCode);
  }
}

void main() {
  late FakeWeatherRepository repository;
  late FakeLocationResolver resolver;
  late WeatherReport report;
  late FakeWeatherCache cache;

  setUp(() {
    repository = FakeWeatherRepository();
    resolver = FakeLocationResolver();
    cache = FakeWeatherCache();
    resolver.handler = (_) async => null;
    repository.searchHandler = (_, _) async =>
        const Success([testLocation], 200);
    report = buildTestWeatherReport(testLocation);
    repository.weatherHandler = (_) async => Success(report, 200);
  });

  WeatherReport asCurrent(WeatherReport value) {
    return value.copyWith(
      location: value.location.copyWith(origin: LocationOrigin.gps),
    );
  }

  Future<void> pumpApp(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
    bool largeText = false,
  }) async {
    tester.binding.platformDispatcher.localesTestValue = [locale];
    addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      await tester.idle();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
    });
    if (largeText) {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    }
    await tester.runAsync(() async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            weatherRepositoryProvider.overrideWithValue(repository),
            locationResolverProvider.overrideWithValue(resolver),
            weatherCacheProvider.overrideWith((ref) async => cache),
          ],
          child: const WeatherApp(),
        ),
      );
      await tester.pump();
      await tester.pump();
      await Future<void>.delayed(Duration.zero);
      await tester.pump();
    });
  }

  Future<void> openSearchPage(WidgetTester tester) async {
    if (find.byType(TextField).evaluate().isNotEmpty) return;
    await tester.tap(find.byKey(const Key('search_button')));
    await tester.pump();
    await tester.pump();
  }

  Future<void> submitCity(WidgetTester tester, String city) async {
    await openSearchPage(tester);
    await tester.enterText(find.byType(TextField), city);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    await tester.pump();
  }

  Future<void> selectLocation(WidgetTester tester, {int index = 0}) async {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(ValueKey('location_item_$index')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(Duration.zero);
    });
  }

  Future<void> addPreview(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('add_location_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(Duration.zero);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    });
  }

  Future<void> cancelPreview(WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('cancel_preview_button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await Future<void>.delayed(Duration.zero);
    });
  }

  testWidgets('locating still allows manual search through search button', (
    tester,
  ) async {
    final pending = Completer<Location?>();
    resolver.handler = (_) => pending.future;

    await pumpApp(tester);

    expect(find.text('Finding your location…'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await openSearchPage(tester);
    expect(find.byType(TextField), findsOneWidget);
    pending.complete(null);
    await tester.pump();
  });

  testWidgets('locating status is vertically centered in the page', (
    tester,
  ) async {
    final pending = Completer<Location?>();
    resolver.handler = (_) => pending.future;
    await pumpApp(tester);

    final statusCenter = tester.getCenter(find.byType(WeatherStatusMessage));
    final pageCenter = tester.getCenter(find.byType(PageView));
    expect(statusCenter.dy, closeTo(pageCenter.dy, 1));

    pending.complete(null);
    await tester.pump();
  });

  testWidgets('postcode shows city name validation without calling search', (
    tester,
  ) async {
    var searchCalls = 0;
    repository.searchHandler = (_, _) async {
      searchCalls++;
      return const Success(<Location>[], 200);
    };
    await pumpApp(tester);

    await submitCity(tester, '10001');

    expect(
      find.text('Enter a city name without postcodes or coordinates'),
      findsOneWidget,
    );
    expect(searchCalls, 0);
  });

  testWidgets('single character city name searches with city-only hint', (
    tester,
  ) async {
    final queries = <String>[];
    repository.searchHandler = (query, _) async {
      queries.add(query);
      return const Success(<Location>[], 200);
    };
    await pumpApp(tester);
    await openSearchPage(tester);

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.decoration!.hintText, 'Enter a city name');
    await tester.enterText(find.byType(TextField), 'B');
    await tester.pump(const Duration(milliseconds: 600));

    expect(queries, ['B']);
    expect(find.text('No matching cities'), findsOneWidget);
  });

  testWidgets('typing debounces search for 500ms and keeps latest query', (
    tester,
  ) async {
    final queries = <String>[];
    repository.searchHandler = (query, _) async {
      queries.add(query);
      return Success([testLocation], 200);
    };
    await pumpApp(tester);
    await openSearchPage(tester);

    await tester.enterText(find.byType(TextField), 'Beijing');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.enterText(find.byType(TextField), 'Berlin');
    await tester.pump(const Duration(milliseconds: 199));
    expect(queries, isEmpty);

    await tester.pump(const Duration(seconds: 1));

    expect(queries, ['Berlin']);
  });

  testWidgets('IME composition waits until Chinese text is committed', (
    tester,
  ) async {
    final queries = <String>[];
    repository.searchHandler = (query, _) async {
      queries.add(query);
      return Success([testLocation], 200);
    };
    await pumpApp(tester);
    await openSearchPage(tester);

    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: 'wu',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(queries, isEmpty);

    // iOS 中文候选已经上屏时，输入法仍可能保留组合区间，不能继续拦截。
    tester.testTextInput.updateEditingValue(
      const TextEditingValue(
        text: '武汉',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 0, end: 2),
      ),
    );
    await tester.pump(const Duration(milliseconds: 499));
    expect(queries, isEmpty);
    await tester.pump(const Duration(milliseconds: 1));
    expect(queries, ['武汉']);
  });

  testWidgets('manual submit cancels pending debounced search', (tester) async {
    final queries = <String>[];
    repository.searchHandler = (query, _) async {
      queries.add(query);
      return Success([testLocation], 200);
    };
    await pumpApp(tester);
    await openSearchPage(tester);

    await tester.enterText(find.byType(TextField), 'Berlin');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(queries, ['Berlin']);

    await tester.pump(const Duration(seconds: 1));
    expect(queries, ['Berlin']);
  });

  testWidgets('search empty and error states are visible', (tester) async {
    repository.searchHandler = (query, _) async {
      if (query == 'Unknown') return const Success([], 200);
      return const Failure(AppNetworkException(), null);
    };
    await pumpApp(tester);

    await submitCity(tester, 'Unknown');
    expect(find.text('No matching cities'), findsOneWidget);

    await submitCity(tester, 'Berlin');
    expect(find.text('Check your connection and try again'), findsOneWidget);
  });

  testWidgets('selecting location shows current weather 24 hours and 7 days', (
    tester,
  ) async {
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);
    expect(find.byKey(const Key('add_location_button')), findsOneWidget);
    await addPreview(tester);

    expect(repository.weatherCalls, 1);
    expect(cache.savedReports.map((item) => item.toJson()), [
      withClientIdentity(report).toJson(),
    ]);
    expect(find.text('Rain'), findsWidgets);
    expect(find.byKey(const ValueKey('hourly_item_0')), findsOneWidget);
    expect(find.text('Now'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('hourly_item_23')),
      300,
      scrollable: find.descendant(
        of: find.byType(HourlyForecastList),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.pump();
    expect(find.byKey(const ValueKey('hourly_item_23')), findsOneWidget);
    expect(find.byKey(const ValueKey('hourly_item_24')), findsNothing);
    expect(find.byKey(const ValueKey('daily_item_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('daily_item_6')), findsOneWidget);
    expect(find.byKey(const ValueKey('daily_item_7')), findsNothing);
    expect(find.textContaining('Weather data by QWeather'), findsNothing);
    expect(find.text('IP location by ipwho.is'), findsNothing);
    await tester.idle();
    (tester.binding as AutomatedTestWidgetsFlutterBinding).elapseBlocking(
      Duration.zero,
    );
  });

  testWidgets('ip location hides redundant approximate label', (tester) async {
    final ip = testLocation.copyWith(origin: LocationOrigin.ip);
    resolver.handler = (_) async => ip;
    repository.weatherHandler = (_) async =>
        Success(report.copyWith(location: ip), 200);
    await pumpApp(tester);

    expect(find.text('Approximate location (IP)'), findsNothing);
  });

  testWidgets('unavailable gps keeps fixed placeholder with retry', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(
      find.byKey(const Key('current_location_placeholder')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('retry_location_button')), findsOneWidget);
    expect(find.text('Berlin'), findsNothing);
  });

  testWidgets('weather error can be retried', (tester) async {
    resolver.handler = (_) async => testLocation;
    repository.weatherHandler = (_) async {
      if (repository.weatherCalls == 1) {
        return Failure(AppHttpException(500), 500);
      }
      return Success(report, 200);
    };
    await pumpApp(tester);

    expect(find.text('Weather service is unavailable'), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump();
      await Future<void>.delayed(Duration.zero);
    });

    expect(repository.weatherCalls, 2);
    expect(find.byKey(const ValueKey('daily_item_6')), findsOneWidget);
  });

  testWidgets('search page lists every result and adds selected preview', (
    tester,
  ) async {
    final paris = testLocation.copyWith(id: '1', name: 'Paris');
    repository.searchHandler = (_, _) async =>
        Success([testLocation, paris], 200);
    repository.weatherHandler = (location) async =>
        Success(report.copyWith(location: location), 200);
    await pumpApp(tester);

    expect(find.byType(TextField), findsNothing);
    await submitCity(tester, 'City');

    expect(find.byKey(const ValueKey('location_item_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('location_item_1')), findsOneWidget);
    await selectLocation(tester, index: 1);
    expect(find.textContaining('Paris'), findsOneWidget);
    await addPreview(tester);

    expect(find.textContaining('Paris'), findsOneWidget);
    expect(repository.weatherCalls, 1);
  });

  testWidgets('rapid repeated result taps open only one preview', (
    tester,
  ) async {
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');

    final result = tester.widget<ListTile>(
      find.byKey(const ValueKey('location_item_0')),
    );
    result.onTap!();
    result.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('add_location_button')), findsOneWidget);
    expect(repository.weatherCalls, 1);
  });

  testWidgets('cancel preview preserves search results and home cache', (
    tester,
  ) async {
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);

    expect(find.byKey(const Key('add_location_button')), findsOneWidget);
    await cancelPreview(tester);

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const ValueKey('location_item_0')), findsOneWidget);
    expect(repository.weatherCalls, 1);
    expect(cache.savedReports, isEmpty);
  });

  testWidgets('system back from preview preserves search and home', (
    tester,
  ) async {
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);

    await tester.binding.handlePopRoute();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.byKey(const ValueKey('location_item_0')), findsOneWidget);
    expect(cache.savedReports, isEmpty);
  });

  testWidgets('cancelling in-flight preview cannot later change home cache', (
    tester,
  ) async {
    final response = Completer<ApiResult<WeatherReport>>();
    repository.weatherHandler = (_) => response.future;
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);

    await cancelPreview(tester);
    response.complete(Success(report, 200));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(find.byType(TextField), findsOneWidget);
    expect(cache.savedReports, isEmpty);
    expect(repository.weatherCalls, 1);
  });

  testWidgets('main page refreshes weather with pull to refresh', (
    tester,
  ) async {
    final refreshed = Completer<ApiResult<WeatherReport>>();
    repository.weatherHandler = (_) {
      if (repository.weatherCalls == 1) {
        return Future.value(Success(report, 200));
      }
      return refreshed.future;
    };
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);
    await addPreview(tester);

    expect(repository.weatherCalls, 1);
    expect(find.byType(EasyRefresh), findsOneWidget);
    await tester.runAsync(() async {
      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 400),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      await Future<void>.delayed(Duration.zero);
    });

    expect(repository.weatherCalls, 2);
    expect(find.byKey(const ValueKey('daily_item_0')), findsOneWidget);
    expect(find.text('Loading weather…'), findsNothing);

    refreshed.complete(Success(report, 200));
    await tester.pump();
    await tester.pump();
  });

  testWidgets('cold start shows cached weather before background refresh', (
    tester,
  ) async {
    cache.stored = asCurrent(report);
    resolver.handler = (_) async => cache.stored!.location;
    final refreshed = Completer<ApiResult<WeatherReport>>();
    repository.weatherHandler = (_) => refreshed.future;

    await pumpApp(tester);

    expect(find.text('Loading weather…'), findsNothing);
    expect(find.text('Locating…'), findsNothing);
    expect(find.byKey(const ValueKey('hourly_item_0')), findsOneWidget);
    expect(find.byKey(const ValueKey('daily_item_6')), findsOneWidget);

    final updated = report.copyWith(
      current: report.current.copyWith(temperature: 20),
    );
    refreshed.complete(Success(updated, 200));
    await tester.pump();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();

    expect(find.text('20°C'), findsOneWidget);
    expect(cache.stored, same(updated));
  });

  testWidgets('air quality appears above feels like with aqi and category', (
    tester,
  ) async {
    final airReport = report.copyWith(
      current: report.current.copyWith(
        airQuality: const AirQuality(displayValue: '62', category: 'Good'),
      ),
    );
    cache.stored = asCurrent(airReport);
    repository.weatherHandler = (_) async => Success(airReport, 200);

    await pumpApp(tester);

    expect(find.text('Air quality'), findsOneWidget);
    expect(find.text('62 Good'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Air quality')).dy,
      lessThan(tester.getTopLeft(find.text('Feels like')).dy),
    );
  });

  testWidgets('missing air quality shows placeholder', (tester) async {
    cache.stored = asCurrent(report);
    repository.weatherHandler = (_) async => Success(report, 200);

    await pumpApp(tester);

    final row = find
        .ancestor(of: find.text('Air quality'), matching: find.byType(Row))
        .first;
    expect(find.descendant(of: row, matching: find.text('--')), findsOneWidget);
  });

  testWidgets('missing weather config has a specific error message', (
    tester,
  ) async {
    resolver.handler = (_) async => testLocation;
    repository.weatherHandler = (_) async =>
        Failure(const AppConfigException(), null);

    await pumpApp(tester);

    expect(
      find.text(
        'Weather API is not configured. Use the QWeather launch configuration.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('horizontal hourly swipe does not trigger pull refresh', (
    tester,
  ) async {
    cache.stored = asCurrent(report);
    repository.weatherHandler = (_) async => Success(report, 200);
    await pumpApp(tester);
    // 定位重新获取失败时保留缓存且不发起天气请求。
    expect(repository.weatherCalls, 0);
    expect(
      tester.widget<EasyRefresh>(find.byType(EasyRefresh)).triggerAxis,
      Axis.vertical,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('hourly_item_0'))),
    );
    await gesture.moveBy(const Offset(200, 0));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(repository.weatherCalls, 0);
    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('settings button opens the independent settings page', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('settings_page')), findsOneWidget);
  });

  testWidgets(
    'home places bottom actions around page indicator without app bar',
    (tester) async {
      await pumpApp(tester);

      final settings = find.byKey(const Key('settings_button'));
      final indicator = find.byKey(const Key('weather_page_indicator_0'));
      final search = find.byKey(const Key('search_button'));
      expect(find.byType(AppBar), findsNothing);
      expect(find.byKey(const Key('weather_bottom_bar')), findsOneWidget);
      expect(settings, findsOneWidget);
      expect(search, findsOneWidget);
      expect(
        tester.getCenter(settings).dx,
        lessThan(tester.getCenter(indicator).dx),
      );
      expect(
        tester.getCenter(indicator).dx,
        lessThan(tester.getCenter(search).dx),
      );
      expect(find.textContaining('Weather data by QWeather'), findsNothing);
    },
  );

  testWidgets('city name stays pinned while weather scrolls upward', (
    tester,
  ) async {
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);
    await addPreview(tester);

    final header = find.byKey(const Key('weather_city_sticky_header'));
    final scrollView = find.byKey(const Key('weather_city_scroll_view'));
    expect(header, findsOneWidget);
    expect(find.text('Berlin'), findsOneWidget);
    final initialTop = tester.getTopLeft(header).dy;

    await tester.fling(scrollView, const Offset(0, -500), 1200);
    await tester.pumpAndSettle();

    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scrollView, matching: find.byType(Scrollable)).first,
    );
    expect(scrollable.position.pixels, greaterThan(0));
    expect(tester.getTopLeft(header).dy, closeTo(initialTop, 0.01));
    expect(find.text('Berlin'), findsOneWidget);
  });

  testWidgets('pull to refresh moves city name with weather content', (
    tester,
  ) async {
    await pumpApp(tester);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);
    await addPreview(tester);

    final header = find.byKey(const Key('weather_city_sticky_header'));
    final scrollView = find.byKey(const Key('weather_city_scroll_view'));
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: scrollView, matching: find.byType(Scrollable)).first,
    );
    // 明确从天气列表顶部开始下拉，而不是操作外层横向城市分页。
    scrollable.position.jumpTo(0);
    await tester.pump();
    final initialTop = tester.getTopLeft(header).dy;
    final gesture = await tester.startGesture(tester.getCenter(scrollView));
    await gesture.moveBy(const Offset(0, 20));
    await tester.pump();
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();

    final refreshOffset = EasyRefresh.of(
      tester.element(scrollView),
    ).headerNotifier.offset;
    expect(refreshOffset, greaterThan(0));
    // 标题必须与刷新组件使用同一下拉位移，不能再停在箭头后方。
    expect(
      tester.getTopLeft(header).dy,
      closeTo(initialTop + refreshOffset, 0.01),
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(header).dy, closeTo(initialTop, 0.01));
  });

  testWidgets('cached current page stays first and cities swipe in order', (
    tester,
  ) async {
    final currentLocation = testLocation.copyWith(
      id: 'gps-current',
      name: 'Current',
      origin: LocationOrigin.gps,
    );
    cache.reports = [buildTestWeatherReport(currentLocation), report];
    resolver.handler = (_) async => null;
    await pumpApp(tester);

    expect(find.text('Current'), findsOneWidget);
    expect(repository.weatherCalls, 0);
    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Berlin'), findsOneWidget);
    expect(repository.weatherCalls, 1);

    await tester.fling(find.byType(PageView), const Offset(400, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('page indicator follows swipes and taps switch pages', (
    tester,
  ) async {
    final currentLocation = testLocation.copyWith(
      id: 'gps-current',
      name: 'Current',
      origin: LocationOrigin.gps,
    );
    cache.reports = [buildTestWeatherReport(currentLocation), report];
    resolver.handler = (_) async => null;
    await pumpApp(tester);

    final locationMarker = find.byKey(
      const Key('weather_page_location_marker'),
    );
    final cityDot = find.byKey(const Key('weather_page_dot_1'));
    expect(locationMarker, findsOneWidget);
    expect(cityDot, findsOneWidget);
    expect(tester.getSize(cityDot).width, 7);
    final indicatorTap = tester.widget<InkResponse>(
      find.byKey(const Key('weather_page_indicator_0')),
    );
    expect(indicatorTap.splashFactory, NoSplash.splashFactory);
    expect(indicatorTap.highlightColor, Colors.transparent);
    final rotation = tester.widget<Transform>(
      find.byKey(const Key('weather_page_location_rotation')),
    );
    expect(rotation.transform.storage[0], closeTo(math.cos(math.pi / 4), 1e-6));
    expect(rotation.transform.storage[1], closeTo(math.sin(math.pi / 4), 1e-6));

    await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Berlin'), findsOneWidget);
    expect(tester.getSize(cityDot).width, 9);
    expect(repository.weatherCalls, 1);

    await tester.tap(find.byKey(const Key('weather_page_indicator_0')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Current'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getSize(cityDot).width, 7);
    expect(
      tester.widget<Icon>(locationMarker).color,
      Theme.of(tester.element(locationMarker)).colorScheme.onSurface,
    );
  });

  testWidgets('page indicator jumps directly across multiple pages', (
    tester,
  ) async {
    final currentLocation = testLocation.copyWith(
      id: 'gps-current',
      name: 'Current',
      origin: LocationOrigin.gps,
    );
    cache.reports = [
      buildTestWeatherReport(currentLocation),
      for (var index = 1; index <= 4; index++)
        buildTestWeatherReport(
          testLocation.copyWith(id: 'city-$index', name: 'City $index'),
        ),
    ];
    repository.weatherHandler = (location) async =>
        Success(buildTestWeatherReport(location), 200);
    resolver.handler = (_) async => null;
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('weather_page_indicator_3')));
    await tester.pump();
    // 按真实帧推进，确保动画经过中间页，而不是一帧直接跳到动画结束。
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();

    expect(find.text('City 3'), findsOneWidget);
    expect(find.text('City 2'), findsNothing);
    expect(
      tester.widget<PageView>(find.byType(PageView)).controller!.page,
      closeTo(3, 0.01),
    );
  });

  testWidgets('added cities swipe back in first-add order', (tester) async {
    final paris = testLocation.copyWith(id: 'paris', name: 'Paris');
    repository.searchHandler = (query, _) async {
      return Success([query == 'Paris' ? paris : testLocation], 200);
    };
    repository.weatherHandler = (location) async =>
        Success(buildTestWeatherReport(location), 200);
    await pumpApp(tester);

    await submitCity(tester, 'Berlin');
    await selectLocation(tester);
    await addPreview(tester);
    await submitCity(tester, 'Paris');
    await selectLocation(tester);
    await addPreview(tester);
    expect(find.text('Paris'), findsOneWidget);

    // 缓存用例已覆盖真实手势；这里用确定性跳页精确验证添加顺序。
    final pageController = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    pageController.jumpToPage(1);
    await tester.pump();
    expect(find.text('Berlin'), findsOneWidget);

    pageController.jumpToPage(0);
    await tester.pump();
    expect(
      find.byKey(const Key('current_location_placeholder')),
      findsOneWidget,
    );
    await tester.idle();
    (tester.binding as AutomatedTestWidgetsFlutterBinding).elapseBlocking(
      Duration.zero,
    );
    await tester.pump();
  });

  testWidgets('cached current weather remains visible when gps is denied', (
    tester,
  ) async {
    final currentLocation = testLocation.copyWith(
      id: 'gps-current',
      name: 'Current',
      origin: LocationOrigin.gps,
    );
    cache.stored = buildTestWeatherReport(currentLocation);
    resolver.handler = (_) async => null;

    await pumpApp(tester);

    expect(find.text('Current'), findsOneWidget);
    expect(find.byKey(const Key('current_location_warning')), findsOneWidget);
  });

  testWidgets('settings manages city order deletion and home indicators', (
    tester,
  ) async {
    final currentLocation = testLocation.copyWith(
      id: 'gps-current',
      name: 'Current',
      origin: LocationOrigin.gps,
    );
    final parisLocation = testLocation.copyWith(id: 'paris', name: 'Paris');
    final parisReport = buildTestWeatherReport(parisLocation);
    cache.reports = [
      buildTestWeatherReport(currentLocation),
      report,
      parisReport,
    ];
    resolver.handler = (_) async => null;
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.byKey(const Key('city_management_entry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const Key('city_management_page')), findsOneWidget);
    expect(find.byKey(const Key('managed_city_current')), findsNothing);
    await tester.timedDrag(
      find.byKey(const Key('reorder_city_2950159')),
      const Offset(0, 140),
      const Duration(milliseconds: 500),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(
      tester.getTopLeft(find.byKey(const Key('managed_city_paris'))).dy,
      lessThan(
        tester.getTopLeft(find.byKey(const Key('managed_city_2950159'))).dy,
      ),
    );
    expect(cache.cityOrders.single.map((item) => item.location.id), [
      'paris',
      testLocation.id,
    ]);

    await tester.tap(find.byKey(const Key('delete_city_paris')));
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(find.byKey(const Key('managed_city_paris')), findsNothing);
    expect(cache.deletedReports, [parisReport]);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Current'), findsOneWidget);
    expect(find.byKey(const Key('weather_page_dot_1')), findsOneWidget);
    expect(find.byKey(const Key('weather_page_dot_2')), findsNothing);
  });

  testWidgets('switching to English renames an existing Chinese city', (
    tester,
  ) async {
    final wuhan = testLocation.copyWith(id: 'wuhan', name: '武汉');
    repository.searchHandler = (_, _) async => Success([wuhan], 200);
    repository.weatherHandler = (location) async {
      final name = repository.localizationRequests.last
          ? 'Wuhan'
          : location.name;
      return Success(
        report.copyWith(location: location.copyWith(name: name)),
        200,
      );
    };
    await pumpApp(tester, locale: const Locale('zh'));
    await submitCity(tester, '武汉');
    await selectLocation(tester);
    await addPreview(tester);
    expect(find.text('武汉'), findsOneWidget);

    await tester.tap(find.byKey(const Key('settings_button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('language_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English').last);
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(repository.localizationRequests, contains(true));
    expect(find.text('Wuhan'), findsOneWidget);
    expect(find.text('武汉'), findsNothing);
    // 主页先展示新报告，再异步写入 SQLite；等待写入完成后验证持久化地名。
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    expect(cache.savedReports.last.location.name, 'Wuhan');
  });

  testWidgets('Chinese copy and narrow large text layout work', (tester) async {
    await pumpApp(tester, locale: const Locale('zh'), largeText: true);
    await submitCity(tester, 'Berlin');
    await selectLocation(tester);
    await addPreview(tester);

    expect(find.byKey(const Key('weather_home_page')), findsOneWidget);
    expect(find.text('现在'), findsOneWidget);
    expect(find.text('24小时预报'), findsOneWidget);
    expect(find.text('7天预报'), findsOneWidget);
    final exception = tester.takeException();
    if (exception != null) {
      throw exception;
    }
  });
}
