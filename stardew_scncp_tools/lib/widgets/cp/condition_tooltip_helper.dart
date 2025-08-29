import 'package:flutter/material.dart';

/// 条件Tooltip帮助类，提供共享的tooltip逻辑
class ConditionTooltipHelper {
  static const double _tooltipWidth = 500;
  static const double _tooltipMaxHeight = 400;
  static const double _tooltipMinHeight = 200;
  static const double _tooltipContentMaxHeight = 300;

  /// 显示条件详细信息的tooltip
  static OverlayEntry showConditionTooltip({
    required BuildContext context,
    required Offset position,
    required Widget content,
    required VoidCallback onHide,
    required VoidCallback onCancelHide,
    required VoidCallback onStartHide,
    bool useFixedPosition = true, // 添加布尔参数控制定位方式
  }) {
    final overlay = OverlayEntry(
      builder: (context) => Positioned(
        top: useFixedPosition ? position.dy : position.dy + 20, // 根据定位方式选择Y位置
        left: useFixedPosition
            ? position.dx
            : (position.dx - _tooltipWidth / 2).clamp(
                10,
                MediaQuery.of(context).size.width -
                    _tooltipWidth -
                    10), // 根据定位方式选择X位置
        child: MouseRegion(
          onEnter: (_) => onCancelHide(),
          onExit: (_) => onStartHide(),
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: _tooltipWidth,
              constraints: const BoxConstraints(
                maxHeight: _tooltipMaxHeight,
                minHeight: _tooltipMinHeight,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .colorScheme
                        .shadow
                        .withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTooltipHeader(context),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: _tooltipContentMaxHeight,
                        ),
                        child: SingleChildScrollView(child: content),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlay);
    return overlay;
  }

  /// 构建tooltip头部
  static Widget _buildTooltipHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            Icons.info_outline,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            'Condition Details',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
        ),
      ],
    );
  }

  /// 构建带悬浮效果的条件摘要显示
  static Widget buildConditionSummaryWithTooltip({
    required BuildContext context,
    required String summary,
    required VoidCallback onHover,
    required VoidCallback onExit,
  }) {
    return MouseRegion(
      onHover: (_) => onHover(),
      onExit: (_) => onExit(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
              child: Text(
                summary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.info_outline,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  /// 计算固定位置的tooltip位置（相对于触发元素）
  static Offset calculateFixedPosition({
    required BuildContext context,
    required GlobalKey triggerKey,
    double offsetY = 10,
  }) {
    final RenderBox? renderBox =
        triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const Offset(0, 0);

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double width = renderBox.size.width;

    // 计算tooltip位置：水平居中，垂直在下方
    final double tooltipLeft = offset.dx + (width / 2) - (_tooltipWidth / 2);
    final double tooltipTop = offset.dy + renderBox.size.height + offsetY;

    // 确保tooltip不会超出屏幕边界
    final double clampedLeft = tooltipLeft.clamp(
        10, MediaQuery.of(context).size.width - _tooltipWidth - 10);

    return Offset(clampedLeft, tooltipTop);
  }

  /// 计算屏幕中央的tooltip位置
  static Offset calculateCenterPosition({
    required BuildContext context,
    double verticalOffset = 150,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 水平居中，垂直位置可调整
    final double tooltipLeft = (screenWidth - _tooltipWidth) / 2;
    final double tooltipTop =
        verticalOffset.clamp(10, screenHeight - _tooltipMaxHeight - 10);

    return Offset(tooltipLeft, tooltipTop);
  }

  /// 计算控件右侧的tooltip位置
  static Offset calculateRightPosition({
    required BuildContext context,
    required GlobalKey triggerKey,
    double offsetX = 10, // 距离控件的水平偏移
    double offsetY = 0, // 距离控件的垂直偏移
  }) {
    final RenderBox? renderBox =
        triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return const Offset(0, 0);

    final Offset offset = renderBox.localToGlobal(Offset.zero);
    final double width = renderBox.size.width;
    final double height = renderBox.size.height;

    // 计算tooltip位置：水平在控件右侧，垂直对齐控件中心
    final double tooltipLeft = offset.dx + width + offsetX;
    final double tooltipTop =
        offset.dy + (height / 2) - (_tooltipMaxHeight / 2) + offsetY;

    // 确保tooltip不会超出屏幕边界
    final double clampedLeft = tooltipLeft.clamp(
        10, MediaQuery.of(context).size.width - _tooltipWidth - 10);
    final double clampedTop = tooltipTop.clamp(
        10, MediaQuery.of(context).size.height - _tooltipMaxHeight - 10);

    return Offset(clampedLeft, clampedTop);
  }
}
