import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:file_selector/file_selector.dart';

import '../models/sprite_data.dart';
import '../models/sprite_slice.dart';
import '../constants/app_constants.dart';
import '../utils/image_utils.dart';

/// 精灵数据提供者，管理所有精灵相关的状态和操作
class SpriteProvider extends ChangeNotifier {
  SpriteData _spriteData = SpriteData();
  final List<SpriteSlice> _slices = [];
  int _currentSliceIndex = 0;
  ui.Image? _currentDisplayImage;

  // 辅助方法：简化setter模式
  void _setBool(
      bool Function() getter, void Function(bool) setter, bool value) {
    if (getter() != value) {
      setter(value);
      notifyListeners();
    }
  }

  void _setValue<T>(T currentValue, void Function(T) setter, T value) {
    if (currentValue != value) {
      setter(value);
      notifyListeners();
    }
  }

  Rect _selectionRect = AppConstants.defaultSelectionRect;
  double _displayScale = 1.0;
  Offset _displayOffset = Offset.zero;

  bool _showCenterlines = true;
  bool _showGrid = true;
  bool _showRulers = false; // Default to false
  bool _exportDefaults = true;
  bool _isDragging = false;
  bool _isLoading = false;

  // Modern selection box state
  bool _isSelectionActive = false;
  SelectionMode _selectionMode = SelectionMode.none;
  Offset? _dragStartPoint;
  Rect? _originalSelectionRect;

  // Getters
  SpriteData get spriteData => _spriteData;
  List<SpriteSlice> get slices => _slices;
  int get currentSliceIndex => _currentSliceIndex;
  ui.Image? get currentDisplayImage => _currentDisplayImage;
  Rect get selectionRect => _selectionRect;
  double get displayScale => _displayScale;
  Offset get displayOffset => _displayOffset;
  bool get showCenterlines => _showCenterlines;
  bool get showGrid => _showGrid;
  bool get showRulers => _showRulers;
  bool get exportDefaults => _exportDefaults;
  bool get isDragging => _isDragging;
  bool get isLoading => _isLoading;
  bool get hasSprites => _slices.isNotEmpty;
  bool get isSelectionActive => _isSelectionActive;
  SelectionMode get selectionMode => _selectionMode;

  // Content Patcher data
  String _characterName = 'Haley';
  bool _cpIncludeLoad = true;
  bool _cpIncludeAssets = true;
  bool _cpUsePage1Sprite = true;
  bool _cpIncludeAppearance = true;
  int _cpScale = 4;

  final Map<String, bool> _appearanceEntryVars = {};
  final Map<String, bool> _appearanceSpriteVars = {};
  final Map<String, bool> _appearancePortraitVars = {};

  // Getters for CP data
  String get characterName => _characterName;
  bool get cpIncludeLoad => _cpIncludeLoad;
  bool get cpIncludeAssets => _cpIncludeAssets;
  bool get cpUsePage1Sprite => _cpUsePage1Sprite;
  bool get cpIncludeAppearance => _cpIncludeAppearance;
  int get cpScale => _cpScale;

  Map<String, bool> get appearanceEntryVars => _appearanceEntryVars;
  Map<String, bool> get appearanceSpriteVars => _appearanceSpriteVars;
  Map<String, bool> get appearancePortraitVars => _appearancePortraitVars;

  SpriteProvider() {
    _initializeAppearanceKeys();
  }

  void _initializeAppearanceKeys() {
    for (final key in AppConstants.appearanceKeys) {
      final suffix = key.suffix;
      _appearanceEntryVars[suffix] = true;
      _appearanceSpriteVars[suffix] = true;
      _appearancePortraitVars[suffix] = true;
    }
  }

  /// 加载精灵图表文件
  Future<void> loadSpritesheet() async {
    try {
      _isLoading = true;
      notifyListeners();

      const XTypeGroup typeGroup = XTypeGroup(
        label: 'Images',
        extensions: <String>['png', 'jpg', 'jpeg'],
      );

      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[typeGroup],
      );

      if (file == null) return;

      final File imageFile = File(file.path);
      final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      _slices.clear();

      // Split the spritesheet into individual slices
      for (int y = 0; y < image.height; y += AppConstants.sliceHeight) {
        for (int x = 0; x < image.width; x += AppConstants.sliceWidth) {
          final sliceImage = img.copyCrop(
            image,
            x: x,
            y: y,
            width: AppConstants.sliceWidth,
            height: AppConstants.sliceHeight,
          );

          final slice = SpriteSlice(
            image: sliceImage,
            x: x,
            y: y,
            width: AppConstants.sliceWidth,
            height: AppConstants.sliceHeight,
          );

          _slices.add(slice);
        }
      }

      if (_slices.isNotEmpty) {
        _currentSliceIndex = 0;
        await _updateDisplayImage();
        _calculateOptimalDisplay();
      }
    } catch (e) {
      debugPrint('Error loading spritesheet: $e');
      // You might want to show a snackbar or dialog here
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 从指定路径加载精灵图表文件
  Future<void> loadSpritesheetFromPath(String filePath) async {
    try {
      _isLoading = true;
      notifyListeners();

      final File imageFile = File(filePath);
      if (!await imageFile.exists()) {
        throw Exception('Spritesheet file not found at: $filePath');
      }

      final img.Image? image = img.decodeImage(await imageFile.readAsBytes());

      if (image == null) {
        throw Exception('Failed to decode image');
      }

      _slices.clear();

      // Split the spritesheet into individual slices
      for (int y = 0; y < image.height; y += AppConstants.sliceHeight) {
        for (int x = 0; x < image.width; x += AppConstants.sliceWidth) {
          final sliceImage = img.copyCrop(
            image,
            x: x,
            y: y,
            width: AppConstants.sliceWidth,
            height: AppConstants.sliceHeight,
          );

          final slice = SpriteSlice(
            image: sliceImage,
            x: x,
            y: y,
            width: AppConstants.sliceWidth,
            height: AppConstants.sliceHeight,
          );

          _slices.add(slice);
        }
      }

      if (_slices.isNotEmpty) {
        _currentSliceIndex = 0;
        await _updateDisplayImage();
        _calculateOptimalDisplay();
      }
    } catch (e) {
      debugPrint('Error loading spritesheet: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateDisplayImage() async {
    if (_slices.isEmpty || _currentSliceIndex >= _slices.length) return;

    final slice = _slices[_currentSliceIndex];
    _currentDisplayImage = await ImageUtils.convertImageToUiImage(slice.image);
    notifyListeners();
  }

  void _calculateOptimalDisplay([Size? canvasSize]) {
    if (_currentDisplayImage == null) return;

    // Use provided canvas size or fallback to default
    final effectiveCanvasSize = canvasSize ?? const Size(800, 600);
    final imageSize = Size(
      _currentDisplayImage!.width.toDouble(),
      _currentDisplayImage!.height.toDouble(),
    );

    // Calculate scale to fit the entire image within the canvas while maintaining aspect ratio
    final scaleX = effectiveCanvasSize.width / imageSize.width;
    final scaleY = effectiveCanvasSize.height / imageSize.height;
    _displayScale = scaleX < scaleY ? scaleX : scaleY;

    // Center the image in the canvas
    final scaledWidth = imageSize.width * _displayScale;
    final scaledHeight = imageSize.height * _displayScale;
    _displayOffset = Offset(
      (effectiveCanvasSize.width - scaledWidth) / 2,
      (effectiveCanvasSize.height - scaledHeight) / 2,
    );

    // Force center the selection rectangle when display changes
    _centerSelectionRectangle();
  }

  void _centerSelectionRectangle() {
    if (_currentDisplayImage == null) return;

    final imageWidth = _currentDisplayImage!.width.toDouble();
    final imageHeight = _currentDisplayImage!.height.toDouble();

    // 强制居中：计算选择框在图像中的居中位置
    final centerX = (imageWidth - _selectionRect.width) / 2;
    final centerY = (imageHeight - _selectionRect.height) / 2;

    // 确保选择框完全在图像边界内
    final clampedX = centerX.clamp(0.0, imageWidth - _selectionRect.width);
    final clampedY = centerY.clamp(0.0, imageHeight - _selectionRect.height);

    _selectionRect = Rect.fromLTWH(
      clampedX,
      clampedY,
      _selectionRect.width,
      _selectionRect.height,
    );

    // 更新精灵数据
    _updateSpriteDataFromSelection();
  }

  // Public method to force center the selection rectangle
  void centerSelectionRectangle() {
    _centerSelectionRectangle();
    notifyListeners();
  }

  // 强制重新计算并居中选择框
  void forceCenterSelection() {
    if (_currentDisplayImage != null) {
      // 重新计算选择框尺寸
      final width = AppConstants.sliceWidth - 2 * (_spriteData.headShotX ?? 0);
      final height = width / AppConstants.aspectRatio;

      if (height > 0 && height <= AppConstants.sliceHeight) {
        _selectionRect = Rect.fromLTWH(
          _selectionRect.left,
          _selectionRect.top,
          width.toDouble(),
          height,
        );
      }

      // 强制居中
      _centerSelectionRectangle();
      notifyListeners();
    }
  }

  void setCurrentSlice(int index) {
    if (index >= 0 && index < _slices.length && index != _currentSliceIndex) {
      _currentSliceIndex = index;
      _updateDisplayImage();
      _centerSelectionRectangle(); // Center selection when changing slices
      notifyListeners();
    }
  }

  // Modern selection box methods
  void startSelection(Offset position, SelectionMode mode) {
    _isSelectionActive = true;
    _selectionMode = mode;
    _dragStartPoint = position;
    _originalSelectionRect = _selectionRect;
    notifyListeners();
  }

  void updateSelection(Offset position) {
    if (!_isSelectionActive ||
        _dragStartPoint == null ||
        _originalSelectionRect == null) {
      return;
    }

    final delta = position - _dragStartPoint!;

    switch (_selectionMode) {
      case SelectionMode.move:
        _updateSelectionPosition(delta);
        break;
      case SelectionMode.resizeTopLeft:
        _updateSelectionSize(delta, ResizeDirection.topLeft);
        break;
      case SelectionMode.resizeTopRight:
        _updateSelectionSize(delta, ResizeDirection.topRight);
        break;
      case SelectionMode.resizeBottomLeft:
        _updateSelectionSize(delta, ResizeDirection.bottomLeft);
        break;
      case SelectionMode.resizeBottomRight:
        _updateSelectionSize(delta, ResizeDirection.bottomRight);
        break;
      case SelectionMode.none:
        break;
    }

    notifyListeners();
  }

  void endSelection() {
    _isSelectionActive = false;
    _selectionMode = SelectionMode.none;
    _dragStartPoint = null;
    _originalSelectionRect = null;
    notifyListeners();
  }

  void _updateSelectionPosition(Offset delta) {
    if (_originalSelectionRect == null) return;

    final imageDelta = Offset(
      delta.dx / _displayScale,
      delta.dy / _displayScale,
    );

    final newLeft = (_originalSelectionRect!.left + imageDelta.dx)
        .clamp(0.0, AppConstants.sliceWidth - _selectionRect.width);
    final newTop = (_originalSelectionRect!.top + imageDelta.dy)
        .clamp(0.0, AppConstants.sliceHeight - _selectionRect.height);

    _selectionRect = Rect.fromLTWH(
      newLeft,
      newTop,
      _selectionRect.width,
      _selectionRect.height,
    );

    // 立即同步到精灵数据
    _updateSpriteDataFromSelection();
  }

  void _updateSelectionSize(Offset delta, ResizeDirection direction) {
    if (_originalSelectionRect == null) return;

    final imageDelta = Offset(
      delta.dx / _displayScale,
      delta.dy / _displayScale,
    );

    double newLeft = _originalSelectionRect!.left;
    double newTop = _originalSelectionRect!.top;
    double newWidth = _originalSelectionRect!.width;
    double newHeight = _originalSelectionRect!.height;

    switch (direction) {
      case ResizeDirection.topLeft:
        newLeft = (_originalSelectionRect!.left + imageDelta.dx)
            .clamp(0.0, _originalSelectionRect!.right - 20);
        newTop = (_originalSelectionRect!.top + imageDelta.dy)
            .clamp(0.0, _originalSelectionRect!.bottom - 20);
        newWidth = _originalSelectionRect!.right - newLeft;
        newHeight = _originalSelectionRect!.bottom - newTop;
        break;
      case ResizeDirection.topRight:
        newTop = (_originalSelectionRect!.top + imageDelta.dy)
            .clamp(0.0, _originalSelectionRect!.bottom - 20);
        newWidth = (_originalSelectionRect!.width + imageDelta.dx)
            .clamp(20.0, AppConstants.sliceWidth - newLeft);
        newHeight = _originalSelectionRect!.bottom - newTop;
        break;
      case ResizeDirection.bottomLeft:
        newLeft = (_originalSelectionRect!.left + imageDelta.dx)
            .clamp(0.0, _originalSelectionRect!.right - 20);
        newWidth = _originalSelectionRect!.right - newLeft;
        newHeight = (_originalSelectionRect!.height + imageDelta.dy)
            .clamp(20.0, AppConstants.sliceHeight - newTop);
        break;
      case ResizeDirection.bottomRight:
        newWidth = (_originalSelectionRect!.width + imageDelta.dx)
            .clamp(20.0, AppConstants.sliceWidth - newLeft);
        newHeight = (_originalSelectionRect!.height + imageDelta.dy)
            .clamp(20.0, AppConstants.sliceHeight - newTop);
        break;
    }

    // Maintain aspect ratio
    final aspectRatio = AppConstants.aspectRatio;
    if (newWidth > newHeight * aspectRatio) {
      newHeight = newWidth / aspectRatio;
    } else {
      newWidth = newHeight * aspectRatio;
    }

    // Ensure bounds
    if (newLeft + newWidth > AppConstants.sliceWidth) {
      newWidth = AppConstants.sliceWidth - newLeft;
      newHeight = newWidth / aspectRatio;
    }
    if (newTop + newHeight > AppConstants.sliceHeight) {
      newHeight = AppConstants.sliceHeight - newTop;
      newWidth = newHeight * aspectRatio;
    }

    _selectionRect = Rect.fromLTWH(newLeft, newTop, newWidth, newHeight);
    // 立即同步到精灵数据
    _updateSpriteDataFromSelection();
  }

  void updateSelectionRect(Rect newRect) {
    _selectionRect = newRect;
    _updateSpriteDataFromSelection();
    notifyListeners();
  }

  void _updateSpriteDataFromSelection() {
    // 选择框的左上角坐标同步到headShotX和headShotY
    _spriteData.headShotX = _selectionRect.left.toInt();
    _spriteData.headShotY = _selectionRect.top.toInt();

    // 同时更新选择框的宽度和高度，保持宽高比
    final width = _selectionRect.width;
    final height = width / AppConstants.aspectRatio;

    // 确保高度不超出边界
    if (height > AppConstants.sliceHeight - _selectionRect.top) {
      final maxHeight = AppConstants.sliceHeight - _selectionRect.top;
      final adjustedWidth = maxHeight * AppConstants.aspectRatio;
      _selectionRect = Rect.fromLTWH(
        _selectionRect.left,
        _selectionRect.top,
        adjustedWidth,
        maxHeight,
      );
    }
  }

  /// 更新精灵数据并同步选择框位置
  void updateSpriteData(SpriteData newData) {
    _spriteData = newData;
    _updateSelectionRectFromSpriteData();
    notifyListeners();
  }

  /// 从精灵数据更新选择框位置
  void _updateSelectionRectFromSpriteData() {
    final headShotX = _spriteData.headShotX ?? 0;
    final headShotY = _spriteData.headShotY ?? 0;

    // 计算选择框的宽度，保持宽高比
    final width = AppConstants.sliceWidth - 2 * headShotX;
    final height = width / AppConstants.aspectRatio;

    if (height <= 0 || height > AppConstants.sliceHeight) return;

    // 直接使用headShotX和headShotY作为选择框的左上角坐标
    _selectionRect = Rect.fromLTWH(
      headShotX.toDouble(),
      headShotY.toDouble(),
      width.toDouble(),
      height,
    );

    // 确保选择框不超出图像边界
    if (_currentDisplayImage != null) {
      final imageWidth = _currentDisplayImage!.width.toDouble();
      final imageHeight = _currentDisplayImage!.height.toDouble();

      final clampedX =
          _selectionRect.left.clamp(0.0, imageWidth - _selectionRect.width);
      final clampedY =
          _selectionRect.top.clamp(0.0, imageHeight - _selectionRect.height);

      if (clampedX != _selectionRect.left || clampedY != _selectionRect.top) {
        _selectionRect = Rect.fromLTWH(
          clampedX,
          clampedY,
          _selectionRect.width,
          _selectionRect.height,
        );
      }
    }
  }

  void setShowCenterlines(bool value) =>
      _setBool(() => _showCenterlines, (v) => _showCenterlines = v, value);
  void setShowGrid(bool value) =>
      _setBool(() => _showGrid, (v) => _showGrid = v, value);
  void setShowRulers(bool value) =>
      _setBool(() => _showRulers, (v) => _showRulers = v, value);
  void setExportDefaults(bool value) =>
      _setBool(() => _exportDefaults, (v) => _exportDefaults = v, value);
  void setDragging(bool value) =>
      _setBool(() => _isDragging, (v) => _isDragging = v, value);

  // Content Patcher methods
  void setCharacterName(String name) =>
      _setValue(_characterName, (v) => _characterName = v, name);
  void setCpIncludeLoad(bool value) =>
      _setBool(() => _cpIncludeLoad, (v) => _cpIncludeLoad = v, value);
  void setCpIncludeAssets(bool value) =>
      _setBool(() => _cpIncludeAssets, (v) => _cpIncludeAssets = v, value);
  void setCpUsePage1Sprite(bool value) =>
      _setBool(() => _cpUsePage1Sprite, (v) => _cpUsePage1Sprite = v, value);
  void setCpIncludeAppearance(bool value) => _setBool(
      () => _cpIncludeAppearance, (v) => _cpIncludeAppearance = v, value);
  void setCpScale(int scale) => _setValue(_cpScale, (v) => _cpScale = v, scale);

  void setAppearanceEntryVar(String suffix, bool value) {
    final currentValue = _appearanceEntryVars[suffix];
    if (currentValue != value) {
      _appearanceEntryVars[suffix] = value;
      if (!value) {
        _appearanceSpriteVars[suffix] = false;
        _appearancePortraitVars[suffix] = false;
      } else {
        _appearanceSpriteVars[suffix] = true;
        _appearancePortraitVars[suffix] = true;
      }
      notifyListeners();
    }
  }

  void setAppearanceSpriteVar(String suffix, bool value) => _setBool(
      () => _appearanceSpriteVars[suffix] ?? false,
      (v) => _appearanceSpriteVars[suffix] = v,
      value);

  void setAppearancePortraitVar(String suffix, bool value) => _setBool(
      () => _appearancePortraitVars[suffix] ?? false,
      (v) => _appearancePortraitVars[suffix] = v,
      value);

  void resetToDefaults() {
    _spriteData = SpriteData();
    _selectionRect = AppConstants.defaultSelectionRect;
    _showCenterlines = true;
    _showGrid = true;
    _showRulers = false;
    _exportDefaults = true;
    _isSelectionActive = false;
    _selectionMode = SelectionMode.none;
    _dragStartPoint = null;
    _originalSelectionRect = null;
    _characterName = 'Haley';
    _cpIncludeLoad = true;
    _cpIncludeAssets = true;
    _cpUsePage1Sprite = true;
    _cpIncludeAppearance = true;
    _cpScale = 4;
    _initializeAppearanceKeys();
    notifyListeners();
  }
}

// Enums for modern selection box
enum SelectionMode {
  none,
  move,
  resizeTopLeft,
  resizeTopRight,
  resizeBottomLeft,
  resizeBottomRight,
}

enum ResizeDirection {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}
