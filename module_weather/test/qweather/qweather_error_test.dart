import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_network/network/api_client.dart';
import 'package:module_network/network/api_result.dart';
import 'package:module_weather/src/qweather/api/qweather_city_lookup_api.dart';
import 'package:module_weather/src/qweather/api/qweather_current_weather_api.dart';
import 'package:module_weather/src/qweather/dto/qweather_city_lookup_dto.dart';
import 'package:module_weather/src/qweather/dto/qweather_weather_dto.dart';
import 'package:module_weather/src/qweather/qweather_config.dart';
import 'package:module_weather/src/qweather/qweather_error.dart';

import '../helpers/recording_dio_adapter.dart';
import '../helpers/weather_test_data.dart';

const testQWeatherConfig = QWeatherConfig(
  apiHost: 'https://test.qweatherapi.com',
  apiKey: 'test-key',
);

/// 构造和风官方 problem+json 错误响应体，type 为完整文档 URL。
String qweatherErrorBody(String fragment, int status, {String? title}) {
  return jsonEncode({
    'error': {
      'status': status,
      'type': 'https://dev.qweather.com/docs/resource/error-code/#$fragment',
      'title': title ?? fragment,
      'detail': 'Sensitive diagnostic detail',
    },
  });
}

void main() {
  late RecordingDioAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = RecordingDioAdapter();
    client = ApiClient(createTestDio(adapter));
  });

  group('QWeatherErrorCode parsing', () {
    test('parses every documented error type fragment', () {
      const cases = {
        'invalid-parameters': QWeatherErrorCode.invalidParameters,
        'missing-parameter': QWeatherErrorCode.missingParameter,
        'no-such-location': QWeatherErrorCode.noSuchLocation,
        'data-not-available': QWeatherErrorCode.dataNotAvailable,
        'unauthorized': QWeatherErrorCode.unauthorized,
        'no-credit': QWeatherErrorCode.noCredit,
        'overdue': QWeatherErrorCode.overdue,
        'security-restriction': QWeatherErrorCode.securityRestriction,
        'invalid-host': QWeatherErrorCode.invalidHost,
        'account-suspension': QWeatherErrorCode.accountSuspension,
        'deprecated': QWeatherErrorCode.deprecated,
        'forbidden': QWeatherErrorCode.forbidden,
        'not-found': QWeatherErrorCode.notFound,
        'method-not-allowed': QWeatherErrorCode.methodNotAllowed,
        'too-many-requests': QWeatherErrorCode.tooManyRequests,
        'over-monthly-limit': QWeatherErrorCode.overMonthlyLimit,
        'unknown-error': QWeatherErrorCode.unknownError,
      };
      cases.forEach((fragment, expected) {
        expect(
          QWeatherErrorCode.fromErrorType(
            'https://dev.qweather.com/docs/resource/error-code/#$fragment',
          ),
          expected,
        );
      });
    });

    test('fragment matching is case insensitive', () {
      expect(
        QWeatherErrorCode.fromErrorType(
          'https://dev.qweather.com/docs/resource/error-code/#UNAUTHORIZED',
        ),
        QWeatherErrorCode.unauthorized,
      );
    });

    test('unknown or missing type returns null', () {
      expect(QWeatherErrorCode.fromErrorType(null), isNull);
      expect(
        QWeatherErrorCode.fromErrorType('https://example.com/#other'),
        isNull,
      );
      expect(QWeatherErrorCode.fromErrorType('no fragment'), isNull);
    });

    test('title fallback parses official titles', () {
      expect(
        QWeatherErrorCode.fromErrorTitle('No Such Location'),
        QWeatherErrorCode.noSuchLocation,
      );
      expect(
        QWeatherErrorCode.fromErrorTitle('Too Many Requests'),
        QWeatherErrorCode.tooManyRequests,
      );
      expect(QWeatherErrorCode.fromErrorTitle(null), isNull);
      expect(QWeatherErrorCode.fromErrorTitle('Random'), isNull);
    });

    test('parseQWeatherErrorCode rejects malformed bodies', () {
      expect(parseQWeatherErrorCode('not a map'), isNull);
      expect(parseQWeatherErrorCode(<String, dynamic>{}), isNull);
      expect(parseQWeatherErrorCode({'error': 'string'}), isNull);
      expect(
        parseQWeatherErrorCode({
          'error': {'status': 400, 'type': 'unknown'},
        }),
        isNull,
      );
      expect(
        parseQWeatherErrorCode({
          'error': {'title': 'Unauthorized'},
        }),
        QWeatherErrorCode.unauthorized,
      );
    });
  });

  group('QWeatherApi error mapping', () {
    Future<ApiResult<QWeatherCurrentWeatherDto>> sendCurrent(
      String body,
      int status,
    ) {
      adapter.handler = (options, bodyBytes) async =>
          jsonResponse(body, status);
      return QWeatherCurrentWeatherApi(
        client,
        location: testLocation,
        languageCode: 'zh',
        config: testQWeatherConfig,
      ).send();
    }

    test('401 unauthorized maps to QWeatherServiceException', () async {
      final result = await sendCurrent(
        qweatherErrorBody('unauthorized', 401),
        401,
      );

      expect(result, isA<Failure<QWeatherCurrentWeatherDto>>());
      final failure = result as Failure<QWeatherCurrentWeatherDto>;
      final error = failure.error;
      expect(error, isA<QWeatherServiceException>());
      expect(
        (error as QWeatherServiceException).code,
        QWeatherErrorCode.unauthorized,
      );
      expect(error.statusCode, 401);
      expect(error.isCredentialOrQuota, isTrue);
      expect(failure.statusCode, 401);
    });

    test('403 no-credit maps to credential or quota category', () async {
      final result = await sendCurrent(
        qweatherErrorBody('no-credit', 403),
        403,
      );

      final failure = result as Failure<QWeatherCurrentWeatherDto>;
      final error = failure.error as QWeatherServiceException;
      expect(error.code, QWeatherErrorCode.noCredit);
      expect(error.isCredentialOrQuota, isTrue);
    });

    test(
      '500 unknown-error maps to QWeatherServiceException not quota',
      () async {
        final result = await sendCurrent(
          qweatherErrorBody('unknown-error', 500),
          500,
        );

        final failure = result as Failure<QWeatherCurrentWeatherDto>;
        final error = failure.error as QWeatherServiceException;
        expect(error.code, QWeatherErrorCode.unknownError);
        expect(error.isCredentialOrQuota, isFalse);
        expect(failure.statusCode, 500);
      },
    );

    test('429 too-many-requests maps to generic rate limit', () async {
      final result = await sendCurrent(
        qweatherErrorBody('too-many-requests', 429),
        429,
      );

      final failure = result as Failure<QWeatherCurrentWeatherDto>;
      expect(failure.error, isA<AppRateLimitException>());
      expect(failure.statusCode, 429);
    });

    test('429 over-monthly-limit also maps to rate limit', () async {
      final result = await sendCurrent(
        qweatherErrorBody('over-monthly-limit', 429),
        429,
      );

      final failure = result as Failure<QWeatherCurrentWeatherDto>;
      expect(failure.error, isA<AppRateLimitException>());
    });

    test('unrecognized error body falls back to AppHttpException', () async {
      final result = await sendCurrent(jsonEncode({'foo': 'bar'}), 400);

      final failure = result as Failure<QWeatherCurrentWeatherDto>;
      expect(failure.error, isA<AppHttpException>());
      expect((failure.error as AppHttpException).statusCode, 400);
    });

    test(
      'non-JSON error body maps to data error without status code',
      () async {
        final result = await sendCurrent('Internal Server Error', 500);

        final failure = result as Failure<QWeatherCurrentWeatherDto>;
        // Dio 解码失败发生在获得响应体之后、状态码可用之前，按数据错误处理。
        expect(failure.error, isA<AppDataException>());
        expect(failure.statusCode, isNull);
      },
    );

    test('error message does not leak detail or key', () async {
      final result = await sendCurrent(
        qweatherErrorBody(
          'security-restriction',
          403,
          title: 'Security Restriction',
        ),
        403,
      );

      final failure = result as Failure<QWeatherCurrentWeatherDto>;
      final message = failure.error.message;
      expect(message.contains('securityRestriction'), isTrue);
      expect(message.contains('Sensitive diagnostic detail'), isFalse);
      expect(message.contains('test-key'), isFalse);
    });
  });

  group('city lookup delegation', () {
    Future<ApiResult<QWeatherCityLookupResponseDto>> sendLookup(
      String body,
      int status,
    ) {
      adapter.handler = (options, bodyBytes) async =>
          jsonResponse(body, status);
      return QWeatherCityLookupApi(
        client,
        query: '孝感',
        languageCode: 'zh',
        config: testQWeatherConfig,
      ).send();
    }

    Future<ApiResult<QWeatherCityLookupResponseDto>> send404NoLocation() {
      return sendLookup(
        jsonEncode({
          'error': {
            'status': 400,
            'type':
                'https://dev.qweather.com/docs/resource/error-code/#no-such-location',
            'title': 'No Such Location',
          },
        }),
        400,
      );
    }

    test('no-such-location still becomes an empty 404-style result', () async {
      final result = await send404NoLocation();

      expect(result, isA<Success<QWeatherCityLookupResponseDto>>());
      final success = result as Success<QWeatherCityLookupResponseDto>;
      expect(success.data.code, '404');
    });

    test('other error codes are delegated to the official mapping', () async {
      final result = await sendLookup(
        qweatherErrorBody('invalid-parameters', 400),
        400,
      );

      final failure = result as Failure<QWeatherCityLookupResponseDto>;
      final error = failure.error as QWeatherServiceException;
      expect(error.code, QWeatherErrorCode.invalidParameters);
    });

    test('non-400 status delegates directly to the base mapping', () async {
      final result = await sendLookup(
        qweatherErrorBody('unauthorized', 401),
        401,
      );

      final failure = result as Failure<QWeatherCityLookupResponseDto>;
      expect(
        (failure.error as QWeatherServiceException).code,
        QWeatherErrorCode.unauthorized,
      );
    });
  });
}
