import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:weather_app/features/weather/application/weather_home_controller.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 已添加城市管理页：定位页不参与，搜索城市支持删除和拖拽排序。
///
/// 页面直接观察主页的同一组有序条目，操作会立即反映到 PageView、底部
/// 指示器及 SQLite；无需在返回主页时再同步另一份列表状态。
class CityManagementPage extends ConsumerWidget {
  const CityManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final cities = ref
        .watch(weatherHomeControllerProvider)
        .entries
        .skip(1)
        .toList(growable: false);

    return Scaffold(
      key: const Key('city_management_page'),
      appBar: AppBar(title: Text(l10n.cityManagement)),
      body: SafeArea(
        child: cities.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_city,
                        size: 48,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noSavedCities,
                        style: Theme.of(context).textTheme.titleMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.noSavedCitiesHint, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                buildDefaultDragHandles: false,
                itemCount: cities.length,
                onReorder: (oldIndex, newIndex) {
                  // 旧版 Flutter 的 newIndex 是移除前的插入位置；向下拖拽时
                  // 先减一，转换为 Controller 使用的最终列表下标。
                  final targetIndex = newIndex > oldIndex
                      ? newIndex - 1
                      : newIndex;
                  ref
                      .read(weatherHomeControllerProvider.notifier)
                      .reorderCities(oldIndex, targetIndex);
                },
                itemBuilder: (context, index) {
                  final entry = cities[index];
                  final location = entry.location!;
                  final name = location.name ?? '';
                  final region = [location.admin1, location.country]
                      .whereType<String>()
                      .where((part) => part.isNotEmpty)
                      .toSet()
                      .join(' · ');
                  return Card(
                    key: ValueKey('managed_city_${entry.key}'),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: ReorderableDragStartListener(
                        key: ValueKey('reorder_city_${entry.key}'),
                        index: index,
                        child: Semantics(
                          label: l10n.reorderCity(name),
                          child: const Icon(Icons.drag_handle),
                        ),
                      ),
                      title: Text(name),
                      subtitle: region.isEmpty ? null : Text(region),
                      trailing: IconButton(
                        key: ValueKey('delete_city_${entry.key}'),
                        tooltip: l10n.deleteCity(name),
                        onPressed: () {
                          ref
                              .read(weatherHomeControllerProvider.notifier)
                              .deleteCity(entry.key);
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
