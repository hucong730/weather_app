/// 业务方可选择的天气数据来源，默认由工厂选择 [qweather]。
enum WeatherProviderType {
  /// 和风天气，需要配置专属 API Host 与项目密钥。
  qweather,

  /// Open-Meteo，无需项目密钥，由适配器转换其 WMO 代码和并行数组。
  openMeteo,
}
