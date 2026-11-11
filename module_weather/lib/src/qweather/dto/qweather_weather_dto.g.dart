// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qweather_weather_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QWeatherValueDto _$QWeatherValueDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QWeatherValueDto', json, ($checkedConvert) {
      final val = QWeatherValueDto(
        value: $checkedConvert('value', (v) => (v as num).toDouble()),
        unit: $checkedConvert('unit', (v) => v as String),
      );
      return val;
    });

Map<String, dynamic> _$QWeatherValueDtoToJson(QWeatherValueDto instance) =>
    <String, dynamic>{'value': instance.value, 'unit': instance.unit};

QWeatherConditionDto _$QWeatherConditionDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherConditionDto', json, ($checkedConvert) {
  final val = QWeatherConditionDto(
    text: $checkedConvert('text', (v) => v as String),
    code: $checkedConvert('code', (v) => v as String),
  );
  return val;
});

Map<String, dynamic> _$QWeatherConditionDtoToJson(
  QWeatherConditionDto instance,
) => <String, dynamic>{'text': instance.text, 'code': instance.code};

QWeatherWindDto _$QWeatherWindDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QWeatherWindDto', json, ($checkedConvert) {
      final val = QWeatherWindDto(
        speed: $checkedConvert(
          'speed',
          (v) => QWeatherValueDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$QWeatherWindDtoToJson(QWeatherWindDto instance) =>
    <String, dynamic>{'speed': instance.speed.toJson()};

QWeatherPrecipitationDto _$QWeatherPrecipitationDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherPrecipitationDto', json, ($checkedConvert) {
  final val = QWeatherPrecipitationDto(
    amount: $checkedConvert(
      'amount',
      (v) => QWeatherValueDto.fromJson(v as Map<String, dynamic>),
    ),
    probability: $checkedConvert('probability', (v) => (v as num?)?.toDouble()),
  );
  return val;
});

Map<String, dynamic> _$QWeatherPrecipitationDtoToJson(
  QWeatherPrecipitationDto instance,
) => <String, dynamic>{
  'amount': instance.amount.toJson(),
  'probability': instance.probability,
};

QWeatherCurrentWeatherDto _$QWeatherCurrentWeatherDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherCurrentWeatherDto', json, ($checkedConvert) {
  final val = QWeatherCurrentWeatherDto(
    condition: $checkedConvert(
      'condition',
      (v) => QWeatherConditionDto.fromJson(v as Map<String, dynamic>),
    ),
    temperature: $checkedConvert(
      'temperature',
      (v) => QWeatherValueDto.fromJson(v as Map<String, dynamic>),
    ),
    feelsLike: $checkedConvert(
      'feelsLike',
      (v) => QWeatherValueDto.fromJson(v as Map<String, dynamic>),
    ),
    humidity: $checkedConvert('humidity', (v) => (v as num).toDouble()),
    wind: $checkedConvert(
      'wind',
      (v) => QWeatherWindDto.fromJson(v as Map<String, dynamic>),
    ),
    precipitation: $checkedConvert(
      'precipitation',
      (v) => QWeatherPrecipitationDto.fromJson(v as Map<String, dynamic>),
    ),
  );
  return val;
});

Map<String, dynamic> _$QWeatherCurrentWeatherDtoToJson(
  QWeatherCurrentWeatherDto instance,
) => <String, dynamic>{
  'condition': instance.condition.toJson(),
  'temperature': instance.temperature.toJson(),
  'feelsLike': instance.feelsLike.toJson(),
  'humidity': instance.humidity,
  'wind': instance.wind.toJson(),
  'precipitation': instance.precipitation.toJson(),
};
