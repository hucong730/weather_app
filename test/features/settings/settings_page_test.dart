import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/settings/domain/settings_repository.dart';
import 'package:weather_app/features/settings/presentation/settings_page.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/data/datasources/device_location_data_source.dart';
import 'package:weather_app/l10n/app_localizations.dart';

class FakeSettingsPageRepository implements SettingsRepository {
  AppSettings stored = const AppSettings();

  @override
  Future<AppSettings> load() async => stored;

  @override
  Future<void> save(AppSettings settings) async {
    stored = settings;
  }
}

class FakeSettingsLocationGateway implements DeviceLocationGateway {
  LocationPermission permission = LocationPermission.denied;
  LocationPermission requested = LocationPermission.whileInUse;
  int requests = 0;
  int settingsOpened = 0;

  @override
  Future<bool> isLocationServiceEnabled() async => true;

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requests++;
    permission = requested;
    return permission;
  }

  @override
  Future<bool> openAppSettings() async {
    settingsOpened++;
    return true;
  }

  @override
  Future<Position> getCurrentPosition(LocationSettings settings) {
    throw UnimplementedError();
  }
}

void main() {
  late FakeSettingsPageRepository repository;
  late FakeSettingsLocationGateway gateway;

  setUp(() {
    repository = FakeSettingsPageRepository();
    gateway = FakeSettingsLocationGateway();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          settingsRepositoryProvider.overrideWithValue(repository),
          deviceLocationDataSourceProvider.overrideWithValue(
            DeviceLocationDataSource(gateway: gateway),
          ),
        ],
        child: Consumer(
          builder: (context, ref, _) {
            final settings = ref.watch(settingsControllerProvider);
            return MaterialApp(
              locale: settings.locale,
              themeMode: settings.themeMode,
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const SettingsPage(),
            );
          },
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
  }

  testWidgets('language theme and source information are configurable', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.textContaining('Weather data by QWeather'), findsOneWidget);
    expect(find.textContaining('QWeather Icons'), findsOneWidget);

    await tester.tap(find.byKey(const Key('language_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('简体中文').last);
    await tester.pumpAndSettle();
    expect(repository.stored.language, LanguagePreference.zh);

    await tester.tap(find.byKey(const Key('theme_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('深色').last);
    await tester.pumpAndSettle();
    expect(repository.stored.theme, ThemePreference.dark);
    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.locale, const Locale('zh'));
    expect(app.themeMode, ThemeMode.dark);
  });

  testWidgets('weather provider can switch and updates source attribution', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(find.text('Weather service'), findsOneWidget);
    expect(find.textContaining('Weather data by QWeather'), findsOneWidget);
    await tester.tap(find.byKey(const Key('weather_provider_dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open-Meteo').last);
    await tester.pumpAndSettle();

    expect(repository.stored.weatherProvider.name, 'openMeteo');
    expect(find.textContaining('Weather data by Open-Meteo'), findsOneWidget);
    expect(find.textContaining('Weather data by QWeather'), findsNothing);
  });

  testWidgets('city management entry opens an empty management page', (
    tester,
  ) async {
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('city_management_entry')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('city_management_page')), findsOneWidget);
    expect(find.text('No added cities'), findsOneWidget);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('permission switch requests authorization when enabled', (
    tester,
  ) async {
    await pumpSettings(tester);

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('location_permission_switch')),
          )
          .value,
      isFalse,
    );
    await tester.tap(find.byKey(const Key('location_permission_switch')));
    await tester.pumpAndSettle();

    expect(gateway.requests, 1);
    expect(gateway.settingsOpened, 0);
    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('location_permission_switch')),
          )
          .value,
      isTrue,
    );
  });

  testWidgets('permanent denial opens system settings instead of fake grant', (
    tester,
  ) async {
    gateway.permission = LocationPermission.deniedForever;
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('location_permission_switch')));
    await tester.pumpAndSettle();

    expect(gateway.requests, 0);
    expect(gateway.settingsOpened, 1);
  });

  testWidgets('granted permission opens system settings when switched off', (
    tester,
  ) async {
    gateway.permission = LocationPermission.whileInUse;
    await pumpSettings(tester);

    await tester.tap(find.byKey(const Key('location_permission_switch')));
    await tester.pumpAndSettle();

    expect(gateway.settingsOpened, 1);
  });

  testWidgets('resuming settings refreshes the real permission state', (
    tester,
  ) async {
    await pumpSettings(tester);
    gateway.permission = LocationPermission.whileInUse;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<SwitchListTile>(
            find.byKey(const Key('location_permission_switch')),
          )
          .value,
      isTrue,
    );
  });
}
