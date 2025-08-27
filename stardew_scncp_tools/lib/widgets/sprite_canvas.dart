import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/sprite_provider.dart';

class MoveUpIntent extends Intent {}

class MoveDownIntent extends Intent {}

class MoveLeftIntent extends Intent {}

class MoveRightIntent extends Intent {}

class SpriteCanvas extends StatefulWidget {
  const SpriteCanvas({super.key});

  @override
  State<SpriteCanvas> createState() => _SpriteCanvasState();
}

class _SpriteCanvasState extends State<SpriteCanvas> {
  bool _isVerticalDragging = false;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      // 确保当获得焦点时重新请求焦点以保持焦点
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final spriteProvider = Provider.of<SpriteProvider>(context);

    return Shortcuts(
      shortcuts: <ShortcutActivator, Intent>{
        LogicalKeySet(LogicalKeyboardKey.arrowUp): MoveUpIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowDown): MoveDownIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowLeft): MoveLeftIntent(),
        LogicalKeySet(LogicalKeyboardKey.arrowRight): MoveRightIntent(),
      },
      child: Actions(
        actions: <Type, Action<Intent>>{
          MoveUpIntent: CallbackAction<MoveUpIntent>(
            onInvoke: (MoveUpIntent intent) => _handleDirectionKey('up'),
          ),
          MoveDownIntent: CallbackAction<MoveDownIntent>(
            onInvoke: (MoveDownIntent intent) => _handleDirectionKey('down'),
          ),
          MoveLeftIntent: CallbackAction<MoveLeftIntent>(
            onInvoke: (MoveLeftIntent intent) => _handleDirectionKey('left'),
          ),
          MoveRightIntent: CallbackAction<MoveRightIntent>(
            onInvoke: (MoveRightIntent intent) => _handleDirectionKey('right'),
          ),
        },
        child: KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent) {
              _handleRawKeyEvent(event);
              // 阻止事件冒泡
              return;
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: spriteProvider.hasSprites
                ? _buildCanvasWithSprite(context, spriteProvider)
                : _buildEmptyCanvas(context, spriteProvider),
          ),
        ),
      ),
    );
  }

  /// 构建包含精灵画布的Widget
  Widget _buildCanvasWithSprite(
      BuildContext context, SpriteProvider spriteProvider) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Listener(
          onPointerSignal: (PointerSignalEvent event) {
            if (event is PointerScrollEvent) {
              final delta = event.scrollDelta.dy > 0 ? 1 : -1;
              _handleScrollWheel(delta, spriteProvider);
            }
          },
          child: GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            onVerticalDragStart: (details) {
              _focusNode.requestFocus();
              _handleVerticalDragStart(details);
            },
            onVerticalDragUpdate: _handleVerticalDragUpdate,
            onVerticalDragEnd: _handleVerticalDragEnd,
            child: CustomPaint(
              painter: SpriteCanvasPainter(
                spriteProvider: spriteProvider,
                context: context,
              ),
              size: Size.infinite,
            ),
          ),
        );
      },
    );
  }

  /// 构建空画布的占位符Widget
  Widget _buildEmptyCanvas(
      BuildContext context, SpriteProvider spriteProvider) {
    return Container(
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.image_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Load a spritesheet to begin',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Use the "Load Spritesheet" button to get started',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// 处理垂直拖拽开始事件
  void _handleVerticalDragStart(DragStartDetails details) {
    final spriteProvider = Provider.of<SpriteProvider>(context, listen: false);
    if (!spriteProvider.hasSprites) return;

    _isVerticalDragging = true;
    spriteProvider.setDragging(true);
  }

  /// 处理垂直拖拽更新事件，将鼠标移动转换为画板坐标增量
  void _handleVerticalDragUpdate(DragUpdateDetails details) {
    final spriteProvider = Provider.of<SpriteProvider>(context, listen: false);
    if (!spriteProvider.hasSprites || !_isVerticalDragging) return;

    final mouseDeltaY = details.delta.dy;
    final displayScale = spriteProvider.displayScale;
    final canvasDeltaY = mouseDeltaY / displayScale;

    final currentHeadshotY = spriteProvider.spriteData.headShotY ?? 0;
    final newHeadshotY = (currentHeadshotY + canvasDeltaY).clamp(0.0, 128.0);

    final updatedSpriteData = spriteProvider.spriteData.copyWith(
      headShotY: newHeadshotY.toInt(),
    );

    spriteProvider.updateSpriteData(updatedSpriteData);
  }

  /// 处理垂直拖拽结束事件
  void _handleVerticalDragEnd(DragEndDetails details) {
    final spriteProvider = Provider.of<SpriteProvider>(context, listen: false);
    if (!spriteProvider.hasSprites) return;

    setState(() {
      _isVerticalDragging = false;
    });

    spriteProvider.setDragging(false);
  }

  /// 处理鼠标滚轮事件，用于控制X坐标
  void _handleScrollWheel(int delta, SpriteProvider spriteProvider) {
    if (!spriteProvider.hasSprites) return;

    final currentHeadshotX = spriteProvider.spriteData.headShotX ?? 0;
    final newHeadshotX = (currentHeadshotX + delta).clamp(0.0, 64.0);

    final updatedSpriteData = spriteProvider.spriteData.copyWith(
      headShotX: newHeadshotX.toInt(),
    );

    spriteProvider.updateSpriteData(updatedSpriteData);
  }

  /// 处理方向键 Intent
  void _handleDirectionKey(String direction) {
    final spriteProvider = Provider.of<SpriteProvider>(context, listen: false);
    if (!spriteProvider.hasSprites) return;

    final currentHeadshotX = spriteProvider.spriteData.headShotX ?? 0;
    final currentHeadshotY = spriteProvider.spriteData.headShotY ?? 0;

    int newHeadshotX = currentHeadshotX;
    int newHeadshotY = currentHeadshotY;

    switch (direction) {
      case 'up':
        newHeadshotY = (currentHeadshotY - 1).clamp(0, 128);
        break;
      case 'down':
        newHeadshotY = (currentHeadshotY + 1).clamp(0, 128);
        break;
      case 'left':
        newHeadshotX = (currentHeadshotX - 1).clamp(0, 64);
        break;
      case 'right':
        newHeadshotX = (currentHeadshotX + 1).clamp(0, 64);
        break;
    }

    if (newHeadshotX != currentHeadshotX || newHeadshotY != currentHeadshotY) {
      final updatedSpriteData = spriteProvider.spriteData.copyWith(
        headShotX: newHeadshotX,
        headShotY: newHeadshotY,
      );
      spriteProvider.updateSpriteData(updatedSpriteData);
    }
  }

  /// 处理原始键盘事件，支持方向键控制和长按
  void _handleRawKeyEvent(KeyEvent event) {
    final spriteProvider = Provider.of<SpriteProvider>(context, listen: false);
    if (!spriteProvider.hasSprites) return;

    final currentHeadshotX = spriteProvider.spriteData.headShotX ?? 0;
    final currentHeadshotY = spriteProvider.spriteData.headShotY ?? 0;

    int newHeadshotX = currentHeadshotX;
    int newHeadshotY = currentHeadshotY;

    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        newHeadshotY = (currentHeadshotY - 1).clamp(0, 128);
        break;
      case LogicalKeyboardKey.arrowDown:
        newHeadshotY = (currentHeadshotY + 1).clamp(0, 128);
        break;
      case LogicalKeyboardKey.arrowLeft:
        newHeadshotX = (currentHeadshotX - 1).clamp(0, 64);
        break;
      case LogicalKeyboardKey.arrowRight:
        newHeadshotX = (currentHeadshotX + 1).clamp(0, 64);
        break;
      default:
        return;
    }

    if (newHeadshotX != currentHeadshotX || newHeadshotY != currentHeadshotY) {
      final updatedSpriteData = spriteProvider.spriteData.copyWith(
        headShotX: newHeadshotX,
        headShotY: newHeadshotY,
      );
      spriteProvider.updateSpriteData(updatedSpriteData);
    }
  }
}

/// 精灵画布的自定义绘制器，负责绘制精灵图像和各种覆盖层
class SpriteCanvasPainter extends CustomPainter {
  final SpriteProvider spriteProvider;
  final BuildContext context;

  SpriteCanvasPainter({
    required this.spriteProvider,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!spriteProvider.hasSprites) return;

    final displayImage = spriteProvider.currentDisplayImage;
    if (displayImage == null) return;

    final effectiveCanvasSize = size;

    final imageSize = Size(
      displayImage.width.toDouble(),
      displayImage.height.toDouble(),
    );

    final scaleX = effectiveCanvasSize.width / imageSize.width;
    final scaleY = effectiveCanvasSize.height / imageSize.height;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;

    // 图像始终居中显示，标尺在图像周围绘制
    final offset = Offset(
      (effectiveCanvasSize.width - scaledWidth) / 2,
      (effectiveCanvasSize.height - scaledHeight) / 2,
    );

    final imageRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      imageSize.width * scale,
      imageSize.height * scale,
    );

    canvas.drawImageRect(
      displayImage,
      Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
      imageRect,
      Paint(),
    );

    _drawSelectionRectangle(canvas, imageRect, scale, offset);
    _drawBreathingBox(canvas, imageRect, scale, offset);
    _drawCenterlines(canvas, imageRect);
    _drawGrid(canvas, imageRect, scale);
    _drawRulers(canvas, imageRect, scale, offset);
  }

  /// 绘制选择矩形框
  void _drawSelectionRectangle(
      Canvas canvas, Rect imageRect, double scale, Offset offset) {
    final selectionRect = spriteProvider.selectionRect;

    final scaledRect = Rect.fromLTWH(
      offset.dx + selectionRect.left * scale,
      offset.dy + selectionRect.top * scale,
      selectionRect.width * scale,
      selectionRect.height * scale,
    );

    final paint = Paint()
      ..color = Theme.of(context).colorScheme.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(scaledRect, paint);
  }

  /// 绘制呼吸动画的胸部区域框
  void _drawBreathingBox(
      Canvas canvas, Rect imageRect, double scale, Offset offset) {
    final spriteData = spriteProvider.spriteData;
    if (spriteData.breathType == null || spriteData.breathType == 0) return;

    final chestX = spriteData.chestSourceX ?? 0;
    final chestY = spriteData.chestSourceY ?? 0;
    final chestWidth = spriteData.chestSourceWidth ?? 0;
    final chestHeight = spriteData.chestSourceHeight ?? 0;

    if (chestWidth <= 0 || chestHeight <= 0) return;

    final chestRect = Rect.fromLTWH(
      offset.dx + chestX * scale,
      offset.dy + chestY * scale,
      chestWidth * scale,
      chestHeight * scale,
    );

    final paint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    canvas.drawRect(chestRect, paint);
  }

  /// 绘制中心线
  void _drawCenterlines(Canvas canvas, Rect imageRect) {
    if (!spriteProvider.showCenterlines) return;

    final centerX = imageRect.center.dx;
    final centerY = imageRect.center.dy;

    final paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(
      Offset(centerX, imageRect.top),
      Offset(centerX, imageRect.bottom),
      paint,
    );

    canvas.drawLine(
      Offset(imageRect.left, centerY),
      Offset(imageRect.right, centerY),
      paint,
    );
  }

  /// 绘制网格线
  void _drawGrid(Canvas canvas, Rect imageRect, double scale) {
    if (!spriteProvider.showGrid) return;

    const gridSpacing = 8.0;
    final paint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = imageRect.left;
        x <= imageRect.right;
        x += gridSpacing * scale) {
      canvas.drawLine(
        Offset(x, imageRect.top),
        Offset(x, imageRect.bottom),
        paint,
      );
    }

    for (double y = imageRect.top;
        y <= imageRect.bottom;
        y += gridSpacing * scale) {
      canvas.drawLine(
        Offset(imageRect.left, y),
        Offset(imageRect.right, y),
        paint,
      );
    }
  }

  /// 绘制标尺
  void _drawRulers(Canvas canvas, Rect imageRect, double scale, Offset offset) {
    // Check if rulers should be shown
    if (!spriteProvider.showRulers) return;

    final paint = Paint()
      ..color = Theme.of(context).colorScheme.onSurfaceVariant
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    for (int i = 0; i <= 64; i += 8) {
      final x = offset.dx + i * scale;
      final isMajor = i % 16 == 0;

      // 绘制垂直标尺线（在图像顶部边界）
      canvas.drawLine(
        Offset(x, imageRect.top - 10),
        Offset(x, imageRect.top),
        paint,
      );

      if (isMajor) {
        textPainter.text = TextSpan(
          text: i.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(x - textPainter.width / 2, imageRect.top - 25));
      }
    }

    for (int i = 0; i <= 128; i += 8) {
      final y = offset.dy + i * scale;
      final isMajor = i % 16 == 0;

      // 绘制水平标尺线（在图像左侧边界）
      canvas.drawLine(
        Offset(imageRect.left - 10, y),
        Offset(imageRect.left, y),
        paint,
      );

      if (isMajor) {
        textPainter.text = TextSpan(
          text: i.toString(),
          style: Theme.of(context).textTheme.bodySmall,
        );
        textPainter.layout();
        textPainter.paint(
            canvas, Offset(imageRect.left - 35, y - textPainter.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant SpriteCanvasPainter oldDelegate) {
    return oldDelegate.spriteProvider != spriteProvider;
  }
}
