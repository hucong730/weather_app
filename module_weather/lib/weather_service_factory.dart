import 'package:module_network/network/api_client.dart';

import 'src/open_meteo/open_meteo_weather_adapter.dart';
import 'src/qweather/qweather_weather_adapter.dart';
import 'weather_provider.dart';
import 'weather_service.dart';

/// 按用户选择创建天气适配器，不向业务方暴露具体 DTO 与请求类。
abstract final class WeatherServiceFactory {
  /// 根据 [provider] 创建统一服务；未指定时使用和风，[client] 由调用方注入。
  static WeatherService create(
    ApiClient client, {
    WeatherProviderType provider = WeatherProviderType.qweather,
  }) {
    return switch (provider) {
      WeatherProviderType.qweather => QWeatherWeatherAdapter(client),
      WeatherProviderType.openMeteo => OpenMeteoWeatherAdapter(client),
    };
  }
}
