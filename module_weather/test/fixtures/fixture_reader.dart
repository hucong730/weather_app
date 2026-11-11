import 'dart:convert';
import 'dart:io';

Map<String, dynamic> readJsonFixture(String path) {
  final text = File('test/fixtures/$path').readAsStringSync();
  return jsonDecode(text) as Map<String, dynamic>;
}
