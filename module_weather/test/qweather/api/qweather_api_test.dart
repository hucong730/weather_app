import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_weather/src/qweather/api/qweather_city_lookup_api.dart';
import 'package:module_weather/src/qweather/api/qweather_current_weather_api.dart';
import 'package:module_weather/src/qweather/api/qweather_daily_forecast_api.dart';
import 'package:module_weather/src/qweather/api/qweather_hourly_forecast_api.dart';
import 'package:module_weather/src/qweather/dto/qweather_city_lookup_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_daily_forecast_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_hourly_forecast_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_weather_dto.dart';
import 'package:module_weather/src/qweather/qweather_config.dart';

import '../../fixtures/fixture_reader.dart';
import '../../helpers/recording_dio_adapter.dart';
import '../../helpers/weather_test_data.dart';

const testQWeatherConfig = QWeatherConfig(
  apiHost: 'https://test.qweatherapi.com',
  apiKey: 'test-key',
);

void main() {
  late RecordingDioAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = RecordingDioAdapter();
    client = ApiClient(createTestDio(adapter));
  });

  test('city lookup sends location language and api key header', () async {
    adapter.handler = (options, bodyBytes) async => jsonResponse(
      jsonEncode(readJsonFixture('qweather_city_lookup.json')),
      200,
    );

    final result = await QWeatherCityLookupApi(
      client,
      query: '孝感',
      languageCode: 'zh',
      countryCode: 'cn',
      config: testQWeatherConfig,
    ).send();

    expect(result, isA<Success<QWeatherCityLookupResponseDto>>());
    final request = adapter.requests.single.options;
    expect(request.uri.host, 'test.qweatherapi.com');
    expect(request.uri.path, '/geo/v2/city/lookup');
    expect(request.uri.queryParameters['location'], '孝感');
    expect(request.uri.queryParameters['number'], '20');
    expect(request.uri.queryParameters['range'], 'cn');
    expect(request.uri.queryParameters['lang'], 'zh');
    expect(request.headers['X-QW-Api-Key'], 'test-key');
  });

  test('current weather uses coordinate path and local language', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse(jsonEncode(readJsonFixture('qweather_current.json')), 200);

    final result = await QWeatherCurrentWeatherApi(
      client,
      location: testLocation,
      languageCode: 'en',
      config: testQWeatherConfig,
    ).send();

    expect(result, isA<Success<QWeatherCurrentWeatherDto>>());
    final request = adapter.requests.single.options;
    expect(request.uri.path, '/weather/v1/current/52.52/13.41');
    expect(request.uri.queryParameters['lang'], 'en');
    expect(request.headers['X-QW-Api-Key'], 'test-key');
  });

  test('hourly forecast requests exactly 24 hours', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse(jsonEncode(readJsonFixture('qweather_hourly.json')), 200);

    final result = await QWeatherHourlyForecastApi(
      client,
      location: testLocation,
      languageCode: 'zh',
      config: testQWeatherConfig,
    ).send();

    expect(result, isA<Success<QWeatherHourlyForecastDto>>());
    final request = adapter.requests.single.options;
    expect(request.uri.path, '/weather/v1/hourly/52.52/13.41');
    expect(request.uri.queryParameters['hours'], '24');
  });

  test('daily forecast requests exactly 7 days', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse(jsonEncode(readJsonFixture('qweather_daily.json')), 200);

    final result = await QWeatherDailyForecastApi(
      client,
      location: testLocation,
      languageCode: 'zh',
      config: testQWeatherConfig,
    ).send();

    expect(result, isA<Success<QWeatherDailyForecastDto>>());
    final request = adapter.requests.single.options;
    expect(request.uri.path, '/weather/v1/daily/52.52/13.41');
    expect(request.uri.queryParameters['days'], '7');
    expect(request.uri.queryParameters['localTime'], 'true');
  });
}
