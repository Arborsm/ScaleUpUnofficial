import 'package:flutter/material.dart';

import '../widgets/content_patcher_settings.dart';
import '../widgets/appearance_tree.dart';
import '../widgets/json_preview.dart';

class ContentPatcherScreen extends StatelessWidget {
  const ContentPatcherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Row(
        children: [
          // Left panel - Settings and tree
          Container(
            width: 400,
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: [
                ContentPatcherSettings(),
                SizedBox(height: 16),
                Expanded(child: AppearanceTree()),
              ],
            ),
          ),

          // Divider
          Container(
            width: 1,
            color: Theme.of(context).dividerColor,
          ),

          // Right panel - JSON preview
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: const JsonPreview(),
            ),
          ),
        ],
      ),
    );
  }
}
