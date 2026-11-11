import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/l10n/app_localizations_en.dart';
import 'package:weather_app/l10n/app_localizations_zh.dart';

import '../../../helpers/weather_test_data.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('zh');
  });

  test('temperature and decimal formatting follow requested precision', () {
    expect(WeatherFormatters.temperature(12.6, const Locale('en')), '13');
    expect(WeatherFormatters.decimal(8.25, const Locale('en')), '8.3');
    expect(WeatherFormatters.temperature(12.6, const Locale('zh')), '13');
  });

  test('nullable precipitation probability uses placeholder', () {
    expect(WeatherFormatters.probability(null), '--');
    expect(WeatherFormatters.probability(60), '60%');
  });

  test('hour uses location offset instead of device timezone', () {
    final time = DateTime.utc(2024, 1, 1, 0, 30);

    expect(WeatherFormatters.hour(time, 3600, const Locale('en')), '01:30');
    expect(WeatherFormatters.hour(time, -18000, const Locale('en')), '19:30');
  });

  test('daily date uses locale calendar formatting', () {
    final date = DateTime.utc(2024, 1, 1);

    expect(WeatherFormatters.date(date, const Locale('en')), 'Jan 1, 2024');
    expect(WeatherFormatters.date(date, const Locale('zh')), '2024年1月1日');
  });

  test('daily forecast labels today using the selected city calendar day', () {
    final date = DateTime.utc(2024, 1, 1);
    final today = DateTime.utc(2024, 1, 1, 23, 30);

    expect(
      WeatherFormatters.dailyDate(
        date,
        today,
        const Locale('zh'),
        AppLocalizationsZh(),
      ),
      '今天（1月1日）',
    );
    expect(
      WeatherFormatters.dailyDate(
        date,
        today,
        const Locale('en'),
        AppLocalizationsEn(),
      ),
      'Today, Jan 1',
    );
  });

  test('daily forecast labels other days with weekday and month day', () {
    final date = DateTime.utc(2024, 1, 2);
    final today = DateTime.utc(2024, 1, 1, 23, 30);

    expect(
      WeatherFormatters.dailyDate(
        date,
        today,
        const Locale('zh'),
        AppLocalizationsZh(),
      ),
      '周二（1月2日）',
    );
    expect(
      WeatherFormatters.dailyDate(
        date,
        today,
        const Locale('en'),
        AppLocalizationsEn(),
      ),
      'Tuesday, Jan 2',
    );
  });

  test('daily forecast does not label yesterday as today near midnight', () {
    final yesterday = DateTime.utc(2023, 12, 31);
    final today = DateTime.utc(2024, 1, 1, 0, 30);

    expect(
      WeatherFormatters.dailyDate(
        yesterday,
        today,
        const Locale('zh'),
        AppLocalizationsZh(),
      ),
      '周日（12月31日）',
    );
    expect(
      WeatherFormatters.dailyDate(
        yesterday,
        today,
        const Locale('en'),
        AppLocalizationsEn(),
      ),
      'Sunday, Dec 31',
    );
  });

  test(
    'location today applies positive and negative offsets across utc days',
    () {
      final beforePositiveBoundary = DateTime.utc(2023, 12, 31, 23, 30);
      final afterNegativeBoundary = DateTime.utc(2024, 1, 1, 1);

      expect(
        WeatherFormatters.locationToday(beforePositiveBoundary, 3600),
        DateTime.utc(2024, 1, 1, 0, 30),
      );
      expect(
        WeatherFormatters.locationToday(afterNegativeBoundary, -7200),
        DateTime.utc(2023, 12, 31, 23),
      );
    },
  );

  test('weather details show city only while search keeps full details', () {
    final l10n = AppLocalizationsEn();

    expect(
      WeatherFormatters.locationName(testLocation, l10n, includeDetails: false),
      'Berlin',
    );
    expect(
      WeatherFormatters.locationName(testLocation, l10n),
      'Berlin, Berlin, Germany',
    );
  });

  test('error messages map official QWeather error codes by category', () {
    final en = AppLocalizationsEn();
    final zh = AppLocalizationsZh();

    // 凭据/额度类错误码：提示用户检查配置，而非通用服务错误。
    final unauthorized = QWeatherServiceException(
      QWeatherErrorCode.unauthorized,
      401,
    );
    expect(
      WeatherFormatters.errorMessage(unauthorized, en),
      'Weather service rejected the request. Check the API key, host or account quota',
    );
    expect(
      WeatherFormatters.errorMessage(unauthorized, zh),
      '天气服务拒绝了请求，请检查 API 密钥、Host 或账户额度',
    );
    expect(
      WeatherFormatters.errorMessage(
        QWeatherServiceException(QWeatherErrorCode.noCredit, 403),
        en,
      ),
      en.accountError,
    );

    // 其余官方错误码保持通用服务错误，不额外暴露细节。
    expect(
      WeatherFormatters.errorMessage(
        QWeatherServiceException(QWeatherErrorCode.unknownError, 500),
        en,
      ),
      en.serviceError,
    );
    expect(
      WeatherFormatters.errorMessage(
        QWeatherServiceException(QWeatherErrorCode.dataNotAvailable, 400),
        en,
      ),
      en.serviceError,
    );

    // Open-Meteo 无凭据与错误码枚举，服务端确认的错误统一按服务错误展示。
    expect(
      WeatherFormatters.errorMessage(OpenMeteoServiceException(400), en),
      en.serviceError,
    );
    expect(
      WeatherFormatters.errorMessage(OpenMeteoServiceException(429), zh),
      zh.serviceError,
    );
  });
}
