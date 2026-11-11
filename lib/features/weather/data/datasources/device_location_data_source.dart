import 'package:geolocator/geolocator.dart';
import 'package:module_weather/models/location.dart';

/// 设备定位能力抽象，隔离 geolocator 静态 API，便于测试权限分支。
abstract interface class DeviceLocationGateway {
  /// 查询系统定位服务是否开启，与应用内权限状态分开处理。
  Future<bool> isLocationServiceEnabled();

  /// 读取当前 App 的真实定位权限，不缓存系统授权结果。
  Future<LocationPermission> checkPermission();

  /// 发起一次前台定位权限申请并返回系统最终结果。
  Future<LocationPermission> requestPermission();

  /// 打开当前 App 的系统设置页，供用户修改权限。
  Future<bool> openAppSettings();

  /// 按指定精度和时间限制读取一次设备坐标。
  Future<Position> getCurrentPosition(LocationSettings settings);
}

/// geolocator 的真实实现，只负责转发调用，不包含业务决策。
class GeolocatorDeviceLocationGateway implements DeviceLocationGateway {
  @override
  Future<bool> isLocationServiceEnabled() {
    return Geolocator.isLocationServiceEnabled();
  }

  @override
  Future<LocationPermission> checkPermission() {
    return Geolocator.checkPermission();
  }

  @override
  Future<LocationPermission> requestPermission() {
    return Geolocator.requestPermission();
  }

  @override
  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) {
    return Geolocator.getCurrentPosition(locationSettings: settings);
  }
}

/// 前台 GPS 数据源，处理服务开关、权限请求和低精度单次定位。
///
/// 平台定位设置等待 10 秒，外层默认 12 秒兜底；拒绝授权、永久拒绝、
/// 服务关闭或插件异常均返回 null，让上层显示手动搜索引导，不使用 IP 兜底，
/// 也不申请后台定位。
class DeviceLocationDataSource {
  /// 平台定位能力边界，测试可替换为 Fake，不直接访问真实设备。
  final DeviceLocationGateway _gateway;

  /// 外层定位等待上限，防止平台未按 timeLimit 结束时页面永久等待。
  final Duration requestTimeout;

  DeviceLocationDataSource({
    DeviceLocationGateway? gateway,
    this.requestTimeout = const Duration(seconds: 12),
  }) : _gateway = gateway ?? GeolocatorDeviceLocationGateway();

  /// 读取系统真实权限，不维护一个可能与系统不一致的应用内授权状态。
  Future<LocationPermission> checkPermission() => _gateway.checkPermission();

  /// 打开当前 App 的系统设置，供用户撤销权限或处理永久拒绝。
  Future<bool> openAppSettings() => _gateway.openAppSettings();

  /// 响应设置页开关：开启时请求前台权限，关闭或永久拒绝时跳系统设置。
  ///
  /// 插件异常按未授权返回，UI 不会把失败误显示为已授权；定位服务开关与
  /// 权限开关是不同概念，本方法只处理权限。
  Future<LocationPermission> changePermission(bool enable) async {
    try {
      var permission = await _gateway.checkPermission();
      if (!enable || permission == LocationPermission.deniedForever) {
        await _gateway.openAppSettings();
        return permission;
      }
      if (permission == LocationPermission.denied) {
        permission = await _gateway.requestPermission();
      }
      return permission;
    } on Exception {
      return LocationPermission.denied;
    }
  }

  /// 获取一次当前位置；失败时返回 null，不向用户暴露平台异常细节。
  ///
  /// 部分平台在没有可用坐标时可能不会按 timeLimit 结束，因此再用
  /// requestTimeout 兜底，避免页面永久停留在“正在获取位置”。
  Future<Location?> getCurrentLocation() async {
    try {
      if (!await _gateway.isLocationServiceEnabled()) return null;

      var permission = await _gateway.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await _gateway.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await _gateway
          .getCurrentPosition(
            const LocationSettings(
              accuracy: LocationAccuracy.low,
              timeLimit: Duration(seconds: 10),
            ),
          )
          .timeout(requestTimeout);
      return Location(
        latitude: position.latitude,
        longitude: position.longitude,
        origin: LocationOrigin.gps,
      );
    } on Exception {
      return null;
    }
  }
}
