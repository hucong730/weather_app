// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '天气';

  @override
  String get searchPrompt => '搜索城市以查看天气';

  @override
  String get searchHint => '输入城市名称';

  @override
  String get searchButton => '搜索';

  @override
  String get cancel => '取消';

  @override
  String get add => '添加';

  @override
  String get settings => '设置';

  @override
  String get cityManagement => '城市管理';

  @override
  String get cityManagementHint => '删除或调整已添加城市的顺序';

  @override
  String get noSavedCities => '暂无已添加城市';

  @override
  String get noSavedCitiesHint => '请先在主页搜索并添加城市。';

  @override
  String deleteCity(String city) {
    return '删除$city';
  }

  @override
  String reorderCity(String city) {
    return '拖拽调整$city的顺序';
  }

  @override
  String get locationPrompt => '无法获取当前位置。请检查系统定位服务和定位权限后重试，也可以手动搜索城市。';

  @override
  String get cachedLocationWarning => '当前定位不可用，正在显示上次保存的天气';

  @override
  String get language => '语言';

  @override
  String get theme => '主题';

  @override
  String get followSystem => '跟随系统';

  @override
  String get lightTheme => '浅色';

  @override
  String get darkTheme => '深色';

  @override
  String get locationPermission => '定位权限';

  @override
  String get permissionSystemHint => '授权结果由操作系统确认。关闭权限时将跳转到 App 系统设置。';

  @override
  String get aboutApp => '关于此 App';

  @override
  String get appDescription => '一个使用 Flutter 构建的天气 App，支持当前天气、分时与每日预报以及多城市查看。';

  @override
  String get dataSources => '数据来源';

  @override
  String get iconSource =>
      '天气图标：QWeather Icons（MIT License）\nhttps://github.com/qwd/Icons';

  @override
  String get invalidQuery => '请输入城市名称，不支持邮政编码或坐标';

  @override
  String get noResults => '未找到匹配城市';

  @override
  String get locating => '正在获取您的位置…';

  @override
  String get loading => '正在加载天气…';

  @override
  String get currentLocation => '当前位置';

  @override
  String currentLocationPage(int index, int count) {
    return '当前位置，第 $index 页，共 $count 页';
  }

  @override
  String cityPage(int index, int count) {
    return '城市，第 $index 页，共 $count 页';
  }

  @override
  String get hourlyForecast => '24小时预报';

  @override
  String get dailyForecast => '7天预报';

  @override
  String dailyForecastToday(String date) {
    return '今天（$date）';
  }

  @override
  String dailyForecastWeekday(String weekday, String date) {
    return '$weekday（$date）';
  }

  @override
  String get now => '现在';

  @override
  String get airQuality => '空气质量';

  @override
  String get feelsLike => '体感温度';

  @override
  String get humidity => '湿度';

  @override
  String get precipitation => '降水量';

  @override
  String get wind => '风速';

  @override
  String get retry => '重试';

  @override
  String get refresh => '刷新';

  @override
  String get networkError => '请检查网络连接后重试';

  @override
  String get timeoutError => '请求超时，请重试';

  @override
  String get rateLimitError => '请求过于频繁，请稍后重试';

  @override
  String get serviceError => '天气服务暂不可用';

  @override
  String get dataError => '无法读取天气数据';

  @override
  String get configError => '天气服务未配置，请使用和风天气启动配置';

  @override
  String get accountError => '天气服务拒绝了请求，请检查 API 密钥、Host 或账户额度';

  @override
  String get weatherSource =>
      '天气数据由和风天气提供\nhttps://developer.qweather.com/attribution.html';

  @override
  String get openMeteoSource => '天气数据由 Open-Meteo 提供\nhttps://open-meteo.com/';

  @override
  String get weatherProvider => '天气服务';

  @override
  String get weatherProviderHint => '切换后保留已添加城市，并刷新当前页面。';

  @override
  String get qWeatherService => '和风天气';

  @override
  String get openMeteoService => 'Open-Meteo';

  @override
  String get conditionClear => '晴';

  @override
  String get conditionMainlyClear => '大部晴朗';

  @override
  String get conditionPartlyCloudy => '局部多云';

  @override
  String get conditionOvercast => '阴';

  @override
  String get conditionFog => '雾';

  @override
  String get conditionDrizzle => '毛毛雨';

  @override
  String get conditionFreezingDrizzle => '冻毛毛雨';

  @override
  String get conditionRain => '雨';

  @override
  String get conditionFreezingRain => '冻雨';

  @override
  String get conditionSnow => '雪';

  @override
  String get conditionSnowGrains => '雪粒';

  @override
  String get conditionShowers => '阵雨';

  @override
  String get conditionSnowShowers => '阵雪';

  @override
  String get conditionThunderstorm => '雷暴';

  @override
  String get conditionThunderstormHail => '雷暴伴冰雹';

  @override
  String get conditionUnknown => '未知天气';
}
