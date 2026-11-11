import '../dto/open_meteo_geocoding_dto.dart';
import 'open_meteo_api_base.dart';

/// Open-Meteo 名称到坐标的搜索请求，不用于 GPS 反向地名单独查询。
class OpenMeteoGeocodingApi extends OpenMeteoApi<OpenMeteoGeocodingDto> {
  /// 用户输入的城市名称关键词。
  final String query;

  /// 地名结果的语言代码，跟随当前界面语言。
  final String languageCode;

  OpenMeteoGeocodingApi(
    super.client, {
    required this.query,
    required this.languageCode,
    super.cancelToken,
  }) : super(decoder: OpenMeteoGeocodingDto.fromJson);

  @override
  Uri get uri => Uri.parse('https://geocoding-api.open-meteo.com/v1/search');

  @override
  Map<String, dynamic> get params => {
    'name': query,
    'count': 20,
    'language': languageCode,
    'format': 'json',
  };
}
