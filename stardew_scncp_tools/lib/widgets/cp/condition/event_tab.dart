import 'package:flutter/material.dart';
import '../../../constants/content_patcher_constants.dart';

/// 事件选择Tab组件
class EventTab extends StatelessWidget {
  final List<String> eventIds;
  final TextEditingController controller;
  final VoidCallback onAdd;
  final void Function(String) onRemove;

  const EventTab({
    super.key,
    required this.eventIds,
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
              ContentPatcherConstants.uiCommonEvents,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final event in ContentPatcherConstants.commonEvents)
                  FilterChip(
                    label: Text(event),
                    selected: eventIds.contains(event),
                    onSelected: (selected) {
                      if (selected) {
                        // 添加事件
                        if (!eventIds.contains(event)) {
                          controller.text = event;
                          onAdd();
                        }
                      } else {
                        // 移除事件
                        onRemove(event);
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
                      labelText: ContentPatcherConstants.uiAddCustomEvent,
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
                for (final id in eventIds)
                  InputChip(
                    label: Text(id),
                    onDeleted: () => onRemove(id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
