import 'package:module_network/state/load_state.dart';
import 'package:module_weather/models/location.dart';

/// 搜索输入的本地校验状态，与网络加载状态分开，避免混淆。
enum SearchValidation { none, invalidQuery }

/// 搜索页不可变状态，保存当前关键词、校验结果和城市列表加载状态。
class SearchState {
  /// 当前输入框中的原始关键词，由搜索 Controller 统一裁剪和校验。
  final String query;

  /// 本地输入校验结果，不与服务端空结果或网络错误混用。
  final SearchValidation validation;

  /// 城市列表的请求阶段、数据及可空异常信息。
  final LoadState<List<Location>> loadState;

  const SearchState({
    required this.query,
    required this.validation,
    required this.loadState,
  });

  const SearchState.idle()
    : this(
        query: '',
        validation: SearchValidation.none,
        loadState: const LoadState.idle(),
      );

  SearchState copyWith({
    String? query,
    SearchValidation? validation,
    LoadState<List<Location>>? loadState,
  }) {
    return SearchState(
      query: query ?? this.query,
      validation: validation ?? this.validation,
      loadState: loadState ?? this.loadState,
    );
  }
}
