import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/application/weather_home_controller.dart';
import 'package:weather_app/features/weather/application/weather_home_state.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_cache.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

import '../../../helpers/weather_test_data.dart';

class FakeHomeCache implements WeatherCache {
  List<WeatherReport> reports = [];
  Future<List<WeatherReport>> Function()? loadHandler;
  final List<WeatherReport> saved = [];
  final List<int> positions = [];
  final List<WeatherReport> deleted = [];
  final List<int> deletedPositions = [];
  final List<List<WeatherReport>> cityOrders = [];

  @override
  Future<List<WeatherReport>> loadAll() {
    return loadHandler?.call() ?? Future.value(reports);
  }

  @override
  Future<void> save(WeatherReport report, {required int position}) async {
    saved.add(report);
    positions.add(position);
  }

  @override
  Future<void> delete(WeatherReport report, {required int position}) async {
    deleted.add(report);
    deletedPositions.add(position);
  }

  @override
  Future<void> saveCityOrder(List<WeatherReport> cities) async {
    cityOrders.add(List.of(cities));
  }
}

class FakeHomeResolver implements LocationResolver {
  Future<Location?> Function()? handler;
  int calls = 0;

  @override
  Future<Location?> resolve({String languageCode = 'en'}) {
    calls++;
    return handler!();
  }
}

class FakeHomeRepository implements WeatherRepository {
  Future<ApiResult<WeatherReport>> Function(Location location)? handler;
  final List<Location> locations = [];
  final List<String> languages = [];
  final List<bool> localizationRequests = [];

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) {
    locations.add(location);
    languages.add(languageCode);
    localizationRequests.add(localizeLocation);
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
  late FakeHomeCache cache;
  late FakeHomeResolver resolver;
  late FakeHomeRepository repository;
  late ProviderContainer container;
  late WeatherHomeController controller;
  late WeatherReport currentReport;
  late WeatherReport berlinReport;

  setUp(() {
    cache = FakeHomeCache();
    resolver = FakeHomeResolver();
    repository = FakeHomeRepository();
    final currentLocation = testLocation.copyWith(
      id: 'gps-current',
      name: 'Current',
      origin: LocationOrigin.gps,
    );
    currentReport = buildTestWeatherReport(currentLocation);
    berlinReport = buildTestWeatherReport(testLocation);
    container = ProviderContainer(
      overrides: [
        weatherCacheProvider.overrideWith((ref) async => cache),
        locationResolverProvider.overrideWithValue(resolver),
        weatherRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(
      weatherHomeControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    controller = container.read(weatherHomeControllerProvider.notifier);
  });

  void keepCityAlive(String key) {
    final subscription = container.listen(
      weatherCityControllerProvider(key),
      (_, _) {},
    );
    addTearDown(subscription.close);
  }

  test(
    'bootstrap restores ordered cache and retains current after denial',
    () async {
      cache.reports = [currentReport, berlinReport];
      final gps = Completer<Location?>();
      resolver.handler = () => gps.future;

      final pending = controller.bootstrap();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      var state = container.read(weatherHomeControllerProvider);
      expect(state.entries.map((entry) => entry.key), [
        'current',
        testLocation.id!,
      ]);
      expect(state.entries[0].report, currentReport);
      expect(state.entries[1].report, berlinReport);
      expect(state.currentLocationStatus, LocationResolutionStatus.locating);

      gps.complete(null);
      await pending;
      state = container.read(weatherHomeControllerProvider);
      expect(
        state.currentLocationStatus,
        LocationResolutionStatus.manualRequired,
      );
      expect(state.entries[0].report, currentReport);
      expect(repository.locations, isEmpty);
    },
  );

  test(
    'settings loading during bootstrap does not discard restored cities',
    () async {
      final cacheLoad = Completer<List<WeatherReport>>();
      cache.loadHandler = () => cacheLoad.future;
      resolver.handler = () async => null;

      final bootstrap = controller.bootstrap(languageCode: 'en');
      await Future<void>.delayed(Duration.zero);
      // 模拟 SharedPreferences 晚于 SQLite 返回：只更新设置，由首次刷新吸收。
      await controller.refreshVisible(
        languageCode: 'zh',
        localizeLocations: true,
      );
      cacheLoad.complete([currentReport, berlinReport]);
      await bootstrap;

      final state = container.read(weatherHomeControllerProvider);
      expect(state.entries.map((entry) => entry.key), [
        'current',
        testLocation.id,
      ]);
      expect(state.entries[0].report, currentReport);
      expect(state.entries[1].report, berlinReport);
      expect(state.entries[1].needsLocalization, isTrue);
      expect(resolver.calls, 1);
    },
  );

  test('bootstrap reacquires gps and refreshes current only once', () async {
    cache.reports = [currentReport];
    keepCityAlive('current');
    final newLocation = currentReport.location.copyWith(
      latitude: 40,
      longitude: 116,
    );
    final newReport = buildTestWeatherReport(newLocation);
    resolver.handler = () async => newLocation;
    repository.handler = (_) async => Success(newReport, 200);

    await controller.bootstrap(languageCode: 'zh');

    expect(resolver.calls, 1);
    expect(repository.locations, [newLocation]);
    expect(repository.languages, ['zh']);
    final state = container.read(weatherHomeControllerProvider);
    expect(state.entries[0].location, newLocation);
    expect(state.entries[0].report, newReport);
    expect(state.currentLocationStatus, LocationResolutionStatus.ready);
  });

  test('add appends cities and duplicate updates original position', () async {
    final paris = testLocation.copyWith(id: 'paris', name: 'Paris');
    final parisReport = buildTestWeatherReport(paris);
    final updatedBerlin = berlinReport.copyWith(
      current: berlinReport.current.copyWith(temperature: 25),
    );

    await controller.addReport(berlinReport);
    await controller.addReport(parisReport);
    await controller.addReport(updatedBerlin);

    final state = container.read(weatherHomeControllerProvider);
    expect(state.entries.map((entry) => entry.key), [
      'current',
      testLocation.id!,
      'paris',
    ]);
    expect(
      state.entries[1].report?.toJson(),
      withClientIdentity(updatedBerlin).toJson(),
    );
    expect(state.selectedPageIndex, 1);
    expect(cache.positions, [1, 2, 1]);
  });

  test(
    'delete removes city preserves current and rejects stale updates',
    () async {
      final paris = testLocation.copyWith(id: 'paris', name: 'Paris');
      final parisReport = buildTestWeatherReport(paris);
      await controller.addReport(berlinReport);
      await controller.addReport(parisReport);

      await controller.deleteCity('paris');
      await controller.deleteCity('current');
      await controller.updateReport(
        'paris',
        parisReport.copyWith(
          current: parisReport.current.copyWith(temperature: 30),
        ),
      );

      final state = container.read(weatherHomeControllerProvider);
      expect(state.entries.map((entry) => entry.key), [
        'current',
        testLocation.id!,
      ]);
      expect(state.selectedPageIndex, 1);
      expect(cache.deleted.map((item) => item.toJson()), [
        withClientIdentity(parisReport).toJson(),
      ]);
      expect(cache.deletedPositions, [2]);
      // 删除后到达的旧网络响应不得重新保存城市。
      expect(cache.saved.map((item) => item.toJson()), [
        withClientIdentity(berlinReport).toJson(),
        withClientIdentity(parisReport).toJson(),
      ]);
    },
  );

  test(
    'reorder keeps fixed current selected city and persists order',
    () async {
      final paris = testLocation.copyWith(id: 'paris', name: 'Paris');
      final parisReport = buildTestWeatherReport(paris);
      await controller.addReport(berlinReport);
      await controller.addReport(parisReport);

      await controller.reorderCities(0, 1);

      final state = container.read(weatherHomeControllerProvider);
      expect(state.entries.map((entry) => entry.key), [
        'current',
        'paris',
        testLocation.id!,
      ]);
      expect(state.selectedPageIndex, 1);
      expect(cache.cityOrders.single.map((report) => report.location.id), [
        'paris',
        testLocation.id,
      ]);
    },
  );

  test('visible language refresh updates current and selected city', () async {
    cache.reports = [currentReport, berlinReport];
    keepCityAlive('current');
    resolver.handler = () async => currentReport.location;
    repository.handler = (location) async {
      if (location.origin == LocationOrigin.gps) {
        return Success(currentReport, 200);
      }
      return Success(berlinReport, 200);
    };
    await controller.bootstrap();
    keepCityAlive(testLocation.id!);
    controller.selectPage(1);
    repository.languages.clear();

    await controller.refreshVisible(languageCode: 'en');

    expect(repository.languages, ['en', 'en']);
    expect(resolver.calls, 1);
    expect(container.read(weatherHomeControllerProvider).selectedPageIndex, 1);
  });

  test(
    'language refresh localizes visible city and defers other cities',
    () async {
      final chineseBerlin = berlinReport.copyWith(
        location: berlinReport.location.copyWith(name: '柏林'),
      );
      final parisLocation = testLocation.copyWith(id: 'paris', name: '巴黎');
      final chineseParis = buildTestWeatherReport(parisLocation);
      cache.reports = [currentReport, chineseBerlin, chineseParis];
      keepCityAlive('current');
      resolver.handler = () async => currentReport.location;
      repository.handler = (location) async {
        if (location.origin == LocationOrigin.gps) {
          return Success(currentReport, 200);
        }
        final name = location.id == 'paris' ? 'Paris' : 'Berlin';
        return Success(
          buildTestWeatherReport(location.copyWith(name: name)),
          200,
        );
      };
      await controller.bootstrap();
      keepCityAlive(testLocation.id!);
      controller.selectPage(1);
      repository.localizationRequests.clear();

      await controller.refreshVisible(
        languageCode: 'en',
        localizeLocations: true,
      );

      expect(repository.localizationRequests, [false, true]);
      final state = container.read(weatherHomeControllerProvider);
      expect(state.entries[1].location?.name, 'Berlin');
      expect(state.entries[1].needsLocalization, isFalse);
      expect(state.entries[2].location?.name, '巴黎');
      expect(state.entries[2].needsLocalization, isTrue);
      expect(cache.saved.last.location.name, 'Berlin');
      expect(cache.positions.last, 1);
    },
  );
}
