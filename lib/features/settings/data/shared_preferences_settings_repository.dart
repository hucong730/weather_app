import 'package:module_weather/weather_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/domain/settings_repository.dart';

/// 使用 shared_preferences 保存语言、主题和服务选择，不存放天气或凭据。
class SharedPreferencesSettingsRepository implements SettingsRepository {
  /// SharedPreferences 中保存语言枚举名称的键。
  static const _languageKey = 'language_preference';

  /// SharedPreferences 中保存主题枚举名称的键。
  static const _themeKey = 'theme_preference';

  /// SharedPreferences 中保存天气服务枚举名称的键。
  static const _weatherProviderKey = 'weather_provider_preference';

  const SharedPreferencesSettingsRepository();

  @override
  Future<AppSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return AppSettings(
      language: _enumValue(
        LanguagePreference.values,
        preferences.getString(_languageKey),
        LanguagePreference.system,
      ),
      theme: _enumValue(
        ThemePreference.values,
        preferences.getString(_themeKey),
        ThemePreference.system,
      ),
      weatherProvider: _enumValue(
        WeatherProviderType.values,
        preferences.getString(_weatherProviderKey),
        WeatherProviderType.qweather,
      ),
    );
  }

  @override
  Future<void> save(AppSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_languageKey, settings.language.name);
    await preferences.setString(_themeKey, settings.theme.name);
    await preferences.setString(
      _weatherProviderKey,
      settings.weatherProvider.name,
    );
  }

  /// 对未知或旧版本字符串使用明确默认值，避免设置异常阻止 App 启动。
  static T _enumValue<T extends Enum>(
    List<T> values,
    String? stored,
    T fallback,
  ) {
    return values.asNameMap()[stored] ?? fallback;
  }
}
