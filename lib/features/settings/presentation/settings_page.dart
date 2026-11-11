import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:module_weather/weather_provider.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/settings/domain/app_settings.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/presentation/city_management_page.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 独立设置页，管理语言、主题、真实定位权限和 App/数据来源信息。
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(settingsControllerProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 用户可能刚从系统设置返回，必须重新读取而不是沿用旧开关状态。
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(locationPermissionProvider);
    }
  }

  /// 开关只发起系统请求/跳转，最终结果由 Provider 重新查询确认。
  Future<void> _changePermission(bool enable) async {
    await ref.read(deviceLocationDataSourceProvider).changePermission(enable);
    if (mounted) ref.invalidate(locationPermissionProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider);
    final permission = ref.watch(locationPermissionProvider);
    final granted =
        permission.value == LocationPermission.whileInUse ||
        permission.value == LocationPermission.always;

    return Scaffold(
      key: const Key('settings_page'),
      appBar: AppBar(title: Text(l10n.settings)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: ListTile(
                title: Text(l10n.language),
                subtitle: DropdownButton<LanguagePreference>(
                  key: const Key('language_dropdown'),
                  isExpanded: true,
                  value: settings.language,
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setLanguage(value);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: LanguagePreference.system,
                      child: Text(l10n.followSystem),
                    ),
                    const DropdownMenuItem(
                      value: LanguagePreference.zh,
                      child: Text('简体中文'),
                    ),
                    const DropdownMenuItem(
                      value: LanguagePreference.en,
                      child: Text('English'),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: Text(l10n.theme),
                subtitle: DropdownButton<ThemePreference>(
                  key: const Key('theme_dropdown'),
                  isExpanded: true,
                  value: settings.theme,
                  onChanged: (value) {
                    if (value != null) {
                      ref
                          .read(settingsControllerProvider.notifier)
                          .setTheme(value);
                    }
                  },
                  items: [
                    DropdownMenuItem(
                      value: ThemePreference.system,
                      child: Text(l10n.followSystem),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.light,
                      child: Text(l10n.lightTheme),
                    ),
                    DropdownMenuItem(
                      value: ThemePreference.dark,
                      child: Text(l10n.darkTheme),
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                title: Text(l10n.weatherProvider),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<WeatherProviderType>(
                      key: const Key('weather_provider_dropdown'),
                      isExpanded: true,
                      value: settings.weatherProvider,
                      onChanged: (value) {
                        if (value != null) {
                          ref
                              .read(settingsControllerProvider.notifier)
                              .setWeatherProvider(value);
                        }
                      },
                      items: [
                        DropdownMenuItem(
                          value: WeatherProviderType.qweather,
                          child: Text(l10n.qWeatherService),
                        ),
                        DropdownMenuItem(
                          value: WeatherProviderType.openMeteo,
                          child: Text(l10n.openMeteoService),
                        ),
                      ],
                    ),
                    Text(l10n.weatherProviderHint),
                  ],
                ),
              ),
            ),
            Card(
              child: ListTile(
                key: const Key('city_management_entry'),
                leading: const Icon(Icons.location_city),
                title: Text(l10n.cityManagement),
                subtitle: Text(l10n.cityManagementHint),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // 与主页共享 ProviderScope，管理结果立即作用于同一组城市。
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const CityManagementPage(),
                    ),
                  );
                },
              ),
            ),
            Card(
              child: Column(
                children: [
                  SwitchListTile(
                    key: const Key('location_permission_switch'),
                    title: Text(l10n.locationPermission),
                    value: granted,
                    onChanged: permission.isLoading ? null : _changePermission,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Text(l10n.permissionSystemHint),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.aboutApp, style: Theme.of(context).textTheme.titleMedium),
            Card(
              child: ListTile(
                title: Text(l10n.appTitle),
                subtitle: Text(l10n.appDescription),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.dataSources,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      WeatherFormatters.weatherSource(
                        settings.weatherProvider,
                        l10n,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(l10n.iconSource),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
