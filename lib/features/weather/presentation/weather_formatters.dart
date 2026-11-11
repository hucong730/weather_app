import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:module_network/error/app_exception.dart';
import 'package:module_weather/module_weather.dart';
import 'package:weather_app/l10n/app_localizations.dart';

/// 天气展示格式化工具，集中处理 locale、时区、天气图标和错误文案。
abstract final class WeatherFormatters {
  /// 来源声明由实际报告或当前服务决定，不能在 Open-Meteo 下误标和风。
  static String weatherSource(
    WeatherProviderType provider,
    AppLocalizations l10n,
  ) {
    return switch (provider) {
      WeatherProviderType.qweather => l10n.weatherSource,
      WeatherProviderType.openMeteo => l10n.openMeteoSource,
    };
  }

  /// 温度按 locale 四舍五入为整数显示，不附带单位，单位由组件统一添加。
  static String temperature(double value, Locale locale) {
    return NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: 0,
    ).format(value);
  }

  /// 降水和风速等数值保留一位小数，分组与小数点随 locale 变化。
  static String decimal(double value, Locale locale) {
    return NumberFormat.decimalPatternDigits(
      locale: locale.toString(),
      decimalDigits: 1,
    ).format(value);
  }

  /// 降水概率为 null 时显示 `--`，不误导为 0%。
  static String probability(int? value) => value == null ? '--' : '$value%';

  /// 将 UTC 时刻加上地点偏移后格式化，避免直接使用设备时区。
  static String hour(DateTime timeUtc, int offsetSeconds, Locale locale) {
    final localTime = timeUtc.add(Duration(seconds: offsetSeconds));
    return DateFormat.Hm(locale.toString()).format(localTime);
  }

  /// 将当前 UTC 时刻换算为所选城市的本地时间，供“今天”年月日比较。
  ///
  /// 显式调用 toUtc 可统一带时区或不带时区的输入；这里只进行固定偏移
  /// 运算，不使用设备时区。城市偏移来自天气报告，与小时预报保持一致。
  static DateTime locationToday(DateTime timeUtc, int offsetSeconds) {
    return timeUtc.toUtc().add(Duration(seconds: offsetSeconds));
  }

  /// 按 locale 格式化完整日历日期，用于需要年月日的天气信息。
  static String date(DateTime date, Locale locale) {
    return DateFormat.yMMMd(locale.toString()).format(date);
  }

  /// 格式化 7 天预报的日历日期。
  ///
  /// [date] 是预报所在的地点本地日历日，[today] 是已按地点 UTC 偏移
  /// 换算后的当前时间。只比较年月日，避免时刻或设备时区影响“今天”判断；
  /// 当天和其他日期分别使用 ARB 文案，周几与月日由 intl 按语言生成。
  static String dailyDate(
    DateTime date,
    DateTime today,
    Locale locale,
    AppLocalizations l10n,
  ) {
    final localeName = locale.toString();
    final dateLabel = DateFormat.MMMd(localeName).format(date);
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    if (isToday) {
      return l10n.dailyForecastToday(dateLabel);
    }
    // 中文使用“周二”而不是“星期二”，与手机天气应用的紧凑习惯一致；
    // 其他语言保留完整周几名称，避免不自然的英文缩写。
    final weekday = locale.languageCode == 'zh'
        ? DateFormat.E(localeName).format(date)
        : DateFormat.EEEE(localeName).format(date);
    return l10n.dailyForecastWeekday(weekday, dateLabel);
  }

  /// 格式化地点名称。
  ///
  /// 主页传 includeDetails=false，只显示城市；搜索结果使用默认 true，
  /// 保留一级行政区与国家，便于区分同名城市。
  static String locationName(
    Location location,
    AppLocalizations l10n, {
    bool includeDetails = true,
  }) {
    final parts = [
      if (location.name?.isNotEmpty ?? false)
        location.name!
      else
        l10n.currentLocation,
      if (includeDetails && (location.admin1?.isNotEmpty ?? false))
        location.admin1!,
      if (includeDetails && (location.country?.isNotEmpty ?? false))
        location.country!,
    ];
    return parts.join(', ');
  }

  /// 将统一天气代码映射为当前语言的文本，不直接展示服务端原始描述。
  static String conditionLabel(
    WeatherCondition condition,
    AppLocalizations l10n,
  ) {
    return switch (condition) {
      WeatherCondition.clear => l10n.conditionClear,
      WeatherCondition.mainlyClear => l10n.conditionMainlyClear,
      WeatherCondition.partlyCloudy => l10n.conditionPartlyCloudy,
      WeatherCondition.overcast => l10n.conditionOvercast,
      WeatherCondition.fog => l10n.conditionFog,
      WeatherCondition.drizzle => l10n.conditionDrizzle,
      WeatherCondition.freezingDrizzle => l10n.conditionFreezingDrizzle,
      WeatherCondition.rain => l10n.conditionRain,
      WeatherCondition.freezingRain => l10n.conditionFreezingRain,
      WeatherCondition.snow => l10n.conditionSnow,
      WeatherCondition.snowGrains => l10n.conditionSnowGrains,
      WeatherCondition.showers => l10n.conditionShowers,
      WeatherCondition.snowShowers => l10n.conditionSnowShowers,
      WeatherCondition.thunderstorm => l10n.conditionThunderstorm,
      WeatherCondition.thunderstormHail => l10n.conditionThunderstormHail,
      WeatherCondition.unknown => l10n.conditionUnknown,
    };
  }

  /// 将统一天气类别映射为 Material 图标，并区分晴天昼夜。
  static IconData conditionIcon(WeatherCondition condition, bool isDay) {
    return switch (condition) {
      WeatherCondition.clear => isDay ? Icons.wb_sunny : Icons.nightlight,
      WeatherCondition.mainlyClear || WeatherCondition.partlyCloudy =>
        isDay ? Icons.wb_cloudy : Icons.nights_stay,
      WeatherCondition.overcast => Icons.cloud,
      WeatherCondition.fog => Icons.foggy,
      WeatherCondition.drizzle ||
      WeatherCondition.freezingDrizzle => Icons.grain,
      WeatherCondition.rain ||
      WeatherCondition.freezingRain ||
      WeatherCondition.showers => Icons.umbrella,
      WeatherCondition.snow ||
      WeatherCondition.snowGrains ||
      WeatherCondition.snowShowers => Icons.ac_unit,
      WeatherCondition.thunderstorm ||
      WeatherCondition.thunderstormHail => Icons.thunderstorm,
      WeatherCondition.unknown => Icons.help_outline,
    };
  }

  /// 按异常类型选择国际化文案，不向界面暴露状态码、堆栈或原始响应。
  static String errorMessage(AppException error, AppLocalizations l10n) {
    return switch (error) {
      AppNetworkException() => l10n.networkError,
      AppTimeoutException() => l10n.timeoutError,
      AppRateLimitException() => l10n.rateLimitError,
      // 和风官方错误码：凭据/额度被拒给出可操作的配置提示，其余保持服务错误。
      QWeatherServiceException() =>
        error.isCredentialOrQuota ? l10n.accountError : l10n.serviceError,
      // Open-Meteo 无凭据与错误码枚举，服务端确认的错误统一按服务错误展示。
      OpenMeteoServiceException() => l10n.serviceError,
      AppHttpException() => l10n.serviceError,
      AppDataException() => l10n.dataError,
      AppConfigException() => l10n.configError,
      // 通用异常基类允许业务扩展，未知扩展统一降级为服务错误。
      _ => l10n.serviceError,
    };
  }
}
