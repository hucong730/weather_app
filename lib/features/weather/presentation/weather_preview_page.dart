import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/settings/application/settings_controller.dart';
import 'package:weather_app/features/weather/application/weather_preview_controller.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_error_view.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_report_content.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_status_message.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 搜索结果的全屏天气预览页，提供“取消”和“添加”确认操作。
///
/// 页面只观察独立预览状态；取消或系统返回不返回数据，添加只在成功取得
/// 完整报告后可用，并把该报告原样返回给搜索页，避免主页重复请求。
class WeatherPreviewPage extends ConsumerStatefulWidget {
  /// 用户在搜索结果中明确选择、等待预览天气的地点。
  final Location location;

  const WeatherPreviewPage({super.key, required this.location});

  /// 构造带独立 ProviderScope 的全屏路由。
  ///
  /// 每条预览路由都创建自己的 Controller，即使调用方意外叠加两个页面，
  /// 不同城市的加载状态也不会互相覆盖。
  static MaterialPageRoute<WeatherReport> route(Location location) {
    return MaterialPageRoute<WeatherReport>(
      fullscreenDialog: true,
      builder: (_) => ProviderScope(
        overrides: [
          weatherPreviewControllerProvider.overrideWith(
            WeatherPreviewController.new,
          ),
        ],
        child: WeatherPreviewPage(location: location),
      ),
    );
  }

  @override
  ConsumerState<WeatherPreviewPage> createState() => _WeatherPreviewPageState();
}

class _WeatherPreviewPageState extends ConsumerState<WeatherPreviewPage> {
  /// 是否已经开始关闭路由，防止取消和添加连续点击造成重复 pop。
  bool _isClosing = false;

  /// 统一关闭入口，保证连续点击取消/添加不会多 pop 一层搜索或主页路由。
  void _close([WeatherReport? report]) {
    if (_isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop(report);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  /// 加载或重试当前城市，语言跟随预览页所在 locale。
  void _load() {
    ref
        .read(weatherPreviewControllerProvider.notifier)
        .load(
          widget.location,
          languageCode: Localizations.localeOf(context).languageCode,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final selectedProvider = ref.watch(
      settingsControllerProvider.select((settings) => settings.weatherProvider),
    );
    // 服务切换后旧预览 Controller 已失效，使用新适配器重新加载同一地点。
    ref.listen(settingsControllerProvider, (previous, next) {
      if (previous?.weatherProvider == next.weatherProvider) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    });
    final state = ref.watch(weatherPreviewControllerProvider);
    final report = state.data;
    final canAdd = state.status == LoadStatus.success && report != null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: TextButton(
          key: const Key('cancel_preview_button'),
          onPressed: _close,
          child: Text(l10n.cancel),
        ),
        actions: [
          TextButton(
            key: const Key('add_location_button'),
            onPressed: canAdd ? () => _close(report) : null,
            child: Text(l10n.add),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _previewContent(state),
                const SizedBox(height: 24),
                Text(
                  WeatherFormatters.weatherSource(
                    report?.provider ?? selectedProvider,
                    l10n,
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 将独立加载状态映射为加载、错误或共享天气内容。
  Widget _previewContent(LoadState<WeatherReport> state) {
    final l10n = AppLocalizations.of(context);
    return switch (state.status) {
      LoadStatus.idle || LoadStatus.loading => WeatherStatusMessage(
        icon: Icons.cloud_download,
        text: l10n.loading,
        showProgress: true,
      ),
      LoadStatus.empty => WeatherStatusMessage(
        icon: Icons.search,
        text: l10n.searchPrompt,
      ),
      LoadStatus.error => WeatherErrorView(error: state.error!, onRetry: _load),
      LoadStatus.success => WeatherReportContent(report: state.data!),
    };
  }
}
