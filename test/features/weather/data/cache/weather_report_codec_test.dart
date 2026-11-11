import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/cache/weather_report_codec.dart';

import '../../../../helpers/weather_test_data.dart';

void main() {
  test('legacy cache without air quality remains readable', () {
    final report = buildTestWeatherReport(testLocation);
    final json = report.toJson();
    (json['current'] as Map<String, dynamic>).remove('air_quality');

    final restored = WeatherReportCodec.tryDecode(jsonEncode(json));

    expect(restored, isNotNull);
    expect(restored!.current.airQuality, isNull);
    expect(restored.hourly, hasLength(24));
    expect(restored.daily, hasLength(7));
  });
}
