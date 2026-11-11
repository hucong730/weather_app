// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_meteo_air_quality_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenMeteoAirQualityDto _$OpenMeteoAirQualityDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OpenMeteoAirQualityDto', json, ($checkedConvert) {
  final val = OpenMeteoAirQualityDto(
    current: $checkedConvert(
      'current',
      (v) => OpenMeteoAirQualityCurrentDto.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$OpenMeteoAirQualityDtoToJson(
  OpenMeteoAirQualityDto instance,
) => <String, dynamic>{'current': instance.current.toJson()};

OpenMeteoAirQualityCurrentDto _$OpenMeteoAirQualityCurrentDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('OpenMeteoAirQualityCurrentDto', json, ($checkedConvert) {
  final val = OpenMeteoAirQualityCurrentDto(
    usAqi: $checkedConvert('us_aqi', (v) => (v as num).toDouble()),
  );
  return val;
}, fieldKeyMap: const {'usAqi': 'us_aqi'});

Map<String, dynamic> _$OpenMeteoAirQualityCurrentDtoToJson(
  OpenMeteoAirQualityCurrentDto instance,
) => <String, dynamic>{'us_aqi': instance.usAqi};
