import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/features/settings/data/shared_preferences_settings_repository.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('empty preferences use system language and theme', () async {
    final settings = await SharedPreferencesSettingsRepository().load();

    expect(settings.language, LanguagePreference.system);
    expect(settings.theme, ThemePreference.system);
  });

  test('language and theme survive a repository recreation', () async {
    const expected = AppSettings(
      language: LanguagePreference.zh,
      theme: ThemePreference.dark,
    );
    await SharedPreferencesSettingsRepository().save(expected);

    final restored = await SharedPreferencesSettingsRepository().load();

    expect(restored.language, LanguagePreference.zh);
    expect(restored.theme, ThemePreference.dark);
  });
}
