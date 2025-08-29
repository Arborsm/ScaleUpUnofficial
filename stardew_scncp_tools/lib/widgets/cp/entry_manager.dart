import 'package:flutter/material.dart';
import 'dart:async';
import '../../constants/content_patcher_constants.dart';
import '../../models/condition_entry.dart';
import '../../models/condition_data.dart';
import 'preset_manager.dart';
import 'condition_builder.dart';
import 'condition_tooltip_helper.dart';

/// 条目管理组件
class EntryManager extends StatefulWidget {
  final List<ConditionEntry> entries;
  final Set<String> selectedTypes;
  final Function(ConditionEntry) onPresetAdded;
  final Function(int) onEntryRemoved;
  final Function(int)? onEntrySelected; // 新增：条目选择回调
  final String characterName;
  final Map<int, ConditionData> entriesConditionData; // 每个entry的conditionData映射
  final int? selectedEntryIndex; // 新增：当前选中的条目索引

  const EntryManager({
    super.key,
    required this.entries,
    required this.selectedTypes,
    required this.onPresetAdded,
    required this.onEntryRemoved,
    this.onEntrySelected, // 可选参数
    required this.characterName,
    required this.entriesConditionData, // 必需参数
    this.selectedEntryIndex, // 可选参数
  });

  @override
  State<EntryManager> createState() => _EntryManagerState();
}

class _EntryManagerState extends State<EntryManager> {
  // 为每个条目创建GlobalKey，用于定位tooltip
  final Map<int, GlobalKey> _entryKeys = {};
  OverlayEntry? _tooltipOverlay;
  Timer? _hideTooltipTimer;

  @override
  Widget build(BuildContext context) {
    // 确保每个条目都有对应的GlobalKey
    for (int i = 0; i < widget.entries.length; i++) {
      _entryKeys.putIfAbsent(i, () => GlobalKey());
    }

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.16),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainer
                  .withValues(alpha: 0.3),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.12),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Text(
                  ContentPatcherConstants.uiGeneratedEntries,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                const Spacer(),
                PresetManager(
                  selectedTypes: widget.selectedTypes,
                  existingEntries: widget.entries,
                  pendingEntries: const [],
                  onPresetAdded: widget.onPresetAdded,
                  characterName: widget.characterName,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.entries.isEmpty
                ? _buildEmptyState(context)
                : _buildEntriesList(context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .surfaceContainer
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.list_alt_outlined,
                size: 56,
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant
                    .withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              ContentPatcherConstants.uiNoEntriesYet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              ContentPatcherConstants.uiConfigureConditions,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.4,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntriesList(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: widget.entries.length,
      itemBuilder: (context, index) {
        final entry = widget.entries[index];
        return _buildEntryCard(context, entry, index);
      },
    );
  }

  Widget _buildEntryCard(
      BuildContext context, ConditionEntry entry, int index) {
    // 确定条目类型
    final hasCharacter = entry.characterType.isNotEmpty;
    final hasPortrait = entry.portraitType.isNotEmpty;
    final isBaseAsset = entry.conditionText.isEmpty;

    // 生成类型标签
    final typeLabels = <String>[];
    if (hasCharacter) typeLabels.add('Character');
    if (hasPortrait) typeLabels.add('Portrait');

    // 生成预设名称
    final presetName = entry.presets.isNotEmpty ? entry.presets.first : '';
    final displayName = isBaseAsset ? 'Base Asset' : presetName;

    // 检查是否为当前选中的条目
    final isSelected = widget.selectedEntryIndex == index;

    return GestureDetector(
      onTap: () {
        if (widget.onEntrySelected != null) {
          widget.onEntrySelected!(index);
        }
      },
      child: Container(
        key: _entryKeys[index], // 添加GlobalKey
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.1)
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 0,
            ),
            BoxShadow(
              color:
                  Theme.of(context).colorScheme.shadow.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : (Theme.of(context).brightness == Brightness.light
                    ? Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.12)
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.16)),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: _buildEntryContent(context, entry, index, displayName,
            typeLabels, isBaseAsset, hasCharacter, hasPortrait),
      ),
    );
  }

  Widget _buildEntryContent(
      BuildContext context,
      ConditionEntry entry,
      int index,
      String displayName,
      List<String> typeLabels,
      bool isBaseAsset,
      bool hasCharacter,
      bool hasPortrait) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 标题行
          Row(
            children: [
              // 类型图标
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isBaseAsset
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (isBaseAsset
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary)
                          .withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  isBaseAsset ? Icons.image : Icons.style,
                  size: 22,
                  color: isBaseAsset
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 16),

              // 标题和类型
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (hasCharacter) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFFF3E5F5) // 浅色模式下使用更明显的紫色背景
                                  : Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? const Color(0xFF7B1FA2) // 浅色模式下使用深紫色边框
                                    : Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 10,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFF7B1FA2) // 浅色模式下使用深紫色图标
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'C',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? const Color(
                                                0xFF7B1FA2) // 浅色模式下使用深紫色文字
                                            : Theme.of(context)
                                                .colorScheme
                                                .primary,
                                      ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                        ],
                        if (hasPortrait) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? const Color(0xFFE3F2FD) // 浅色模式下使用更明显的蓝色背景
                                  : Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? const Color(0xFF1976D2) // 浅色模式下使用深蓝色边框
                                    : Theme.of(context)
                                        .colorScheme
                                        .secondary
                                        .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.face,
                                  size: 10,
                                  color: Theme.of(context).brightness ==
                                          Brightness.light
                                      ? const Color(0xFF1976D2) // 浅色模式下使用深蓝色图标
                                      : Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'P',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context).brightness ==
                                                Brightness.light
                                            ? const Color(
                                                0xFF1976D2) // 浅色模式下使用深蓝色文字
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSecondaryContainer,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // 删除按钮
              SizedBox(
                width: 48,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                    ),
                    onPressed: () => widget.onEntryRemoved(index),
                    tooltip: 'Remove entry',
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    padding: const EdgeInsets.all(8),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 详细信息 - 使用可滚动容器
          if (!isBaseAsset) ...[
            _buildConditionInfo(context, {}, index),
            const SizedBox(height: 8),
          ],

          if (entry.precedence != null) ...[
            _buildPrecedenceInfoRow(
              context,
              'Precedence',
              entry.precedence!,
              Icons.priority_high,
            ),
            const SizedBox(height: 8),
          ],

          // 显示Indoors/Outdoors信息
          if (entry.conditionData != null) ...[
            _buildIndoorsOutdoorsInfo(context, entry.conditionData!),
            const SizedBox(height: 8),
          ],

          // 显示Weight信息（如果不是默认值1）
          if (entry.weight != null && entry.weight != '1') ...[
            _buildPrecedenceInfoRow(
              context,
              'Weight',
              entry.weight!,
              Icons.tune,
            ),
            const SizedBox(height: 8),
          ],

          if (entry.isIslandAttire == true) ...[
            _buildInfoRow(
              context,
              'Island Attire',
              'Yes',
              Icons.beach_access,
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF0097A7) // 浅色模式下使用深青色，更加醒目
                  : const Color(0xFF00BCD4), // 深色模式下使用青色
            ),
            const SizedBox(height: 8),
          ],

          // 预设信息
          if (entry.presets.isNotEmpty && !isBaseAsset) ...[
            _buildInfoRow(
              context,
              'Preset',
              entry.presets.first,
              Icons.category,
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFFD32F2F) // 浅色模式下使用深红色，更加醒目
                  : const Color(0xFFEF5350), // 深色模式下使用红色
            ),
          ],

          // 基础资源信息
          if (isBaseAsset) ...[
            _buildInfoRow(
              context,
              'Description',
              'Base character and portrait assets without conditions',
              Icons.info_outline,
              Theme.of(context).brightness == Brightness.light
                  ? const Color(0xFF455A64) // 浅色模式下使用深蓝灰色，更加醒目
                  : const Color(0xFF78909C), // 深色模式下使用blue grey
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPrecedenceInfoRow(
      BuildContext context, String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建条件信息显示 - 显示简单的摘要文字，带悬浮效果
  Widget _buildConditionInfo(
      BuildContext context, Map<String, dynamic> condition, int entryIndex) {
    // 获取当前entry对应的conditionData
    final conditionData = widget.entriesConditionData[entryIndex];

    if (conditionData != null) {
      final summary = conditionData.generateSummary();

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFE8F5E8) // 浅色模式下使用浅绿色背景
              : Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? const Color(0xFF4CAF50) // 浅色模式下使用绿色边框
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.light
                    ? const Color(0xFF4CAF50) // 浅色模式下使用绿色背景
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.info_outline,
                size: 16,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.white // 浅色模式下使用白色图标
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Condition: ',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            Expanded(
              child: _buildConditionSummaryWithTooltipFromData(
                  context, summary, entryIndex),
            ),
          ],
        ),
      );
    }

    // 如果没有ConditionData，显示默认文本
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainer
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.info_outline,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Condition: ',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Expanded(
            child: Text(
              'No condition data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建带悬浮效果的条件摘要显示（使用ConditionData）
  Widget _buildConditionSummaryWithTooltipFromData(
      BuildContext context, String summary, int entryIndex) {
    return ConditionTooltipHelper.buildConditionSummaryWithTooltip(
      context: context,
      summary: summary,
      onHover: () => _showDetailedTooltipFromDataSimple(context, entryIndex),
      onExit: _startHideTooltipTimer,
    );
  }

  void _hideDetailedTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    _hideTooltipTimer?.cancel();
  }

  void _startHideTooltipTimer() {
    _hideTooltipTimer?.cancel();
    _hideTooltipTimer = Timer(const Duration(milliseconds: 300), () {
      if (_tooltipOverlay != null) {
        _hideDetailedTooltip();
      }
    });
  }

  void _cancelHideTooltipTimer() {
    _hideTooltipTimer?.cancel();
  }

  /// 显示基于ConditionData的详细tooltip（无事件参数版本）
  void _showDetailedTooltipFromDataSimple(
      BuildContext context, int entryIndex) {
    final conditionData = widget.entriesConditionData[entryIndex];
    if (conditionData == null) return;

    _hideDetailedTooltip();

    // 使用控件右侧位置
    final position = ConditionTooltipHelper.calculateRightPosition(
      context: context,
      triggerKey: _entryKeys[entryIndex]!,
      offsetX: 15, // 距离控件右侧15像素
      offsetY: 0, // 垂直对齐控件中心
    );

    _tooltipOverlay = ConditionTooltipHelper.showConditionTooltip(
      context: context,
      position: position,
      content: ConditionBuilder.buildDetailedConditionDisplay(
        context,
        selectedSeasons: conditionData.selectedSeasons,
        eventIds: conditionData.eventIds,
        locations: conditionData.locations,
      ),
      onHide: _hideDetailedTooltip,
      onCancelHide: _cancelHideTooltipTimer,
      onStartHide: _startHideTooltipTimer,
      useFixedPosition: true, // 使用固定位置（右侧）
    );
  }

  /// 构建Indoors/Outdoors信息显示
  Widget _buildIndoorsOutdoorsInfo(
      BuildContext context, ConditionData conditionData) {
    final isIndoors = conditionData.isIndoors;
    final isOutdoors = conditionData.isOutdoors;

    // 如果两者都为true，显示"All Locations"
    if (isIndoors && isOutdoors) {
      return _buildInfoRow(
        context,
        'Location',
        'All Locations',
        Icons.location_on,
        Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF388E3C) // 浅色模式下使用深绿色
            : const Color(0xFF4CAF50), // 深色模式下使用绿色
      );
    }

    // 如果只有Indoors为true
    if (isIndoors && !isOutdoors) {
      return _buildInfoRow(
        context,
        'Location',
        'Indoors Only',
        Icons.home,
        Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF1976D2) // 浅色模式下使用深蓝色
            : const Color(0xFF2196F3), // 深色模式下使用蓝色
      );
    }

    // 如果只有Outdoors为true
    if (!isIndoors && isOutdoors) {
      return _buildInfoRow(
        context,
        'Location',
        'Outdoors Only',
        Icons.landscape,
        Theme.of(context).brightness == Brightness.light
            ? const Color(0xFFF57C00) // 浅色模式下使用深橙色
            : const Color(0xFFFF9800), // 深色模式下使用橙色
      );
    }

    // 如果两者都为false（理论上不应该发生）
    return _buildInfoRow(
      context,
      'Location',
      'No Location',
      Icons.location_off,
      Theme.of(context).brightness == Brightness.light
          ? const Color(0xFFD32F2F) // 浅色模式下使用深红色
          : const Color(0xFFEF5350), // 深色模式下使用红色
    );
  }

  @override
  void dispose() {
    _hideDetailedTooltip();
    _hideTooltipTimer?.cancel();
    super.dispose();
  }
}
