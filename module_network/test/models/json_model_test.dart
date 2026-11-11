import 'package:flutter_test/flutter_test.dart';
import 'package:module_network/module_network.dart';

class SampleModel extends JsonModel {
  final String name;
  final int count;

  const SampleModel(this.name, this.count);

  factory SampleModel.fromJson(Map<String, dynamic> json) {
    return SampleModel(json['name'] as String, json['count'] as int);
  }

  @override
  SampleModel copyWith({String? name, int? count}) {
    return SampleModel(name ?? this.name, count ?? this.count);
  }

  @override
  Map<String, dynamic> toJson() => {'name': name, 'count': count};
}

void main() {
  test('json_model_from_json_uses_decoder', () {
    final model = JsonModel.fromJson({
      'name': 'Berlin',
      'count': 1,
    }, SampleModel.fromJson);

    expect(model, isA<SampleModel>());
    expect(model.name, 'Berlin');
    expect(model.count, 1);
  });

  test('copywith_updates_only_supplied_fields', () {
    const model = SampleModel('Berlin', 1);

    final updated = model.copyWith(count: 2);

    expect(updated.name, 'Berlin');
    expect(updated.count, 2);
    expect(updated.toJson(), {'name': 'Berlin', 'count': 2});
  });
}
