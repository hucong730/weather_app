import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/weather/presentation/weather_page.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 应用根组件，加载持久化设置并配置语言、明暗主题和天气主页。
class WeatherApp extends ConsumerStatefulWidget {
  /// 可选构建器供集成测试关闭动画；生产运行保持 null，不改变系统行为。
  final TransitionBuilder? builder;

  const WeatherApp({super.key, this.builder});

  @override
  ConsumerState<WeatherApp> createState() => _WeatherAppState();
}

class _WeatherAppState extends ConsumerState<WeatherApp> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(settingsControllerProvider.notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsControllerProvider);
    return MaterialApp(
      locale: settings.locale,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: widget.builder,
      themeMode: settings.themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const WeatherPage(),
    );
  }
}
