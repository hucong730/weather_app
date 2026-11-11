import 'package:sqflite/sqflite.dart';
import 'package:weather_app/features/weather/data/cache/weather_report_codec.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_cache.dart';

/// 基于 sqflite 的有序多城市天气缓存。
///
/// 表 `weather_report` 使用稳定 page_key 区分定位页和城市，position 决定
/// 左右滑动顺序；所有写入共享串行队列，保证后接受的操作最后落盘。
/// [factory] 与 [path] 主要用于内存数据库测试，生产使用平台默认路径。
class SqfliteWeatherCache implements WeatherCache {
  /// 可选数据库工厂；测试注入内存实现，生产为 null 时使用平台默认工厂。
  final DatabaseFactory? factory;

  /// 可选数据库文件路径；测试使用内存路径，生产为 null 时使用默认应用目录。
  final String? path;

  /// 延迟创建并复用的数据库连接，close 后清空以便安全释放资源。
  Future<Database>? _database;

  /// 所有保存、删除和排序共享的串行写入队列尾部。
  Future<void> _writeQueue = Future<void>.value();

  SqfliteWeatherCache({this.factory, this.path});

  @override
  Future<List<WeatherReport>> loadAll() async {
    final database = await _open();
    final rows = await database.query(
      'weather_report',
      columns: ['payload'],
      orderBy: 'position ASC, saved_at ASC',
    );
    final reports = <WeatherReport>[];
    for (final row in rows) {
      final payload = row['payload'];
      if (payload is! String) continue;
      final report = WeatherReportCodec.tryDecode(payload);
      if (report != null) reports.add(report);
    }
    return reports;
  }

  @override
  Future<void> save(WeatherReport report, {required int position}) {
    final operation = _writeQueue.then((_) async {
      final database = await _open();
      await database.insert('weather_report', {
        'page_key': _pageKey(report),
        'location_id': report.location.id,
        'payload': WeatherReportCodec.encode(report),
        'saved_at': DateTime.now().toUtc().millisecondsSinceEpoch,
        'position': position,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    });
    // 失败返回给当前调用方，但队列尾部消化错误，后续写入仍可继续。
    _writeQueue = operation.onError((error, stackTrace) {});
    return operation;
  }

  @override
  Future<void> delete(WeatherReport report, {required int position}) {
    final operation = _writeQueue.then((_) async {
      final database = await _open();
      await database.transaction((transaction) async {
        await transaction.delete(
          'weather_report',
          where: 'page_key = ?',
          whereArgs: [_pageKey(report)],
        );
        // 删除后立即压缩位置，避免后续新增与现有城市占用同一位置。
        await transaction.rawUpdate(
          'UPDATE weather_report SET position = position - 1 WHERE position > ?',
          [position],
        );
      });
    });
    _writeQueue = operation.onError((error, stackTrace) {});
    return operation;
  }

  @override
  Future<void> saveCityOrder(List<WeatherReport> cities) {
    final operation = _writeQueue.then((_) async {
      final database = await _open();
      await database.transaction((transaction) async {
        for (var index = 0; index < cities.length; index++) {
          await transaction.update(
            'weather_report',
            {'position': index + 1},
            where: 'page_key = ?',
            whereArgs: [_pageKey(cities[index])],
          );
        }
      });
    });
    _writeQueue = operation.onError((error, stackTrace) {});
    return operation;
  }

  /// GPS 永远使用 current；城市使用跨服务稳定的 clientId 作为持久 key。
  static String _pageKey(WeatherReport report) {
    if (report.location.origin == LocationOrigin.gps) return 'current';
    final clientId = report.location.clientId ?? report.location.id;
    return 'city:${clientId ?? '${report.location.latitude},${report.location.longitude}'}';
  }

  Future<Database> _open() {
    return _database ??= _openDatabase();
  }

  Future<Database> _openDatabase() async {
    final factory = this.factory ?? databaseFactory;
    final path =
        this.path ?? '${await factory.getDatabasesPath()}/weather_cache.db';
    return factory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (database, version) => _createSchema(database),
        onUpgrade: (database, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await _migrateV1ToV2(database);
          }
        },
      ),
    );
  }

  Future<void> _createSchema(Database database) {
    return database.execute('''
      CREATE TABLE weather_report (
        id INTEGER PRIMARY KEY,
        page_key TEXT UNIQUE,
        location_id TEXT,
        payload TEXT NOT NULL,
        saved_at INTEGER NOT NULL,
        position INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  /// 保留 v1 的 id/payload，并补充 key、位置和唯一索引。
  ///
  /// 原 GPS 数据使用 current；search 与历史 IP 数据使用 city key，既不丢失
  /// 用户报告，也不会把旧 IP 地点误认为实时 GPS。
  Future<void> _migrateV1ToV2(Database database) async {
    await database.execute(
      'ALTER TABLE weather_report ADD COLUMN page_key TEXT',
    );
    await database.execute(
      'ALTER TABLE weather_report ADD COLUMN position INTEGER NOT NULL DEFAULT 0',
    );
    final rows = await database.query('weather_report');
    for (final row in rows) {
      final payload = row['payload'];
      if (payload is! String) continue;
      final report = WeatherReportCodec.tryDecode(payload);
      if (report == null) continue;
      await database.update(
        'weather_report',
        {'page_key': _pageKey(report), 'position': 0},
        where: 'id = ?',
        whereArgs: [row['id']],
      );
    }
    await database.execute(
      'CREATE UNIQUE INDEX weather_report_page_key ON weather_report(page_key)',
    );
  }

  Future<void> close() async {
    await _writeQueue;
    final pending = _database;
    _database = null;
    if (pending != null) {
      final database = await pending;
      await database.close();
    }
  }
}
