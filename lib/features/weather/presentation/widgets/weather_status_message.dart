import 'package:flutter/material.dart';

/// 天气页面通用的图标状态提示，用于定位、加载、空内容和手动搜索引导。
class WeatherStatusMessage extends StatelessWidget {
  /// 状态区域顶部显示的 Material 图标。
  final IconData icon;

  /// 面向用户的状态说明，由调用方提供已国际化文本。
  final String text;

  /// 是否在文本下方显示环形进度指示器。
  final bool showProgress;

  const WeatherStatusMessage({
    super.key,
    required this.icon,
    required this.text,
    this.showProgress = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(icon, size: 48),
          const SizedBox(height: 16),
          Text(text, textAlign: TextAlign.center),
          if (showProgress)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
