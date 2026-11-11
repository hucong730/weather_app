import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:weather_app/features/weather/data/cache/sqflite_weather_cache.dart';
import 'package:weather_app/features/weather/data/cache/weather_report_codec.dart';
import 'package:module_weather/module_weather.dart';

import '../../../../helpers/weather_test_data.dart';

void main() {
  late SqfliteWeatherCache cache;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    cache = SqfliteWeatherCache(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() async {
    await cache.close();
    await databaseFactoryFfi.deleteDatabase(inMemoryDatabasePath);
  });

  Future<void> createV1Cache(WeatherReport report, String path) async {
    final database = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE weather_report (
            id INTEGER PRIMARY KEY,
            location_id TEXT,
            payload TEXT NOT NULL,
            saved_at INTEGER NOT NULL
          )
        '''),
      ),
    );
    await database.insert('weather_report', {
      'id': 0,
      'location_id': report.location.id,
      'payload': WeatherReportCodec.encode(report),
      'saved_at': 1,
    });
    await database.close();
  }

  test('empty database returns an empty list', () async {
    expect(await cache.loadAll(), isEmpty);
  });

  test('save restores the complete weather report', () async {
    final report = buildTestWeatherReport(testLocation).copyWith(
      current: buildTestWeatherReport(testLocation).current.copyWith(
        airQuality: const AirQuality(displayValue: '62', category: '良'),
      ),
    );

    await cache.save(report, position: 1);
    final restored = (await cache.loadAll()).single;

    expect(restored.location.id, testLocation.id);
    expect(restored.location.name, 'Berlin');
    expect(restored.location.utcOffsetSeconds, 3600);
    expect(restored.current.temperature, 12.5);
    expect(restored.current.airQuality?.displayValue, '62');
    expect(restored.current.airQuality?.category, '良');
    expect(restored.current.observedAtUtc, DateTime.utc(2024, 1, 1));
    expect(restored.hourly, hasLength(24));
    expect(restored.hourly[1].precipitationProbability, 50);
    expect(restored.daily, hasLength(7));
    expect(restored.daily.last.date, DateTime.utc(2024, 1, 7));
  });

  test(
    'reports restore in page order and duplicate city replaces in place',
    () async {
      final currentLocation = testLocation.copyWith(
        id: 'current-location',
        name: 'Current',
        origin: LocationOrigin.gps,
      );
      final current = buildTestWeatherReport(currentLocation);
      final berlin = buildTestWeatherReport(testLocation);
      final parisLocation = testLocation.copyWith(id: 'paris', name: 'Paris');
      final paris = buildTestWeatherReport(parisLocation);

      await cache.save(berlin, position: 1);
      await cache.save(current, position: 0);
      await cache.save(paris, position: 2);
      await cache.save(
        berlin.copyWith(current: berlin.current.copyWith(temperature: 20)),
        position: 1,
      );

      final restored = await cache.loadAll();
      expect(restored.map((item) => item.location.id), [
        'current-location',
        testLocation.id,
        'paris',
      ]);
      expect(restored[1].current.temperature, 20);
    },
  );

  for (final origin in [
    LocationOrigin.gps,
    LocationOrigin.search,
    LocationOrigin.ip,
  ]) {
    test('v1 ${origin.name} report migrates without data loss', () async {
      // :memory: 在 v1 连接关闭后即消失，迁移测试必须使用真实临时文件。
      final path = 'build/v1_${origin.name}_cache_test.db';
      await databaseFactoryFfi.deleteDatabase(path);
      final migrationCache = SqfliteWeatherCache(
        factory: databaseFactoryFfi,
        path: path,
      );
      addTearDown(() async {
        await migrationCache.close();
        await databaseFactoryFfi.deleteDatabase(path);
      });
      final report = buildTestWeatherReport(
        testLocation.copyWith(origin: origin),
      );
      await createV1Cache(report, path);

      final restored = await migrationCache.loadAll();

      expect(restored, hasLength(1));
      expect(restored.single.location.id, testLocation.id);
      expect(restored.single.location.origin, origin);
    });
  }

  test('delete compacts positions so later cities keep their order', () async {
    final current = buildTestWeatherReport(
      testLocation.copyWith(id: 'current', origin: LocationOrigin.gps),
    );
    final berlin = buildTestWeatherReport(testLocation);
    final paris = buildTestWeatherReport(
      testLocation.copyWith(id: 'paris', name: 'Paris'),
    );
    final london = buildTestWeatherReport(
      testLocation.copyWith(id: 'london', name: 'London'),
    );
    await cache.save(current, position: 0);
    await cache.save(berlin, position: 1);
    await cache.save(paris, position: 2);
    await cache.save(london, position: 3);

    await cache.delete(paris, position: 2);
    await cache.save(london, position: 2);
    final tokyo = buildTestWeatherReport(
      testLocation.copyWith(id: 'tokyo', name: 'Tokyo'),
    );
    await cache.save(tokyo, position: 3);

    expect((await cache.loadAll()).map((report) => report.location.id), [
      'current',
      testLocation.id,
      'london',
      'tokyo',
    ]);
  });

  test('save city order atomically restores reordered cities', () async {
    final current = buildTestWeatherReport(
      testLocation.copyWith(id: 'current', origin: LocationOrigin.gps),
    );
    final berlin = buildTestWeatherReport(testLocation);
    final paris = buildTestWeatherReport(
      testLocation.copyWith(id: 'paris', name: 'Paris'),
    );
    await cache.save(current, position: 0);
    await cache.save(berlin, position: 1);
    await cache.save(paris, position: 2);

    await cache.saveCityOrder([paris, berlin]);

    expect((await cache.loadAll()).map((report) => report.location.id), [
      'current',
      'paris',
      testLocation.id,
    ]);
  });

  test('corrupt row does not hide other valid cities', () async {
    final current = buildTestWeatherReport(
      testLocation.copyWith(id: 'current', origin: LocationOrigin.gps),
    );
    await cache.save(current, position: 0);
    await cache.save(buildTestWeatherReport(testLocation), position: 1);
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    await database.update('weather_report', {
      'payload': '{invalid',
    }, where: 'position = 1');

    final restored = await cache.loadAll();

    expect(restored.map((item) => item.location.id), ['current']);
    await database.close();
  });

  test('concurrent saves preserve acceptance order', () async {
    final berlin = buildTestWeatherReport(testLocation);
    await cache.save(berlin, position: 1);
    final database = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
    );
    final lockStarted = Completer<void>();
    final releaseLock = Completer<void>();
    final locked = database.transaction((transaction) async {
      lockStarted.complete();
      await releaseLock.future;
    });
    await lockStarted.future;

    final oldSave = cache.save(
      berlin.copyWith(current: berlin.current.copyWith(temperature: 20)),
      position: 1,
    );
    final newSave = cache.save(
      berlin.copyWith(current: berlin.current.copyWith(temperature: 30)),
      position: 1,
    );
    releaseLock.complete();
    await Future.wait([oldSave, newSave, locked]);

    final restored = (await cache.loadAll()).single;
    expect(restored.location.id, testLocation.id);
    expect(restored.current.temperature, 30);
    await database.close();
  });
}
