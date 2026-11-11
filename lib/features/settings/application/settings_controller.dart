import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_weather/weather_provider.dart';
import 'package:weather_app/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/domain/settings_repository.dart';

/// 设置存储 Provider，可在测试中以内存 Repository 覆盖。
final settingsRepositoryProvider = Provider<SettingsRepository>(
  (ref) => const SharedPreferencesSettingsRepository(),
);

/// 全局设置 Provider，生命周期与 ProviderScope 一致。
final settingsControllerProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// 协调设置读取、即时 UI 更新和持久化。
class SettingsController extends Notifier<AppSettings> {
  /// 是否已开始读取持久化设置，防止主页和设置页重复加载覆盖新修改。
  bool _loaded = false;

  @override
  AppSettings build() => const AppSettings();

  /// 只在首次启动读取一次；读取失败时保留系统默认，不阻塞主页。
  Future<void> load() async {
    if (_loaded) return;
    _loaded = true;
    try {
      state = await ref.read(settingsRepositoryProvider).load();
    } on Exception {
      // 本地偏好不可读时使用当前默认设置，用户仍可重新修改并保存。
    }
  }

  /// 立即更新语言，再异步保存完整快照。
  Future<void> setLanguage(LanguagePreference language) {
    return _update(state.copyWith(language: language));
  }

  /// 立即更新主题，再异步保存完整快照。
  Future<void> setTheme(ThemePreference theme) {
    return _update(state.copyWith(theme: theme));
  }

  /// 立即切换天气适配器；主页保留城市并隔离旧服务请求。
  Future<void> setWeatherProvider(WeatherProviderType provider) {
    return _update(state.copyWith(weatherProvider: provider));
  }

  Future<void> _update(AppSettings settings) async {
    state = settings;
    try {
      await ref.read(settingsRepositoryProvider).save(settings);
    } on Exception {
      // 保存失败只影响下次启动恢复，不撤销当前已经生效的设置。
    }
  }
}
