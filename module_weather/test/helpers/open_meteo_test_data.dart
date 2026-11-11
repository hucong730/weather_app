import 'dart:convert';

import 'package:module_weather/models/location.dart';

import '../fixtures/fixture_reader.dart';

const openMeteoTestLocation = Location(
  clientId: 'city-berlin',
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

Map<String, dynamic> openMeteoGeocodingJson() =>
    readJsonFixture('open_meteo_geocoding.json');

Map<String, dynamic> openMeteoForecastJson() =>
    readJsonFixture('open_meteo_forecast.json');

Map<String, dynamic> openMeteoAirQualityJson() =>
    readJsonFixture('open_meteo_air_quality.json');

Map<String, dynamic> openMeteoErrorJson() =>
    readJsonFixture('open_meteo_error.json');

/// 深拷贝 fixture，确保单个异常用例不会污染其他测试。
Map<String, dynamic> mutableJson(Map<String, dynamic> source) {
  return (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
}
