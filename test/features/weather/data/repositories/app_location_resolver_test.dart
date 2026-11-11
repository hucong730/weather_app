import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/weather/data/datasources/device_location_data_source.dart';
import 'package:weather_app/features/weather/data/repositories/app_location_resolver.dart';
import 'package:module_weather/models/location.dart';

class FakeDeviceLocationDataSource extends DeviceLocationDataSource {
  Location? location;
  int calls = 0;

  @override
  Future<Location?> getCurrentLocation() async {
    calls++;
    return location;
  }
}

void main() {
  late FakeDeviceLocationDataSource device;
  late AppLocationResolver resolver;

  setUp(() {
    device = FakeDeviceLocationDataSource();
    resolver = AppLocationResolver(deviceLocation: device);
  });

  test('gps success returns the device location', () async {
    device.location = const Location(
      latitude: 52.52,
      longitude: 13.41,
      origin: LocationOrigin.gps,
    );

    final result = await resolver.resolve();

    expect(result?.origin, LocationOrigin.gps);
    expect(device.calls, 1);
  });

  test('gps failure returns null without an ip request', () async {
    final result = await resolver.resolve(languageCode: 'zh');

    expect(result, isNull);
    expect(device.calls, 1);
  });
}
