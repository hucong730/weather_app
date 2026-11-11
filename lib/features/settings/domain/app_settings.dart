import 'package:flutter/material.dart';
import 'package:module_network/models/json_model.dart';
import 'package:module_weather/weather_provider.dart';

/// 用户语言偏好；system 表示不使用显式 locale，继续跟随设备。
enum LanguagePreference { system, en, zh }

/// 用户主题偏好；system 对应 MaterialApp 的系统明暗模式。
enum ThemePreference { system, light, dark }

/// 应用设置领域模型，同时提供 MaterialApp 需要的 locale/themeMode 映射。
class AppSettings extends JsonModel {
  /// 界面语言偏好，默认跟随系统；动态 API 地名不受该字段影响。
  final LanguagePreference language;

  /// MaterialApp 使用的浅色、深色或跟随系统主题偏好。
  final ThemePreference theme;

  /// 当前天气服务，决定后续搜索和天气刷新使用的适配器。
  final WeatherProviderType weatherProvider;

  const AppSettings({
    this.language = LanguagePreference.system,
    this.theme = ThemePreference.system,
    this.weatherProvider = WeatherProviderType.qweather,
  });

  Locale? get locale => switch (language) {
    LanguagePreference.system => null,
    LanguagePreference.en => const Locale('en'),
    LanguagePreference.zh => const Locale('zh'),
  };

  ThemeMode get themeMode => switch (theme) {
    ThemePreference.system => ThemeMode.system,
    ThemePreference.light => ThemeMode.light,
    ThemePreference.dark => ThemeMode.dark,
  };

  @override
  AppSettings copyWith({
    LanguagePreference? language,
    ThemePreference? theme,
    WeatherProviderType? weatherProvider,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      weatherProvider: weatherProvider ?? this.weatherProvider,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'language': language.name,
    'theme': theme.name,
    'weather_provider': weatherProvider.name,
  };

  @override
  bool operator ==(Object other) {
    return other is AppSettings &&
        other.language == language &&
        other.theme == theme &&
        other.weatherProvider == weatherProvider;
  }

  @override
  int get hashCode => Object.hash(language, theme, weatherProvider);
}
