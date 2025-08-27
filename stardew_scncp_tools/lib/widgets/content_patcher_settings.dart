import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sprite_provider.dart';
import 'character_name_input.dart';

class ContentPatcherSettings extends StatelessWidget {
  const ContentPatcherSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final spriteProvider = Provider.of<SpriteProvider>(context);

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
            'Content Patcher Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Character Name: combined input
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Character Name',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: CharacterNameInput(
                  currentValue: spriteProvider.characterName,
                  onChanged: (value) => spriteProvider.setCharacterName(value),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Scale
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Scale',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<int>(
                  initialValue: spriteProvider.cpScale,
                  items: List.generate(
                    9,
                    (index) => DropdownMenuItem(
                      value: index + 1,
                      child: Text('${index + 1}x'),
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      spriteProvider.setCpScale(value);
                    }
                  },
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Checkboxes
          _buildSwitchField(
            context: context,
            label: 'Include Loading Action',
            value: spriteProvider.cpIncludeLoad,
            onChanged: (value) => spriteProvider.setCpIncludeLoad(value),
          ),
          _buildSwitchField(
            context: context,
            label: 'Include Scale Up Action',
            value: spriteProvider.cpIncludeAssets,
            onChanged: (value) => spriteProvider.setCpIncludeAssets(value),
          ),
          _buildSwitchField(
            context: context,
            label: 'Use Editor Page Sprite JSON',
            value: spriteProvider.cpUsePage1Sprite,
            onChanged: (value) => spriteProvider.setCpUsePage1Sprite(value),
          ),
          _buildSwitchField(
            context: context,
            label: 'Include Appearance Section',
            value: spriteProvider.cpIncludeAppearance,
            onChanged: (value) => spriteProvider.setCpIncludeAppearance(value),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchField({
    required BuildContext context,
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
