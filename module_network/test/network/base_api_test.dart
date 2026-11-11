import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/module_network.dart';

import '../helpers/recording_dio_adapter.dart';

class TestModel extends JsonModel {
  final String value;

  const TestModel(this.value);

  factory TestModel.fromJson(Map<String, dynamic> json) {
    return TestModel(json['value'] as String);
  }

  @override
  TestModel copyWith({String? value}) => TestModel(value ?? this.value);

  @override
  Map<String, dynamic> toJson() => {'value': value};
}

class TestApi extends BaseApi<TestModel> {
  TestApi(super.client, {super.cancelToken})
    : super(decoder: TestModel.fromJson);

  @override
  Uri get uri => Uri.https('example.com', '/default');
}

class CustomApi extends TestApi {
  CustomApi(super.client);

  @override
  Uri get uri => Uri.https('example.com', '/custom');

  @override
  HttpMethod get method => HttpMethod.post;

  @override
  Map<String, dynamic> get params => {'query': 'yes'};

  @override
  Map<String, String> get headers => {'X-Custom': 'yes'};

  @override
  Object? get body => {'input': 'value'};

  @override
  int get successStatusCode => 201;
}

class ErrorMappingApi extends TestApi {
  ErrorMappingApi(super.client);

  @override
  ApiResult<TestModel>? mapErrorResponse(Response<dynamic> response) {
    if (response.statusCode != 400) return null;
    final body = response.data;
    if (body is Map<String, dynamic> && body['empty'] == true) {
      return const Success(TestModel('empty'), 400);
    }
    return null;
  }
}

void main() {
  late RecordingDioAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = RecordingDioAdapter();
    client = ApiClient(createTestDio(adapter));
  });

  test('base api uses get and empty defaults', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse('{"value":"ok"}', 200);

    final result = await TestApi(client).send();

    expect(result, isA<Success<TestModel>>());
    final request = adapter.requests.single.options;
    expect(request.method, 'GET');
    expect(request.uri.queryParameters, isEmpty);
    expect(request.headers, isNot(contains('X-Custom')));
    expect(TestApi(client).params, isEmpty);
    expect(TestApi(client).headers, isEmpty);
    expect(TestApi(client).body, isNull);
    expect(TestApi(client).successStatusCode, 200);
  });

  test(
    'custom api overrides method params headers body and success code',
    () async {
      adapter.handler = (options, bodyBytes) async =>
          jsonResponse('{"value":"created"}', 201);

      final result = await CustomApi(client).send();

      expect(result, isA<Success<TestModel>>());
      expect(result.statusCode, 201);
      final request = adapter.requests.single;
      expect(request.options.method, 'POST');
      expect(request.options.uri.queryParameters, {'query': 'yes'});
      expect(request.options.headers['X-Custom'], 'yes');
      expect(request.jsonBody, {'input': 'value'});
    },
  );

  test('send returns failure for non success status', () async {
    adapter.handler = (options, bodyBytes) async => jsonResponse('{}', 500);

    final result = await TestApi(client).send();

    expect((result as Failure).error, isA<AppHttpException>());
    expect(result.statusCode, 500);
  });

  test('business api can map a specific error response', () async {
    adapter.handler = (options, bodyBytes) async =>
        jsonResponse('{"empty":true}', 400);

    final result = await ErrorMappingApi(client).send();

    expect(result, isA<Success<TestModel>>());
    expect((result as Success<TestModel>).data.value, 'empty');
    expect(result.statusCode, 400);
  });

  test('send maps timeout without response to null status code', () async {
    adapter.handler = (options, bodyBytes) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.receiveTimeout,
      );
    };

    final result = await TestApi(client).send();

    expect((result as Failure).error, isA<AppTimeoutException>());
    expect(result.statusCode, isNull);
  });

  test('send maps socket error without response', () async {
    adapter.handler = (options, bodyBytes) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        error: const SocketException('offline'),
      );
    };

    final result = await TestApi(client).send();

    expect((result as Failure).error, isA<AppNetworkException>());
    expect(result.statusCode, isNull);
  });

  test('send finishes when an in-flight request is cancelled', () async {
    final response = Completer<ResponseBody>();
    final requestStarted = Completer<void>();
    adapter.handler = (options, bodyBytes) {
      if (!requestStarted.isCompleted) requestStarted.complete();
      return response.future;
    };
    final cancelToken = CancelToken();

    final pending = TestApi(client, cancelToken: cancelToken).send();
    await requestStarted.future.timeout(const Duration(seconds: 1));
    expect(adapter.requests, hasLength(1));

    cancelToken.cancel();
    final result = await pending;

    expect(result, isA<Failure<TestModel>>());
    expect((result as Failure).error, isA<AppNetworkException>());
    expect(result.statusCode, isNull);
  });
}
