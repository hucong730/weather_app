import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:module_weather/src/open_meteo/open_meteo_weather_adapter.dart';
import 'package:module_weather/src/qweather/qweather_config.dart';
import 'package:module_weather/src/qweather/qweather_weather_adapter.dart';
import 'package:module_weather/weather_provider.dart';
import 'package:module_weather/weather_service.dart';
import 'package:module_weather/weather_service_factory.dart';

import '../helpers/open_meteo_test_data.dart';
import '../helpers/qweather_test_data.dart';
import '../helpers/recording_dio_adapter.dart';

void main() {
  runContract(
    name: 'QWeather',
    provider: WeatherProviderType.qweather,
    create: (client) => QWeatherWeatherAdapter(
      client,
      config: const QWeatherConfig(
        apiHost: 'https://test.qweatherapi.com',
        apiKey: 'test-key',
      ),
    ),
    location: qWeatherTestLocation.copyWith(clientId: 'stable-berlin'),
    response: (options) {
      final json = switch (options.uri.path) {
        '/geo/v2/city/lookup' => buildQWeatherCityJson(),
        '/weather/v1/current/39.92/116.41' => buildQWeatherCurrentJson(),
        '/weather/v1/hourly/39.92/116.41' => buildQWeatherHourlyJson(),
        '/weather/v1/daily/39.92/116.41' => buildQWeatherDailyJson(),
        '/airquality/v1/current/39.92/116.41' => buildQWeatherAirQualityJson(),
        _ => throw StateError('Unexpected QWeather path: ${options.uri.path}'),
      };
      return json;
    },
  );

  runContract(
    name: 'Open-Meteo',
    provider: WeatherProviderType.openMeteo,
    create: OpenMeteoWeatherAdapter.new,
    location: openMeteoTestLocation,
    response: (options) => switch (options.uri.host) {
      'geocoding-api.open-meteo.com' => openMeteoGeocodingJson(),
      'api.open-meteo.com' => openMeteoForecastJson(),
      'air-quality-api.open-meteo.com' => openMeteoAirQualityJson(),
      _ => throw StateError('Unexpected Open-Meteo host: ${options.uri.host}'),
    },
  );

  test('factory selects both adapters and defaults to QWeather', () {
    final client = ApiClient(createTestDio(RecordingDioAdapter()));

    expect(WeatherServiceFactory.create(client), isA<QWeatherWeatherAdapter>());
    expect(
      WeatherServiceFactory.create(
        client,
        provider: WeatherProviderType.openMeteo,
      ),
      isA<OpenMeteoWeatherAdapter>(),
    );
  });
}

void runContract({
  required String name,
  required WeatherProviderType provider,
  required WeatherService Function(ApiClient client) create,
  required Location location,
  required Map<String, dynamic> Function(RequestOptions options) response,
}) {
  group('$name unified service contract', () {
    late RecordingDioAdapter dioAdapter;
    late WeatherService service;

    setUp(() {
      dioAdapter = RecordingDioAdapter();
      dioAdapter.handler = (options, bodyBytes) async =>
          jsonResponse(jsonEncode(response(options)), 200);
      service = create(ApiClient(createTestDio(dioAdapter)));
    });

    test('search returns unified locations and requests at most 20', () async {
      final result = await service.searchLocations('Berlin', 'en');

      expect(result, isA<Success<List<Location>>>());
      final locations = (result as Success<List<Location>>).data;
      expect(locations, isNotEmpty);
      expect(locations.first.name, isNotEmpty);
      expect(locations.first.origin, LocationOrigin.search);
      final params = dioAdapter.requests.single.options.queryParameters;
      expect(
        params[provider == WeatherProviderType.qweather ? 'number' : 'count'],
        20,
      );
    });

    test(
      'report has unified identity provider units and forecast sizes',
      () async {
        final result = await service.getWeather(location);

        expect(result, isA<Success<WeatherReport>>());
        final report = (result as Success<WeatherReport>).data;
        expect(report.provider, provider);
        expect(report.location.clientId, location.clientId);
        expect(report.location.origin, location.origin);
        expect(report.location.timezone, isNotNull);
        expect(report.current.temperature, isA<double>());
        expect(report.current.humidity, inInclusiveRange(0, 100));
        expect(report.hourly, hasLength(24));
        expect(report.daily, hasLength(7));
      },
    );

    test('report shares one cancellation token across requests', () async {
      final cancelToken = CancelToken();

      final result = await service.getWeather(
        location,
        cancelToken: cancelToken,
      );

      expect(result, isA<Success<WeatherReport>>());
      expect(dioAdapter.requests, isNotEmpty);
      for (final request in dioAdapter.requests) {
        expect(request.options.cancelToken, same(cancelToken));
      }
    });
  });
}
