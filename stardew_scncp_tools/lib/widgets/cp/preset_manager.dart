import 'package:flutter/material.dart';
import '../../constants/content_patcher_constants.dart';
import '../../models/preset_info.dart';
import '../../models/condition_entry.dart';
import '../../models/condition_data.dart';
import '../../utils/preset_utils.dart';

/// 预设管理组件
class PresetManager extends StatefulWidget {
  final Set<String> selectedTypes;
  final List<ConditionEntry> existingEntries;
  final List<ConditionEntry> pendingEntries;
  final Function(ConditionEntry) onPresetAdded;
  final String characterName;

  const PresetManager({
    super.key,
    required this.selectedTypes,
    required this.existingEntries,
    required this.pendingEntries,
    required this.onPresetAdded,
    required this.characterName,
  });

  @override
  State<PresetManager> createState() => _PresetManagerState();
}

class _PresetManagerState extends State<PresetManager> {
  // 为每个预设创建独立的选择状态
  final Map<String, Set<String>> _presetSelections = {};

  @override
  void initState() {
    super.initState();
    // 初始化所有预设的选择状态
    _initializePresetSelections();
  }

  void _initializePresetSelections() {
    // 初始化季节预设
    for (final preset in _createSeasonPresets()) {
      _presetSelections[preset.name] = <String>{};
    }
    // 初始化事件预设
    for (final preset in _createEventPresets()) {
      _presetSelections[preset.name] = <String>{};
    }
    // 初始化位置预设
    for (final preset in _createLocationPresets()) {
      _presetSelections[preset.name] = <String>{};
    }
    // 初始化基础资源预设
    for (final preset in _createBaseAssetPresets()) {
      _presetSelections[preset.name] = <String>{};
    }
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.settings),
      onPressed: () => _showPresetDialog(context),
      tooltip: ContentPatcherConstants.uiSelectPresets,
    );
  }

  void _showPresetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext dialogContext, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(ContentPatcherConstants.uiAddPresetToPanel),
              content: SizedBox(
                width: 400,
                height: 300,
                child: ListView(
                  children: [
                    _buildPresetCategory(
                      'Base Assets',
                      _createBaseAssetPresets(),
                      dialogContext,
                      setDialogState,
                    ),
                    _buildPresetCategory(
                      ContentPatcherConstants.uiSeasonPresets,
                      _createSeasonPresets(),
                      dialogContext,
                      setDialogState,
                    ),
                    _buildPresetCategory(
                      ContentPatcherConstants.uiEventPresets,
                      _createEventPresets(),
                      dialogContext,
                      setDialogState,
                    ),
                    _buildPresetCategory(
                      ContentPatcherConstants.uiLocationPresets,
                      _createLocationPresets(),
                      dialogContext,
                      setDialogState,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(ContentPatcherConstants.uiCancel),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildPresetCategory(
    String title,
    List<PresetInfo> presets,
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        ...presets.map((preset) =>
            _buildPresetItem(preset, dialogContext, setDialogState)),
        const Divider(),
      ],
    );
  }

  List<PresetInfo> _createSeasonPresets() {
    return ContentPatcherConstants.seasonPresets
        .map((preset) => _createPresetWithCharacterName(preset))
        .toList();
  }

  List<PresetInfo> _createEventPresets() {
    return ContentPatcherConstants.eventPresets
        .map((preset) => _createPresetWithCharacterName(preset))
        .toList();
  }

  List<PresetInfo> _createLocationPresets() {
    return ContentPatcherConstants.locationPresets
        .map((preset) => _createPresetWithCharacterName(preset))
        .toList();
  }

  PresetInfo _createPresetWithCharacterName(Map<String, dynamic> presetMap) {
    final name = presetMap['name']?.toString() ?? '';
    final condition = presetMap['condition']?.toString() ?? '';
    final precedence = presetMap['precedence']?.toString() ?? '';
    final isIslandAttire = presetMap['isIslandAttire'] ?? false;

    // 替换角色名称占位符
    final processedName =
        name.replaceAll('{{CharacterName}}', widget.characterName);

    return PresetInfo(
      name: processedName,
      condition: condition,
      precedence: precedence,
      isIslandAttire: isIslandAttire,
    );
  }

  void _addPresetToPanel(BuildContext dialogContext, PresetInfo preset) {
    // 获取当前预设的选择状态
    final presetSelection = _presetSelections[preset.name] ?? <String>{};

    // 检查是否至少选择了一种类型
    if (preset.supportsCharacter || preset.supportsPortrait) {
      final hasSelection = presetSelection
              .contains(ContentPatcherConstants.conditionTypeCharacter) ||
          presetSelection
              .contains(ContentPatcherConstants.conditionTypePortrait);
      if (!hasSelection) {
        // 显示错误提示
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content:
                Text('Please select at least one type (Character or Portrait)'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (preset.condition.isEmpty) {
      // 基础资源预设（无条件的）
      // 提取实际预设名称（移除角色前缀）
      final presetName = PresetUtils.extractPresetName(preset.name);

      // 检查条件是否已存在并生成唯一预设名称
      final String conditionText = '';
      final allEntries = [...widget.existingEntries, ...widget.pendingEntries];
      final List<String> uniquePresets = PresetUtils.generateUniquePresets(
        [presetName],
        conditionText,
        allEntries.map((e) => e.toMap()).toList(),
      );

      // 创建条目 - 同时包含Character和Portrait类型
      final entry = ConditionEntry(
        characterType: presetSelection
                .contains(ContentPatcherConstants.conditionTypeCharacter)
            ? ContentPatcherConstants.conditionTypeCharacter
            : '',
        portraitType: presetSelection
                .contains(ContentPatcherConstants.conditionTypePortrait)
            ? ContentPatcherConstants.conditionTypePortrait
            : '',
        conditionText: conditionText,
        presets: uniquePresets,
        conditionData: ConditionData(
          selectedSeasons: {},
          eventIds: [],
          locations: [],
        ),
        precedence: preset.precedence,
        weight: '1',
        isIslandAttire: false,
      );

      // 通知父组件添加预设
      widget.onPresetAdded(entry);
    } else {
      // 有条件预设（季节、事件、位置等）
      // 提取实际预设名称（移除角色前缀）
      final presetName = PresetUtils.extractPresetName(preset.name);

      // 检查条件是否已存在并生成唯一预设名称
      final String conditionText = preset.condition;
      final allEntries = [...widget.existingEntries, ...widget.pendingEntries];
      final List<String> uniquePresets = PresetUtils.generateUniquePresets(
        [presetName],
        conditionText,
        allEntries.map((e) => e.toMap()).toList(),
      );

      // 创建条目 - 同时包含Character和Portrait类型
      final entry = ConditionEntry(
        characterType: presetSelection
                .contains(ContentPatcherConstants.conditionTypeCharacter)
            ? ContentPatcherConstants.conditionTypeCharacter
            : '',
        portraitType: presetSelection
                .contains(ContentPatcherConstants.conditionTypePortrait)
            ? ContentPatcherConstants.conditionTypePortrait
            : '',
        conditionText: conditionText,
        presets: uniquePresets,
        conditionData: PresetUtils.parsePresetCondition(preset.condition),
        precedence: preset.precedence,
        weight: '1',
        isIslandAttire: preset.isIslandAttire,
      );

      // 通知父组件添加预设
      widget.onPresetAdded(entry);
    }

    // 关闭对话框
    Navigator.of(dialogContext).pop();
  }

  List<PresetInfo> _createBaseAssetPresets() {
    return [
      PresetInfo(
        name: widget.characterName,
        condition: '',
        precedence: '-1200',
        supportsCharacter: true,
        supportsPortrait: true,
      ),
    ];
  }

  Widget _buildPresetItem(PresetInfo preset, BuildContext dialogContext,
      StateSetter setDialogState) {
    // 为每个预设创建独立的选择状态
    final bool isCharacterSelected = _presetSelections[preset.name]
            ?.contains(ContentPatcherConstants.conditionTypeCharacter) ??
        false;
    final bool isPortraitSelected = _presetSelections[preset.name]
            ?.contains(ContentPatcherConstants.conditionTypePortrait) ??
        false;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        preset.name,
                        style: Theme.of(dialogContext)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        preset.condition.isEmpty
                            ? 'Base Assets - ${widget.characterName}'
                            : 'Condition: ${preset.condition}',
                        style: Theme.of(dialogContext)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(dialogContext)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                FilledButton(
                  onPressed: () => _addPresetToPanel(dialogContext, preset),
                  child: Text(ContentPatcherConstants.uiAdd),
                ),
              ],
            ),
            if (preset.supportsCharacter || preset.supportsPortrait) ...[
              const SizedBox(height: 12),
              Text(
                'Select Type:',
                style: Theme.of(dialogContext).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (preset.supportsCharacter)
                    FilterChip(
                      label: const Text('Character'),
                      selected: isCharacterSelected,
                      onSelected: (bool selected) {
                        // 更新本地预设选择状态
                        setDialogState(() {
                          _presetSelections[preset.name] ??= <String>{};
                          if (selected) {
                            _presetSelections[preset.name]!.add(
                                ContentPatcherConstants.conditionTypeCharacter);
                          } else {
                            _presetSelections[preset.name]!.remove(
                                ContentPatcherConstants.conditionTypeCharacter);
                          }
                        });
                      },
                      selectedColor:
                          Theme.of(dialogContext).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(dialogContext)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                  if (preset.supportsPortrait)
                    FilterChip(
                      label: const Text('Portrait'),
                      selected: isPortraitSelected,
                      onSelected: (bool selected) {
                        // 更新本地预设选择状态
                        setDialogState(() {
                          _presetSelections[preset.name] ??= <String>{};
                          if (selected) {
                            _presetSelections[preset.name]!.add(
                                ContentPatcherConstants.conditionTypePortrait);
                          } else {
                            _presetSelections[preset.name]!.remove(
                                ContentPatcherConstants.conditionTypePortrait);
                          }
                        });
                      },
                      selectedColor:
                          Theme.of(dialogContext).colorScheme.primaryContainer,
                      checkmarkColor: Theme.of(dialogContext)
                          .colorScheme
                          .onPrimaryContainer,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
