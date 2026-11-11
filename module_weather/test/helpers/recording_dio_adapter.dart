import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

typedef AdapterHandler = Future<ResponseBody> Function(
  RequestOptions options,
  List<int> bodyBytes,
);

class RecordedRequest {
  final RequestOptions options;
  final List<int> bodyBytes;

  const RecordedRequest(this.options, this.bodyBytes);

  Object? get jsonBody {
    if (bodyBytes.isEmpty) return null;
    return jsonDecode(utf8.decode(bodyBytes));
  }
}

class RecordingDioAdapter implements HttpClientAdapter {
  final List<RecordedRequest> requests = [];
  AdapterHandler? handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final bodyBytes = requestStream == null
        ? <int>[]
        : await requestStream.expand((chunk) => chunk).toList();
    requests.add(RecordedRequest(options, bodyBytes));
    final currentHandler = handler;
    if (currentHandler == null) {
      throw StateError('No adapter handler configured');
    }
    return currentHandler(options, bodyBytes);
  }

  @override
  void close({bool force = false}) {}
}

Dio createTestDio(RecordingDioAdapter adapter) {
  return Dio(
    BaseOptions(responseType: ResponseType.json, validateStatus: (_) => true),
  )..httpClientAdapter = adapter;
}

ResponseBody jsonResponse(String body, int statusCode) {
  return ResponseBody.fromString(
    body,
    statusCode,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
