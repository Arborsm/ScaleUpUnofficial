import 'condition_data.dart';

/// 条件条目数据模型
class ConditionEntry {
  final String characterType;
  final String portraitType;
  final String conditionText;
  final List<String> presets;
  final ConditionData? conditionData;
  final String? precedence;
  final bool? isIslandAttire;
  final String? weight;

  const ConditionEntry({
    required this.characterType,
    required this.portraitType,
    required this.conditionText,
    required this.presets,
    required this.conditionData,
    this.precedence,
    this.isIslandAttire,
    this.weight,
  });

  /// 转换为Map格式（用于JSON预览）
  Map<String, dynamic> toMap() {
    return {
      'characterType': characterType,
      'portraitType': portraitType,
      'conditionText': conditionText,
      'presets': presets,
      'conditionData': conditionData,
      'precedence': precedence,
      'isIslandAttire': isIslandAttire,
      'weight': weight,
    };
  }

  /// 从Map创建实例
  factory ConditionEntry.fromMap(Map<String, dynamic> map) {
    return ConditionEntry(
      characterType: map['characterType'] ?? '',
      portraitType: map['portraitType'] ?? '',
      conditionText: map['conditionText'] ?? '',
      presets: List<String>.from(map['presets'] ?? []),
      conditionData: map['conditionData'] != null
          ? ConditionData.fromMap(
              Map<String, dynamic>.from(map['conditionData']))
          : null,
      precedence: map['precedence'],
      isIslandAttire: map['isIslandAttire'],
      weight: map['weight'],
    );
  }

  /// 创建副本并更新指定字段
  ConditionEntry copyWith({
    String? characterType,
    String? portraitType,
    String? conditionText,
    List<String>? presets,
    ConditionData? conditionData,
    String? precedence,
    bool? isIslandAttire,
    String? weight,
  }) {
    return ConditionEntry(
      characterType: characterType ?? this.characterType,
      portraitType: portraitType ?? this.portraitType,
      conditionText: conditionText ?? this.conditionText,
      presets: presets ?? this.presets,
      conditionData: conditionData ?? this.conditionData,
      precedence: precedence ?? this.precedence,
      isIslandAttire: isIslandAttire ?? this.isIslandAttire,
      weight: weight ?? this.weight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConditionEntry &&
        other.characterType == characterType &&
        other.portraitType == portraitType &&
        other.conditionText == conditionText &&
        other.precedence == precedence &&
        other.isIslandAttire == isIslandAttire &&
        other.weight == weight;
  }

  @override
  int get hashCode {
    return characterType.hashCode ^
        portraitType.hashCode ^
        conditionText.hashCode ^
        precedence.hashCode ^
        isIslandAttire.hashCode ^
        weight.hashCode;
  }

  @override
  String toString() {
    return 'ConditionEntry(characterType: $characterType, portraitType: $portraitType, conditionText: $conditionText, presets: $presets, precedence: $precedence, isIslandAttire: $isIslandAttire, weight: $weight)';
  }
}
