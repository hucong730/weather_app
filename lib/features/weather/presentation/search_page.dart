import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/search_controller.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';
import 'package:weather_app/features/weather/presentation/weather_preview_page.dart';
import 'package:weather_app/features/weather/presentation/widgets/location_search_field.dart';
import 'package:weather_app/features/weather/presentation/widgets/search_results_view.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 独立城市搜索页，持有输入框、焦点、防抖定时器和结果列表。
///
/// 输入停止 500ms 后自动搜索；中文输入法组合输入期间不启动请求，
/// 候选词确认上屏后再开始防抖。手动提交立即执行并取消待执行搜索。
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  /// 搜索输入控制器，由当前页面创建并在 dispose 中释放。
  late final TextEditingController _controller;

  /// 输入框焦点节点，打开预览前收起键盘。
  late final FocusNode _focusNode;

  /// 当前待执行的 500ms 防抖任务，新输入和手动提交会将其取消。
  Timer? _debounceTimer;

  /// 是否已有预览路由存活，防止快速点击结果叠加多个全屏页面。
  bool _isOpeningPreview = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(searchControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.searchButton)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              LocationSearchField(
                controller: _controller,
                focusNode: _focusNode,
                autofocus: true,
                isLoading: state.loadState.status == LoadStatus.loading,
                onChanged: _onQueryChanged,
                onSubmitted: _search,
                onSearchPressed: () => _search(_controller.text),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SearchResultsView(
                  state: state,
                  onSelected: _selectLocation,
                  onRetry: () => _search(state.query),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onQueryChanged(String query) {
    _debounceTimer?.cancel();
    final value = _controller.value;
    final composing = value.composing;
    if (value.isComposingRangeValid) {
      final composingText = query.substring(composing.start, composing.end);
      final hasCommittedChinese = RegExp(r'[\u3400-\u9fff]')
          .hasMatch(composingText);
      if (!hasCommittedChinese) {
        // 拼音等组合文本尚未上屏，此时请求会误搜 wu、pin 等中间内容。
        // iOS 中文候选上屏后仍可能保留组合区间，其中出现汉字时不能拦截。
        return;
      }
    }
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) _search(query);
    });
  }

  void _search(String query) {
    _debounceTimer?.cancel();
    ref
        .read(searchControllerProvider.notifier)
        .search(query, Localizations.localeOf(context).languageCode);
  }

  /// 点击结果只打开全屏预览，不立即返回主页。
  ///
  /// 取消/系统返回得到 null 并保留当前搜索页；只有预览“添加”带回报告时，
  /// 才把报告继续 pop 给主页，因此取消不会触发主页天气或缓存变化。
  Future<void> _selectLocation(Location location) async {
    if (_isOpeningPreview) return;
    _isOpeningPreview = true;
    _focusNode.unfocus();
    try {
      // 标记在整个预览存活期间保持，连续点击结果不会叠加多个路由。
      final report = await Navigator.of(context)
          .push<WeatherReport>(WeatherPreviewPage.route(location));
      if (report == null || !mounted) return;
      Navigator.of(context).pop(report);
    } finally {
      _isOpeningPreview = false;
    }
  }
}
