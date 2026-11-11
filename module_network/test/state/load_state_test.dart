import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/module_network.dart';

void main() {
  test('load_state_idle_and_loading', () {
    const idle = LoadState<List<int>>.idle();
    const loading = LoadState<List<int>>.loading();

    expect(idle.status, LoadStatus.idle);
    expect(idle.data, isNull);
    expect(loading.status, LoadStatus.loading);
    expect(loading.error, isNull);
  });

  test('load_state_success_nonempty', () {
    final state = LoadState.fromResult(
      const Success([1], 200),
      isEmpty: (items) => items.isEmpty,
    );

    expect(state.status, LoadStatus.success);
    expect(state.data, [1]);
    expect(state.statusCode, 200);
  });

  test('load_state_success_empty', () {
    final state = LoadState.fromResult(
      const Success(<int>[], 200),
      isEmpty: (items) => items.isEmpty,
    );

    expect(state.status, LoadStatus.empty);
    expect(state.data, isEmpty);
  });

  test('load_state_failure_error', () {
    final state = LoadState.fromResult(
      const Failure(AppNetworkException(), null),
    );

    expect(state.status, LoadStatus.error);
    expect(state.error, isA<AppNetworkException>());
    expect(state.statusCode, isNull);
    expect(state.data, isNull);
  });
}
