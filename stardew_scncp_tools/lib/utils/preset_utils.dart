import '../constants/content_patcher_constants.dart';
import '../models/condition_data.dart';

/// 预设相关工具类
class PresetUtils {
  /// 生成唯一的预设名称
  static List<String> generateUniquePresets(
    List<String> basePresets,
    String conditionText,
    List<Map<String, dynamic>> existingEntries,
  ) {
    if (basePresets.isEmpty) return basePresets;

    // 检查条件是否已存在
    final existingEntry = existingEntries.firstWhere(
      (entry) => entry['conditionText'] == conditionText,
      orElse: () => <String, dynamic>{},
    );

    // 如果条件不存在，返回基础预设名称
    if (existingEntry.isEmpty) {
      return basePresets;
    }

    // 如果条件存在，生成新的唯一名称
    final List<String> uniquePresets = [];
    int counter = 1;

    for (final basePreset in basePresets) {
      String uniqueName = basePreset;

      // 检查预设名称是否已存在于任何条目中
      while (existingEntries.any((entry) =>
          (entry['presets'] as List<String>?)?.contains(uniqueName) == true)) {
        uniqueName = '${basePreset}_$counter';
        counter++;
      }

      uniquePresets.add(uniqueName);
    }

    return uniquePresets;
  }

  /// 解析预设条件
  static ConditionData parsePresetCondition(String condition) {
    final Set<String> seasons = {};
    final List<String> events = [];
    final List<String> locations = [];

    if (condition.contains(ContentPatcherConstants.seasonPrefix)) {
      final season = condition.split(' ').last;
      seasons.add(season);
    }

    if (condition.contains(ContentPatcherConstants.eventPrefix)) {
      final event = condition.split(' ').last;
      events.add(event);
    }

    if (condition.contains(ContentPatcherConstants.locationPrefix)) {
      final locationPart = condition
          .split('${ContentPatcherConstants.locationTargetPrefix} ')
          .last;
      final locationList =
          locationPart.split(' ').where((l) => l.isNotEmpty).toList();
      locations.addAll(locationList);
    }

    return ConditionData(
      selectedSeasons: seasons,
      eventIds: events,
      locations: locations,
    );
  }

  /// 生成预设名称基于条件
  static List<String> generatePresetNamesFromConditions({
    required Set<String> selectedSeasons,
    required List<String> eventIds,
    required List<String> locations,
  }) {
    final List<String> generatedPresets = [];

    // 季节预设名称
    if (selectedSeasons.isNotEmpty) {
      for (final season in selectedSeasons) {
        generatedPresets.add(season[0].toUpperCase() + season.substring(1));
      }
    }

    // 事件预设名称
    if (eventIds.isNotEmpty) {
      for (final event in eventIds) {
        final presetName =
            ContentPatcherConstants.eventPresetNames[event] ?? event;
        generatedPresets.add(presetName);
      }
    }

    // 位置预设名称
    if (locations.isNotEmpty) {
      for (final location in locations) {
        String presetName;
        if (ContentPatcherConstants.islandLocations.contains(location)) {
          presetName = 'Island';
        } else {
          presetName =
              ContentPatcherConstants.locationPresetNames[location] ?? location;
        }
        generatedPresets.add(presetName);
      }
    }

    return generatedPresets;
  }

  /// 构建条件文本
  static String buildConditionText({
    required Set<String> selectedSeasons,
    required List<String> eventIds,
    required List<String> locations,
  }) {
    final List<String> conditionParts = [];

    // 季节条件
    if (selectedSeasons.isNotEmpty) {
      final seasonConditions = selectedSeasons
          .map((s) =>
              '${ContentPatcherConstants.seasonPrefix} ${s.toLowerCase()}')
          .toList();
      conditionParts.addAll(seasonConditions);
    }

    // 事件条件
    if (eventIds.isNotEmpty) {
      final eventConditions = eventIds
          .map((e) => '${ContentPatcherConstants.eventPrefix} $e')
          .toList();
      conditionParts.addAll(eventConditions);
    }

    // 位置条件
    if (locations.isNotEmpty) {
      final locationConditions = locations
          .map((l) =>
              '${ContentPatcherConstants.locationPrefix} ${ContentPatcherConstants.locationTargetPrefix} $l')
          .toList();
      conditionParts.addAll(locationConditions);
    }

    // 生成唯一的关键字，避免条件合并
    if (conditionParts.isEmpty) {
      return 'No condition';
    }

    // 对条件进行排序，确保相同条件组合生成相同的文本
    conditionParts.sort();

    // 使用分隔符连接，但为每个条件组合生成唯一标识
    final conditionKey = conditionParts.join('|');

    // 添加条件数量信息，确保唯一性
    final seasonCount = selectedSeasons.length;
    final eventCount = eventIds.length;
    final locationCount = locations.length;

    return '$conditionKey|S:$seasonCount|E:$eventCount|L:$locationCount';
  }

  /// 构建条件数据
  static ConditionData buildConditionData({
    required Set<String> selectedSeasons,
    required List<String> eventIds,
    required List<String> locations,
  }) {
    return ConditionData(
      selectedSeasons: selectedSeasons,
      eventIds: eventIds,
      locations: locations,
    );
  }

  /// 确定优先级
  static String determinePrecedence({
    required Set<String> selectedSeasons,
    required List<String> eventIds,
    required List<String> locations,
  }) {
    if (locations.isNotEmpty) {
      return ContentPatcherConstants.locationPrecedence;
    }
    if (eventIds.isNotEmpty) {
      return ContentPatcherConstants.eventPrecedence;
    }
    return ContentPatcherConstants.seasonPrecedence;
  }

  /// 检查是否为岛屿服装
  static bool isIslandAttire(List<String> locations) {
    return locations
        .any((l) => ContentPatcherConstants.islandLocations.contains(l));
  }

  /// 从预设名称中提取实际名称（移除角色前缀）
  static String extractPresetName(String fullName) {
    // 查找第一个大写字母的位置（角色名称通常以大写字母开头）
    for (int i = 0; i < fullName.length; i++) {
      if (fullName[i] == fullName[i].toUpperCase() &&
          fullName[i] != fullName[i].toLowerCase()) {
        // 找到第一个大写字母，检查是否后面跟着小写字母（角色名称的格式）
        if (i + 1 < fullName.length &&
            fullName[i + 1] == fullName[i + 1].toLowerCase()) {
          // 继续查找角色名称的结束位置
          int j = i + 1;
          while (
              j < fullName.length && fullName[j] == fullName[j].toLowerCase()) {
            j++;
          }
          // 返回角色名称后面的部分
          if (j < fullName.length) {
            return fullName.substring(j);
          }
        }
      }
    }

    // 如果没有找到角色名称模式，返回原名称
    return fullName;
  }
}
