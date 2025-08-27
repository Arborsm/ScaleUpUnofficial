import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/sprite_provider.dart';
import '../services/json_export_service.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final spriteProvider = Provider.of<SpriteProvider>(context);

    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).colorScheme.surface,
      child: Row(
        children: [
          // Load Spritesheet Button
          ElevatedButton.icon(
            onPressed: () => _loadSpritesheet(context, spriteProvider),
            icon: const Icon(Icons.folder_open),
            label: const Text('Load Spritesheet'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(width: 16),

          // Slice Selector (only show if sprites are loaded)
          if (spriteProvider.hasSprites) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: DropdownButton<int>(
                value: spriteProvider.currentSliceIndex,
                items: List.generate(
                  spriteProvider.slices.length,
                  (index) => DropdownMenuItem(
                    value: index,
                    child: Text('Slice ${index + 1}'),
                  ),
                ),
                onChanged: (value) {
                  if (value != null) {
                    spriteProvider.setCurrentSlice(value);
                  }
                },
                hint: const Text('Select Slice'),
                underline: Container(),
              ),
            ),
            const SizedBox(width: 16),
          ],

          // Copy JSON Button
          ElevatedButton.icon(
            onPressed: spriteProvider.hasSprites
                ? () => _copyJsonToClipboard(context, spriteProvider)
                : null,
            icon: const Icon(Icons.copy),
            label: const Text('Copy JSON'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const Spacer(),

          // Status information
          if (spriteProvider.isLoading)
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Loading...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            )
          else if (spriteProvider.hasSprites)
            Text(
              '${spriteProvider.slices.length} slice(s) loaded',
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Text(
              'No sprites loaded',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
        ],
      ),
    );
  }

  Future<void> _loadSpritesheet(
      BuildContext context, SpriteProvider spriteProvider) async {
    try {
      await spriteProvider.loadSpritesheet();

      if (spriteProvider.hasSprites && context.mounted) {
        _showSnackBar(context, 'Spritesheet loaded successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error loading spritesheet: $e', isError: true);
      }
    }
  }

  Future<void> _copyJsonToClipboard(
      BuildContext context, SpriteProvider spriteProvider) async {
    try {
      final jsonData = JsonExportService.generateSpriteJson(spriteProvider);

      // Format JSON string
      final jsonString = JsonExportService.formatJsonString(jsonData);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));

      if (context.mounted) {
        _showSnackBar(context, 'JSON copied to clipboard successfully!');
      }
    } catch (e) {
      if (context.mounted) {
        _showSnackBar(context, 'Error copying JSON: $e', isError: true);
      }
    }
  }

  void _showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
