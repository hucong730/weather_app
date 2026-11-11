import 'package:flutter/material.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/search_state.dart';
import 'package:module_weather/models/location.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/features/weather/presentation/widgets/weather_error_view.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 搜索结果视图，覆盖校验失败、加载、空结果、错误和成功列表。
///
/// 每个结果使用稳定的 location_item_index Key，点击后原样返回 Location。
class SearchResultsView extends StatelessWidget {
  /// 搜索页当前不可变状态，决定显示校验、加载或结果分支。
  final SearchState state;

  /// 点击城市结果时的回调，由页面打开独立天气预览。
  final ValueChanged<Location> onSelected;

  /// 请求失败后点击重试的回调，复用当前关键词重新搜索。
  final VoidCallback onRetry;

  const SearchResultsView({
    super.key,
    required this.state,
    required this.onSelected,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (state.validation == SearchValidation.invalidQuery) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          l10n.invalidQuery,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      );
    }

    return switch (state.loadState.status) {
      LoadStatus.idle => const SizedBox.shrink(),
      LoadStatus.loading => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      LoadStatus.empty => Padding(
        padding: const EdgeInsets.all(16),
        child: Text(l10n.noResults),
      ),
      LoadStatus.error => WeatherErrorView(
        error: state.loadState.error!,
        onRetry: onRetry,
      ),
      LoadStatus.success => ListView.separated(
        shrinkWrap: true,
        itemCount: state.loadState.data!.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final location = state.loadState.data![index];
          return ListTile(
            key: ValueKey('location_item_$index'),
            leading: const Icon(Icons.location_on),
            title: Text(WeatherFormatters.locationName(location, l10n)),
            onTap: () => onSelected(location),
          );
        },
      ),
    };
  }
}
