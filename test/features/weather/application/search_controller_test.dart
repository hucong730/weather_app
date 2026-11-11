import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/application/search_controller.dart';
import 'package:weather_app/features/weather/application/search_state.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

import '../../../helpers/weather_test_data.dart';

class FakeWeatherRepository implements WeatherRepository {
  Future<ApiResult<List<Location>>> Function(String, String)? searchHandler;
  final List<String> queries = [];
  final List<CancelToken?> cancelTokens = [];

  @override
  Future<ApiResult<List<Location>>> searchLocations(
    String query,
    String languageCode, {
    CancelToken? cancelToken,
  }) {
    queries.add(query);
    cancelTokens.add(cancelToken);
    return searchHandler!(query, languageCode);
  }

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) {
    throw UnimplementedError();
  }
}

void main() {
  late FakeWeatherRepository repository;
  late ProviderContainer container;
  late SearchController controller;

  setUp(() {
    repository = FakeWeatherRepository();
    container = ProviderContainer(
      overrides: [weatherRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(searchControllerProvider, (_, _) {});
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    controller = container.read(searchControllerProvider.notifier);
  });

  test(
    'blank and numeric queries are rejected but one character searches',
    () async {
      repository.searchHandler = (_, _) async => const Success([], 200);
      expect(
        container.read(searchControllerProvider).loadState.status,
        LoadStatus.idle,
      );

      await controller.search(' ', 'en');
      await controller.search('10001', 'en');
      await controller.search('SW1A 1AA', 'en');
      await controller.search('39.90,116.40', 'en');

      expect(
        container.read(searchControllerProvider).validation,
        SearchValidation.invalidQuery,
      );
      expect(
        container.read(searchControllerProvider).loadState.status,
        LoadStatus.idle,
      );
      expect(repository.queries, isEmpty);

      await controller.search('B', 'en');
      expect(repository.queries, ['B']);
      expect(
        container.read(searchControllerProvider).validation,
        SearchValidation.none,
      );
      expect(
        container.read(searchControllerProvider).loadState.status,
        LoadStatus.empty,
      );
    },
  );

  test('success and empty results map to load state', () async {
    repository.searchHandler = (query, languageCode) async {
      if (query == 'Berlin') return const Success([testLocation], 200);
      return const Success([], 200);
    };

    await controller.search('Berlin', 'en');
    expect(
      container.read(searchControllerProvider).loadState.status,
      LoadStatus.success,
    );
    expect(container.read(searchControllerProvider).loadState.data, [
      testLocation,
    ]);

    await controller.search('Unknown', 'en');
    expect(
      container.read(searchControllerProvider).loadState.status,
      LoadStatus.empty,
    );
  });

  test('failure maps to error and clear resets state', () async {
    repository.searchHandler = (query, languageCode) async {
      return const Failure(AppNetworkException(), null);
    };

    await controller.search('Berlin', 'en');
    expect(
      container.read(searchControllerProvider).loadState.status,
      LoadStatus.error,
    );

    controller.clearResults();
    final state = container.read(searchControllerProvider);
    expect(state.loadState.status, LoadStatus.idle);
    expect(state.loadState.data, isNull);
    expect(state.loadState.error, isNull);
  });

  test('same query while loading is ignored', () async {
    final completer = Completer<ApiResult<List<Location>>>();
    repository.searchHandler = (query, languageCode) => completer.future;

    final first = controller.search('Berlin', 'en');
    final second = controller.search('Berlin', 'en');
    completer.complete(const Success([testLocation], 200));
    await Future.wait([first, second]);

    expect(repository.queries, ['Berlin']);
  });

  test('new query cancels old request and wins the latest state', () async {
    final berlin = Completer<ApiResult<List<Location>>>();
    final paris = Completer<ApiResult<List<Location>>>();
    repository.searchHandler = (query, languageCode) {
      return query == 'Berlin' ? berlin.future : paris.future;
    };

    final first = controller.search('Berlin', 'en');
    final second = controller.search('Paris', 'en');
    expect(repository.cancelTokens[0]?.isCancelled, isTrue);
    expect(repository.cancelTokens[1]?.isCancelled, isFalse);
    berlin.complete(const Success([testLocation], 200));
    await first;
    paris.complete(
      Success([testLocation.copyWith(id: '1', name: 'Paris')], 200),
    );
    await second;

    final state = container.read(searchControllerProvider);
    expect(state.query, 'Paris');
    expect(state.loadState.data?.single.name, 'Paris');
  });

  test('dispose cancels the request and invalidates its response', () async {
    final completer = Completer<ApiResult<List<Location>>>();
    repository.searchHandler = (query, languageCode) => completer.future;

    final pending = controller.search('Berlin', 'en');
    final cancelToken = repository.cancelTokens.single;
    container.dispose();
    expect(cancelToken?.isCancelled, isTrue);
    completer.complete(const Success([testLocation], 200));

    await expectLater(pending, completes);
  });
}
