import 'package:flutter/material.dart';
import 'package:module_weather/models/weather_condition.dart';
import 'package:weather_app/features/weather/presentation/weather_formatters.dart';
import 'package:weather_app/features/weather/presentation/widgets/qweather_icon.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 和风官方 SVG 天气动画容器，根据天气类别和昼夜显示图标。
///
/// 使用 4 秒放大、4 秒缩小的轻量往复循环，不改变图标形状；系统开启
/// “减少动画”时停止 AnimationController，仅显示静态 SVG，并保留天气文本语义。
class WeatherAnimation extends StatefulWidget {
  /// 当前天气类别，同时决定 SVG 资源和天气语义文本。
  final WeatherCondition condition;

  /// 是否选择白天版本图标，不改变缩放动画参数。
  final bool isDay;

  const WeatherAnimation({
    super.key,
    required this.condition,
    required this.isDay,
  });

  @override
  State<WeatherAnimation> createState() => _WeatherAnimationState();
}

class _WeatherAnimationState extends State<WeatherAnimation>
    with SingleTickerProviderStateMixin {
  /// 驱动 4 秒正向、4 秒反向缩放的控制器，由当前 State 提供 Ticker。
  late final AnimationController _controller;

  /// 是否允许播放动画，直接跟随系统“减少动画”设置。
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final shouldAnimate = !MediaQuery.disableAnimationsOf(context);
    if (_animate == shouldAnimate) return;
    _animate = shouldAnimate;
    if (_animate) {
      // 到达最大尺寸后沿原曲线缩小，避免单向 repeat 在循环边界突然复位。
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = WeatherFormatters.conditionLabel(
      widget.condition,
      AppLocalizations.of(context),
    );
    final icon = QWeatherIcon(
      condition: widget.condition,
      isDay: widget.isDay,
      size: 110,
    );

    return Semantics(
      label: label,
      child: RepaintBoundary(
        child: SizedBox(
          width: 120,
          height: 120,
          child: _animate
              ? AnimatedBuilder(
                  key: const ValueKey('weather_animation_builder'),
                  animation: _controller,
                  builder: (context, child) {
                    return ScaleTransition(
                      scale: Tween(begin: 0.96, end: 1.04).animate(
                        CurvedAnimation(
                          parent: _controller,
                          curve: Curves.easeInOut,
                        ),
                      ),
                      child: child,
                    );
                  },
                  child: icon,
                )
              : icon,
        ),
      ),
    );
  }
}
