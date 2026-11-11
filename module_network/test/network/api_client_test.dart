import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/module_network.dart';

import '../helpers/recording_dio_adapter.dart';

void main() {
  late RecordingDioAdapter adapter;
  late ApiClient client;

  setUp(() {
    adapter = RecordingDioAdapter()
      ..handler = (options, bodyBytes) async =>
          jsonResponse('{"ok":true}', 200);
    client = ApiClient(createTestDio(adapter));
  });

  test('get forwards params and headers and returns raw response', () async {
    final response = await client.get(
      Uri.https('example.com', '/weather'),
      params: {'city': 'Berlin'},
      headers: {'X-Test': 'yes'},
    );

    expect(response, isA<Response<dynamic>>());
    expect(response.statusCode, 200);
    expect(response.data, {'ok': true});
    final request = adapter.requests.single.options;
    expect(request.method, 'GET');
    expect(request.uri.queryParameters, {'city': 'Berlin'});
    expect(request.headers['X-Test'], 'yes');
  });

  test('post forwards query and json body', () async {
    await client.post(
      Uri.https('example.com', '/weather'),
      params: {'units': 'metric'},
      body: {'city': 'Berlin'},
    );

    final request = adapter.requests.single;
    expect(request.options.method, 'POST');
    expect(request.options.uri.queryParameters, {'units': 'metric'});
    expect(request.jsonBody, {'city': 'Berlin'});
  });

  test('request supports other methods', () async {
    await client.request(
      Uri.https('example.com', '/weather'),
      method: HttpMethod.patch,
    );

    expect(adapter.requests.single.options.method, 'PATCH');
  });

  test('request forwards the same cancellation token to Dio', () async {
    final cancelToken = CancelToken();

    await client.get(
      Uri.https('example.com', '/weather'),
      cancelToken: cancelToken,
    );

    expect(adapter.requests.single.options.cancelToken, same(cancelToken));
  });
}
