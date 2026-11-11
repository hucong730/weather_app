import 'package:flutter/material.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 城市搜索输入框，统一处理加载禁用、键盘搜索和右侧提交按钮。
///
/// 输入校验和网络请求交由 SearchController，组件自身不执行业务逻辑；
/// onChanged 交给页面实现防抖，避免在可复用组件中直接持有定时器。
class LocationSearchField extends StatelessWidget {
  /// 由搜索页持有和释放的文本控制器，组件不负责其生命周期。
  final TextEditingController controller;

  /// 输入框焦点节点，供页面控制进入搜索页后的键盘行为。
  final FocusNode focusNode;

  /// 是否正在请求；加载时禁用手动提交，防止重复搜索。
  final bool isLoading;

  /// 是否在组件首次显示时自动聚焦输入框。
  final bool autofocus;

  /// 输入变化回调，页面在此执行校验和 500ms 防抖。
  final ValueChanged<String> onChanged;

  /// 键盘搜索动作回调，立即提交当前关键词并取消待执行防抖。
  final ValueChanged<String> onSubmitted;

  /// 右侧搜索按钮回调，与键盘提交共用同一搜索逻辑。
  final VoidCallback onSearchPressed;

  const LocationSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSearchPressed,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: controller,
      focusNode: focusNode,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: l10n.searchHint,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: IconButton(
          onPressed: isLoading ? null : onSearchPressed,
          tooltip: l10n.searchButton,
          icon: const Icon(Icons.arrow_forward),
        ),
      ),
      onSubmitted: isLoading ? null : onSubmitted,
    );
  }
}
