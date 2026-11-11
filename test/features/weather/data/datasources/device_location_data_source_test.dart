import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/features/weather/data/datasources/device_location_data_source.dart';
import 'package:module_weather/models/location.dart';

class FakeDeviceLocationGateway implements DeviceLocationGateway {
  bool serviceEnabled = true;
  LocationPermission initialPermission = LocationPermission.whileInUse;
  LocationPermission requestedPermission = LocationPermission.whileInUse;
  Position? position;
  Object? positionError;
  Future<Position>? positionFuture;
  int permissionRequests = 0;
  int appSettingsOpened = 0;

  @override
  Future<bool> openAppSettings() async {
    appSettingsOpened++;
    return true;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<LocationPermission> checkPermission() async => initialPermission;

  @override
  Future<LocationPermission> requestPermission() async {
    permissionRequests++;
    return requestedPermission;
  }

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) async {
    if (positionFuture != null) return positionFuture!;
    if (positionError != null) throw positionError!;
    return position!;
  }
}

Position createPosition() {
  return Position(
    latitude: 52.52,
    longitude: 13.41,
    timestamp: DateTime.utc(2024),
    accuracy: 100,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}

void main() {
  late FakeDeviceLocationGateway gateway;

  setUp(() => gateway = FakeDeviceLocationGateway());

  test(
    'disabled location service returns null without permission request',
    () async {
      gateway.serviceEnabled = false;

      final result = await DeviceLocationDataSource(gateway: gateway)
          .getCurrentLocation();

      expect(result, isNull);
      expect(gateway.permissionRequests, 0);
    },
  );

  test(
    'denied permission is requested once and gps success returns location',
    () async {
      gateway.initialPermission = LocationPermission.denied;
      gateway.position = createPosition();

      final result = await DeviceLocationDataSource(gateway: gateway)
          .getCurrentLocation();

      expect(gateway.permissionRequests, 1);
      expect(result?.origin, LocationOrigin.gps);
      expect(result?.latitude, 52.52);
      expect(result?.name, isNull);
    },
  );

  test('denied forever returns null', () async {
    gateway.initialPermission = LocationPermission.deniedForever;

    final result = await DeviceLocationDataSource(gateway: gateway)
        .getCurrentLocation();

    expect(result, isNull);
    expect(gateway.permissionRequests, 0);
  });

  test('gps timeout returns null', () async {
    gateway.positionError = TimeoutException('timeout');

    final result = await DeviceLocationDataSource(gateway: gateway)
        .getCurrentLocation();

    expect(result, isNull);
  });

  test('unresponsive platform location exits after fallback timeout', () async {
    gateway.positionFuture = Completer<Position>().future;

    final result = await DeviceLocationDataSource(
      gateway: gateway,
      requestTimeout: const Duration(milliseconds: 1),
    ).getCurrentLocation();

    expect(result, isNull);
  });

  test('enabling denied permission requests system authorization', () async {
    gateway.initialPermission = LocationPermission.denied;

    await DeviceLocationDataSource(gateway: gateway).changePermission(true);

    expect(gateway.permissionRequests, 1);
    expect(gateway.appSettingsOpened, 0);
  });

  test('disabling granted permission opens app settings', () async {
    gateway.initialPermission = LocationPermission.whileInUse;

    await DeviceLocationDataSource(gateway: gateway).changePermission(false);

    expect(gateway.permissionRequests, 0);
    expect(gateway.appSettingsOpened, 1);
  });

  test('enabling permanently denied permission opens app settings', () async {
    gateway.initialPermission = LocationPermission.deniedForever;

    await DeviceLocationDataSource(gateway: gateway).changePermission(true);

    expect(gateway.permissionRequests, 0);
    expect(gateway.appSettingsOpened, 1);
  });
}
