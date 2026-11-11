/// 把 JSON 对象还原为具体模型实例的函数类型。
///
/// Dart 的工厂构造和静态方法不能继承，因此每个模型提供自己的解码函数，
/// 再由 [JsonModel.fromJson] 统一调用，避免在基类里错误地实例化子类。
typedef ModelDecoder<T> = T Function(Map<String, dynamic> json);

/// DTO 与领域模型的共同契约：支持 JSON 输出和局部不可变拷贝。
abstract class JsonModel {
  const JsonModel();

  /// 转换为可持久化或用于网络诊断的 JSON 对象，不输出任何凭据。
  Map<String, dynamic> toJson();

  /// 仅替换调用方显式提供的字段，其余字段保持原值。
  JsonModel copyWith();

  /// 使用具体模型提供的 [decoder] 构造实例，并保留准确的泛型类型。
  static T fromJson<T>(Map<String, dynamic> json, ModelDecoder<T> decoder) {
    return decoder(json);
  }
}
