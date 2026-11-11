# module_network

一个可独立测试、可被多个 Flutter 项目复用的通用网络子包。生产代码只依赖 Dart、Dio 和 `json_annotation`，不包含天气、定位、页面、Repository、API Host 或密钥配置。

## 架构边界

```text
业务 API / Repository
  → BaseApi<T> / ApiResult<T> / LoadState<T>
  → ApiClient
  → Dio
```

- `ApiClient`：纯传输层，发送 GET、POST 及其他 HTTP 方法，返回 Dio 原始 `Response`。
- `BaseApi<T>`：具体请求模板，声明 URI、方法、参数、请求头、请求体、成功状态码和模型 decoder。非成功 HTTP 状态默认统一映射为 `Failure`；业务 API 可按需重写 `mapErrorResponse`，仅识别具有明确业务语义的错误响应，未处理时仍走默认映射，不应把全部 HTTP 错误伪装成成功。
- `ApiResult<T>`：统一 `Success<T>` / `Failure<T>`，保留响应状态码并转换网络、限流和解析异常。
- `LoadState<T>`：界面可选的通用加载状态，把 `ApiResult` 转为 idle/loading/empty/success/error，并支持失败时保留旧数据。
- `JsonModel` / `ModelDecoder`：模型 `toJson`、`copyWith` 和类型安全反序列化契约。
- `AppException`：可预期网络异常的抽象基类，只提供网络、超时、HTTP、限流和数据解析子类，不包含具体业务配置或界面文案。使用方可继承它定义自己的业务异常；例如天气项目的 `AppConfigException` 属于和风配置模块，不在本包提供。

模块不会创建 Dio 全局单例，也不规定依赖注入方式。应用应创建并持有 Dio/ApiClient，按自身架构注入业务 API；这样可分别配置超时、代理、拦截器和证书策略。

## 在其他项目中使用

本地 path 依赖：

```yaml
dependencies:
  module_network:
    path: ../module_network
```

统一导入：

```dart
import 'package:module_network/module_network.dart';
```

也可以只导入需要的公开子库，例如 `package:module_network/network/api_client.dart`。

定义业务请求：

```dart
final class ExampleApi extends BaseApi<ExampleModel> {
  ExampleApi(super.client) : super(decoder: ExampleModel.fromJson);

  @override
  Uri get uri => Uri.https('api.example.com', '/example');
}

final result = await ExampleApi(apiClient).send();
```

`ExampleModel` 属于业务项目并实现 `JsonModel`。Host、KEY、拦截器、DTO、业务错误文案及 Repository 均不应移入本模块。

## 独立验证

在本目录执行：

```bash
flutter pub get
flutter analyze
flutter test
```

测试使用可控 Dio `HttpClientAdapter`，不访问真实网络，也不依赖天气主项目。
