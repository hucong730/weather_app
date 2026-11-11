import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:weather_app/features/weather/application/search_state.dart';

/// 搜索控制器 Provider，离开搜索页后自动释放并取消未完成请求。
final searchControllerProvider =
    NotifierProvider.autoDispose<SearchController, SearchState>(
      SearchController.new,
    );

/// 管理关键词校验、搜索加载状态、HTTP 取消和响应竞态。
///
/// _requestId 单调递增，只有最后一次请求允许更新状态，防止慢响应覆盖新关键词。
class SearchController extends Notifier<SearchState> {
  /// 单调递增的请求编号，只让最后一次有效搜索提交状态。
  int _requestId = 0;

  /// 当前搜索的取消令牌，新搜索、清空和销毁都会取消它。
  CancelToken? _cancelToken;

  @override
  SearchState build() {
    // 新服务生效后取消旧搜索并废弃结果，避免混用不同服务的地点 ID。
    ref.watch(weatherRepositoryProvider);
    ref.onDispose(() {
      _requestId++;
      _cancelPendingRequest();
    });
    return const SearchState.idle();
  }

  /// 按城市名称搜索，支持单字城市名，不接受邮政编码或坐标。
  ///
  /// 空白以及包含数字的输入仅显示校验提示，不发送请求；同一关键词正在
  /// 加载时去重。新搜索会真正取消旧 HTTP，请求编号再兜底丢弃过期结果。
  Future<void> search(String query, String languageCode) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty || RegExp(r'\d').hasMatch(trimmedQuery)) {
      _requestId++;
      _cancelPendingRequest();
      state = SearchState(
        query: trimmedQuery,
        validation: SearchValidation.invalidQuery,
        loadState: const LoadState.idle(),
      );
      return;
    }

    if (state.loadState.status == LoadStatus.loading &&
        state.query == trimmedQuery) {
      return;
    }

    _cancelPendingRequest();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    final requestId = ++_requestId;
    state = state.copyWith(
      query: trimmedQuery,
      validation: SearchValidation.none,
      loadState: const LoadState.loading(),
    );

    final result = await ref
        .read(weatherRepositoryProvider)
        .searchLocations(trimmedQuery, languageCode, cancelToken: cancelToken);
    if (requestId != _requestId) return;

    _cancelToken = null;
    state = state.copyWith(
      loadState: LoadState.fromResult(
        result,
        isEmpty: (locations) => locations.isEmpty,
      ),
    );
  }

  /// 清空结果并取消仍在执行的搜索，避免空页面继续消耗网络请求。
  void clearResults() {
    _requestId++;
    _cancelPendingRequest();
    state = const SearchState.idle();
  }

  /// 取消当前令牌并解除引用；CancelToken 本身不需要 dispose。
  void _cancelPendingRequest() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}
