import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/src/qweather/qweather_config.dart';
import 'package:module_weather/weather_exception.dart';

void main() {
  test('direct mode requires an api key', () {
    const config = QWeatherConfig(
      apiHost: 'https://test.qweatherapi.com',
      apiKey: '',
    );

    expect(
      () => config.resolve('/geo/v2/city/lookup'),
      throwsA(isA<AppConfigException>()),
    );
  });
}
