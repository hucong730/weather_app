/// 应用内部天气类别，统一驱动中文/英文文案、官方 SVG 图标和轻量缩放动画。
///
/// mapper 负责把和风数值代码映射到这些值，未知代码归为 [unknown]，
/// 避免第三方新增天气代码导致页面崩溃。
enum WeatherCondition {
  clear,
  mainlyClear,
  partlyCloudy,
  overcast,
  fog,
  drizzle,
  freezingDrizzle,
  rain,
  freezingRain,
  snow,
  snowGrains,
  showers,
  snowShowers,
  thunderstorm,
  thunderstormHail,
  unknown,
}
