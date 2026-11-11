// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_meteo_geocoding_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenMeteoGeocodingDto _$OpenMeteoGeocodingDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OpenMeteoGeocodingDto', json, ($checkedConvert) {
  final val = OpenMeteoGeocodingDto(
    results: $checkedConvert(
      'results',
      (v) => (v as List<dynamic>?)
          ?.map((e) => OpenMeteoLocationDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    error: $checkedConvert('error', (v) => v as bool?),
    reason: $checkedConvert('reason', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$OpenMeteoGeocodingDtoToJson(
  OpenMeteoGeocodingDto instance,
) => <String, dynamic>{
  'results': instance.results?.map((e) => e.toJson()).toList(),
  'error': instance.error,
  'reason': instance.reason,
};

OpenMeteoLocationDto _$OpenMeteoLocationDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OpenMeteoLocationDto', json, ($checkedConvert) {
  final val = OpenMeteoLocationDto(
    id: $checkedConvert('id', (v) => (v as num).toInt()),
    name: $checkedConvert('name', (v) => v as String),
    latitude: $checkedConvert('latitude', (v) => (v as num).toDouble()),
    longitude: $checkedConvert('longitude', (v) => (v as num).toDouble()),
    admin1: $checkedConvert('admin1', (v) => v as String?),
    country: $checkedConvert('country', (v) => v as String?),
    timezone: $checkedConvert('timezone', (v) => v as String?),
  );
  return val;
});

Map<String, dynamic> _$OpenMeteoLocationDtoToJson(
  OpenMeteoLocationDto instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'admin1': instance.admin1,
  'country': instance.country,
  'timezone': instance.timezone,
};
