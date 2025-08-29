import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';

import '../../providers/sprite_provider.dart';
import '../../models/sprite_data.dart';
import '../../constants/app_constants.dart';

/// 参数面板组件，用于显示和编辑精灵数据参数
class ParameterPanel extends StatefulWidget {
  const ParameterPanel({super.key});

  @override
  State<ParameterPanel> createState() => _ParameterPanelState();
}

class _ParameterPanelState extends State<ParameterPanel> {
  final TextEditingController _headShotXController = TextEditingController();
  final TextEditingController _headShotYController = TextEditingController();
  final TextEditingController _breathTypeController = TextEditingController();
  final TextEditingController _chestSourceXController = TextEditingController();
  final TextEditingController _chestSourceYController = TextEditingController();
  final TextEditingController _chestSourceWidthController =
      TextEditingController();
  final TextEditingController _chestSourceHeightController =
      TextEditingController();
  final TextEditingController _miniMapXOffsetController =
      TextEditingController();
  final TextEditingController _miniMapYOffsetController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  @override
  void dispose() {
    _headShotXController.dispose();
    _headShotYController.dispose();
    _breathTypeController.dispose();
    _chestSourceXController.dispose();
    _chestSourceYController.dispose();
    _chestSourceWidthController.dispose();
    _chestSourceHeightController.dispose();
    _miniMapXOffsetController.dispose();
    _miniMapYOffsetController.dispose();
    super.dispose();
  }

  /// 初始化文本控制器，设置初始值
  void _initializeControllers() {
    final spriteProvider = context.read<SpriteProvider>();
    final spriteData = spriteProvider.spriteData;

    _headShotXController.text = (spriteData.headShotX ?? 0).toString();
    _headShotYController.text = (spriteData.headShotY ?? 0).toString();
    _breathTypeController.text =
        _getBreathTypeString(spriteData.breathType ?? 0);
    _chestSourceXController.text = (spriteData.chestSourceX ?? 0).toString();
    _chestSourceYController.text = (spriteData.chestSourceY ?? 0).toString();
    _chestSourceWidthController.text =
        (spriteData.chestSourceWidth ?? 0).toString();
    _chestSourceHeightController.text =
        (spriteData.chestSourceHeight ?? 0).toString();
    _miniMapXOffsetController.text =
        (spriteData.miniMapXOffset ?? 0).toString();
    _miniMapYOffsetController.text =
        (spriteData.miniMapYOffset ?? 0).toString();
  }

  /// 将呼吸类型数字转换为显示字符串
  String _getBreathTypeString(int breathType) {
    switch (breathType) {
      case 0:
        return '0: None';
      case 1:
        return '1: Male';
      case 2:
        return '2: Female';
      default:
        return '0: None';
    }
  }

  /// 从显示字符串解析呼吸类型数字
  int _getBreathTypeFromString(String value) {
    if (value.startsWith('1:')) return 1;
    if (value.startsWith('2:')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final spriteProvider = context.watch<SpriteProvider>();

    final spriteData = spriteProvider.spriteData;
    final currentHeadShotX = spriteData.headShotX ?? 0;
    final currentHeadShotY = spriteData.headShotY ?? 0;
    final currentMiniMapXOffset = spriteData.miniMapXOffset ?? 0;
    final currentMiniMapYOffset = spriteData.miniMapYOffset ?? 0;

    if (int.tryParse(_headShotXController.text) != currentHeadShotX) {
      _headShotXController.text = currentHeadShotX.toString();
    }
    if (int.tryParse(_headShotYController.text) != currentHeadShotY) {
      _headShotYController.text = currentHeadShotY.toString();
    }
    if (int.tryParse(_miniMapXOffsetController.text) != currentMiniMapXOffset) {
      _miniMapXOffsetController.text = currentMiniMapXOffset.toString();
    }
    if (int.tryParse(_miniMapYOffsetController.text) != currentMiniMapYOffset) {
      _miniMapYOffsetController.text = currentMiniMapYOffset.toString();
    }

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(right: 20), // 为滚动条留出更多空间
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Headshot Coordinates Section
              _buildSectionHeader('Headshot Coordinates'),
              _buildParameterField(
                label: 'HeadShot X',
                controller: _headShotXController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  int intValue = int.tryParse(value) ?? 0;
                  intValue = intValue.clamp(0, AppConstants.sliceWidth);
                  _headShotXController.text = intValue.toString();
                  _headShotXController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _headShotXController.text.length));
                  final updatedData = spriteProvider.spriteData.copyWith(
                    headShotX: intValue,
                  );
                  spriteProvider.updateSpriteData(updatedData);
                },
              ),
              const SizedBox(height: 8),
              _buildParameterField(
                label: 'HeadShot Y',
                controller: _headShotYController,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (value) {
                  int intValue = int.tryParse(value) ?? 0;
                  intValue = intValue.clamp(0, AppConstants.sliceHeight);
                  _headShotYController.text = intValue.toString();
                  _headShotYController.selection = TextSelection.fromPosition(
                      TextPosition(offset: _headShotYController.text.length));
                  final updatedData = spriteProvider.spriteData.copyWith(
                    headShotY: intValue,
                  );
                  spriteProvider.updateSpriteData(updatedData);
                },
              ),

              const SizedBox(height: 16),

              // Animation Section
              _buildSectionHeader('Animation'),
              _buildDropdownField(
                label: 'Breath Type',
                controller: _breathTypeController,
                items: const ['0: None', '1: Male', '2: Female'],
                onChanged: (value) {
                  final breathType = _getBreathTypeFromString(value);
                  final updatedData = spriteProvider.spriteData.copyWith(
                    breathType: breathType,
                  );
                  spriteProvider.updateSpriteData(updatedData);

                  // Apply default values for breath type
                  final defaults = AppConstants.breathTypeDefaults[breathType]!;
                  final dataWithDefaults = updatedData.copyWith(
                    chestSourceX: defaults['ChestSourceX'],
                    chestSourceY: defaults['ChestSourceY'],
                    chestSourceWidth: defaults['ChestSourceWidth'],
                    chestSourceHeight: defaults['ChestSourceHeight'],
                    chestAdjustX: defaults['ChestAdjustX'],
                    chestAdjustY: defaults['ChestAdjustY'],
                  );
                  spriteProvider.updateSpriteData(dataWithDefaults);
                  _updateChestControllers(dataWithDefaults);
                },
              ),

              const SizedBox(height: 8),
              _buildSectionHeader('Chest Source'),
              _buildParameterField(
                label: 'Chest Source X',
                controller: _chestSourceXController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    final updatedData = spriteProvider.spriteData.copyWith(
                      chestSourceX: intValue,
                    );
                    spriteProvider.updateSpriteData(updatedData);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildParameterField(
                label: 'Chest Source Y',
                controller: _chestSourceYController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    final updatedData = spriteProvider.spriteData.copyWith(
                      chestSourceY: intValue,
                    );
                    spriteProvider.updateSpriteData(updatedData);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildParameterField(
                label: 'Chest Source Width',
                controller: _chestSourceWidthController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    final updatedData = spriteProvider.spriteData.copyWith(
                      chestSourceWidth: intValue,
                    );
                    spriteProvider.updateSpriteData(updatedData);
                  }
                },
              ),
              const SizedBox(height: 8),
              _buildParameterField(
                label: 'Chest Source Height',
                controller: _chestSourceHeightController,
                onChanged: (value) {
                  final intValue = int.tryParse(value);
                  if (intValue != null) {
                    final updatedData = spriteProvider.spriteData.copyWith(
                      chestSourceHeight: intValue,
                    );
                    spriteProvider.updateSpriteData(updatedData);
                  }
                },
              ),

              const SizedBox(height: 16),

              // MiniMap Offset Section
              _buildSectionHeader('MiniMap Offset'),
              _buildParameterField(
                label: 'MiniMap X Offset',
                controller: _miniMapXOffsetController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
                ],
                onChanged: (value) {
                  int intValue = int.tryParse(value) ?? 0;
                  _miniMapXOffsetController.text = intValue.toString();
                  _miniMapXOffsetController.selection =
                      TextSelection.fromPosition(TextPosition(
                          offset: _miniMapXOffsetController.text.length));
                  final updatedData = spriteProvider.spriteData.copyWith(
                    miniMapXOffset: intValue,
                  );
                  spriteProvider.updateSpriteData(updatedData);
                },
              ),
              const SizedBox(height: 8),
              _buildParameterField(
                label: 'MiniMap Y Offset',
                controller: _miniMapYOffsetController,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^-?\d*'))
                ],
                onChanged: (value) {
                  int intValue = int.tryParse(value) ?? 0;
                  _miniMapYOffsetController.text = intValue.toString();
                  _miniMapYOffsetController.selection =
                      TextSelection.fromPosition(TextPosition(
                          offset: _miniMapYOffsetController.text.length));
                  final updatedData = spriteProvider.spriteData.copyWith(
                    miniMapYOffset: intValue,
                  );
                  spriteProvider.updateSpriteData(updatedData);
                },
              ),

              const SizedBox(height: 16),

              // Display Options
              _buildSectionHeader('Display Options'),
              _buildSwitchField(
                label: 'Show Centerlines',
                value: spriteProvider.showCenterlines,
                onChanged: (value) => spriteProvider.setShowCenterlines(value),
              ),
              _buildSwitchField(
                label: 'Show Grid',
                value: spriteProvider.showGrid,
                onChanged: (value) => spriteProvider.setShowGrid(value),
              ),
              _buildSwitchField(
                label: 'Show Rulers',
                value: spriteProvider.showRulers,
                onChanged: (value) => spriteProvider.setShowRulers(value),
              ),
              _buildSwitchField(
                label: 'Include Defaults in Export',
                value: spriteProvider.exportDefaults,
                onChanged: (value) => spriteProvider.setExportDefaults(value),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _updateChestControllers(SpriteData spriteData) {
    _chestSourceXController.text = (spriteData.chestSourceX ?? 0).toString();
    _chestSourceYController.text = (spriteData.chestSourceY ?? 0).toString();
    _chestSourceWidthController.text =
        (spriteData.chestSourceWidth ?? 0).toString();
    _chestSourceHeightController.text =
        (spriteData.chestSourceHeight ?? 0).toString();
    _miniMapXOffsetController.text =
        (spriteData.miniMapXOffset ?? 0).toString();
    _miniMapYOffsetController.text =
        (spriteData.miniMapYOffset ?? 0).toString();
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }

  /// 构建参数输入字段
  Widget _buildParameterField({
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    TextInputType keyboardType = TextInputType.number,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            ),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  /// 构建下拉选择字段
  Widget _buildDropdownField({
    required String label,
    required TextEditingController controller,
    required List<String> items,
    required Function(String) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            initialValue: controller.text,
            items: items.map((item) {
              return DropdownMenuItem(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                controller.text = value;
                onChanged(value);
              }
            },
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// 构建开关字段
  Widget _buildSwitchField({
    required String label,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
