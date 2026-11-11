// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qweather_air_quality_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QWeatherAirQualityResponseDto _$QWeatherAirQualityResponseDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherAirQualityResponseDto', json, ($checkedConvert) {
  final val = QWeatherAirQualityResponseDto(
    indexes: $checkedConvert(
      'indexes',
      (v) => (v as List<dynamic>)
          .map(
            (e) =>
                QWeatherAirQualityIndexDto.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$QWeatherAirQualityResponseDtoToJson(
  QWeatherAirQualityResponseDto instance,
) => <String, dynamic>{
  'indexes': instance.indexes.map((e) => e.toJson()).toList(),
};

QWeatherAirQualityIndexDto _$QWeatherAirQualityIndexDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherAirQualityIndexDto', json, ($checkedConvert) {
  final val = QWeatherAirQualityIndexDto(
    code: $checkedConvert('code', (v) => v as String),
    aqiDisplay: $checkedConvert('aqiDisplay', (v) => v as String),
    category: $checkedConvert('category', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$QWeatherAirQualityIndexDtoToJson(
  QWeatherAirQualityIndexDto instance,
) => <String, dynamic>{
  'code': instance.code,
  'aqiDisplay': instance.aqiDisplay,
  'category': instance.category,
};
