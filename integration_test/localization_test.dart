import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:module_weather/models/location.dart';
import 'package:weather_app/app.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/domain/repositories/location_resolver.dart';

class ManualLocationResolver implements LocationResolver {
  @override
  Future<Location?> resolve({String languageCode = 'en'}) async => null;
}

/// 在设备上通过真实和风接口验证已有中文城市的地名会随语言更新。
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('existing Chinese city is localized after switching to English', (
    tester,
  ) async {
    Future<void> settle() async {
      await tester.pumpAndSettle(
        const Duration(milliseconds: 100),
        EnginePhase.sendSemanticsUpdate,
        const Duration(seconds: 60),
      );
    }

    Future<void> selectLanguage(String label) async {
      await tester.tap(find.byKey(const Key('settings_button')));
      await settle();
      await tester.tap(find.byKey(const Key('language_dropdown')));
      await settle();
      await tester.tap(find.text(label).last);
      await settle();
      await tester.tap(find.byType(BackButton));
      await settle();
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          locationResolverProvider.overrideWithValue(ManualLocationResolver()),
        ],
        child: WeatherApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: true),
            child: child!,
          ),
        ),
      ),
    );
    await settle();
    await selectLanguage('简体中文');

    await tester.tap(find.byKey(const Key('search_button')));
    await settle();
    await tester.enterText(find.byType(TextField), '武汉');
    await tester.pump(const Duration(milliseconds: 600));
    await settle();
    await tester.tap(find.byKey(const Key('location_item_0')));
    await settle();
    await tester.tap(find.byKey(const Key('add_location_button')));
    await settle();
    expect(find.text('武汉'), findsOneWidget);

    await selectLanguage('English');

    final title = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const Key('weather_city_sticky_header')),
        matching: find.byType(Text),
      ),
    );
    expect(title.data, 'Wuhan');
    expect(find.text('武汉'), findsNothing);
  });
}
