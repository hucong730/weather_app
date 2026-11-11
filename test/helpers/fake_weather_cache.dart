import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/domain/repositories/weather_cache.dart';

class FakeWeatherCache implements WeatherCache {
  WeatherReport? stored;
  List<WeatherReport> reports = [];
  bool failOnLoad = false;
  bool failOnSave = false;
  Future<void> Function(WeatherReport report)? saveHandler;
  final List<WeatherReport> savedReports = [];
  final List<WeatherReport> deletedReports = [];
  final List<List<WeatherReport>> cityOrders = [];

  @override
  Future<List<WeatherReport>> loadAll() async {
    if (failOnLoad) throw Exception('Cache read failed');
    if (reports.isNotEmpty) return reports;
    return stored == null ? [] : [stored!];
  }

  @override
  Future<void> save(WeatherReport report, {required int position}) async {
    if (failOnSave) throw Exception('Cache write failed');
    savedReports.add(report);
    await saveHandler?.call(report);
    // 在异步写入完成后才更新 stored，模拟真实磁盘乱序完成的可能性。
    stored = report;
  }

  @override
  Future<void> delete(WeatherReport report, {required int position}) async {
    if (failOnSave) throw Exception('Cache write failed');
    deletedReports.add(report);
    reports.removeWhere((item) => item.location.id == report.location.id);
  }

  @override
  Future<void> saveCityOrder(List<WeatherReport> cities) async {
    if (failOnSave) throw Exception('Cache write failed');
    cityOrders.add(List.of(cities));
  }
}
