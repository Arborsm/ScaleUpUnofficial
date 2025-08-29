import 'package:flutter/material.dart';
import '../../../constants/content_patcher_constants.dart';

/// 季节选择Tab组件
class SeasonTab extends StatelessWidget {
  final Set<String> selectedSeasons;
  final void Function(String) onToggle;

  const SeasonTab({
    super.key,
    required this.selectedSeasons,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final season in ContentPatcherConstants.seasons)
            FilterChip(
              label: Text(season[0].toUpperCase() + season.substring(1)),
              selected: selectedSeasons.contains(season),
              onSelected: (_) => onToggle(season),
            ),
        ],
      ),
    );
  }
}
