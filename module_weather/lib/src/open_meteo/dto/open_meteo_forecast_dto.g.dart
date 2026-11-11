// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'open_meteo_forecast_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OpenMeteoForecastDto _$OpenMeteoForecastDtoFromJson(
  Map<String, dynamic> json,
) => $checkedCreate(
  'OpenMeteoForecastDto',
  json,
  ($checkedConvert) {
    final val = OpenMeteoForecastDto(
      timezone: $checkedConvert('timezone', (v) => v as String),
      utcOffsetSeconds: $checkedConvert(
        'utc_offset_seconds',
        (v) => (v as num).toInt(),
      ),
      current: $checkedConvert(
        'current',
        (v) => OpenMeteoCurrentDto.fromJson(v as Map<String, dynamic>),
      ),
      hourly: $checkedConvert(
        'hourly',
        (v) => OpenMeteoHourlyDto.fromJson(v as Map<String, dynamic>),
      ),
      daily: $checkedConvert(
        'daily',
        (v) => OpenMeteoDailyDto.fromJson(v as Map<String, dynamic>),
      ),
      error: $checkedConvert('error', (v) => v as bool?),
      reason: $checkedConvert('reason', (v) => v as String?),
    );
    return val;
  },
  fieldKeyMap: const {'utcOffsetSeconds': 'utc_offset_seconds'},
);

Map<String, dynamic> _$OpenMeteoForecastDtoToJson(
  OpenMeteoForecastDto instance,
) => <String, dynamic>{
  'timezone': instance.timezone,
  'utc_offset_seconds': instance.utcOffsetSeconds,
  'current': instance.current.toJson(),
  'hourly': instance.hourly.toJson(),
  'daily': instance.daily.toJson(),
  'error': instance.error,
  'reason': instance.reason,
};

OpenMeteoCurrentDto _$OpenMeteoCurrentDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OpenMeteoCurrentDto',
      json,
      ($checkedConvert) {
        final val = OpenMeteoCurrentDto(
          time: $checkedConvert('time', (v) => v as String),
          temperature: $checkedConvert(
            'temperature_2m',
            (v) => (v as num).toDouble(),
          ),
          apparentTemperature: $checkedConvert(
            'apparent_temperature',
            (v) => (v as num).toDouble(),
          ),
          humidity: $checkedConvert(
            'relative_humidity_2m',
            (v) => (v as num).toInt(),
          ),
          precipitation: $checkedConvert(
            'precipitation',
            (v) => (v as num).toDouble(),
          ),
          windSpeed: $checkedConvert(
            'wind_speed_10m',
            (v) => (v as num).toDouble(),
          ),
          weatherCode: $checkedConvert(
            'weather_code',
            (v) => (v as num).toInt(),
          ),
          isDay: $checkedConvert('is_day', (v) => (v as num).toInt()),
        );
        return val;
      },
      fieldKeyMap: const {
        'temperature': 'temperature_2m',
        'apparentTemperature': 'apparent_temperature',
        'humidity': 'relative_humidity_2m',
        'windSpeed': 'wind_speed_10m',
        'weatherCode': 'weather_code',
        'isDay': 'is_day',
      },
    );

Map<String, dynamic> _$OpenMeteoCurrentDtoToJson(
  OpenMeteoCurrentDto instance,
) => <String, dynamic>{
  'time': instance.time,
  'temperature_2m': instance.temperature,
  'apparent_temperature': instance.apparentTemperature,
  'relative_humidity_2m': instance.humidity,
  'precipitation': instance.precipitation,
  'wind_speed_10m': instance.windSpeed,
  'weather_code': instance.weatherCode,
  'is_day': instance.isDay,
};

OpenMeteoHourlyDto _$OpenMeteoHourlyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OpenMeteoHourlyDto',
      json,
      ($checkedConvert) {
        final val = OpenMeteoHourlyDto(
          time: $checkedConvert(
            'time',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          temperature: $checkedConvert(
            'temperature_2m',
            (v) =>
                (v as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ),
          precipitationProbability: $checkedConvert(
            'precipitation_probability',
            (v) =>
                (v as List<dynamic>).map((e) => (e as num?)?.toInt()).toList(),
          ),
          weatherCode: $checkedConvert(
            'weather_code',
            (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          ),
          isDay: $checkedConvert(
            'is_day',
            (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'temperature': 'temperature_2m',
        'precipitationProbability': 'precipitation_probability',
        'weatherCode': 'weather_code',
        'isDay': 'is_day',
      },
    );

Map<String, dynamic> _$OpenMeteoHourlyDtoToJson(OpenMeteoHourlyDto instance) =>
    <String, dynamic>{
      'time': instance.time,
      'temperature_2m': instance.temperature,
      'precipitation_probability': instance.precipitationProbability,
      'weather_code': instance.weatherCode,
      'is_day': instance.isDay,
    };

OpenMeteoDailyDto _$OpenMeteoDailyDtoFromJson(Map<String, dynamic> json) =>
    $checkedCreate(
      'OpenMeteoDailyDto',
      json,
      ($checkedConvert) {
        final val = OpenMeteoDailyDto(
          time: $checkedConvert(
            'time',
            (v) => (v as List<dynamic>).map((e) => e as String).toList(),
          ),
          minTemperature: $checkedConvert(
            'temperature_2m_min',
            (v) =>
                (v as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ),
          maxTemperature: $checkedConvert(
            'temperature_2m_max',
            (v) =>
                (v as List<dynamic>).map((e) => (e as num).toDouble()).toList(),
          ),
          precipitationProbability: $checkedConvert(
            'precipitation_probability_max',
            (v) =>
                (v as List<dynamic>).map((e) => (e as num?)?.toInt()).toList(),
          ),
          weatherCode: $checkedConvert(
            'weather_code',
            (v) => (v as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          ),
        );
        return val;
      },
      fieldKeyMap: const {
        'minTemperature': 'temperature_2m_min',
        'maxTemperature': 'temperature_2m_max',
        'precipitationProbability': 'precipitation_probability_max',
        'weatherCode': 'weather_code',
      },
    );

Map<String, dynamic> _$OpenMeteoDailyDtoToJson(OpenMeteoDailyDto instance) =>
    <String, dynamic>{
      'time': instance.time,
      'temperature_2m_min': instance.minTemperature,
      'temperature_2m_max': instance.maxTemperature,
      'precipitation_probability_max': instance.precipitationProbability,
      'weather_code': instance.weatherCode,
    };
