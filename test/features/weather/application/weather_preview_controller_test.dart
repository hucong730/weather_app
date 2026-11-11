import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/application/weather_preview_controller.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_repository.dart';

import '../../../helpers/weather_test_data.dart';

class FakePreviewWeatherRepository implements WeatherRepository {
  Future<ApiResult<WeatherReport>> Function(Location location)? handler;
  final List<String> languageCodes = [];
  final List<CancelToken?> cancelTokens = [];

  @override
  Future<ApiResult<WeatherReport>> getWeather(
    Location location, {
    String languageCode = 'en',
    CancelToken? cancelToken,
    bool localizeLocation = false,
  }) {
    languageCodes.add(languageCode);
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
  late FakePreviewWeatherRepository repository;
  late ProviderContainer container;
  late WeatherPreviewController controller;
  late WeatherReport report;
  late ProviderSubscription<LoadState<WeatherReport>> keepAliveSubscription;

  setUp(() {
    repository = FakePreviewWeatherRepository();
    report = buildTestWeatherReport(testLocation);
    container = ProviderContainer(
      overrides: [weatherRepositoryProvider.overrideWithValue(repository)],
    );
    keepAliveSubscription = container.listen(
      weatherPreviewControllerProvider,
      (_, _) {},
    );
    addTearDown(keepAliveSubscription.close);
    addTearDown(container.dispose);
    controller = container.read(weatherPreviewControllerProvider.notifier);
  });

  test(
    'preview load exposes loading then success and forwards language',
    () async {
      final response = Completer<ApiResult<WeatherReport>>();
      repository.handler = (_) => response.future;

      expect(
        container.read(weatherPreviewControllerProvider).status,
        LoadStatus.idle,
      );
      final pending = controller.load(testLocation, languageCode: 'zh');
      expect(
        container.read(weatherPreviewControllerProvider).status,
        LoadStatus.loading,
      );
      response.complete(Success(report, 200));
      await pending;

      final state = container.read(weatherPreviewControllerProvider);
      expect(state.status, LoadStatus.success);
      expect(state.data, report);
      expect(state.statusCode, 200);
      expect(repository.languageCodes, ['zh']);
    },
  );

  test('preview failure exposes safe error and http status', () async {
    repository.handler = (_) async => Failure(AppHttpException(500), 500);

    await controller.load(testLocation);

    final state = container.read(weatherPreviewControllerProvider);
    expect(state.status, LoadStatus.error);
    expect(state.error, isA<AppHttpException>());
    expect(state.statusCode, 500);
    expect(state.data, isNull);
  });

  test('preview retry cancels old request and keeps latest report', () async {
    final first = Completer<ApiResult<WeatherReport>>();
    final second = Completer<ApiResult<WeatherReport>>();
    final latestReport = report.copyWith(
      location: testLocation.copyWith(id: 'latest', name: 'Paris'),
    );
    var calls = 0;
    repository.handler = (_) {
      calls++;
      return calls == 1 ? first.future : second.future;
    };

    final firstPending = controller.load(testLocation);
    final secondPending = controller.load(testLocation);
    expect(repository.cancelTokens[0]?.isCancelled, isTrue);
    expect(repository.cancelTokens[1]?.isCancelled, isFalse);
    second.complete(Success(latestReport, 200));
    await secondPending;
    first.complete(Success(report, 200));
    await firstPending;

    expect(container.read(weatherPreviewControllerProvider).data, latestReport);
  });

  test('disposed preview cancels and ignores an in-flight response', () async {
    final response = Completer<ApiResult<WeatherReport>>();
    repository.handler = (_) => response.future;
    final states = <LoadStatus>[];
    final subscription = container.listen(
      weatherPreviewControllerProvider,
      (_, next) => states.add(next.status),
    );

    final pending = controller.load(testLocation);
    final cancelToken = repository.cancelTokens.single;
    subscription.close();
    keepAliveSubscription.close();
    await Future<void>.delayed(Duration.zero);
    expect(cancelToken?.isCancelled, isTrue);
    response.complete(Success(report, 200));
    await pending;

    expect(states, [LoadStatus.loading]);
    // 重新监听必须创建新的 idle 实例，证明原 Provider 确实已销毁。
    final newSubscription = container.listen(
      weatherPreviewControllerProvider,
      (_, _) {},
    );
    expect(
      container.read(weatherPreviewControllerProvider).status,
      LoadStatus.idle,
    );
    newSubscription.close();
  });
}
