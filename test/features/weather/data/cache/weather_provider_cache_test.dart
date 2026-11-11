import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/weather_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:weather_app/features/weather/data/cache/sqflite_weather_cache.dart';
import 'package:weather_app/features/weather/data/cache/weather_report_codec.dart';

import '../../../../helpers/weather_test_data.dart';

void main() {
  test('legacy payload initializes client identity and QWeather source', () {
    final json = buildTestWeatherReport(testLocation).toJson();
    (json['location'] as Map<String, dynamic>).remove('client_id');
    json.remove('provider');

    final restored = WeatherReportCodec.tryDecode(jsonEncode(json));

    expect(restored, isNotNull);
    expect(restored!.location.clientId, testLocation.id);
    expect(restored.provider, WeatherProviderType.qweather);
  });

  test('Open-Meteo source and stable identity survive codec round trip', () {
    final report = buildTestWeatherReport(
      testLocation.copyWith(clientId: 'stable-city', id: 'open-id'),
    ).copyWith(provider: WeatherProviderType.openMeteo);

    final restored = WeatherReportCodec.tryDecode(
      WeatherReportCodec.encode(report),
    );

    expect(restored, isNotNull);
    expect(restored!.provider, WeatherProviderType.openMeteo);
    expect(restored.location.clientId, 'stable-city');
    expect(restored.location.id, 'open-id');
  });

  test('SQLite replaces the same client page across providers', () async {
    sqfliteFfiInit();
    final cache = SqfliteWeatherCache(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(() async {
      await cache.close();
      await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
    });
    final qweather = buildTestWeatherReport(
      testLocation.copyWith(clientId: 'stable-city'),
    );
    final openMeteo = buildTestWeatherReport(
      testLocation.copyWith(clientId: 'stable-city', id: 'open-id'),
    ).copyWith(provider: WeatherProviderType.openMeteo);

    await cache.save(qweather, position: 1);
    await cache.save(openMeteo, position: 1);

    final restored = (await cache.loadAll()).single;
    expect(restored.location.clientId, 'stable-city');
    expect(restored.location.id, 'open-id');
    expect(restored.provider, WeatherProviderType.openMeteo);
  });
}
