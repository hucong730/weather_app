import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/src/qweather/dto/qweather_city_lookup_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_daily_forecast_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_hourly_forecast_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_weather_dto.dart';

import '../../fixtures/fixture_reader.dart';

void main() {
  test('qweather city dto parses string coordinates and metadata', () {
    final dto = QWeatherCityLookupResponseDto.fromJson(
      readJsonFixture('qweather_city_lookup.json'),
    );

    final location = dto.location!.single;
    expect(dto.code, '200');
    expect(location.id, '101220101');
    expect(location.lat, '30.92689');
    expect(location.utcOffset, '+08:00');
    expect(dto.toJson()['location'], isA<List<dynamic>>());
  });

  test('qweather current dto parses units and ratios', () {
    final dto = QWeatherCurrentWeatherDto.fromJson(
      readJsonFixture('qweather_current.json'),
    );

    expect(dto.temperature.value, 31.71);
    expect(dto.feelsLike.value, 33.64);
    expect(dto.humidity, 0.69);
    expect(dto.wind.speed.value, 4.74);
    expect(dto.precipitation.amount.value, 0.2);
    expect(dto.condition.code, '102');
  });

  test('qweather hourly dto parses forecast times and probability', () {
    final dto = QWeatherHourlyForecastDto.fromJson(
      readJsonFixture('qweather_hourly.json'),
    );

    expect(dto.hours, hasLength(2));
    expect(dto.hours.first.forecastTime, '2024-05-31T03:00Z');
    expect(dto.hours.first.precipitation.probability, 0.31);
  });

  test('qweather daily dto parses temperature and daytime condition', () {
    final dto = QWeatherDailyForecastDto.fromJson(
      readJsonFixture('qweather_daily.json'),
    );

    expect(dto.days, hasLength(2));
    expect(dto.days.first.temperatureMax.value, 29.94);
    expect(dto.days.first.daytime.condition.code, '305');
    expect(dto.days.first.daytime.precipitation.probability, 0.64);
  });
}
