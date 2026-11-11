import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/domain/settings_repository.dart';

class FakeSettingsRepository implements SettingsRepository {
  AppSettings stored = const AppSettings();
  int saveCalls = 0;

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    saveCalls++;
    stored = settings;
  }
}

void main() {
  late FakeSettingsRepository repository;
  late ProviderContainer container;
  late SettingsController controller;

  setUp(() {
    repository = FakeSettingsRepository();
    container = ProviderContainer(
      overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
    );
    final subscription = container.listen(
      settingsControllerProvider,
      (_, _) {},
    );
    addTearDown(subscription.close);
    addTearDown(container.dispose);
    controller = container.read(settingsControllerProvider.notifier);
  });

  test(
    'settings start with system defaults and load persisted values',
    () async {
      repository.stored = const AppSettings(
        language: LanguagePreference.en,
        theme: ThemePreference.dark,
      );

      expect(container.read(settingsControllerProvider), const AppSettings());
      await controller.load();

      final state = container.read(settingsControllerProvider);
      expect(state.language, LanguagePreference.en);
      expect(state.theme, ThemePreference.dark);
      expect(state.locale, const Locale('en'));
      expect(state.themeMode, ThemeMode.dark);
    },
  );

  test('language and theme changes apply immediately and persist', () async {
    await controller.setLanguage(LanguagePreference.zh);
    await controller.setTheme(ThemePreference.light);

    final state = container.read(settingsControllerProvider);
    expect(state.locale, const Locale('zh'));
    expect(state.themeMode, ThemeMode.light);
    expect(repository.stored, state);
    expect(repository.saveCalls, 2);
  });
}
