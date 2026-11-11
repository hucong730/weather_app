// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'qweather_daily_forecast_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QWeatherDailyForecastDto _$QWeatherDailyForecastDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('QWeatherDailyForecastDto', json, ($checkedConvert) {
  final val = QWeatherDailyForecastDto(
    days: $checkedConvert(
      'days',
      (v) => (v as List<dynamic>)
          .map((e) => QWeatherDailyDto.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
  );
  return val;
});

Map<String, dynamic> _$QWeatherDailyForecastDtoToJson(
  QWeatherDailyForecastDto instance,
) => <String, dynamic>{'days': instance.days.map((e) => e.toJson()).toList()};

QWeatherDailyDto _$QWeatherDailyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QWeatherDailyDto', json, ($checkedConvert) {
      final val = QWeatherDailyDto(
        forecastStartTime: $checkedConvert(
          'forecastStartTime',
          (v) => v as String,
        ),
        temperatureMax: $checkedConvert(
          'temperatureMax',
          (v) => QWeatherValueDto.fromJson(v as Map<String, dynamic>),
        ),
        temperatureMin: $checkedConvert(
          'temperatureMin',
          (v) => QWeatherValueDto.fromJson(v as Map<String, dynamic>),
        ),
        daytime: $checkedConvert(
          'daytime',
          (v) => QWeatherDaytimeDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$QWeatherDailyDtoToJson(QWeatherDailyDto instance) =>
    <String, dynamic>{
      'forecastStartTime': instance.forecastStartTime,
      'temperatureMax': instance.temperatureMax.toJson(),
      'temperatureMin': instance.temperatureMin.toJson(),
      'daytime': instance.daytime.toJson(),
    };

QWeatherDaytimeDto _$QWeatherDaytimeDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate('QWeatherDaytimeDto', json, ($checkedConvert) {
      final val = QWeatherDaytimeDto(
        condition: $checkedConvert(
          'condition',
          (v) => QWeatherConditionDto.fromJson(v as Map<String, dynamic>),
        ),
        precipitation: $checkedConvert(
          'precipitation',
          (v) => QWeatherPrecipitationDto.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$QWeatherDaytimeDtoToJson(QWeatherDaytimeDto instance) =>
    <String, dynamic>{
      'condition': instance.condition.toJson(),
      'precipitation': instance.precipitation.toJson(),
    };
