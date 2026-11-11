part of 'weather_home_controller.dart';

/// 每个稳定城市 key 对应一个独立、可自动销毁的天气 Provider。
final weatherCityControllerProvider = NotifierProvider.autoDispose
    .family<WeatherCityController, LoadState<WeatherReport>, String>(
      (key) => WeatherCityController(key),
    );

/// 单个城市的加载、错误、HTTP 取消和过期响应控制。
///
/// build 从主页条目取得缓存/添加报告；后续网络成功才更新 home 和 SQLite。
class WeatherCityController extends Notifier<LoadState<WeatherReport>> {
  WeatherCityController(this._key);

  /// 当前 Controller 对应的稳定城市页面 key。
  final String _key;

  /// 单调递增的请求编号，用于隔离重试、服务切换和销毁后的旧响应。
  int _requestId = 0;

  /// 当前城市请求的取消令牌，新刷新和 Provider 销毁时取消。
  CancelToken? _cancelToken;

  @override
  LoadState<WeatherReport> build() {
    // 服务切换会取消旧请求；请求编号继续阻止已完成的旧响应写回。
    ref.watch(weatherRepositoryProvider);
    ref.onDispose(() {
      _requestId++;
      _cancelPendingRequest();
    });
    final initial = ref
        .read(weatherHomeControllerProvider)
        .entryByKey(_key)
        .report;
    return initial == null
        ? const LoadState.idle()
        : LoadState.fromResult(Success(initial, 200));
  }

  /// 接受主页已确认的预览报告，取消旧刷新，不重复请求或写缓存。
  void acceptReport(WeatherReport report) {
    _requestId++;
    _cancelPendingRequest();
    state = LoadState.fromResult(Success(report, 200));
  }

  /// 加载指定城市；已有内容时保留成功内容，由 EasyRefresh 展示刷新进度。
  ///
  /// 每次刷新会取消旧 HTTP，并以 requestId 兜底丢弃旧响应。失败通过
  /// previousData 保留旧天气，成功后交给主页按原页面位置持久化。
  Future<void> load(
    Location location, {
    String languageCode = 'en',
    bool localizeLocation = false,
  }) async {
    _cancelPendingRequest();
    final cancelToken = CancelToken();
    _cancelToken = cancelToken;
    final requestId = ++_requestId;
    if (state.data == null) state = const LoadState.loading();
    final result = await ref
        .read(weatherRepositoryProvider)
        .getWeather(
          location,
          languageCode: languageCode,
          cancelToken: cancelToken,
          localizeLocation: localizeLocation,
        );
    if (requestId != _requestId) return;

    _cancelToken = null;
    state = LoadState.fromResult(result, previousData: state.data);
    if (result case Success(:final data)) {
      await ref
          .read(weatherHomeControllerProvider.notifier)
          .updateReport(_key, data);
    }
  }

  /// 取消当前城市的全部并行 HTTP 请求，并解除令牌引用。
  void _cancelPendingRequest() {
    _cancelToken?.cancel();
    _cancelToken = null;
  }
}
