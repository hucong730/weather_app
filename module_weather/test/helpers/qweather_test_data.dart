import 'package:module_weather/models/location.dart';

const qWeatherTestLocation = Location(
  id: '101010100',
  name: 'Beijing',
  admin1: 'Beijing',
  country: 'China',
  latitude: 39.92,
  longitude: 116.41,
  timezone: 'Asia/Shanghai',
  utcOffsetSeconds: 28800,
  origin: LocationOrigin.search,
);

Map<String, dynamic> buildQWeatherCityJson() => {
  'code': '200',
  'location': [
    {
      'name': 'Beijing',
      'id': '101010100',
      'lat': '39.92',
      'lon': '116.41',
      'adm2': 'Beijing',
      'adm1': 'Beijing',
      'country': 'China',
      'tz': 'Asia/Shanghai',
      'utcOffset': '+08:00',
    },
  ],
};

Map<String, dynamic> buildQWeatherCurrentJson({String code = '100'}) => {
  'condition': {'text': 'Sunny', 'code': code},
  'temperature': {'value': 20.5, 'unit': '°C'},
  'feelsLike': {'value': 19.5, 'unit': '°C'},
  'humidity': 0.456,
  'wind': {
    'speed': {'value': 2.5, 'unit': 'm/s'},
  },
  'precipitation': {
    'amount': {'value': 0.2, 'unit': 'mm'},
  },
};

Map<String, dynamic> buildQWeatherHourlyJson({
  int count = 24,
  bool consecutive = true,
}) => {
  'hours': List.generate(count, (index) {
    final hour = consecutive ? index : index * 2;
    return {
      'forecastTime': DateTime.utc(
        2024,
        1,
        1,
      ).add(Duration(hours: hour)).toIso8601String(),
      'condition': {'text': 'Sunny', 'code': index.isEven ? '100' : '150'},
      'temperature': {'value': 20.0 + index, 'unit': '°C'},
      'precipitation': {
        'amount': {'value': 0, 'unit': 'mm'},
        'probability': 0.25,
      },
    };
  }),
};

Map<String, dynamic> buildQWeatherAirQualityJson() => {
  'indexes': [
    {'code': 'cn-mee', 'aqiDisplay': '62', 'category': '良'},
  ],
};

Map<String, dynamic> buildQWeatherDailyJson({int count = 7}) => {
  'days': List.generate(count, (index) {
    final start = DateTime.utc(2023, 12, 31, 16).add(Duration(days: index));
    return {
      'forecastStartTime': start.toIso8601String(),
      'temperatureMax': {'value': 25.0, 'unit': '°C'},
      'temperatureMin': {'value': 15.0, 'unit': '°C'},
      'daytime': {
        'condition': {'text': 'Sunny', 'code': '100'},
        'precipitation': {
          'amount': {'value': 0, 'unit': 'mm'},
          'probability': 0.6,
        },
      },
    };
  }),
};
