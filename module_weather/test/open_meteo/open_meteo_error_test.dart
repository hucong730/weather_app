import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_weather/src/open_meteo/api/open_meteo_air_quality_api.dart';
import 'package:module_weather/src/open_meteo/api/open_meteo_forecast_api.dart';
import 'package:module_weather/src/open_meteo/api/open_meteo_geocoding_api.dart';
import 'package:module_weather/src/open_meteo/dto/open_meteo_air_quality_dto.dart';
import 'package:module_weather/src/open_meteo/dto/open_meteo_forecast_dto.dart';
import 'package:module_weather/src/open_meteo/dto/open_meteo_geocoding_dto.dart';
import 'package:module_weather/src/open_meteo/open_meteo_error.dart';

import '../helpers/recording_dio_adapter.dart';
import '../helpers/weather_test_data.dart';

/// 构造 Open-Meteo 官方错误响应体（各 API 文档 Errors 章节约定的结构）。
/// [reason] 为服务端诊断字符串，可能回显请求参数，异常层不得透传给界面。
String openMeteoErrorBody(String reason) {
  return jsonEncode({'error': true, 'reason': reason});
}

void main() {
  late RecordingDioAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = RecordingDioAdapter();
    client = ApiClient(createTestDio(adapter));
  });

  group('isOpenMeteoErrorBody', () {
    test('accepts the documented error object', () {
      expect(
        isOpenMeteoErrorBody({'error': true, 'reason': 'Not Found'}),
        isTrue,
      );
    });

    test('rejects non-error structures', () {
      expect(isOpenMeteoErrorBody(null), isFalse);
      expect(isOpenMeteoErrorBody('Internal Server Error'), isFalse);
      expect(isOpenMeteoErrorBody(<String, dynamic>{}), isFalse);
      expect(
        isOpenMeteoErrorBody({'generationtime_ms': 0.08}),
        isFalse,
      );
      // error 字段必须是布尔 true，字符串 "true" 不算官方错误对象。
      expect(
        isOpenMeteoErrorBody({'error': 'true'}),
        isFalse,
      );
    });
  });

  group('OpenMeteoForecastApi error mapping', () {
    Future<ApiResult<OpenMeteoForecastDto>> sendForecast(
      String body,
      int status,
    ) {
      adapter.handler = (options, bodyBytes) async =>
          jsonResponse(body, status);
      return OpenMeteoForecastApi(client, location: testLocation).send();
    }

    test('400 parameter error maps to OpenMeteoServiceException', () async {
      final result = await sendForecast(
        openMeteoErrorBody(
          'Invalid value: Cannot initialize Float from invalid String value abc',
        ),
        400,
      );

      expect(
        result,
        isA<Failure<OpenMeteoForecastDto>>(),
      );
      final failure = result as Failure<OpenMeteoForecastDto>;
      expect(failure.error, isA<OpenMeteoServiceException>());
      expect((failure.error as OpenMeteoServiceException).statusCode, 400);
      expect(failure.statusCode, 400);
    });

    test('404 maps to OpenMeteoServiceException', () async {
      final result = await sendForecast(openMeteoErrorBody('Not Found'), 404);

      final failure = result as Failure<OpenMeteoForecastDto>;
      expect((failure.error as OpenMeteoServiceException).statusCode, 404);
    });

    test('429 maps to generic rate limit exception', () async {
      final result = await sendForecast(
        openMeteoErrorBody('API key disabled or daily request limit exceeded'),
        429,
      );

      final failure = result as Failure<OpenMeteoForecastDto>;
      expect(failure.error, isA<AppRateLimitException>());
      expect(failure.statusCode, 429);
    });

    test('400 without official error body falls back to AppHttpException',
        () async {
      final result = await sendForecast(jsonEncode({'foo': 'bar'}), 400);

      final failure = result as Failure<OpenMeteoForecastDto>;
      expect(failure.error, isA<AppHttpException>());
      expect((failure.error as AppHttpException).statusCode, 400);
    });

    test('exception message does not leak the raw reason', () async {
      const reason = 'Invalid value: latitude 52.523 coastline';
      final result = await sendForecast(openMeteoErrorBody(reason), 400);

      final failure = result as Failure<OpenMeteoForecastDto>;
      final message = failure.error.message;
      expect(message.contains('400'), isTrue);
      expect(message.contains(reason), isFalse);
      expect(message.contains('52.523'), isFalse);
    });
  });

  group('other Open-Meteo APIs share the base mapping', () {
    test('geocoding 400 error maps to OpenMeteoServiceException', () async {
      adapter.handler = (options, bodyBytes) async => jsonResponse(
        openMeteoErrorBody('Parameter count must be between 1 and 100.'),
        400,
      );
      final result = await OpenMeteoGeocodingApi(
        client,
        query: 'Beijing',
        languageCode: 'zh',
      ).send();

      final failure = result as Failure<OpenMeteoGeocodingDto>;
      expect(failure.error, isA<OpenMeteoServiceException>());
    });

    test('air quality 400 error maps to OpenMeteoServiceException',
        () async {
      adapter.handler = (options, bodyBytes) async => jsonResponse(
        openMeteoErrorBody('Invalid value: Cannot initialize Float from '
            'invalid String value xyz'),
        400,
      );
      final result = await OpenMeteoAirQualityApi(
        client,
        location: testLocation,
      ).send();

      final failure = result as Failure<OpenMeteoAirQualityDto>;
      expect(failure.error, isA<OpenMeteoServiceException>());
      expect(failure.statusCode, 400);
    });
  });
}
