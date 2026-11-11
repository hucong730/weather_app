import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:module_weather/models/location.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';
import 'package:weather_app/app.dart';

class ManualLocationResolver implements LocationResolver {
  @override
  Future<Location?> resolve({String languageCode = 'en'}) async => null;
}

void main() {
  enableFlutterDriverExtension();
  runApp(
    ProviderScope(
      overrides: [
        locationResolverProvider.overrideWithValue(ManualLocationResolver()),
      ],
      child: WeatherApp(
        // 驱动在持续动画下可能等待帧稳定；仅测试环境关闭动画。
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: true),
          child: child!,
        ),
      ),
    ),
  );
}
