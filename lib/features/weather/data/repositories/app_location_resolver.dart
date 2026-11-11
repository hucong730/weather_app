import 'package:weather_app/features/weather/data/datasources/device_location_data_source.dart';
import 'package:module_weather/models/location.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';

/// 应用的自动地点解析器，只使用前台 GPS。
///
/// 不进行 IP 请求；定位不可用时直接返回 null，由 Controller 显示手动搜索。
class AppLocationResolver implements LocationResolver {
  /// 前台 GPS 数据源，负责实际权限检查与单次坐标读取。
  final DeviceLocationDataSource deviceLocation;

  const AppLocationResolver({required this.deviceLocation});

  @override
  Future<Location?> resolve({String languageCode = 'en'}) {
    return deviceLocation.getCurrentLocation();
  }
}
