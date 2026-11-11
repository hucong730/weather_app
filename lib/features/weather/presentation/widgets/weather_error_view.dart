import 'package:flutter/material.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 通用天气错误提示，仅显示国际化安全文案，不暴露原始异常或响应体。
class WeatherErrorView extends StatelessWidget {
  /// 已分类的安全业务异常，仅用于映射国际化提示，不展示原始错误。
  final AppException error;

  /// 可选重试回调；为 null 时只显示错误说明，不显示重试按钮。
  final VoidCallback? onRetry;

  const WeatherErrorView({super.key, required this.error, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Text(
            WeatherFormatters.errorMessage(error, l10n),
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
        ],
      ),
    );
  }
}
