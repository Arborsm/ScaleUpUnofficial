import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/condition_entry.dart';
import '../models/condition_data.dart';
import '../utils/preset_utils.dart';
import '../constants/content_patcher_constants.dart';
import '../providers/sprite_provider.dart';
import '../widgets/cp/entry_manager.dart';
import '../widgets/cp/character_portrait_selector.dart';
import '../widgets/cp/condition_builder.dart';
import '../widgets/cp/definition_panel.dart';
import '../widgets/cp/json_preview.dart';

class ContentPatcherScreen extends StatefulWidget {
  const ContentPatcherScreen({super.key});

  @override
  State<ContentPatcherScreen> createState() => _ContentPatcherScreenState();
}

class _ContentPatcherScreenState extends State<ContentPatcherScreen> {
  // UI状态
  final Set<String> _selectedSeasons = <String>{};
  final List<String> _eventIds = <String>[];
  final TextEditingController _eventController = TextEditingController();
  final List<String> _locations = <String>[];
  final TextEditingController _locationController = TextEditingController();

  // 类型选择
  Set<String> _selectedTypes = <String>{};

  // 角色名称
  String _characterName = 'Haley';

  // 条目列表
  final List<ConditionEntry> _entries = <ConditionEntry>[];

  // 当前选中的条目索引
  int _selectedEntryIndex = -1;

  @override
  void dispose() {
    _eventController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          // 左侧面板 - 生成的条目
          Container(
            width: 300,
            padding: const EdgeInsets.all(16),
            child: EntryManager(
              entries: _entries,
              selectedTypes: _selectedTypes,
              onPresetAdded: _addPresetEntry,
              onEntryRemoved: _removeEntry,
              onEntrySelected: _selectEntry,
              characterName: _characterName,
              selectedEntryIndex: _selectedEntryIndex,
              entriesConditionData: Map.fromEntries(
                _entries.asMap().entries.map(
                      (entry) => MapEntry<int, ConditionData>(
                        entry.key,
                        entry.value.conditionData ??
                            ConditionData(
                              selectedSeasons: _selectedSeasons,
                              eventIds: _eventIds,
                              locations: _locations,
                            ),
                      ),
                    ),
              ),
            ),
          ),

          // 分隔线
          Container(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),

          // 中间面板 - 角色 + 条件
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CharacterPortraitSelector(
                  selectedTypes: _selectedTypes,
                  onTypesChanged: _onTypesChanged,
                  characterName: _characterName,
                  onCharacterNameChanged: _onCharacterNameChanged,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ConditionBuilder(
                    selectedSeasons: _selectedSeasons,
                    eventIds: _eventIds,
                    locations: _locations,
                    eventController: _eventController,
                    locationController: _locationController,
                    onSeasonToggle: _toggleSeason,
                    onEventAdd: _addEvent,
                    onEventRemove: _removeEvent,
                    onLocationAdd: _addLocation,
                    onLocationRemove: _removeLocation,
                    onAddEntry: _addEntry,
                    canAddEntry: _canAddEntry(),
                  ),
                ),
              ],
            ),
          ),

          // 分隔线
          Container(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),

          // 定义面板
          Container(
            width: 350,
            padding: const EdgeInsets.all(16),
            child: _entries.isNotEmpty && _selectedEntryIndex >= 0
                ? DefinitionPanel(
                    entry: _entries[_selectedEntryIndex],
                    onEntryUpdated: (updatedEntry) {
                      _updateEntry(_selectedEntryIndex, updatedEntry);
                    },
                    characterName: _characterName,
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                        width: 1,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _entries.isEmpty
                            ? 'No entries available.\nAdd an entry to see definition panel.'
                            : 'Select an entry to edit its definition.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
          ),

          // 分隔线
          Container(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),

          // 分隔线
          Container(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),

          // 右侧面板 - JSON预览（自动占用剩余空间）
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Consumer<SpriteProvider>(
                builder: (context, spriteProvider, child) {
                  return JsonPreview(
                    key: ValueKey(_entries.length), // 强制在entries数量变化时重新构建
                    entries: _entries.map((entry) => entry.toMap()).toList(),
                    spriteData: spriteProvider.spriteData,
                    characterName: _characterName,
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 事件处理方法
  void _onTypesChanged(Set<String> types) {
    setState(() {
      _selectedTypes = types;
    });
  }

  void _onCharacterNameChanged(String characterName) {
    setState(() {
      _characterName = characterName;
    });
  }

  void _toggleSeason(String season) {
    setState(() {
      if (_selectedSeasons.contains(season)) {
        _selectedSeasons.remove(season);
      } else {
        _selectedSeasons.add(season);
      }
    });
  }

  void _addEvent() {
    final value = _eventController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_eventIds.contains(value)) {
        _eventIds.add(value);
      }
      _eventController.clear();
    });
  }

  void _removeEvent(String id) {
    setState(() {
      _eventIds.remove(id);
    });
  }

  void _addLocation() {
    final value = _locationController.text.trim();
    if (value.isEmpty) return;
    setState(() {
      if (!_locations.contains(value)) {
        _locations.add(value);
      }
      _locationController.clear();
    });
  }

  void _removeLocation(String name) {
    setState(() {
      _locations.remove(name);
    });
  }

  void _addEntry() {
    // 检查是否选择了类型
    if (_selectedTypes.isEmpty) {
      return;
    }

    // 使用工具类生成条件信息
    final conditionText = PresetUtils.buildConditionText(
      selectedSeasons: _selectedSeasons,
      eventIds: _eventIds,
      locations: _locations,
    );

    // 检查是否已存在相同的Condition
    final hasDuplicateCondition =
        _entries.any((entry) => entry.conditionText == conditionText);

    if (hasDuplicateCondition) {
      // 显示提示信息，不添加重复条目
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Duplicate condition configuration already exists, cannot add duplicate entry'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final conditionData = PresetUtils.buildConditionData(
      selectedSeasons: _selectedSeasons,
      eventIds: _eventIds,
      locations: _locations,
    );

    final precedence = PresetUtils.determinePrecedence(
      selectedSeasons: _selectedSeasons,
      eventIds: _eventIds,
      locations: _locations,
    );

    final isIslandAttire = PresetUtils.isIslandAttire(_locations);

    final generatedPresets = PresetUtils.generatePresetNamesFromConditions(
      selectedSeasons: _selectedSeasons,
      eventIds: _eventIds,
      locations: _locations,
    );

    // 生成唯一预设名称
    final uniquePresets = PresetUtils.generateUniquePresets(
      generatedPresets,
      conditionText,
      _entries.map((e) => e.toMap()).toList(),
    );

    // 创建一个包含所有选择类型的条目
    final entry = ConditionEntry(
      characterType: _selectedTypes
              .contains(ContentPatcherConstants.conditionTypeCharacter)
          ? ContentPatcherConstants.conditionTypeCharacter
          : '',
      portraitType:
          _selectedTypes.contains(ContentPatcherConstants.conditionTypePortrait)
              ? ContentPatcherConstants.conditionTypePortrait
              : '',
      conditionText: conditionText,
      presets: uniquePresets,
      conditionData: conditionData,
      precedence: precedence,
      weight: '1',
      isIslandAttire: isIslandAttire,
    );

    setState(() {
      _entries.add(entry);
      _selectedEntryIndex = _entries.length - 1; // 自动选择新添加的条目
    });
  }

  void _addPresetEntry(ConditionEntry entry) {
    setState(() {
      _entries.add(entry);
      _selectedEntryIndex = _entries.length - 1; // 自动选择新添加的条目
    });
  }

  void _removeEntry(int index) {
    setState(() {
      _entries.removeAt(index);

      // 更新选中索引
      if (_entries.isEmpty) {
        _selectedEntryIndex = -1; // 没有条目时设为-1
      } else if (_selectedEntryIndex >= _entries.length) {
        _selectedEntryIndex = _entries.length - 1; // 如果选中的索引超出范围，设为最后一个
      } else if (_selectedEntryIndex == index) {
        // 如果删除的是当前选中的条目，选择前一个条目
        _selectedEntryIndex = index > 0 ? index - 1 : 0;
      }
    });
  }

  void _updateEntry(int index, ConditionEntry updatedEntry) {
    setState(() {
      _entries[index] = updatedEntry;
    });
  }

  void _selectEntry(int index) {
    setState(() {
      _selectedEntryIndex = index;
    });
  }

  bool _canAddEntry() {
    return _selectedTypes.isNotEmpty &&
        (_selectedSeasons.isNotEmpty ||
            _eventIds.isNotEmpty ||
            _locations.isNotEmpty);
  }
}
