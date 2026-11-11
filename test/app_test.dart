import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/domain/settings_repository.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:module_weather/models/location.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';

import 'helpers/fake_weather_cache.dart';

class ManualLocationResolver implements LocationResolver {
  @override
  Future<Location?> resolve({String languageCode = 'en'}) async => null;
}

class FakeAppSettingsRepository implements SettingsRepository {
  AppSettings stored;

  FakeAppSettingsRepository([this.stored = const AppSettings()]);

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
  }
}

Future<void> pumpAppWithLocale(
  WidgetTester tester,
  Locale locale, {
  SettingsRepository? settingsRepository,
}) async {
  tester.binding.platformDispatcher.localesTestValue = [locale];
  addTearDown(tester.binding.platformDispatcher.clearLocalesTestValue);
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox());
    await tester.idle();
    (tester.binding as AutomatedTestWidgetsFlutterBinding).elapseBlocking(
      Duration.zero,
    );
  });
  await tester.runAsync(() async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationResolverProvider.overrideWithValue(ManualLocationResolver()),
          weatherCacheProvider.overrideWith((ref) async => FakeWeatherCache()),
          settingsRepositoryProvider.overrideWithValue(
            settingsRepository ?? FakeAppSettingsRepository(),
          ),
        ],
        child: const WeatherApp(),
      ),
    );
    await tester.pump();
    await tester.pump();
    await Future<void>.delayed(Duration.zero);
  });
}

void main() {
  testWidgets('app uses English copy', (tester) async {
    await pumpAppWithLocale(tester, const Locale('en'));

    expect(find.byKey(const Key('weather_home_page')), findsOneWidget);
    expect(
      find.text(
        'Unable to get your current position. Check Location Services and location permission, then retry, or search for a city.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('app uses simplified Chinese copy', (tester) async {
    await pumpAppWithLocale(tester, const Locale('zh'));

    expect(find.byKey(const Key('weather_home_page')), findsOneWidget);
    expect(find.text('无法获取当前位置。请检查系统定位服务和定位权限后重试，也可以手动搜索城市。'), findsOneWidget);
  });

  testWidgets('unsupported locale falls back to English', (tester) async {
    await pumpAppWithLocale(tester, const Locale('fr'));

    expect(find.byKey(const Key('weather_home_page')), findsOneWidget);
  });

  testWidgets('app applies persisted language and dark theme', (tester) async {
    final repository = FakeAppSettingsRepository(
      const AppSettings(
        language: LanguagePreference.zh,
        theme: ThemePreference.dark,
      ),
    );

    await pumpAppWithLocale(
      tester,
      const Locale('en'),
      settingsRepository: repository,
    );

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('zh'));
    expect(app.themeMode, ThemeMode.dark);
    expect(app.darkTheme, isNotNull);
    expect(find.byKey(const Key('weather_home_page')), findsOneWidget);
  });
}
