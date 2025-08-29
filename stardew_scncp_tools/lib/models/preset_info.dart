/// 预设信息数据模型
class PresetInfo {
  final String name;
  final String condition;
  final String precedence;
  final bool isIslandAttire;
  final bool supportsCharacter; // 是否支持角色精灵类型
  final bool supportsPortrait; // 是否支持肖像类型

  const PresetInfo({
    required this.name,
    required this.condition,
    required this.precedence,
    this.isIslandAttire = false,
    this.supportsCharacter = true, // 默认都支持
    this.supportsPortrait = true, // 默认都支持
  });

  /// 从Map创建实例
  factory PresetInfo.fromMap(Map<String, dynamic> map) {
    return PresetInfo(
      name: map['name'] ?? '',
      condition: map['condition'] ?? '',
      precedence: map['precedence'] ?? '',
      isIslandAttire: map['isIslandAttire'] ?? false,
      supportsCharacter: map['supportsCharacter'] ?? true,
      supportsPortrait: map['supportsPortrait'] ?? true,
    );
  }

  /// 转换为Map格式
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'condition': condition,
      'precedence': precedence,
      'isIslandAttire': isIslandAttire,
      'supportsCharacter': supportsCharacter,
      'supportsPortrait': supportsPortrait,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PresetInfo &&
        other.name == name &&
        other.condition == condition &&
        other.precedence == precedence &&
        other.isIslandAttire == isIslandAttire &&
        other.supportsCharacter == supportsCharacter &&
        other.supportsPortrait == supportsPortrait;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        condition.hashCode ^
        precedence.hashCode ^
        isIslandAttire.hashCode ^
        supportsCharacter.hashCode ^
        supportsPortrait.hashCode;
  }

  @override
  String toString() {
    return 'PresetInfo(name: $name, condition: $condition, precedence: $precedence, isIslandAttire: $isIslandAttire, supportsCharacter: $supportsCharacter, supportsPortrait: $supportsPortrait)';
  }
}
