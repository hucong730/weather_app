import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:module_weather/src/open_meteo/dto/open_meteo_air_quality_dto.dart';
import 'package:module_weather/src/open_meteo/open_meteo_mapper.dart';

void main() {
  test('WMO codes map to unified conditions and unknown is safe', () {
    final expected = <int, WeatherCondition>{
      0: WeatherCondition.clear,
      1: WeatherCondition.mainlyClear,
      2: WeatherCondition.partlyCloudy,
      3: WeatherCondition.overcast,
      45: WeatherCondition.fog,
      48: WeatherCondition.fog,
      51: WeatherCondition.drizzle,
      56: WeatherCondition.freezingDrizzle,
      61: WeatherCondition.rain,
      66: WeatherCondition.freezingRain,
      71: WeatherCondition.snow,
      77: WeatherCondition.snowGrains,
      80: WeatherCondition.showers,
      85: WeatherCondition.snowShowers,
      95: WeatherCondition.thunderstorm,
      96: WeatherCondition.thunderstormHail,
      999: WeatherCondition.unknown,
    };

    for (final entry in expected.entries) {
      expect(OpenMeteoMapper.conditionFromWmoCode(entry.key), entry.value);
    }
  });

  test('US AQI boundaries map to English categories', () {
    final cases = [
      (0.0, 'Good'),
      (50.0, 'Good'),
      (51.0, 'Moderate'),
      (100.0, 'Moderate'),
      (101.0, 'Unhealthy for Sensitive Groups'),
      (150.0, 'Unhealthy for Sensitive Groups'),
      (151.0, 'Unhealthy'),
      (200.0, 'Unhealthy'),
      (201.0, 'Very Unhealthy'),
      (300.0, 'Very Unhealthy'),
      (301.0, 'Hazardous'),
    ];

    for (final item in cases) {
      final dto = OpenMeteoAirQualityDto(
        current: OpenMeteoAirQualityCurrentDto(usAqi: item.$1),
      );
      expect(OpenMeteoMapper.toAirQuality(dto, 'en').category, item.$2);
    }
  });
}
