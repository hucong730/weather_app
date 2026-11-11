import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_weather/src/qweather/api/qweather_air_quality_api.dart';
import 'package:module_weather/src/qweather/dto/qweather_air_quality_dto.dart';
import 'package:module_weather/src/qweather/qweather_mapper.dart';

import '../../fixtures/fixture_reader.dart';
import '../../helpers/recording_dio_adapter.dart';
import '../../helpers/weather_test_data.dart';
import 'qweather_api_test.dart';

void main() {
  test('air quality sends coordinate path language and api key', () async {
    final adapter = RecordingDioAdapter();
    adapter.handler = (options, bodyBytes) async => jsonResponse(
      jsonEncode(readJsonFixture('qweather_air_quality.json')),
      200,
    );

    final result = await QWeatherAirQualityApi(
      ApiClient(createTestDio(adapter)),
      location: testLocation,
      languageCode: 'zh',
      config: testQWeatherConfig,
    ).send();

    expect(result, isA<Success<QWeatherAirQualityResponseDto>>());
    final request = adapter.requests.single.options;
    expect(request.uri.path, '/airquality/v1/current/52.52/13.41');
    expect(request.uri.queryParameters['lang'], 'zh');
    expect(request.headers['X-QW-Api-Key'], 'test-key');
  });

  test('air quality prefers chinese local aqi and category', () {
    final dto = QWeatherAirQualityResponseDto.fromJson(
      readJsonFixture('qweather_air_quality.json'),
    );

    final airQuality = QWeatherMapper.toAirQuality(dto);

    expect(airQuality?.displayValue, '62');
    expect(airQuality?.category, '良');
  });

  test('air quality falls back to qaqi and handles empty indexes', () {
    final dto = QWeatherAirQualityResponseDto.fromJson(
      readJsonFixture('qweather_air_quality.json'),
    );

    final fallback = QWeatherMapper.toAirQuality(
      dto.copyWith(indexes: [dto.indexes.first]),
    );

    expect(fallback?.displayValue, '0.9');
    expect(fallback?.category, 'Excellent');
    expect(QWeatherMapper.toAirQuality(dto.copyWith(indexes: [])), isNull);
  });
}
