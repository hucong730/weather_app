import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:module_weather/src/qweather/dto/qweather_city_lookup_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_daily_forecast_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_hourly_forecast_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_weather_dto.dart';
import 'package:module_weather/src/qweather/qweather_mapper.dart';

import '../../helpers/qweather_test_data.dart';

void main() {
  test('maps city id coordinates timezone and search origin', () {
    final dto = QWeatherCityLookupResponseDto.fromJson(buildQWeatherCityJson());

    final location = QWeatherMapper.toLocations(dto).single;

    expect(location.id, '101010100');
    expect(location.latitude, 39.92);
    expect(location.longitude, 116.41);
    expect(location.timezone, 'Asia/Shanghai');
    expect(location.origin, LocationOrigin.search);
  });

  test('maps ratios units timestamps and local daily dates', () {
    final report = QWeatherMapper.toWeatherReport(
      current: QWeatherCurrentWeatherDto.fromJson(buildQWeatherCurrentJson()),
      hourly: QWeatherHourlyForecastDto.fromJson(buildQWeatherHourlyJson()),
      daily: QWeatherDailyForecastDto.fromJson(buildQWeatherDailyJson()),
      location: qWeatherTestLocation,
      utcOffsetSeconds: 28800,
    );

    expect(report.current.observedAtUtc, DateTime.utc(2024, 1, 1));
    expect(report.current.humidity, 46);
    expect(report.current.windSpeed, 9);
    expect(report.hourly, hasLength(24));
    expect(report.hourly.first.precipitationProbability, 25);
    expect(report.hourly.first.isDay, isTrue);
    expect(report.hourly[1].isDay, isFalse);
    expect(report.daily, hasLength(7));
    expect(report.daily.first.date, DateTime.utc(2024, 1, 1));
    expect(report.daily.first.precipitationProbability, 60);
  });

  test(
    'daily local calendar date survives a daylight saving offset change',
    () {
      final dailyJson = buildQWeatherDailyJson();
      final days = dailyJson['days']! as List<dynamic>;
      days[0]['forecastStartTime'] = '2024-03-31T00:00:00+02:00';

      final report = QWeatherMapper.toWeatherReport(
        current: QWeatherCurrentWeatherDto.fromJson(buildQWeatherCurrentJson()),
        hourly: QWeatherHourlyForecastDto.fromJson(buildQWeatherHourlyJson()),
        daily: QWeatherDailyForecastDto.fromJson(dailyJson),
        location: qWeatherTestLocation,
        utcOffsetSeconds: 3600,
      );

      expect(report.daily.first.date, DateTime.utc(2024, 3, 31));
    },
  );

  test('maps night current condition and unknown code safely', () {
    final current = QWeatherCurrentWeatherDto.fromJson(
      buildQWeatherCurrentJson(code: '150'),
    );
    final report = QWeatherMapper.toWeatherReport(
      current: current,
      hourly: QWeatherHourlyForecastDto.fromJson(buildQWeatherHourlyJson()),
      daily: QWeatherDailyForecastDto.fromJson(buildQWeatherDailyJson()),
      location: qWeatherTestLocation,
      utcOffsetSeconds: 28800,
    );

    expect(report.current.isDay, isFalse);
    expect(QWeatherMapper.conditionFromCode('9999'), WeatherCondition.unknown);
  });

  test('rejects incomplete or nonconsecutive forecast data', () {
    final current = QWeatherCurrentWeatherDto.fromJson(
      buildQWeatherCurrentJson(),
    );
    WeatherReportBuilder withHourly(QWeatherHourlyForecastDto hourly) {
      return () => QWeatherMapper.toWeatherReport(
        current: current,
        hourly: hourly,
        daily: QWeatherDailyForecastDto.fromJson(buildQWeatherDailyJson()),
        location: qWeatherTestLocation,
        utcOffsetSeconds: 28800,
      );
    }

    expect(
      withHourly(
        QWeatherHourlyForecastDto.fromJson(buildQWeatherHourlyJson(count: 23)),
      ),
      throwsA(isA<AppDataException>()),
    );
    expect(
      withHourly(
        QWeatherHourlyForecastDto.fromJson(
          buildQWeatherHourlyJson(consecutive: false),
        ),
      ),
      throwsA(isA<AppDataException>()),
    );
    expect(
      () => QWeatherMapper.toWeatherReport(
        current: current,
        hourly: QWeatherHourlyForecastDto.fromJson(buildQWeatherHourlyJson()),
        daily: QWeatherDailyForecastDto.fromJson(
          buildQWeatherDailyJson(count: 6),
        ),
        location: qWeatherTestLocation,
        utcOffsetSeconds: 28800,
      ),
      throwsA(isA<AppDataException>()),
    );
  });
}

typedef WeatherReportBuilder = Object Function();
