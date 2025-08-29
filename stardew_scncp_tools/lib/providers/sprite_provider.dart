import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:file_selector/file_selector.dart';

import '../models/sprite_data.dart';
import '../models/sprite_slice.dart';
import '../constants/app_constants.dart';
import '../utils/image_utils.dart';

class SpriteProvider extends ChangeNotifier {
  SpriteData _spriteData = SpriteData();
  final List<SpriteSlice> _slices = [];

  late final ValueNotifier<int> _currentSliceIndex = ValueNotifier(0);
  late final ValueNotifier<ui.Image?> _currentDisplayImage =
      ValueNotifier(null);
  late final ValueNotifier<Rect> _selectionRect =
      ValueNotifier(AppConstants.defaultSelectionRect);
  late final ValueNotifier<double> _displayScale = ValueNotifier(1.0);
  late final ValueNotifier<Offset> _displayOffset = ValueNotifier(Offset.zero);

  late final ValueNotifier<bool> _showCenterlines = ValueNotifier(true);
  late final ValueNotifier<bool> _showGrid = ValueNotifier(true);
  late final ValueNotifier<bool> _showRulers = ValueNotifier(false);
  late final ValueNotifier<bool> _exportDefaults = ValueNotifier(true);
  late final ValueNotifier<bool> _isDragging = ValueNotifier(false);
  late final ValueNotifier<bool> _isLoading = ValueNotifier(false);
  late final ValueNotifier<bool> _isSelectionActive = ValueNotifier(false);
  late final ValueNotifier<SelectionMode> _selectionMode =
      ValueNotifier(SelectionMode.none);

  late final ValueNotifier<String> _characterName = ValueNotifier('Haley');
  late final ValueNotifier<bool> _cpIncludeLoad = ValueNotifier(true);
  late final ValueNotifier<bool> _cpIncludeAssets = ValueNotifier(true);
  late final ValueNotifier<bool> _cpUsePage1Sprite = ValueNotifier(true);
  late final ValueNotifier<bool> _cpIncludeAppearance = ValueNotifier(true);
  late final ValueNotifier<int> _cpScale = ValueNotifier(4);

  final Map<String, bool> _appearanceEntryVars = {};
  final Map<String, bool> _appearanceSpriteVars = {};
  final Map<String, bool> _appearancePortraitVars = {};

  SpriteData get spriteData => _spriteData;
  List<SpriteSlice> get slices => _slices;
  int get currentSliceIndex => _currentSliceIndex.value;
  ui.Image? get currentDisplayImage => _currentDisplayImage.value;
  Rect get selectionRect => _selectionRect.value;
  double get displayScale => _displayScale.value;
  Offset get displayOffset => _displayOffset.value;
  bool get showCenterlines => _showCenterlines.value;
  bool get showGrid => _showGrid.value;
  bool get showRulers => _showRulers.value;
  bool get exportDefaults => _exportDefaults.value;
  bool get isDragging => _isDragging.value;
  bool get isLoading => _isLoading.value;
  bool get hasSprites => _slices.isNotEmpty;
  bool get isSelectionActive => _isSelectionActive.value;
  SelectionMode get selectionMode => _selectionMode.value;

  String get characterName => _characterName.value;
  bool get cpIncludeLoad => _cpIncludeLoad.value;
  bool get cpIncludeAssets => _cpIncludeAssets.value;
  bool get cpUsePage1Sprite => _cpUsePage1Sprite.value;
  bool get cpIncludeAppearance => _cpIncludeAppearance.value;
  int get cpScale => _cpScale.value;

  Map<String, bool> get appearanceEntryVars => _appearanceEntryVars;
  Map<String, bool> get appearanceSpriteVars => _appearanceSpriteVars;
  Map<String, bool> get appearancePortraitVars => _appearancePortraitVars;

  SpriteProvider() {
    _initializeAppearanceKeys();
    _setupValueNotifierListeners();
  }

  void _setupValueNotifierListeners() {
    _currentSliceIndex.addListener(notifyListeners);
    _currentDisplayImage.addListener(notifyListeners);
    _selectionRect.addListener(notifyListeners);
    _displayScale.addListener(notifyListeners);
    _displayOffset.addListener(notifyListeners);
    _showCenterlines.addListener(notifyListeners);
    _showGrid.addListener(notifyListeners);
    _showRulers.addListener(notifyListeners);
    _exportDefaults.addListener(notifyListeners);
    _isDragging.addListener(notifyListeners);
    _isLoading.addListener(notifyListeners);
    _isSelectionActive.addListener(notifyListeners);
    _selectionMode.addListener(notifyListeners);
    _characterName.addListener(notifyListeners);
    _cpIncludeLoad.addListener(notifyListeners);
    _cpIncludeAssets.addListener(notifyListeners);
    _cpUsePage1Sprite.addListener(notifyListeners);
    _cpIncludeAppearance.addListener(notifyListeners);
    _cpScale.addListener(notifyListeners);
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
      _isLoading.value = true;
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
        _currentSliceIndex.value = 0;
        await _updateDisplayImage();
        _calculateOptimalDisplay();
      }
    } catch (e) {
      debugPrint('Error loading spritesheet: $e');
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  /// 从指定路径加载精灵图表文件
  Future<void> loadSpritesheetFromPath(String filePath) async {
    try {
      _isLoading.value = true;
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
        _currentSliceIndex.value = 0;
        await _updateDisplayImage();
        _calculateOptimalDisplay();
      }
    } catch (e) {
      debugPrint('Error loading spritesheet from path: $e');
      rethrow;
    } finally {
      _isLoading.value = false;
      notifyListeners();
    }
  }

  Future<void> _updateDisplayImage() async {
    if (_slices.isEmpty || _currentSliceIndex.value >= _slices.length) return;

    final slice = _slices[_currentSliceIndex.value];
    _currentDisplayImage.value =
        await ImageUtils.convertImageToUiImage(slice.image);
    notifyListeners();
  }

  void _calculateOptimalDisplay([Size? canvasSize]) {
    if (_currentDisplayImage.value == null) return;

    final effectiveCanvasSize = canvasSize ?? const Size(800, 600);
    final imageSize = Size(
      _currentDisplayImage.value!.width.toDouble(),
      _currentDisplayImage.value!.height.toDouble(),
    );

    final scaleX = effectiveCanvasSize.width / imageSize.width;
    final scaleY = effectiveCanvasSize.height / imageSize.height;
    _displayScale.value = scaleX < scaleY ? scaleX : scaleY;

    final scaledWidth = imageSize.width * _displayScale.value;
    final scaledHeight = imageSize.height * _displayScale.value;
    _displayOffset.value = Offset(
      (effectiveCanvasSize.width - scaledWidth) / 2,
      (effectiveCanvasSize.height - scaledHeight) / 2,
    );

    if (_spriteData.headShotX == null || _spriteData.headShotY == null) {
      _updateSpriteDataFromSelection();
    }
  }

  void setCurrentSlice(int index) {
    if (index >= 0 &&
        index < _slices.length &&
        index != _currentSliceIndex.value) {
      _currentSliceIndex.value = index;
      _updateDisplayImage();
      notifyListeners();
    }
  }

  void updateSelectionRect(Rect newRect) {
    _selectionRect.value = newRect;
    _updateSpriteDataFromSelection();
    notifyListeners();
  }

  void _updateSpriteDataFromSelection() {
    _spriteData.headShotX =
        _selectionRect.value.left.toInt().clamp(0, AppConstants.sliceWidth);
    _spriteData.headShotY =
        _selectionRect.value.top.toInt().clamp(0, AppConstants.sliceHeight);
  }

  /// 更新精灵数据并同步选择框位置
  void updateSpriteData(SpriteData newData) {
    final oldData = _spriteData;
    _spriteData = newData;
    if (_updateSelectionRectFromSpriteData()) {
      notifyListeners();
    } else {
      _spriteData = oldData;
    }
  }

  /// 从精灵数据更新选择框位置
  bool _updateSelectionRectFromSpriteData() {
    int headShotX = _spriteData.headShotX ?? 0;
    int headShotY = _spriteData.headShotY ?? 0;

    headShotX = headShotX.clamp(0, AppConstants.sliceWidth);
    headShotY = headShotY.clamp(0, AppConstants.sliceHeight);

    double width = (AppConstants.sliceWidth - 2 * headShotX).toDouble();
    double height = width / AppConstants.aspectRatio;

    if (height <= 0 || headShotY + height > AppConstants.sliceHeight) {
      height = AppConstants.sliceHeight - headShotY.toDouble();
      if (height <= 0) {
        height = 0;
        width = 0;
      } else {
        return false;
      }
    }
    if (width <= 0 || 2 * headShotX + width > AppConstants.sliceWidth) {
      width = AppConstants.sliceWidth - 2 * headShotX.toDouble();
      if (width <= 0) {
        width = 0;
        height = 0;
      } else {
        return false;
      }
    }

    _selectionRect.value = Rect.fromLTWH(
      headShotX.toDouble(),
      headShotY.toDouble(),
      width,
      height,
    );

    if (_currentDisplayImage.value != null) {
      final imageWidth = _currentDisplayImage.value!.width.toDouble();
      final imageHeight = _currentDisplayImage.value!.height.toDouble();

      final clampedX = _selectionRect.value.left
          .clamp(0.0, imageWidth - _selectionRect.value.width);
      final clampedY = _selectionRect.value.top
          .clamp(0.0, imageHeight - _selectionRect.value.height);

      if (clampedX != _selectionRect.value.left ||
          clampedY != _selectionRect.value.top) {
        _selectionRect.value = Rect.fromLTWH(
          clampedX,
          clampedY,
          _selectionRect.value.width,
          _selectionRect.value.height,
        );
      }
    }
    return true;
  }

  void setShowCenterlines(bool value) => _showCenterlines.value = value;
  void setShowGrid(bool value) => _showGrid.value = value;
  void setShowRulers(bool value) => _showRulers.value = value;
  void setExportDefaults(bool value) => _exportDefaults.value = value;
  void setDragging(bool value) => _isDragging.value = value;

  void setCharacterName(String name) => _characterName.value = name;
  void setCpIncludeLoad(bool value) => _cpIncludeLoad.value = value;
  void setCpIncludeAssets(bool value) => _cpIncludeAssets.value = value;
  void setCpUsePage1Sprite(bool value) => _cpUsePage1Sprite.value = value;
  void setCpIncludeAppearance(bool value) => _cpIncludeAppearance.value = value;
  void setCpScale(int scale) => _cpScale.value = scale;

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

  void setAppearanceSpriteVar(String suffix, bool value) {
    _appearanceSpriteVars[suffix] = value;
    notifyListeners();
  }

  void setAppearancePortraitVar(String suffix, bool value) {
    _appearancePortraitVars[suffix] = value;
    notifyListeners();
  }

  void resetToDefaults() {
    _spriteData = SpriteData();
    _selectionRect.value = AppConstants.defaultSelectionRect;
    _spriteData.headShotX = _selectionRect.value.left.toInt();
    _spriteData.headShotY = _selectionRect.value.top.toInt();
    _showCenterlines.value = true;
    _showGrid.value = true;
    _showRulers.value = false;
    _exportDefaults.value = true;
    _isSelectionActive.value = false;
    _selectionMode.value = SelectionMode.none;
    _characterName.value = 'Haley';
    _cpIncludeLoad.value = true;
    _cpIncludeAssets.value = true;
    _cpUsePage1Sprite.value = true;
    _cpIncludeAppearance.value = true;
    _cpScale.value = 4;
    _initializeAppearanceKeys();
    notifyListeners();
  }
}

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
