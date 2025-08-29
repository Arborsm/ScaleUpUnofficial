import 'package:flutter/material.dart';
import '../../../constants/content_patcher_constants.dart';

/// 位置选择Tab组件
class LocationTab extends StatelessWidget {
  final List<String> locations;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  const LocationTab({
    super.key,
    required this.locations,
    required this.controller,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ContentPatcherConstants.uiCommonLocations,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final location in ContentPatcherConstants.commonLocations)
                  FilterChip(
                    label: Text(location),
                    selected: locations.contains(location),
                    onSelected: (selected) {
                      if (selected) {
                        // 添加位置
                        if (!locations.contains(location)) {
                          controller.text = location;
                          onAdd();
                        }
                      } else {
                        // 移除位置
                        onRemove(location);
                      }
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      labelText: ContentPatcherConstants.uiAddCustomLocation,
                      isDense: true,
                    ),
                    onSubmitted: (_) => onAdd(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: onAdd,
                  child: Text(ContentPatcherConstants.uiAdd),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final name in locations)
                  InputChip(
                    label: Text(name),
                    onDeleted: () => onRemove(name),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
