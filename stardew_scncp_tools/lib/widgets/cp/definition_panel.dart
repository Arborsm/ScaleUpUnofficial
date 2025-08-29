import 'package:flutter/material.dart';
import '../../models/condition_entry.dart';

/// 定义面板组件 - 包含所有字段的定义和编辑
class DefinitionPanel extends StatefulWidget {
  final ConditionEntry? entry;
  final Function(ConditionEntry) onEntryUpdated;
  final String characterName;

  const DefinitionPanel({
    super.key,
    this.entry,
    required this.onEntryUpdated,
    required this.characterName,
  });

  @override
  State<DefinitionPanel> createState() => _DefinitionPanelState();
}

class _DefinitionPanelState extends State<DefinitionPanel> {
  late TextEditingController _idController;
  late TextEditingController _portraitController;
  late TextEditingController _spriteController;
  late TextEditingController _precedenceController;
  late TextEditingController _weightController;
  late bool _isIndoors;
  late bool _isOutdoors;
  late bool _isIslandAttire;
  late bool _hasCondition;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final entry = widget.entry;
    _idController = TextEditingController(
      text: entry?.presets.isNotEmpty == true ? entry!.presets.first : '',
    );
    _portraitController = TextEditingController(
      text: entry?.portraitType.isNotEmpty == true
          ? 'Portraits/${widget.characterName}'
          : '',
    );
    _spriteController = TextEditingController(
      text: entry?.characterType.isNotEmpty == true
          ? 'Characters/${widget.characterName}'
          : '',
    );
    _precedenceController = TextEditingController(
      text: entry?.precedence ?? '0',
    );
    _weightController = TextEditingController(
      text: entry?.weight ?? '1',
    );

    // 从条目的条件数据中获取Indoors和Outdoors信息
    if (entry?.conditionData != null) {
      final conditionData = entry!.conditionData!;
      _isIndoors = conditionData.isIndoors;
      _isOutdoors = conditionData.isOutdoors;
    } else {
      _isIndoors = true;
      _isOutdoors = true;
    }

    _isIslandAttire = entry?.isIslandAttire ?? false;
    _hasCondition = true;
  }

  @override
  void dispose() {
    _idController.dispose();
    _portraitController.dispose();
    _spriteController.dispose();
    _precedenceController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(DefinitionPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry != widget.entry ||
        oldWidget.characterName != widget.characterName) {
      _initializeControllers();
    }
  }

  void _updateEntry() {
    if (widget.entry == null) return;

    // 更新条件数据
    final conditionData = widget.entry!.conditionData?.copyWith(
      isIndoors: _isIndoors,
      isOutdoors: _isOutdoors,
    );

    final updatedEntry = widget.entry!.copyWith(
      presets: _idController.text.isNotEmpty ? [_idController.text] : [],
      precedence: _precedenceController.text,
      weight: _weightController.text,
      isIslandAttire: _isIslandAttire,
      conditionData: conditionData,
      // 添加portrait和character字段的双向绑定
      portraitType: _portraitController.text.isNotEmpty ? 'portrait' : '',
      characterType: _spriteController.text.isNotEmpty ? 'character' : '',
    );

    widget.onEntryUpdated(updatedEntry);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Definition Panel',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (widget.entry != null) ...[
              const SizedBox(height: 8),
              Text(
                'Editing: ${widget.entry!.presets.isNotEmpty ? widget.entry!.presets.first : 'Unnamed Entry'}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            const SizedBox(height: 16),

            // ID字段
            _buildFieldWithTooltip(
              controller: _idController,
              label: 'Id',
              tooltip:
                  'The unique string ID for this entry within the current list.',
              onChanged: (_) => _updateEntry(),
            ),

            // Indoors/Outdoors字段
            _buildIndoorsOutdoorsField(),

            const SizedBox(height: 16),

            // Condition字段
            _buildConditionField(),

            const SizedBox(height: 16),

            // Portrait字段
            _buildFieldWithTooltip(
              controller: _portraitController,
              label: 'Portrait',
              tooltip:
                  '(Optional) The asset name for the portraits texture to load. If omitted or it can\'t be loaded, it will default to the default asset per the Texture field.',
              onChanged: (_) => _updateEntry(),
            ),

            const SizedBox(height: 16),

            // Sprite字段
            _buildFieldWithTooltip(
              controller: _spriteController,
              label: 'Sprite',
              tooltip:
                  '(Optional) The asset name for the sprites texture to load. If omitted or it can\'t be loaded, it will default to the default asset per the Texture field.',
              onChanged: (_) => _updateEntry(),
            ),

            const SizedBox(height: 16),

            // IsIslandAttire字段
            _buildIslandAttireField(),

            const SizedBox(height: 16),

            // Precedence字段
            _buildFieldWithTooltip(
              controller: _precedenceController,
              label: 'Precedence',
              tooltip:
                  '(Optional) The order in which this entry should be checked, where lower values are checked first. This can be a negative value. Default 0.',
              onChanged: (_) => _updateEntry(),
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            // Weight字段
            _buildFieldWithTooltip(
              controller: _weightController,
              label: 'Weight',
              tooltip:
                  '(Optional) If multiple entries with the same Precedence match, the relative weight to use when randomly choosing one. Default 1. For example, let\'s say two appearance entries match: one has a weight of 2, and the other has a weight of 1. Their probability of being chosen is 2/3 and 1/3 respectively.',
              onChanged: (_) => _updateEntry(),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldWithTooltip({
    required TextEditingController controller,
    required String label,
    required String tooltip,
    required Function(String) onChanged,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message: tooltip,
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIndoorsOutdoorsField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Location Type',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  '(Optional) Whether this appearance should be used when indoors and/or outdoors. Both default to true.',
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: CheckboxListTile(
                title: const Text('Indoors'),
                value: _isIndoors,
                onChanged: (value) {
                  setState(() {
                    _isIndoors = value ?? true;
                  });
                  _updateEntry();
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: CheckboxListTile(
                title: const Text('Outdoors'),
                value: _isOutdoors,
                onChanged: (value) {
                  setState(() {
                    _isOutdoors = value ?? true;
                  });
                  _updateEntry();
                },
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConditionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Condition',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  '(Optional) A game state query which indicates whether this entry can be selected. Default true.',
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Enable Condition'),
          value: _hasCondition,
          onChanged: (value) {
            setState(() {
              _hasCondition = value ?? true;
            });
            _updateEntry();
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildIslandAttireField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Island Attire',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            const SizedBox(width: 8),
            Tooltip(
              message:
                  '(Optional) Whether this is island beach attire worn at the resort. Default false. This is mutually exclusive: NPCs will never wear it in other contexts if it\'s true, and will never wear it as island attire if it\'s false.',
              child: Icon(
                Icons.help_outline,
                size: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        CheckboxListTile(
          title: const Text('Is Island Beach Attire'),
          value: _isIslandAttire,
          onChanged: (value) {
            setState(() {
              _isIslandAttire = value ?? false;
            });
            _updateEntry();
          },
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}
