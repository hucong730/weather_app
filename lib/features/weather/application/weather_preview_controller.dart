import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:module_network/network/cancel_token.dart';
import 'package:module_network/state/load_state.dart';
import 'package:weather_app/features/weather/application/providers.dart';
import 'package:module_weather/models/location.dart';
import 'package:module_weather/models/weather_report.dart';

/// 搜索城市天气预览的独立 Provider。
///
/// autoDispose 在预览页退出后释放状态并取消请求，避免残留加载和无效写入。
final weatherPreviewControllerProvider =
    NotifierProvider.autoDispose<
      WeatherPreviewController,
      LoadState<WeatherReport>
    >(WeatherPreviewController.new);

/// 只负责预览城市天气，不读取/写入缓存，也不修改主页 Controller。
///
/// 重试会取消旧 HTTP，请求编号继续保证旧响应和销毁后的响应不会提交状态。
class WeatherPreviewController extends Notifier<LoadState<WeatherReport>> {
  /// 单调递增的请求编号，防止旧预览响应覆盖最新加载结果。
  int _requestId = 0;

  /// 当前预览请求的取消令牌，重试、服务切换和页面销毁时取消。
  CancelToken? _cancelToken;

  @override
  LoadState<WeatherReport> build() {
    // 服务变化使旧预览请求失效，页面会按新服务重新加载当前地点。
    ref.watch(weatherRepositoryProvider);
    ref.onDispose(() {
      _requestId++;
      _cancelPendingRequest();
    });
    return const LoadState.idle();
  }

  /// 加载指定地点的完整天气报告。
  ///
  /// 请求期间清空旧预览并显示 loading；成功/失败统一通过 LoadState 转换，
  /// 语言代码继续传给 Repository，确保预览与当前界面语言一致。
  Future<void> load(Location location, {String languageCode = 'en'}) async {
    _cancelPendingRequest();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    final requestId = ++_requestId;
    state = const LoadState.loading();
    final result = await ref
        .read(weatherRepositoryProvider)
        .getWeather(
          location,
          languageCode: languageCode,
          cancelToken: cancelToken,
        );
    if (requestId != _requestId) return;
    _cancelToken = null;
    state = LoadState.fromResult(result);
  }

  /// 取消当前预览的全部并行 HTTP 请求，并释放控制器持有的令牌引用。
  void _cancelPendingRequest() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}
