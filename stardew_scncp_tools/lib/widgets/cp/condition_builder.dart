import 'package:flutter/material.dart';
import '../../constants/content_patcher_constants.dart';
import '../../models/condition_data.dart';
import 'condition_tooltip_helper.dart';
import 'condition/season_tab.dart';
import 'condition/event_tab.dart';
import 'condition/location_tab.dart';
import 'dart:async'; // Add this import

/// 条件构建组件
class ConditionBuilder extends StatefulWidget {
  final Set<String> selectedSeasons;
  final List<String> eventIds;
  final List<String> locations;
  final TextEditingController eventController;
  final TextEditingController locationController;
  final Function(String) onSeasonToggle;
  final VoidCallback onEventAdd;
  final Function(String) onEventRemove;
  final VoidCallback onLocationAdd;
  final Function(String) onLocationRemove;
  final VoidCallback onAddEntry;
  final bool canAddEntry;

  const ConditionBuilder({
    super.key,
    required this.selectedSeasons,
    required this.eventIds,
    required this.locations,
    required this.eventController,
    required this.locationController,
    required this.onSeasonToggle,
    required this.onEventAdd,
    required this.onEventRemove,
    required this.onLocationAdd,
    required this.onLocationRemove,
    required this.onAddEntry,
    required this.canAddEntry,
  });

  @override
  State<ConditionBuilder> createState() => _ConditionBuilderState();

  /// 生成条件摘要文字（如 "Season · Event · Location"）
  static String generateConditionSummary({
    required Set<String> selectedSeasons,
    required List<String> eventIds,
    required List<String> locations,
  }) {
    final List<String> parts = [];

    // 只显示类别，不显示具体内容
    if (selectedSeasons.isNotEmpty) {
      parts.add('Season');
    }

    if (eventIds.isNotEmpty) {
      parts.add('Event');
    }

    if (locations.isNotEmpty) {
      parts.add('Location');
    }

    return parts.isEmpty ? 'No condition' : parts.join(' · ');
  }

  /// 构建详细的条件显示组件
  static Widget buildDetailedConditionDisplay(
    BuildContext context, {
    required Set<String> selectedSeasons,
    required List<String> eventIds,
    required List<String> locations,
  }) {
    final List<Widget> widgets = [];

    // 季节条件
    if (selectedSeasons.isNotEmpty) {
      widgets.add(_buildConditionSectionStatic(
        context,
        'Season',
        selectedSeasons.toList(),
        Icons.wb_sunny,
        Colors.green.shade600,
      ));
    }

    // 事件条件
    if (eventIds.isNotEmpty) {
      widgets.add(_buildConditionSectionStatic(
        context,
        'Event',
        eventIds,
        Icons.event,
        Theme.of(context).colorScheme.primary,
      ));
    }

    // 位置条件
    if (locations.isNotEmpty) {
      widgets.add(_buildConditionSectionStatic(
        context,
        'Location',
        locations,
        Icons.location_on,
        Theme.of(context).colorScheme.tertiary,
      ));
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          'No conditions configured',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  /// 构建单个条件部分
  static Widget _buildConditionSectionStatic(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon == Icons.wb_sunny
                                ? Icons.wb_sunny
                                : icon == Icons.event
                                    ? Icons.event
                                    : Icons.location_on,
                            size: 14,
                            color: color,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ConditionBuilderState extends State<ConditionBuilder> {
  Timer? _hideTooltipTimer;
  final GlobalKey _summaryKey = GlobalKey(); // Add this line

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hideDetailedTooltip(); // Ensure tooltip is hidden when widget is disposed
    super.dispose();
  }

  OverlayEntry? _tooltipOverlay;

  void _showDetailedTooltip(BuildContext context, PointerEvent event) {
    _hideDetailedTooltip();

    // 使用固定位置，相对于触发元素
    final position = ConditionTooltipHelper.calculateFixedPosition(
      context: context,
      triggerKey: _summaryKey,
    );

    _tooltipOverlay = ConditionTooltipHelper.showConditionTooltip(
      context: context,
      position: position,
      content: _buildDetailedConditionDisplay(context),
      onHide: _hideDetailedTooltip,
      onCancelHide: _cancelHideTooltipTimer,
      onStartHide: _startHideTooltipTimer,
      useFixedPosition: true, // 使用固定位置定位方式
    );
  }

  void _hideDetailedTooltip() {
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
    _hideTooltipTimer?.cancel();
  }

  void _startHideTooltipTimer() {
    _hideTooltipTimer?.cancel();
    _hideTooltipTimer = Timer(const Duration(milliseconds: 300), () {
      if (_tooltipOverlay != null) {
        _hideDetailedTooltip();
      }
    });
  }

  void _cancelHideTooltipTimer() {
    _hideTooltipTimer?.cancel();
  }

  Widget _buildConditionSummary(BuildContext context) {
    final conditionData = ConditionData(
      selectedSeasons: widget.selectedSeasons,
      eventIds: widget.eventIds,
      locations: widget.locations,
    );

    final summary = conditionData.generateSummary();

    return Text(
      summary,
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );
  }

  Widget _buildConditionSummaryWithTooltip(BuildContext context) {
    return Container(
      key: _summaryKey, // Assign the GlobalKey here
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _buildConditionSummary(context),
          ),
          const SizedBox(width: 4),
          // 只有感叹号图标有悬浮效果
          MouseRegion(
            onHover: (event) => _showDetailedTooltip(context, event),
            onExit: (_) => _startHideTooltipTimer(),
            child: Icon(
              Icons.info_outline,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: DefaultTabController(
        length: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ContentPatcherConstants.uiConditions,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Condition:',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildConditionSummaryWithTooltip(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            TabBar(
              labelColor: Theme.of(context).colorScheme.primary,
              tabs: const [
                Tab(text: 'Season'),
                Tab(text: 'Event'),
                Tab(text: 'Location'),
              ],
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: TabBarView(
                      children: [
                        SeasonTab(
                          selectedSeasons: widget.selectedSeasons,
                          onToggle: widget.onSeasonToggle,
                        ),
                        EventTab(
                          eventIds: widget.eventIds,
                          controller: widget.eventController,
                          onAdd: widget.onEventAdd,
                          onRemove: widget.onEventRemove,
                        ),
                        LocationTab(
                          locations: widget.locations,
                          controller: widget.locationController,
                          onAdd: widget.onLocationAdd,
                          onRemove: widget.onLocationRemove,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed:
                            widget.canAddEntry ? widget.onAddEntry : null,
                        icon: const Icon(Icons.add),
                        label: Text(ContentPatcherConstants.uiAddToPanel),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedConditionDisplay(BuildContext context) {
    final List<Widget> widgets = [];

    // 季节条件
    if (widget.selectedSeasons.isNotEmpty) {
      widgets.add(_buildConditionSection(
        context,
        'Season',
        widget.selectedSeasons.toList(),
        Icons.wb_sunny,
        Colors.green.shade600, // 使用更深的绿色，提高对比度
      ));
    }

    // 事件条件
    if (widget.eventIds.isNotEmpty) {
      widgets.add(_buildConditionSection(
        context,
        'Event',
        widget.eventIds,
        Icons.event,
        Theme.of(context).colorScheme.primary,
      ));
    }

    // 位置条件
    if (widget.locations.isNotEmpty) {
      widgets.add(_buildConditionSection(
        context,
        'Location',
        widget.locations,
        Icons.location_on,
        Theme.of(context).colorScheme.tertiary,
      ));
    }

    if (widgets.isEmpty) {
      widgets.add(
        Text(
          'No conditions configured',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildConditionSection(
    BuildContext context,
    String title,
    List<String> items,
    IconData icon,
    Color color,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${items.length}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items
                .map((item) => Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            icon == Icons.wb_sunny
                                ? Icons.wb_sunny
                                : icon == Icons.event
                                    ? Icons.event
                                    : Icons.location_on,
                            color: color,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
