import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';

import '../providers/sprite_provider.dart';
import '../services/json_export_service.dart';

class JsonHighlighter {
  // 层级颜色 - 使用渐进的颜色变化来区分嵌套层级
  static const List<Color> levelColors = [
    Color(0xFF2E86C1), // Level 0 - 深蓝
    Color(0xFF28A745), // Level 1 - 深绿
    Color(0xFFDC3545), // Level 2 - 深红
    Color(0xFF6F42C1), // Level 3 - 深紫
    Color(0xFFFF6B35), // Level 4 - 深橙
    Color(0xFF20B2AA), // Level 5 - 深青
    Color(0xFF8B4513), // Level 6 - 深褐
    Color(0xFF708090), // Level 7 - 深灰
  ];

  static const Color keyColor = Color(0xFF2E86C1); // 深蓝 for keys
  static const Color numberColor = Color(0xFF28A745); // 深绿 for numbers
  static const Color booleanColor = Color(0xFF6F42C1); // 深紫 for booleans
  static const Color bracketColor = Color(0xFF6C757D); // 深灰 for brackets

  static TextSpan highlight(String jsonText, TextStyle baseStyle,
      {required bool isDark}) {
    final Color computedBaseColor = baseStyle.color ??
        (isDark ? const Color(0xFFBBBBBB) : const Color(0xFF2D3748));
    Color adjust(Color c) =>
        isDark ? Color.lerp(c, computedBaseColor, 0.35)! : c;
    final List<Color> levelColorsAdjusted =
        levelColors.map((c) => adjust(c)).toList(growable: false);
    final Color keyColorAdjusted = adjust(keyColor);
    final Color numberColorAdjusted = adjust(numberColor);
    final Color booleanColorAdjusted = adjust(booleanColor);
    final Color bracketColorAdjusted = adjust(bracketColor);
    final List<TextSpan> spans = [];
    final List<int> nestingLevels = []; // 跟踪嵌套层级
    bool inString = false;
    int i = 0;

    while (i < jsonText.length) {
      final char = jsonText[i];

      // Handle string start/end
      if (char == '"' && (i == 0 || jsonText[i - 1] != '\\')) {
        inString = !inString;
        final currentLevel = nestingLevels.isNotEmpty ? nestingLevels.last : 0;
        final stringColor =
            levelColorsAdjusted[currentLevel % levelColorsAdjusted.length];
        spans.add(TextSpan(
            text: char, style: baseStyle.copyWith(color: stringColor)));
        i++;
        continue;
      }

      // Handle string content
      if (inString) {
        final stringStart = i;
        while (i < jsonText.length &&
            !(jsonText[i] == '"' && (i == 0 || jsonText[i - 1] != '\\'))) {
          i++;
        }
        final stringContent = jsonText.substring(stringStart, i);
        final isKey = i < jsonText.length && jsonText[i] == ':';
        final currentLevel = nestingLevels.isNotEmpty ? nestingLevels.last : 0;
        final stringColor =
            levelColorsAdjusted[currentLevel % levelColorsAdjusted.length];
        spans.add(TextSpan(
          text: stringContent,
          style:
              baseStyle.copyWith(color: isKey ? keyColorAdjusted : stringColor),
        ));
        continue;
      }

      // Handle brackets and nesting levels
      if ('[{('.contains(char)) {
        nestingLevels
            .add(nestingLevels.isNotEmpty ? nestingLevels.last + 1 : 0);
        spans.add(TextSpan(
            text: char,
            style: baseStyle.copyWith(color: bracketColorAdjusted)));
      } else if (']})'.contains(char)) {
        if (nestingLevels.isNotEmpty) {
          nestingLevels.removeLast();
        }
        spans.add(TextSpan(
            text: char,
            style: baseStyle.copyWith(color: bracketColorAdjusted)));
      }
      // Handle numbers
      else if (RegExp(r'[0-9\-]').hasMatch(char)) {
        final numberStart = i;
        while (i < jsonText.length &&
            RegExp(r'[0-9\.\-eE]').hasMatch(jsonText[i])) {
          i++;
        }
        final number = jsonText.substring(numberStart, i);
        spans.add(TextSpan(
            text: number,
            style: baseStyle.copyWith(color: numberColorAdjusted)));
        continue;
      }
      // Handle booleans and null
      else if (jsonText.startsWith('true', i)) {
        spans.add(TextSpan(
            text: 'true',
            style: baseStyle.copyWith(color: booleanColorAdjusted)));
        i += 4;
        continue;
      } else if (jsonText.startsWith('false', i)) {
        spans.add(TextSpan(
            text: 'false',
            style: baseStyle.copyWith(color: booleanColorAdjusted)));
        i += 5;
        continue;
      } else if (jsonText.startsWith('null', i)) {
        spans.add(TextSpan(
            text: 'null',
            style: baseStyle.copyWith(color: booleanColorAdjusted)));
        i += 4;
        continue;
      } else {
        // Regular characters (commas, colons, spaces, etc.)
        spans.add(TextSpan(text: char, style: baseStyle));
      }

      i++;
    }

    return TextSpan(children: spans, style: baseStyle);
  }
}

class JsonPreview extends StatefulWidget {
  const JsonPreview({super.key});

  @override
  State<JsonPreview> createState() => _JsonPreviewState();
}

class _JsonPreviewState extends State<JsonPreview> {
  String _jsonText = '';
  bool _isLoading = false;
  double _fontSize = 16.0; // 增大默认字体大小
  final double _minFontSize = 10.0;
  final double _maxFontSize = 24.0;
  SpriteProvider? _spriteProvider;

  void _onProviderChanged() {
    _updateJsonPreview();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _spriteProvider = Provider.of<SpriteProvider>(context, listen: false);
      _spriteProvider?.addListener(_onProviderChanged);
      _updateJsonPreview();
    });
  }

  @override
  void dispose() {
    _spriteProvider?.removeListener(_onProviderChanged);
    super.dispose();
  }

  Future<void> _updateJsonPreview() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final spriteProvider =
          Provider.of<SpriteProvider>(context, listen: false);
      final jsonData =
          JsonExportService.generateContentPatcherJson(spriteProvider);
      final newJsonText = JsonExportService.formatJsonString(jsonData);

      if (mounted) {
        setState(() => _jsonText = newJsonText);
      }
    } catch (e) {
      debugPrint('Error updating JSON preview: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _formatJsonText(String jsonText) {
    // 清理行尾空格，保持JSON本身的格式
    return jsonText.split('\n').map((line) => line.trimRight()).join('\n');
  }

  Future<void> _copyToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: _jsonText));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('JSON copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  void _increaseFontSize() {
    setState(() {
      _fontSize = (_fontSize + 1).clamp(_minFontSize, _maxFontSize);
    });
  }

  void _decreaseFontSize() {
    setState(() {
      _fontSize = (_fontSize - 1).clamp(_minFontSize, _maxFontSize);
    });
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is PointerScrollEvent) {
      // 只有在按住Ctrl键时才进行字体缩放
      if (HardwareKeyboard.instance.isControlPressed) {
        final delta = event.scrollDelta.dy;
        if (delta < 0) {
          // 向上滚动 - 放大
          _increaseFontSize();
        } else {
          // 向下滚动 - 缩小
          _decreaseFontSize();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.code,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'JSON Preview',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
                // 字体大小控制按钮
                IconButton(
                  onPressed: _decreaseFontSize,
                  icon: const Icon(Icons.text_decrease, size: 18),
                  tooltip: 'Decrease font size',
                  padding: const EdgeInsets.all(4),
                ),
                IconButton(
                  onPressed: _increaseFontSize,
                  icon: const Icon(Icons.text_increase, size: 18),
                  tooltip: 'Increase font size',
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_fontSize.toInt()}px',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  FilledButton.icon(
                    onPressed: _jsonText.isNotEmpty ? _copyToClipboard : null,
                    icon: const Icon(Icons.copy, size: 16),
                    label: const Text('Copy'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                    ),
                  ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              color: Theme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1E1E1E)
                  : const Color(0xFFF8F8F8),
              child: _jsonText.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.code_off,
                            size: 48,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No JSON to preview',
                            style:
                                Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure your settings to generate JSON',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    )
                  : Listener(
                      onPointerSignal: _handlePointerSignal,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText.rich(
                          JsonHighlighter.highlight(
                            _formatJsonText(_jsonText),
                            TextStyle(
                              fontFamily: 'JetBrains Mono',
                              fontFamilyFallback: const [
                                'Consolas',
                                'Monaco',
                                'Menlo',
                                'Ubuntu Mono',
                                'DejaVu Sans Mono',
                                'Liberation Mono',
                                'Courier New',
                                'monospace'
                              ],
                              fontSize: _fontSize,
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? const Color(0xFFB8C2CC)
                                  : const Color(0xFF2D3748),
                              height: 1.6, // 增加行高
                              letterSpacing: 0.0, // 确保字符间距一致
                              wordSpacing: 0.0, // 确保单词间距一致
                              fontFeatures: const [
                                FontFeature.tabularFigures(), // 等宽数字
                              ],
                            ),
                            isDark:
                                Theme.of(context).brightness == Brightness.dark,
                          ),
                          style: const TextStyle(
                            fontFamily: 'JetBrains Mono',
                            fontFamilyFallback: [
                              'Consolas',
                              'Monaco',
                              'Menlo',
                              'Ubuntu Mono',
                              'DejaVu Sans Mono',
                              'Liberation Mono',
                              'Courier New',
                              'monospace'
                            ],
                            letterSpacing: 0.0,
                            wordSpacing: 0.0,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
