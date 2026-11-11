import '../../weather_exception.dart';

/// 和风天气官方直连配置。
///
/// [apiHost] 是开发者在和风控制台创建项目后分配的专属 HTTPS Host；
/// [apiKey] 只通过编译期环境变量注入，并统一放入认证请求头。
class QWeatherConfig {
  /// 和风控制台分配的专属 HTTPS API Host，不包含具体业务接口路径。
  final String apiHost;

  /// 和风项目密钥，仅通过编译期环境变量注入并放入认证请求头。
  final String apiKey;

  const QWeatherConfig({required this.apiHost, required this.apiKey});

  const QWeatherConfig.fromEnvironment()
    : this(
        apiHost: const String.fromEnvironment('QWEATHER_API_HOST'),
        apiKey: const String.fromEnvironment('QWEATHER_API_KEY'),
      );

  Uri resolve(String path) {
    final host = Uri.parse(apiHost);
    if (apiHost.isEmpty || !host.isScheme('https') || host.host.isEmpty) {
      throw const AppConfigException('QWeather API host is not configured');
    }
    if (apiKey.isEmpty) {
      throw const AppConfigException('QWeather API key is not configured');
    }
    return host.resolve(path);
  }

  Map<String, String> get headers => {'X-QW-Api-Key': apiKey};
}
