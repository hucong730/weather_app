// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qweather_city_lookup_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QWeatherCityLookupResponseDto _$QWeatherCityLookupResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherCityLookupResponseDto', json, ($checkedConvert) {
  final val = QWeatherCityLookupResponseDto(
    code: $checkedConvert('code', (v) => v as String),
    location: $checkedConvert(
      'location',
      (v) => (v as List<dynamic>?)
          ?.map((e) => QWeatherLocationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$QWeatherCityLookupResponseDtoToJson(
  QWeatherCityLookupResponseDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'location': instance.location?.map((e) => e.toJson()).toList(),
};

QWeatherLocationDto _$QWeatherLocationDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QWeatherLocationDto', json, ($checkedConvert) {
      final val = QWeatherLocationDto(
        name: $checkedConvert('name', (v) => v as String),
        id: $checkedConvert('id', (v) => v as String),
        lat: $checkedConvert('lat', (v) => v as String),
        lon: $checkedConvert('lon', (v) => v as String),
        adm2: $checkedConvert('adm2', (v) => v as String?),
        adm1: $checkedConvert('adm1', (v) => v as String?),
        country: $checkedConvert('country', (v) => v as String?),
        tz: $checkedConvert('tz', (v) => v as String?),
        utcOffset: $checkedConvert('utcOffset', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$QWeatherLocationDtoToJson(
  QWeatherLocationDto instance,
) => <String, dynamic>{
  'name': instance.name,
  'id': instance.id,
  'lat': instance.lat,
  'lon': instance.lon,
  'adm2': instance.adm2,
  'adm1': instance.adm1,
  'country': instance.country,
  'tz': instance.tz,
  'utcOffset': instance.utcOffset,
};
