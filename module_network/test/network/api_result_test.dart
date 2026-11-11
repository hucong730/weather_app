import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/module_network.dart';

class ResponseModel extends JsonModel {
  final String value;

  const ResponseModel(this.value);

  factory ResponseModel.fromJson(Map<String, dynamic> json) {
    final value = json['value'];
    if (value is! String) throw const FormatException('Invalid value');
    return ResponseModel(value);
  }

  @override
  ResponseModel copyWith({String? value}) => ResponseModel(value ?? this.value);

  @override
  Map<String, dynamic> toJson() => {'value': value};
}

Response<dynamic> response(int? statusCode, Object? data) {
  return Response(
    requestOptions: RequestOptions(path: '/test'),
    statusCode: statusCode,
    data: data,
  );
}

void main() {
  test('api_result_from_response_success', () {
    final result = ApiResult.fromResponse(
      response(200, {'value': 'ok'}),
      successStatusCode: 200,
      decoder: ResponseModel.fromJson,
    );

    expect(result, isA<Success<ResponseModel>>());
    expect((result as Success<ResponseModel>).data.value, 'ok');
    expect(result.statusCode, 200);
  });

  test('api_result_supports_custom_success_status_code', () {
    final result = ApiResult.fromResponse(
      response(201, {'value': 'created'}),
      successStatusCode: 201,
      decoder: ResponseModel.fromJson,
    );

    expect(result, isA<Success<ResponseModel>>());
    expect(result.statusCode, 201);
  });

  test('api_result_from_response_failure', () {
    final rateLimited = ApiResult.fromResponse(
      response(429, <String, dynamic>{}),
      successStatusCode: 200,
      decoder: ResponseModel.fromJson,
    );
    final serverError = ApiResult.fromResponse(
      response(500, <String, dynamic>{}),
      successStatusCode: 200,
      decoder: ResponseModel.fromJson,
    );
    final wrongRoot = ApiResult.fromResponse(
      response(200, []),
      successStatusCode: 200,
      decoder: ResponseModel.fromJson,
    );
    final invalidModel = ApiResult.fromResponse(
      response(200, {'value': 1}),
      successStatusCode: 200,
      decoder: ResponseModel.fromJson,
    );
    final missingStatus = ApiResult.fromResponse(
      response(null, <String, dynamic>{}),
      successStatusCode: 200,
      decoder: ResponseModel.fromJson,
    );

    expect((rateLimited as Failure).error, isA<AppRateLimitException>());
    expect(rateLimited.statusCode, 429);
    expect((serverError as Failure).error, isA<AppHttpException>());
    expect(serverError.statusCode, 500);
    expect((wrongRoot as Failure).error, isA<AppDataException>());
    expect(wrongRoot.statusCode, 200);
    expect((invalidModel as Failure).error, isA<AppDataException>());
    expect(invalidModel.statusCode, 200);
    expect((missingStatus as Failure).error, isA<AppNetworkException>());
    expect(missingStatus.statusCode, isNull);
  });
}
