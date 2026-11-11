import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:module_weather/src/qweather/qweather_config.dart';
import 'package:module_weather/src/qweather/qweather_weather_adapter.dart';

import '../helpers/qweather_test_data.dart';
import '../helpers/recording_dio_adapter.dart';

void main() {
  late RecordingDioAdapter adapter;
  late QWeatherWeatherAdapter repository;

  setUp(() {
    adapter = RecordingDioAdapter();
    repository = QWeatherWeatherAdapter(
      ApiClient(createTestDio(adapter)),
      config: const QWeatherConfig(
        apiHost: 'https://test.qweatherapi.com',
        apiKey: 'test-key',
      ),
    );
  });

  test('search maps all returned locations', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse(jsonEncode(buildQWeatherCityJson()), 200);

    final result = await repository.searchLocations('Beijing', 'en');

    expect(result, isA<Success<List<Location>>>());
    expect((result as Success<List<Location>>).data.single.id, '101010100');
    expect(result.statusCode, 200);
  });

  test(
    'cached ip location is localized before fetching three forecasts',
    () async {
      adapter.handler = (options, bodyBytes) async {
        final path = options.uri.path;
        final json = switch (path) {
          '/geo/v2/city/lookup' => buildQWeatherCityJson(),
          '/weather/v1/current/39.92/116.41' => buildQWeatherCurrentJson(),
          '/weather/v1/hourly/39.92/116.41' => buildQWeatherHourlyJson(),
          '/weather/v1/daily/39.92/116.41' => buildQWeatherDailyJson(),
          '/airquality/v1/current/39.92/116.41' =>
            buildQWeatherAirQualityJson(),
          _ => throw StateError('Unexpected path: $path'),
        };
        return jsonResponse(jsonEncode(json), 200);
      };

      final result = await repository.getWeather(
        const Location(
          name: 'English cache',
          latitude: 39.92,
          longitude: 116.41,
          timezone: 'Asia/Shanghai',
          utcOffsetSeconds: 28800,
          origin: LocationOrigin.ip,
        ),
        languageCode: 'zh',
      );

      expect(result, isA<Success>());
      final report = (result as Success).data;
      expect(report.location.name, 'Beijing');
      expect(report.location.origin, LocationOrigin.ip);
      expect(report.utcOffsetSeconds, 28800);
      expect(report.current.airQuality?.displayValue, '62');
      expect(report.current.airQuality?.category, '良');
      expect(report.hourly, hasLength(24));
      expect(report.daily, hasLength(7));
      expect(adapter.requests, hasLength(5));
      expect(adapter.requests.first.options.queryParameters['number'], 1);
      expect(adapter.requests.first.options.queryParameters['lang'], 'zh');
    },
  );

  test(
    'language change localizes cached city name and preserves identity',
    () async {
      adapter.handler = (options, bodyBytes) async {
        final json = switch (options.uri.path) {
          '/geo/v2/city/lookup' => buildQWeatherCityJson(),
          '/weather/v1/current/39.92/116.41' => buildQWeatherCurrentJson(),
          '/weather/v1/hourly/39.92/116.41' => buildQWeatherHourlyJson(),
          '/weather/v1/daily/39.92/116.41' => buildQWeatherDailyJson(),
          '/airquality/v1/current/39.92/116.41' =>
            buildQWeatherAirQualityJson(),
          _ => throw StateError('Unexpected path: ${options.uri.path}'),
        };
        return jsonResponse(jsonEncode(json), 200);
      };

      final result = await repository.getWeather(
        qWeatherTestLocation.copyWith(name: '北京', clientId: 'stable-beijing'),
        languageCode: 'en',
        localizeLocation: true,
      );

      expect(result, isA<Success<WeatherReport>>());
      final report = (result as Success<WeatherReport>).data;
      expect(report.location.name, 'Beijing');
      expect(report.location.clientId, 'stable-beijing');
      expect(report.location.origin, LocationOrigin.search);
      expect(adapter.requests, hasLength(5));
      final geoRequest = adapter.requests.first.options;
      expect(geoRequest.uri.path, '/geo/v2/city/lookup');
      expect(geoRequest.queryParameters['location'], '北京');
      expect(geoRequest.queryParameters['number'], 20);
      expect(geoRequest.queryParameters['lang'], 'en');
    },
  );

  test('ordinary refresh reuses search location without geo lookup', () async {
    adapter.handler = (options, bodyBytes) async {
      final json = switch (options.uri.path) {
        '/weather/v1/current/39.92/116.41' => buildQWeatherCurrentJson(),
        '/weather/v1/hourly/39.92/116.41' => buildQWeatherHourlyJson(),
        '/weather/v1/daily/39.92/116.41' => buildQWeatherDailyJson(),
        '/airquality/v1/current/39.92/116.41' => buildQWeatherAirQualityJson(),
        _ => throw StateError('Unexpected path: ${options.uri.path}'),
      };
      return jsonResponse(jsonEncode(json), 200);
    };

    final result = await repository.getWeather(qWeatherTestLocation);

    expect(result, isA<Success<WeatherReport>>());
    expect(adapter.requests, hasLength(4));
    expect(
      adapter.requests.any(
        (item) => item.options.uri.path == '/geo/v2/city/lookup',
      ),
      isFalse,
    );
  });

  test(
    'weather failure preserves http status and does not return partial data',
    () async {
      adapter.handler = (options, bodyBytes) async {
        if (options.uri.path.contains('/daily/')) {
          return jsonResponse('{}', 429);
        }
        final json = options.uri.path.contains('/hourly/')
            ? buildQWeatherHourlyJson()
            : buildQWeatherCurrentJson();
        return jsonResponse(jsonEncode(json), 200);
      };

      final result = await repository.getWeather(qWeatherTestLocation);

      expect(result, isA<Failure>());
      expect((result as Failure).error, isA<AppRateLimitException>());
      expect(result.statusCode, 429);
      expect(adapter.requests, hasLength(4));
    },
  );

  test('air quality failure does not fail weather report', () async {
    adapter.handler = (options, bodyBytes) async {
      final path = options.uri.path;
      if (path.contains('/airquality/')) {
        return jsonResponse('{}', 500);
      }
      final json = switch (path) {
        '/weather/v1/current/39.92/116.41' => buildQWeatherCurrentJson(),
        '/weather/v1/hourly/39.92/116.41' => buildQWeatherHourlyJson(),
        '/weather/v1/daily/39.92/116.41' => buildQWeatherDailyJson(),
        _ => throw StateError('Unexpected path: $path'),
      };
      return jsonResponse(jsonEncode(json), 200);
    };

    final result = await repository.getWeather(qWeatherTestLocation);

    expect(result, isA<Success>());
    expect((result as Success).data.current.airQuality, isNull);
  });

  test('geo business 404 maps to an empty result', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse(jsonEncode({'code': '404'}), 200);

    final result = await repository.searchLocations('missing', 'en');

    expect(result, isA<Success<List<Location>>>());
    expect((result as Success<List<Location>>).data, isEmpty);
    expect(result.statusCode, 200);
  });

  test('other geo business errors remain failures with http 200', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse(jsonEncode({'code': '400'}), 200);

    final result = await repository.searchLocations('invalid', 'en');

    expect(result, isA<Failure>());
    expect((result as Failure).error, isA<AppDataException>());
    expect(result.statusCode, 200);
  });

  test('http 400 no such location maps to an empty result', () async {
    adapter.handler = (options, bodyBytes) async => jsonResponse(
      jsonEncode({
        'error': {
          'status': 400,
          'type': 'https://dev.qweather.com/docs/resource/error-code/#no-such-location',
          'title': 'No Such Location',
          'detail': 'Cannot find the location of the query, please try another location.',
        },
      }),
      400,
    );

    final result = await repository.searchLocations('missing', 'en');

    expect(result, isA<Success<List<Location>>>());
    expect((result as Success<List<Location>>).data, isEmpty);
    expect(result.statusCode, 400);
  });

  test('other http 400 responses remain http failures', () async {
    adapter.handler = (options, bodyBytes) async => jsonResponse(
      jsonEncode({
        'error': {'status': 400, 'title': 'Bad Request'},
      }),
      400,
    );

    final result = await repository.searchLocations('invalid', 'en');

    expect(result, isA<Failure<List<Location>>>());
    expect((result as Failure<List<Location>>).error, isA<AppHttpException>());
    expect(result.statusCode, 400);
  });
}
