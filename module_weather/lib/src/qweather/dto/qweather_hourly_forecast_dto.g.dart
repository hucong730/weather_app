// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qweather_hourly_forecast_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QWeatherHourlyForecastDto _$QWeatherHourlyForecastDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherHourlyForecastDto', json, ($checkedConvert) {
  final val = QWeatherHourlyForecastDto(
    hours: $checkedConvert(
      'hours',
      (v) => (v as List<dynamic>)
          .map((e) => QWeatherHourlyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$QWeatherHourlyForecastDtoToJson(
  QWeatherHourlyForecastDto instance,
) => <String, dynamic>{'hours': instance.hours.map((e) => e.toJson()).toList()};

QWeatherHourlyDto _$QWeatherHourlyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QWeatherHourlyDto', json, ($checkedConvert) {
      final val = QWeatherHourlyDto(
        forecastTime: $checkedConvert('forecastTime', (v) => v as String),
        condition: $checkedConvert(
          'condition',
          (v) => QWeatherConditionDto.fromJson(v as Map<String, dynamic>),
        ),
        temperature: $checkedConvert(
          'temperature',
          (v) => QWeatherValueDto.fromJson(v as Map<String, dynamic>),
        ),
        precipitation: $checkedConvert(
          'precipitation',
          (v) => QWeatherPrecipitationDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$QWeatherHourlyDtoToJson(QWeatherHourlyDto instance) =>
    <String, dynamic>{
      'forecastTime': instance.forecastTime,
      'condition': instance.condition.toJson(),
      'temperature': instance.temperature.toJson(),
      'precipitation': instance.precipitation.toJson(),
    };
