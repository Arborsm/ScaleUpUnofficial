import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sprite_provider.dart';
import '../constants/app_constants.dart';

class AppearanceTree extends StatefulWidget {
  const AppearanceTree({super.key});

  @override
  State<AppearanceTree> createState() => _AppearanceTreeState();
}

class _AppearanceTreeState extends State<AppearanceTree> {
  final Map<String, bool> _expandedItems = {};

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
            'Appearance Entries',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: AppConstants.appearanceKeys.length,
              itemBuilder: (context, index) {
                final key = AppConstants.appearanceKeys[index];
                final suffix = key.suffix;
                final isExpanded = _expandedItems[suffix] ?? false;

                return Column(
                  children: [
                    _buildParentItem(context, spriteProvider, key, isExpanded),
                    if (isExpanded)
                      _buildChildItems(context, spriteProvider, key),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentItem(
    BuildContext context,
    SpriteProvider spriteProvider,
    appearanceKey,
    bool isExpanded,
  ) {
    final suffix = appearanceKey.suffix;
    final isEnabled = spriteProvider.appearanceEntryVars[suffix] ?? false;

    return InkWell(
      onTap: () {
        setState(() {
          _expandedItems[suffix] = !isExpanded;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            Icon(
              isExpanded ? Icons.expand_more : Icons.chevron_right,
              size: 16,
            ),
            const SizedBox(width: 4),
            Checkbox(
              value: isEnabled,
              onChanged: (value) {
                if (value != null) {
                  spriteProvider.setAppearanceEntryVar(suffix, value);
                }
              },
            ),
            const SizedBox(width: 4),
            Text(
              suffix,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildItems(
    BuildContext context,
    SpriteProvider spriteProvider,
    appearanceKey,
  ) {
    final suffix = appearanceKey.suffix;
    final parentEnabled = spriteProvider.appearanceEntryVars[suffix] ?? false;
    final spriteEnabled = spriteProvider.appearanceSpriteVars[suffix] ?? false;
    final portraitEnabled =
        spriteProvider.appearancePortraitVars[suffix] ?? false;

    return Padding(
      padding: const EdgeInsets.only(left: 24),
      child: Column(
        children: [
          _buildChildItem(
            context,
            'Sprite',
            spriteEnabled && parentEnabled,
            parentEnabled
                ? (value) => spriteProvider.setAppearanceSpriteVar(
                    suffix, value ?? false)
                : null,
          ),
          _buildChildItem(
            context,
            'Portrait',
            portraitEnabled && parentEnabled,
            parentEnabled
                ? (value) => spriteProvider.setAppearancePortraitVar(
                    suffix, value ?? false)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildChildItem(
    BuildContext context,
    String label,
    bool isEnabled,
    ValueChanged<bool?>? onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isEnabled,
            onChanged: onChanged,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }
}
