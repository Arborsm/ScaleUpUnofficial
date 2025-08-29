import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../widgets/sprite/sprite_canvas.dart';
import '../widgets/sprite/parameter_panel.dart';
import '../widgets/sprite/preview_panels.dart';
import '../widgets/sprite/control_panel.dart';
import '../providers/sprite_provider.dart';

/// 精灵编辑器主屏幕，包含画布、参数面板和预览面板
class SpriteEditorScreen extends StatefulWidget {
  const SpriteEditorScreen({super.key});

  @override
  State<SpriteEditorScreen> createState() => _SpriteEditorScreenState();
}

class _SpriteEditorScreenState extends State<SpriteEditorScreen> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    // 不自动获取焦点，让各个组件管理自己的焦点
    // 这样可以避免与Canvas焦点的冲突
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      onKeyEvent: _handleKeyEvent,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Control panel with buttons and options
            const ControlPanel(),

            // Main content area with improved spacing
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left panel - Parameters
                    Card(
                      child: Container(
                        width: 340,
                        padding: const EdgeInsets.all(16),
                        child: const ParameterPanel(),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Center panel - Sprite canvas
                    Expanded(
                      child: Card(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: const SpriteCanvas(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Right panel - Preview panels
                    Card(
                      child: Container(
                        width: 280,
                        padding: const EdgeInsets.all(16),
                        child: const PreviewPanels(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 处理键盘事件，支持方向键控制和长按
  void _handleKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return;

    final spriteProvider = context.read<SpriteProvider>();
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
