import '../error/app_exception.dart';
import '../network/api_result.dart';

/// 页面数据加载阶段：初始、加载中、无内容、成功和失败。
enum LoadStatus { idle, loading, empty, success, error }

/// 界面使用的不可变加载状态，统一承载数据、异常和 HTTP 状态码。
///
/// [previousData] 用于刷新失败时继续展示旧内容，避免页面突然清空；
/// 定位、权限等领域专属阶段由业务项目自行管理，不进入通用加载状态。
class LoadState<T> {
  /// 当前唯一加载阶段，调用方只据此选择 UI 分支。
  final LoadStatus status;

  /// 当前成功数据，或刷新失败时通过 previousData 保留的旧数据。
  final T? data;

  /// 失败阶段的安全异常；其他阶段通常为 null。
  final AppException? error;

  /// 最近一次网络结果的状态码，无响应或尚未请求时为 null。
  final int? statusCode;

  const LoadState._({
    required this.status,
    this.data,
    this.error,
    this.statusCode,
  });

  const LoadState.idle() : this._(status: LoadStatus.idle);
  const LoadState.loading() : this._(status: LoadStatus.loading);

  factory LoadState.fromResult(
    ApiResult<T> result, {
    bool Function(T data)? isEmpty,
    T? previousData,
  }) {
    return switch (result) {
      Success<T>(:final data, :final statusCode) =>
        (isEmpty?.call(data) ?? false)
            ? LoadState<T>._(
                status: LoadStatus.empty,
                data: data,
                statusCode: statusCode,
              )
            : LoadState<T>._(
                status: LoadStatus.success,
                data: data,
                statusCode: statusCode,
              ),
      Failure<T>(:final error, :final statusCode) => LoadState<T>._(
        status: LoadStatus.error,
        data: previousData,
        error: error,
        statusCode: statusCode,
      ),
    };
  }
}
