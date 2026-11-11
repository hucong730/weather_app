import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:module_weather/src/open_meteo/open_meteo_weather_adapter.dart';
import 'package:module_weather/weather_provider.dart';

import '../helpers/open_meteo_test_data.dart';
import '../helpers/recording_dio_adapter.dart';

void main() {
  late RecordingDioAdapter dioAdapter;
  late OpenMeteoWeatherAdapter service;

  setUp(() {
    dioAdapter = RecordingDioAdapter();
    service = OpenMeteoWeatherAdapter(ApiClient(createTestDio(dioAdapter)));
  });

  void respondNormally() {
    dioAdapter.handler = (options, bodyBytes) async {
      final json = switch (options.uri.host) {
        'geocoding-api.open-meteo.com' => openMeteoGeocodingJson(),
        'api.open-meteo.com' => openMeteoForecastJson(),
        'air-quality-api.open-meteo.com' => openMeteoAirQualityJson(),
        _ => throw StateError('Unexpected host: ${options.uri.host}'),
      };
      return jsonResponse(jsonEncode(json), 200);
    };
  }

  test('search sends count and language and maps unified locations', () async {
    respondNormally();

    final result = await service.searchLocations('Berlin', 'zh');

    expect(result, isA<Success<List<Location>>>());
    final location = (result as Success<List<Location>>).data.single;
    expect(location.id, '2950159');
    expect(location.name, 'Berlin');
    expect(location.origin, LocationOrigin.search);
    final request = dioAdapter.requests.single.options;
    expect(request.queryParameters['count'], 20);
    expect(request.queryParameters['language'], 'zh');
    expect(request.queryParameters['format'], 'json');
    expect(request.headers, isNot(contains('X-QW-Api-Key')));
  });

  test('missing geocoding results maps to an empty list', () async {
    dioAdapter.handler = (options, bodyBytes) async =>
        jsonResponse('{"generationtime_ms": 0.1}', 200);

    final result = await service.searchLocations('Unknown', 'en');

    expect(result, isA<Success<List<Location>>>());
    expect((result as Success<List<Location>>).data, isEmpty);
  });

  test('HTTP 200 geocoding error is a data failure', () async {
    dioAdapter.handler = (options, bodyBytes) async =>
        jsonResponse(jsonEncode(openMeteoErrorJson()), 200);

    final result = await service.searchLocations('Berlin', 'en');

    expect(result, isA<Failure<List<Location>>>());
    expect((result as Failure<List<Location>>).error, isA<AppDataException>());
    expect(result.statusCode, 200);
  });

  test(
    'language change localizes cached name and preserves city identity',
    () async {
      respondNormally();

      final result = await service.getWeather(
        openMeteoTestLocation.copyWith(name: '柏林'),
        languageCode: 'en',
        localizeLocation: true,
      );

      expect(result, isA<Success<WeatherReport>>());
      final report = (result as Success<WeatherReport>).data;
      expect(report.location.name, 'Berlin');
      expect(report.location.clientId, 'city-berlin');
      expect(report.location.origin, LocationOrigin.search);
      expect(dioAdapter.requests, hasLength(3));
      final geoRequest = dioAdapter.requests.firstWhere(
        (item) => item.options.uri.host == 'geocoding-api.open-meteo.com',
      );
      expect(geoRequest.options.queryParameters['name'], '柏林');
      expect(geoRequest.options.queryParameters['language'], 'en');
    },
  );

  test(
    'GPS forecast preserves identity and fills timezone without geocoding',
    () async {
      respondNormally();
      const gps = Location(
        clientId: 'current',
        latitude: 52.52437,
        longitude: 13.41053,
        origin: LocationOrigin.gps,
      );

      final result = await service.getWeather(gps, languageCode: 'zh');

      expect(result, isA<Success<WeatherReport>>());
      final report = (result as Success<WeatherReport>).data;
      expect(report.provider, WeatherProviderType.openMeteo);
      expect(report.location.clientId, 'current');
      expect(report.location.origin, LocationOrigin.gps);
      expect(report.location.name, isNull);
      expect(report.timezone, 'Europe/Berlin');
      expect(report.utcOffsetSeconds, 3600);
      expect(report.current.observedAtUtc, DateTime.utc(2024, 1, 1, 11));
      expect(report.current.temperature, 12.5);
      expect(report.current.humidity, 80);
      expect(report.current.windSpeed, 8.3);
      expect(report.current.airQuality?.displayValue, '62');
      expect(report.current.airQuality?.category, '中等');
      expect(report.hourly, hasLength(24));
      expect(report.hourly.first.timeUtc, DateTime.utc(2024, 1, 1, 11));
      expect(report.hourly.first.precipitationProbability, isNull);
      expect(report.daily, hasLength(7));
      expect(report.daily.first.date, DateTime.utc(2024, 1, 1));
      expect(dioAdapter.requests, hasLength(2));
      expect(
        dioAdapter.requests.any(
          (item) => item.options.uri.host == 'geocoding-api.open-meteo.com',
        ),
        isFalse,
      );
      final forecastRequest = dioAdapter.requests.firstWhere(
        (item) => item.options.uri.host == 'api.open-meteo.com',
      );
      final params = forecastRequest.options.queryParameters;
      expect(params['timezone'], 'auto');
      expect(params['forecast_hours'], 24);
      expect(params['forecast_days'], 7);
      expect(params['temperature_unit'], 'celsius');
      expect(params['wind_speed_unit'], 'kmh');
      expect(params['precipitation_unit'], 'mm');
      // 时间数组由服务自动返回，显式请求 time 会导致真实 API 返回 400。
      for (final key in ['current', 'hourly', 'daily']) {
        expect(params[key], isA<String>());
        expect((params[key] as String).split(','), isNot(contains('time')));
      }
    },
  );

  test(
    'core HTTP failure preserves status and returns no partial report',
    () async {
      dioAdapter.handler = (options, bodyBytes) async {
        if (options.uri.host == 'api.open-meteo.com') {
          return jsonResponse('{}', 429);
        }
        return jsonResponse(jsonEncode(openMeteoAirQualityJson()), 200);
      };

      final result = await service.getWeather(openMeteoTestLocation);

      expect(result, isA<Failure<WeatherReport>>());
      expect(
        (result as Failure<WeatherReport>).error,
        isA<AppRateLimitException>(),
      );
      expect(result.statusCode, 429);
    },
  );

  test(
    'air quality failure degrades to null without failing weather',
    () async {
      dioAdapter.handler = (options, bodyBytes) async {
        if (options.uri.host == 'air-quality-api.open-meteo.com') {
          return jsonResponse('{}', 500);
        }
        return jsonResponse(jsonEncode(openMeteoForecastJson()), 200);
      };

      final result = await service.getWeather(openMeteoTestLocation);

      expect(result, isA<Success<WeatherReport>>());
      expect(
        (result as Success<WeatherReport>).data.current.airQuality,
        isNull,
      );
    },
  );

  test('HTTP 200 error response becomes AppDataException', () async {
    dioAdapter.handler = (options, bodyBytes) async {
      final json = options.uri.host == 'api.open-meteo.com'
          ? openMeteoErrorJson()
          : openMeteoAirQualityJson();
      return jsonResponse(jsonEncode(json), 200);
    };

    final result = await service.getWeather(openMeteoTestLocation);

    expect(result, isA<Failure<WeatherReport>>());
    expect((result as Failure<WeatherReport>).error, isA<AppDataException>());
    expect(result.statusCode, 200);
  });

  test('wrong field type becomes AppDataException with HTTP status', () async {
    final forecast = mutableJson(openMeteoForecastJson());
    (forecast['current'] as Map<String, dynamic>)['temperature_2m'] = 'warm';
    dioAdapter.handler = (options, bodyBytes) async {
      final json = options.uri.host == 'api.open-meteo.com'
          ? forecast
          : openMeteoAirQualityJson();
      return jsonResponse(jsonEncode(json), 200);
    };

    final result = await service.getWeather(openMeteoTestLocation);

    expect(result, isA<Failure<WeatherReport>>());
    expect((result as Failure<WeatherReport>).error, isA<AppDataException>());
    expect(result.statusCode, 200);
  });

  for (final testCase in [
    (
      name: 'mismatched parallel arrays',
      mutate: (Map<String, dynamic> json) {
        ((json['hourly'] as Map<String, dynamic>)['temperature_2m'] as List)
            .removeLast();
      },
    ),
    (
      name: 'nonconsecutive hours',
      mutate: (Map<String, dynamic> json) {
        final hourly = json['hourly'] as Map<String, dynamic>;
        (hourly['time'] as List)[1] = (hourly['time'] as List).first;
      },
    ),
    (
      name: 'incomplete seven day forecast',
      mutate: (Map<String, dynamic> json) {
        ((json['daily'] as Map<String, dynamic>)['time'] as List).removeLast();
      },
    ),
  ]) {
    test('${testCase.name} returns data failure', () async {
      final forecast = mutableJson(openMeteoForecastJson());
      testCase.mutate(forecast);
      dioAdapter.handler = (options, bodyBytes) async {
        final json = options.uri.host == 'api.open-meteo.com'
            ? forecast
            : openMeteoAirQualityJson();
        return jsonResponse(jsonEncode(json), 200);
      };

      final result = await service.getWeather(openMeteoTestLocation);

      expect(result, isA<Failure<WeatherReport>>());
      expect((result as Failure<WeatherReport>).error, isA<AppDataException>());
    });
  }
}
