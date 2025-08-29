import 'package:flutter/material.dart';
import '../../constants/content_patcher_constants.dart';
import 'character_name_input.dart';

/// 角色和肖像选择组件
class CharacterPortraitSelector extends StatefulWidget {
  final Set<String> selectedTypes;
  final Function(Set<String>) onTypesChanged;
  final String characterName;
  final Function(String) onCharacterNameChanged;

  const CharacterPortraitSelector({
    super.key,
    required this.selectedTypes,
    required this.onTypesChanged,
    required this.characterName,
    required this.onCharacterNameChanged,
  });

  @override
  State<CharacterPortraitSelector> createState() =>
      _CharacterPortraitSelectorState();
}

class _CharacterPortraitSelectorState extends State<CharacterPortraitSelector> {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ContentPatcherConstants.uiCharacterPortrait,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // 角色名称输入
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Character Name:',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              const SizedBox(height: 8),
              CharacterNameInput(
                currentValue: widget.characterName,
                onChanged: widget.onCharacterNameChanged,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 类型选择
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Character'),
                  value: widget.selectedTypes
                      .contains(ContentPatcherConstants.conditionTypeCharacter),
                  onChanged: (bool? value) {
                    final newTypes = Set<String>.from(widget.selectedTypes);
                    if (value == true) {
                      newTypes
                          .add(ContentPatcherConstants.conditionTypeCharacter);
                    } else {
                      newTypes.remove(
                          ContentPatcherConstants.conditionTypeCharacter);
                    }
                    widget.onTypesChanged(newTypes);
                  },
                ),
              ),
              Expanded(
                child: CheckboxListTile(
                  title: const Text('Portrait'),
                  value: widget.selectedTypes
                      .contains(ContentPatcherConstants.conditionTypePortrait),
                  onChanged: (bool? value) {
                    final newTypes = Set<String>.from(widget.selectedTypes);
                    if (value == true) {
                      newTypes
                          .add(ContentPatcherConstants.conditionTypePortrait);
                    } else {
                      newTypes.remove(
                          ContentPatcherConstants.conditionTypePortrait);
                    }
                    widget.onTypesChanged(newTypes);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
