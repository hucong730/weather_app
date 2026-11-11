import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/domain/settings_repository.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/application/weather_home_controller.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_cache.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

import '../../../helpers/weather_test_data.dart';

class SwitchCache implements WeatherCache {
  final List<WeatherReport> saved = [];

  @override
  Future<List<WeatherReport>> loadAll() async => [];

  @override
  Future<void> save(WeatherReport report, {required int position}) async {
    saved.add(report);
  }

  @override
  Future<void> delete(WeatherReport report, {required int position}) async {}

  @override
  Future<void> saveCityOrder(List<WeatherReport> cities) async {}
}

class SwitchResolver implements LocationResolver {
  final Location gps = testLocation.copyWith(
    id: 'gps-current',
    name: 'Current',
    origin: LocationOrigin.gps,
  );

  @override
  Future<Location?> resolve({String languageCode = 'en'}) async => gps;
}

class SwitchSettingsRepository implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
  }
}

class SwitchRepository implements WeatherRepository {
  SwitchRepository(this.provider);

  final WeatherProviderType provider;
  final List<Location> locations = [];
  Future<ApiResult<WeatherReport>> Function(Location location)? handler;

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) {
    locations.add(location);
    final currentHandler = handler;
    if (currentHandler != null) return currentHandler(location);
    return Future.value(
      Success(
        buildTestWeatherReport(location).copyWith(provider: provider),
        200,
      ),
    );
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
  late ProviderContainer container;
  late WeatherHomeController home;
  late SettingsController settings;
  late SwitchCache cache;
  late List<SwitchRepository> repositories;

  setUp(() {
    cache = SwitchCache();
    repositories = [];
    container = ProviderContainer(
      overrides: [
        weatherCacheProvider.overrideWith((ref) async => cache),
        locationResolverProvider.overrideWithValue(SwitchResolver()),
        settingsRepositoryProvider.overrideWithValue(
          SwitchSettingsRepository(),
        ),
        weatherRepositoryProvider.overrideWith((ref) {
          final provider = ref.watch(
            settingsControllerProvider.select(
              (settings) => settings.weatherProvider,
            ),
          );
          final repository = SwitchRepository(provider);
          repositories.add(repository);
          return repository;
        }),
      ],
    );
    final homeSubscription = container.listen(
      weatherHomeControllerProvider,
      (_, _) {},
    );
    final settingsSubscription = container.listen(
      settingsControllerProvider,
      (_, _) {},
    );
    addTearDown(homeSubscription.close);
    addTearDown(settingsSubscription.close);
    addTearDown(container.dispose);
    home = container.read(weatherHomeControllerProvider.notifier);
    settings = container.read(settingsControllerProvider.notifier);
  });

  test(
    'provider switch preserves pages refreshes visible only and drops stale response',
    () async {
      final paris = testLocation.copyWith(id: 'paris', name: 'Paris');
      await home.addReport(buildTestWeatherReport(testLocation));
      await home.addReport(buildTestWeatherReport(paris));
      home.selectPage(1);
      final citySubscription = container.listen(
        weatherCityControllerProvider(testLocation.id!),
        (_, _) {},
      );
      addTearDown(citySubscription.close);
      final qweather = repositories.single;
      final staleResponse = Completer<ApiResult<WeatherReport>>();
      qweather.handler = (_) => staleResponse.future;
      final city = container.read(
        weatherCityControllerProvider(testLocation.id!).notifier,
      );
      final staleLoad = city.load(testLocation);

      await settings.setWeatherProvider(WeatherProviderType.openMeteo);
      final openMeteo = repositories.last;
      await home.refreshVisible(languageCode: 'en');

      final stateBeforeStale = container.read(weatherHomeControllerProvider);
      expect(stateBeforeStale.entries.map((entry) => entry.key), [
        'current',
        testLocation.id,
        'paris',
      ]);
      expect(stateBeforeStale.selectedPageIndex, 1);
      expect(
        stateBeforeStale.entries[1].report?.provider,
        WeatherProviderType.openMeteo,
      );
      expect(
        stateBeforeStale.entries[2].report?.provider,
        WeatherProviderType.qweather,
      );
      expect(
        openMeteo.locations.map((location) => location.id),
        isNot(contains('paris')),
      );
      final savesBeforeStale = cache.saved.length;

      staleResponse.complete(
        Success(buildTestWeatherReport(testLocation), 200),
      );
      await staleLoad;
      await Future<void>.delayed(Duration.zero);

      final state = container.read(weatherHomeControllerProvider);
      expect(state.entries[1].report?.provider, WeatherProviderType.openMeteo);
      expect(cache.saved.length, savesBeforeStale);
    },
  );

  test(
    'cross-service duplicate keeps original client page and order',
    () async {
      await home.addReport(buildTestWeatherReport(testLocation));
      final openReport = buildTestWeatherReport(
        testLocation.copyWith(id: 'open-meteo-berlin'),
      ).copyWith(provider: WeatherProviderType.openMeteo);

      await home.addReport(openReport);

      final state = container.read(weatherHomeControllerProvider);
      expect(state.entries, hasLength(2));
      expect(state.entries[1].key, testLocation.id);
      expect(state.entries[1].location?.clientId, testLocation.id);
      expect(state.entries[1].location?.id, 'open-meteo-berlin');
      expect(state.entries[1].report?.provider, WeatherProviderType.openMeteo);
    },
  );
}
