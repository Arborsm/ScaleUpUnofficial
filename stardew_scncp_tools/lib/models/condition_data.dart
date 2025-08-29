/// 条件数据模型，用于在不同组件间传递条件信息
class ConditionData {
  final Set<String> selectedSeasons;
  final List<String> eventIds;
  final List<String> locations;
  final bool isIndoors;
  final bool isOutdoors;

  const ConditionData({
    required this.selectedSeasons,
    required this.eventIds,
    required this.locations,
    this.isIndoors = true,
    this.isOutdoors = true,
  });

  /// 生成条件摘要文字（如 "Season · Event · Location"）
  String generateSummary() {
    final List<String> parts = [];

    // 只显示类别，不显示具体内容
    if (selectedSeasons.isNotEmpty) {
      parts.add('Season');
    }

    if (eventIds.isNotEmpty) {
      parts.add('Event');
    }

    if (locations.isNotEmpty) {
      parts.add('Location');
    }

    return parts.isEmpty ? 'No condition' : parts.join(' · ');
  }

  /// 检查是否有任何条件
  bool get hasConditions =>
      selectedSeasons.isNotEmpty || eventIds.isNotEmpty || locations.isNotEmpty;

  /// 创建副本并更新指定字段
  ConditionData copyWith({
    Set<String>? selectedSeasons,
    List<String>? eventIds,
    List<String>? locations,
    bool? isIndoors,
    bool? isOutdoors,
  }) {
    return ConditionData(
      selectedSeasons: selectedSeasons ?? this.selectedSeasons,
      eventIds: eventIds ?? this.eventIds,
      locations: locations ?? this.locations,
      isIndoors: isIndoors ?? this.isIndoors,
      isOutdoors: isOutdoors ?? this.isOutdoors,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConditionData &&
        other.selectedSeasons.length == selectedSeasons.length &&
        other.eventIds.length == eventIds.length &&
        other.locations.length == locations.length;
  }

  @override
  int get hashCode {
    return selectedSeasons.hashCode ^ eventIds.hashCode ^ locations.hashCode;
  }

  /// 从Map创建实例
  factory ConditionData.fromMap(Map<String, dynamic> map) {
    return ConditionData(
      selectedSeasons: Set<String>.from(map['selectedSeasons'] ?? []),
      eventIds: List<String>.from(map['eventIds'] ?? []),
      locations: List<String>.from(map['locations'] ?? []),
      isIndoors: map['isIndoors'] ?? true,
      isOutdoors: map['isOutdoors'] ?? true,
    );
  }
}
