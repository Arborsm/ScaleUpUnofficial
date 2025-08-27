import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';
import 'theme_toggle_button.dart';

class CustomTitleBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomTitleBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(50);

  @override
  State<CustomTitleBar> createState() => _CustomTitleBarState();
}

class _CustomTitleBarState extends State<CustomTitleBar> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      windowManager.addListener(this);
      _checkMaximizedState();
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximizedState() async {
    if (kIsWeb) return;
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() => _isMaximized = isMaximized);
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        children: [
          // Drag area for window movement (full width background)
          GestureDetector(
            behavior: HitTestBehavior.translucent,
            onPanStart: kIsWeb ? null : (_) => windowManager.startDragging(),
            child: Container(
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Stardew SC&CP Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ),

          // Window control buttons (right aligned)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Theme toggle button (always shown)
                const ThemeToggleButton(),

                // Window control buttons (only on non-web platforms)
                if (!kIsWeb) ...[
                  // Minimize button
                  _WindowButton(
                    onPressed: () => windowManager.minimize(),
                    icon: Icons.minimize,
                    tooltip: 'Minimize',
                  ),

                  // Maximize/Restore button
                  _WindowButton(
                    onPressed: () async {
                      if (_isMaximized) {
                        await windowManager.unmaximize();
                      } else {
                        await windowManager.maximize();
                      }
                    },
                    icon:
                        _isMaximized ? Icons.fullscreen_exit : Icons.fullscreen,
                    tooltip: _isMaximized ? 'Restore' : 'Maximize',
                  ),

                  // Close button
                  _WindowButton(
                    onPressed: () => windowManager.close(),
                    icon: Icons.close,
                    tooltip: 'Close',
                    isCloseButton: true,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WindowButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final bool isCloseButton;

  const _WindowButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.isCloseButton = false,
  });

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = widget.isCloseButton
        ? (_isHovered ? Colors.red : Colors.transparent)
        : (_isHovered
            ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1)
            : Colors.transparent);

    final Color iconColor = widget.isCloseButton && _isHovered
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Tooltip(
          message: widget.tooltip,
          child: SizedBox(
            width: 45,
            height: 45,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.zero,
              ),
              child: Icon(
                widget.icon,
                size: 18,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
