import 'package:weather_app/features/settings/domain/app_settings.dart';

/// 设置持久化边界，隔离 Controller 与 shared_preferences 的具体实现。
abstract interface class SettingsRepository {
  /// 读取设置；从未保存或值不可识别时由实现回退到系统默认。
  Future<AppSettings> load();

  /// 保存完整设置快照，避免语言和主题使用不一致的半更新状态。
  Future<void> save(AppSettings settings);
}
