import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/app.dart';

/// 应用入口，在根部创建 Riverpod ProviderScope 以注入全部依赖。
void main() {
  runApp(const ProviderScope(child: WeatherApp()));
}
