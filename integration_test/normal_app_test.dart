import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/app.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(const ProviderScope(child: WeatherApp()));
}
