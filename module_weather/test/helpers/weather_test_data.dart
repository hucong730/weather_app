import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:module_weather/models/weather_report.dart';

const testLocation = Location(
  id: '2950159',
  name: 'Berlin',
  admin1: 'Berlin',
  country: 'Germany',
  latitude: 52.52437,
  longitude: 13.41053,
  timezone: 'Europe/Berlin',
  utcOffsetSeconds: 3600,
  origin: LocationOrigin.search,
);

WeatherReport buildTestWeatherReport(Location location) {
  final start = DateTime.utc(2024, 1, 1);
  return WeatherReport(
    location: location,
    timezone: location.timezone ?? 'UTC',
    utcOffsetSeconds: location.utcOffsetSeconds ?? 0,
    current: CurrentWeather(
      observedAtUtc: start,
      temperature: 12.5,
      apparentTemperature: 10.2,
      humidity: 80,
      precipitation: 0.4,
      windSpeed: 8.3,
      condition: WeatherCondition.rain,
      isDay: true,
    ),
    hourly: List.generate(
      24,
      (index) => HourlyForecast(
        timeUtc: start.add(Duration(hours: index)),
        temperature: 10.0 + index % 5,
        precipitationProbability: index == 0 ? null : 50,
        condition: index.isEven
            ? WeatherCondition.rain
            : WeatherCondition.showers,
        isDay: index.isEven,
      ),
    ),
    daily: List.generate(
      7,
      (index) => DailyForecast(
        date: start.add(Duration(days: index)),
        minTemperature: 6,
        maxTemperature: 15,
        precipitationProbability: index == 0 ? null : 60,
        condition: WeatherCondition.rain,
      ),
    ),
  );
}
