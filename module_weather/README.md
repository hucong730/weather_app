# module_weather

一个可独立复用的天气服务适配模块，向业务方提供统一的地点、天气报告和异步结果模型。当前支持和风天气（QWeather）与 Open-Meteo，默认使用和风天气。

模块的业务抽象基于通用 `module_network`，并直接声明 Dio 依赖用于具体 API 的响应错误扩展；不导入主应用，不包含 Riverpod、页面、SQLite、设备定位或 SharedPreferences。调用方负责注入 `ApiClient`、保存服务选择并管理界面状态。

## 架构

适配器模式的 Target 是 `WeatherService`，两个 Adapter 分别封装各家 API、DTO、Mapper、Host、单位和天气代码差异：

```text
业务 Repository / Controller
  → WeatherService（searchLocations / getWeather）
  → WeatherServiceFactory
      ├─ QWeatherWeatherAdapter
      │    └─ Geo / Current / Hourly / Daily / Air Quality API + DTO + Mapper
      └─ OpenMeteoWeatherAdapter
           └─ Geocoding / Forecast / Air Quality API + DTO + Mapper
  → ApiResult<Location / WeatherReport>
  → module_network → ApiClient → Dio
```

业务方只导入统一公开入口，不接触 `lib/src/` 内的具体 API 或 DTO：

```dart
import 'package:module_weather/module_weather.dart';

final service = WeatherServiceFactory.create(
  apiClient,
  provider: WeatherProviderType.openMeteo,
);

final locations = await service.searchLocations('Wuhan', 'en');
final report = await service.getWeather(location, languageCode: 'en');
```

`WeatherServiceFactory.create` 的 `provider` 默认是 `WeatherProviderType.qweather`。所有请求通过 `ApiResult` 返回成功或可预期失败；网络错误、HTTP 错误和 DTO/映射错误不会作为未处理异常穿过统一接口。

## 统一契约

- `searchLocations` 按城市名称和语言搜索，最多返回 20 条 `Location`；Open-Meteo 缺少 `results`、和风业务 `404`，以及和风新版 HTTP 400 且 `error.type` 以 `#no-such-location` 结尾或 `error.title` 为 `No Such Location` 的响应都映射为空列表，并保留原 HTTP 状态码。其他 HTTP 400、业务错误和真实服务错误仍为 `Failure`。
- `getWeather` 返回当前天气、连续 24 条小时预报和连续 7 条每日预报，温度、风速和降水量统一为 °C、km/h、mm。
- `WeatherReport.provider` 记录实际数据来源，`Location.id` 保留服务方 ID；`Location.clientId` 是调用方分配的跨服务稳定身份，适配器刷新时必须保留。
- 两家天气代码都映射到统一 `WeatherCondition`，未知代码安全降级为 `unknown`。
- 核心天气失败返回 `Failure`；空气质量失败仅让 AQI 为 `null`，不丢弃已经成功取得的核心天气。
- 服务切换由调用方重新创建适配器；模块本身不保存设置，也不自动故障转移到另一家服务。

## 和风天气

- 城市搜索使用 GeoAPI；GPS 坐标先反查地点和时区，再并行请求当前、24 小时、7 天和空气质量。
- 直连模式通过编译期 `QWEATHER_API_HOST`、`QWEATHER_API_KEY` 注入项目 Host 和 KEY，请求头为 `X-QW-Api-Key`。
- 湿度和降水概率从 0–1 转为百分比，风速从 m/s 转为 km/h，天气接口坐标最多保留两位小数。
- `AppConfigException` 是和风配置边界定义的业务异常，不属于通用网络模块。

## Open-Meteo

- 搜索：`https://geocoding-api.open-meteo.com/v1/search`。
- 天气：`https://api.open-meteo.com/v1/forecast`，一次请求当前、24 小时和 7 天数据，显式固定公制单位及 `timezone=auto`。
- 空气质量：`https://air-quality-api.open-meteo.com/v1/air-quality`，使用 US AQI 并映射六档中英文类别。
- 非商业公共服务模式无需 API KEY；首版不包含商业 customer Host 或凭据管理。
- Geocoding 不提供和风式 GPS 反向城市查询，因此 GPS 直接按坐标请求 Forecast，不暗中调用和风或第三方反向地理编码。地名缺失由调用方显示“当前位置”等回退文案。
- 本地 ISO 时间根据响应的 UTC 偏移转换，小时和每日数组先验证等长、数量及连续性，避免静默错位。

## 在其他项目中使用

将 `module_weather` 和相邻的 `module_network` 一起作为 path 依赖：

```yaml
dependencies:
  module_network:
    path: ../module_network
  module_weather:
    path: ../module_weather
```

修改 DTO 后，在本目录重新生成序列化代码，生成物应纳入版本库且不得手改：

```bash
dart run build_runner build --delete-conflicting-outputs
```

## 独立验证

在本目录执行：

```bash
flutter pub get
flutter analyze
flutter test
```

测试使用本地 fixture 和可控 Dio `HttpClientAdapter`，不需要真实 KEY，也不访问真实天气服务。契约测试对两家服务断言相同的统一模型、来源、单位和预报数量；专项测试覆盖异常 JSON、预报错位、时间转换、WMO 未知代码、US AQI 分级和空气质量降级。
