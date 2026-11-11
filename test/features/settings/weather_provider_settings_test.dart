import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:module_weather/weather_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/domain/settings_repository.dart';

class MemorySettingsRepository implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'weather provider defaults to QWeather and persists complete settings',
    () async {
      final repository = MemorySettingsRepository();
      final container = ProviderContainer(
        overrides: [settingsRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(
        settingsControllerProvider,
        (_, _) {},
      );
      addTearDown(subscription.close);
      final controller = container.read(settingsControllerProvider.notifier);

      expect(
        container.read(settingsControllerProvider).weatherProvider,
        WeatherProviderType.qweather,
      );
      await controller.setLanguage(LanguagePreference.zh);
      await controller.setWeatherProvider(WeatherProviderType.openMeteo);

      final state = container.read(settingsControllerProvider);
      expect(state.language, LanguagePreference.zh);
      expect(state.weatherProvider, WeatherProviderType.openMeteo);
      expect(repository.stored, state);
    },
  );

  test(
    'SharedPreferences restores Open-Meteo and defaults old settings',
    () async {
      SharedPreferences.setMockInitialValues({});
      final repository = const SharedPreferencesSettingsRepository();
      final initial = await repository.load();
      expect(initial.weatherProvider, WeatherProviderType.qweather);

      await repository.save(
        initial.copyWith(weatherProvider: WeatherProviderType.openMeteo),
      );

      final restored = await const SharedPreferencesSettingsRepository().load();
      expect(restored.weatherProvider, WeatherProviderType.openMeteo);
    },
  );
}
