import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/application/weather_home_controller.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_cache.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

import '../../../helpers/weather_test_data.dart';

class FakeCityCache implements WeatherCache {
  final List<WeatherReport> saved = [];
  final List<int> positions = [];

  @override
  Future<List<WeatherReport>> loadAll() async => [];

  @override
  Future<void> save(WeatherReport report, {required int position}) async {
    saved.add(report);
    positions.add(position);
  }

  @override
  Future<void> delete(WeatherReport report, {required int position}) async {}

  @override
  Future<void> saveCityOrder(List<WeatherReport> cities) async {}
}

class FakeCityRepository implements WeatherRepository {
  Future<ApiResult<WeatherReport>> Function(Location location)? handler;
  final List<String> languages = [];
  final List<CancelToken?> cancelTokens = [];

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) {
    languages.add(languageCode);
    cancelTokens.add(cancelToken);
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
  late FakeCityCache cache;
  late FakeCityRepository repository;
  late ProviderContainer container;
  late WeatherHomeController home;
  late WeatherReport berlin;
  late WeatherReport paris;
  late Location parisLocation;

  setUp(() {
    cache = FakeCityCache();
    repository = FakeCityRepository();
    berlin = buildTestWeatherReport(testLocation);
    parisLocation = testLocation.copyWith(id: 'paris', name: 'Paris');
    paris = buildTestWeatherReport(parisLocation);
    container = ProviderContainer(
      overrides: [
        weatherCacheProvider.overrideWith((ref) async => cache),
        weatherRepositoryProvider.overrideWithValue(repository),
      ],
    );
    final subscription = container.listen(
      weatherHomeControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    home = container.read(weatherHomeControllerProvider.notifier);
  });

  WeatherCityController cityController(String key) {
    final subscription = container.listen(
      weatherCityControllerProvider(key),
      (_, _) {},
    );
    addTearDown(subscription.close);
    return container.read(weatherCityControllerProvider(key).notifier);
  }

  test('city provider starts with its home cached report', () async {
    await home.addReport(berlin);

    final controller = cityController(testLocation.id!);

    final state = container.read(
      weatherCityControllerProvider(testLocation.id!),
    );
    expect(controller, isNotNull);
    expect(state.status, LoadStatus.success);
    expect(state.data?.toJson(), withClientIdentity(berlin).toJson());
  });

  test(
    'city success updates home and persists at the original position',
    () async {
      await home.addReport(berlin);
      final controller = cityController(testLocation.id!);
      final updated = berlin.copyWith(
        current: berlin.current.copyWith(temperature: 22),
      );
      repository.handler = (_) async => Success(updated, 200);

      await controller.load(testLocation, languageCode: 'zh');

      expect(
        container.read(weatherCityControllerProvider(testLocation.id!)).data,
        updated,
      );
      expect(home.state.entries[1].report, updated);
      expect(cache.saved.last, updated);
      expect(cache.positions.last, 1);
      expect(repository.languages, ['zh']);
    },
  );

  test('city failure retains its previous report', () async {
    await home.addReport(berlin);
    final controller = cityController(testLocation.id!);
    repository.handler = (_) async => Failure(AppHttpException(500), 500);

    await controller.load(testLocation);

    final state = container.read(
      weatherCityControllerProvider(testLocation.id!),
    );
    expect(state.status, LoadStatus.error);
    expect(state.data?.toJson(), withClientIdentity(berlin).toJson());
    expect(state.statusCode, 500);
    expect(
      home.state.entries[1].report?.toJson(),
      withClientIdentity(berlin).toJson(),
    );
  });

  test(
    'two city providers complete independently without crossing reports',
    () async {
      await home.addReport(berlin);
      await home.addReport(paris);
      final berlinController = cityController(testLocation.id!);
      final parisController = cityController('paris');
      final berlinResponse = Completer<ApiResult<WeatherReport>>();
      final parisResponse = Completer<ApiResult<WeatherReport>>();
      repository.handler = (location) {
        return location.id == 'paris'
            ? parisResponse.future
            : berlinResponse.future;
      };

      final berlinPending = berlinController.load(testLocation);
      final parisPending = parisController.load(parisLocation);
      parisResponse.complete(Success(paris, 200));
      await parisPending;
      berlinResponse.complete(Success(berlin, 200));
      await berlinPending;

      expect(
        container.read(weatherCityControllerProvider(testLocation.id!)).data,
        berlin,
      );
      expect(
        container.read(weatherCityControllerProvider('paris')).data,
        paris,
      );
      expect(home.state.entries[1].report, berlin);
      expect(home.state.entries[2].report, paris);
    },
  );

  test('city retry cancels old request and keeps the newer report', () async {
    await home.addReport(berlin);
    final controller = cityController(testLocation.id!);
    final first = Completer<ApiResult<WeatherReport>>();
    final second = Completer<ApiResult<WeatherReport>>();
    final updated = berlin.copyWith(
      current: berlin.current.copyWith(temperature: 30),
    );
    var calls = 0;
    repository.handler = (_) => calls++ == 0 ? first.future : second.future;

    final firstPending = controller.load(testLocation);
    final secondPending = controller.load(testLocation);
    expect(repository.cancelTokens[0]?.isCancelled, isTrue);
    expect(repository.cancelTokens[1]?.isCancelled, isFalse);
    second.complete(Success(updated, 200));
    await secondPending;
    first.complete(Success(berlin, 200));
    await firstPending;

    expect(
      container.read(weatherCityControllerProvider(testLocation.id!)).data,
      updated,
    );
  });

  test('disposed city cancels its in-flight request', () async {
    await home.addReport(berlin);
    final controller = cityController(testLocation.id!);
    final response = Completer<ApiResult<WeatherReport>>();
    repository.handler = (_) => response.future;

    final pending = controller.load(testLocation);
    final cancelToken = repository.cancelTokens.single;
    container.dispose();
    expect(cancelToken?.isCancelled, isTrue);
    response.complete(Success(berlin, 200));

    await expectLater(pending, completes);
  });
}
