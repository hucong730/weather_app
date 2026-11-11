import 'package:dio/dio.dart';
import 'package:module_network/network/api_result.dart';

import '../api/qweather_api_base.dart';
import '../dto/qweather_city_lookup_dto.dart';

/// 城市搜索与坐标反查请求。
///
/// [query] 可为城市名、LocationID 或“经度,纬度”；[resultLimit] 默认 20，
/// GPS 反查时降为 1；[countryCode] 对应 ISO 3166 国家/地区范围。
class QWeatherCityLookupApi extends QWeatherApi<QWeatherCityLookupResponseDto> {
  /// 搜索关键词，也可为 LocationID 或“经度,纬度”格式的坐标反查参数。
  final String query;

  /// 返回地名所使用的 BCP 47 语言代码，跟随当前界面语言。
  final String languageCode;

  /// 可选的 ISO 3166 国家或地区代码，用于限制搜索范围。
  final String? countryCode;

  /// 最大返回条数，普通搜索默认 20 条，GPS 反查只取 1 条。
  final int resultLimit;

  QWeatherCityLookupApi(
    super.client, {
    required this.query,
    required this.languageCode,
    this.countryCode,
    this.resultLimit = 20,
    super.config,
    super.cancelToken,
  }) : super(decoder: QWeatherCityLookupResponseDto.fromJson);

  @override
  Uri get uri => config.resolve('/geo/v2/city/lookup');

  @override
  Map<String, dynamic> get params => {
    'location': query,
    'number': resultLimit,
    'lang': languageCode,
    if (countryCode != null) 'range': countryCode,
  };

  /// 和风新版错误结构用 HTTP 400 + no-such-location 表示无匹配城市。
  ///
  /// 仅识别该明确类型并构造业务 404 空结果，由适配器复用原有空列表映射；
  /// 其他错误码交回基类按官方错误码表映射，非对象响应及真正的服务错误
  /// 仍走通用 Failure，避免误吞异常。
  @override
  ApiResult<QWeatherCityLookupResponseDto>? mapErrorResponse(
    Response<dynamic> response,
  ) {
    if (response.statusCode != 400) return super.mapErrorResponse(response);
    final body = response.data;
    if (body is! Map) return null;
    final error = body['error'];
    if (error is! Map) return null;
    final type = error['type'];
    final isNoSuchLocation =
        (type is String && type.endsWith('#no-such-location')) ||
        error['title'] == 'No Such Location';
    if (!isNoSuchLocation) return super.mapErrorResponse(response);
    return Success(
      const QWeatherCityLookupResponseDto(code: '404'),
      response.statusCode!,
    );
  }
}
