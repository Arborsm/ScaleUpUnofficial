import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

class CharacterNameInput extends StatefulWidget {
  final String currentValue;
  final Function(String) onChanged;

  const CharacterNameInput({
    super.key,
    required this.currentValue,
    required this.onChanged,
  });

  @override
  State<CharacterNameInput> createState() => _CharacterNameInputState();
}

class _CharacterNameInputState extends State<CharacterNameInput> {
  late TextEditingController _controller;
  bool _isDropdownOpen = false;
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _fieldKey = GlobalKey();
  OverlayEntry? _overlayEntry;
  Offset _dropdownOffset = Offset.zero;
  double _dropdownMaxHeight = 200;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentValue);
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(CharacterNameInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus &&
        oldWidget.currentValue != widget.currentValue &&
        _controller.text != widget.currentValue) {
      _controller.text = widget.currentValue;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      setState(() => _isDropdownOpen = true);
      _showOverlay();
    }
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final contextForSize = _fieldKey.currentContext;
    if (contextForSize == null) return;
    final targetBox = contextForSize.findRenderObject() as RenderBox?;
    if (targetBox == null) return;
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final targetSize = targetBox.size;
    final targetPosition =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    const margin = 8.0;
    final bottomSpace = overlayBox.size.height -
        (targetPosition.dy + targetSize.height) -
        margin;
    final topSpace = targetPosition.dy - margin;
    final preferBelow = bottomSpace >= 120 || bottomSpace >= topSpace;
    _dropdownMaxHeight =
        (preferBelow ? bottomSpace : topSpace).clamp(80.0, 200.0);
    _dropdownOffset = preferBelow
        ? Offset(0, targetSize.height)
        : Offset(0, -_dropdownMaxHeight);
    final width = targetSize.width;

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  setState(() => _isDropdownOpen = false);
                  _removeOverlay();
                },
              ),
            ),
            CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: _dropdownOffset,
              child: Material(
                elevation: 4,
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: _dropdownMaxHeight,
                    minWidth: width,
                    maxWidth: width,
                  ),
                  child: _buildDropdownList(),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _updateOverlay() {
    _overlayEntry?.markNeedsBuild();
  }

  void _recomputeOverlayGeometry() {
    final contextForSize = _fieldKey.currentContext;
    if (contextForSize == null) return;
    final targetBox = contextForSize.findRenderObject() as RenderBox?;
    if (targetBox == null) return;
    final overlay = Overlay.of(context);
    final overlayBox = overlay.context.findRenderObject() as RenderBox;
    final targetSize = targetBox.size;
    final targetPosition =
        targetBox.localToGlobal(Offset.zero, ancestor: overlayBox);

    const margin = 8.0;
    final bottomSpace = overlayBox.size.height -
        (targetPosition.dy + targetSize.height) -
        margin;
    final topSpace = targetPosition.dy - margin;
    final preferBelow = bottomSpace >= 120 || bottomSpace >= topSpace;
    _dropdownMaxHeight =
        (preferBelow ? bottomSpace : topSpace).clamp(80.0, 200.0);
    _dropdownOffset = preferBelow
        ? Offset(0, targetSize.height)
        : Offset(0, -_dropdownMaxHeight);
  }

  Widget _buildDropdownList() {
    final items = _filteredPresets;
    if (!_isDropdownOpen || items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(4),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: items.length,
        itemBuilder: (context, index) {
          final name = items[index];
          return ListTile(
            dense: true,
            title: Text(name, style: const TextStyle(fontSize: 14)),
            mouseCursor: SystemMouseCursors.click,
            onTap: () {
              _controller.text = name;
              widget.onChanged(name);
              setState(() => _isDropdownOpen = false);
              _removeOverlay();
              _focusNode.unfocus();
            },
          );
        },
      ),
    );
  }

  List<String> get _allPresets => [
        ...AppConstants.presetBachelors,
        ...AppConstants.presetBachelorettes,
        ...AppConstants.presetNonMarriage,
        ...AppConstants.presetNonGiftable,
      ];

  List<String> get _filteredPresets {
    final query = _controller.text.toLowerCase();
    if (query.isEmpty) return _allPresets;
    return _allPresets
        .where((name) => name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        key: _fieldKey,
        controller: _controller,
        focusNode: _focusNode,
        decoration: InputDecoration(
          hintText: 'Enter character name or select preset',
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          suffixIcon: IconButton(
            icon: Icon(
              _isDropdownOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
              size: 20,
            ),
            onPressed: () {
              if (_isDropdownOpen) {
                setState(() => _isDropdownOpen = false);
                _removeOverlay();
              } else {
                setState(() => _isDropdownOpen = true);
                if (!_focusNode.hasFocus) {
                  _focusNode.requestFocus();
                }
                _showOverlay();
                _updateOverlay();
              }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ),
        onChanged: (value) {
          widget.onChanged(value);
          _recomputeOverlayGeometry();
          _updateOverlay();
        },
        onSubmitted: (_) {
          setState(() => _isDropdownOpen = false);
          _removeOverlay();
        },
        // onTapOutside handled by overlay barrier
      ),
    );
  }
}
