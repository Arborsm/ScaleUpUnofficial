import 'dart:convert';

import '../providers/sprite_provider.dart';
import '../models/sprite_data.dart';
import '../constants/app_constants.dart';

class JsonExportService {
  /// Generate the complete sprite JSON object
  static Map<String, dynamic> generateSpriteJson(
      SpriteProvider spriteProvider) {
    final spriteData = spriteProvider.spriteData;
    final outputData = <String, dynamic>{};

    // Add breath type if applicable
    if (spriteData.breathType != null && spriteData.breathType! > 0) {
      outputData['BreathType'] = _getBreathTypeString(spriteData.breathType!);

      // Add breath-specific defaults or current values
      final breathDefaults = _getBreathDefaults(spriteData.breathType!);
      _addFieldsFromDefaults(outputData, spriteData, breathDefaults,
          spriteProvider.exportDefaults);
    } else {
      // For breath type 0 (None), check if we should export anything
      if (spriteProvider.exportDefaults || spriteData.headShotX != null) {
        _addCommonFields(outputData, spriteData, spriteProvider.exportDefaults);
      }
    }

    return {'Sprite': outputData};
  }

  /// Format JSON object as a pretty-printed string
  static String formatJsonString(Map<String, dynamic> jsonData) {
    return const JsonEncoder.withIndent('    ').convert(jsonData);
  }

  /// Generate Content Patcher JSON
  static Map<String, dynamic> generateContentPatcherJson(
      SpriteProvider spriteProvider) {
    final changes = <Map<String, dynamic>>[];
    final characterName = spriteProvider.characterName;

    // Load action if enabled
    if (spriteProvider.cpIncludeLoad) {
      final targets = <String>[];

      for (final key in AppConstants.appearanceKeys) {
        final suffix = key.suffix;
        final entryVar = spriteProvider.appearanceEntryVars[suffix] ?? false;
        final spriteVar = spriteProvider.appearanceSpriteVars[suffix] ?? false;
        final portraitVar =
            spriteProvider.appearancePortraitVars[suffix] ?? false;

        if (entryVar) {
          if (portraitVar) {
            targets.add('Portraits/${characterName}_$suffix');
          }
          if (spriteVar) {
            targets.add('Characters/${characterName}_$suffix');
          }
        }
      }

      if (targets.isNotEmpty) {
        changes.add({
          'LogName': 'Load $characterName\'s Outfits',
          'Action': 'Load',
          'Priority': 'High',
          'Target': targets.join(', '),
          'FromFile':
              '{{TargetPathOnly}}/$characterName/{{TargetWithoutPath}}.png',
        });
      }
    }

    // Scale up action if enabled
    if (spriteProvider.cpIncludeAssets) {
      final entries = <String, dynamic>{};
      final charAssets = <String>['Characters/$characterName'];
      final portAssets = <String>['Portraits/$characterName'];

      for (final key in AppConstants.appearanceKeys) {
        final suffix = key.suffix;
        final entryVar = spriteProvider.appearanceEntryVars[suffix] ?? false;
        final spriteVar = spriteProvider.appearanceSpriteVars[suffix] ?? false;
        final portraitVar =
            spriteProvider.appearancePortraitVars[suffix] ?? false;

        if (entryVar) {
          if (spriteVar) {
            charAssets.add('Characters/${characterName}_$suffix');
          }
          if (portraitVar) {
            portAssets.add('Portraits/${characterName}_$suffix');
          }
        }
      }

      entries['Playtonymous.$characterName'] = {
        'Asset': charAssets.join(', '),
        'Sprite': generateSpriteJson(spriteProvider)['Sprite'],
      };

      entries['Playtonymous.ScaleUp$characterName'] = {
        'Asset': portAssets.join(', '),
        'Scale': spriteProvider.cpScale,
      };

      changes.add({
        'Action': 'EditData',
        'Target': '{{Platonymous.ScaleUp/Assets}}',
        'Entries': entries,
      });
    }

    // Appearance data if enabled
    if (spriteProvider.cpIncludeAppearance) {
      final entries = <String, dynamic>{};

      for (final key in AppConstants.appearanceKeys) {
        final suffix = key.suffix;
        final entryVar = spriteProvider.appearanceEntryVars[suffix] ?? false;
        final spriteVar = spriteProvider.appearanceSpriteVars[suffix] ?? false;
        final portraitVar =
            spriteProvider.appearancePortraitVars[suffix] ?? false;

        if (entryVar) {
          final entry = <String, dynamic>{
            'Id': '{{ModId}}.$characterName$suffix',
            'Precedence': key.precedence,
          };

          if (key.condition.isNotEmpty) {
            entry['Condition'] = key.condition;
          }

          if (key.isIslandAttire) {
            entry['IsIslandAttire'] = true;
          }

          if (spriteVar) {
            entry['Sprite'] = 'Characters/${characterName}_$suffix';
          }

          if (portraitVar) {
            entry['Portrait'] = 'Portraits/${characterName}_$suffix';
          }

          entries['{{ModId}}.$characterName$suffix'] = entry;
        }
      }

      if (entries.isNotEmpty) {
        changes.add({
          'LogName': '$characterName Appearance Data',
          'Action': 'EditData',
          'Target': 'Data/Characters',
          'TargetField': [characterName, 'Appearance'],
          'Entries': entries,
        });
      }
    }

    return {'Changes': changes};
  }

  static String _getBreathTypeString(int breathType) {
    switch (breathType) {
      case 1:
        return 'Male';
      case 2:
        return 'Female';
      default:
        return 'None';
    }
  }

  static Map<String, int> _getBreathDefaults(int breathType) {
    return AppConstants.breathTypeDefaults[breathType] ?? {};
  }

  static void _addFieldsFromDefaults(
    Map<String, dynamic> outputData,
    SpriteData spriteData,
    Map<String, int> defaults,
    bool includeDefaults,
  ) {
    // Add common fields
    _addCommonFields(outputData, spriteData, includeDefaults);

    // Add breath-specific fields
    for (final entry in defaults.entries) {
      final fieldName = entry.key;
      final defaultValue = entry.value;

      int? currentValue;
      switch (fieldName) {
        case 'ChestSourceX':
          currentValue = spriteData.chestSourceX;
          break;
        case 'ChestSourceY':
          currentValue = spriteData.chestSourceY;
          break;
        case 'ChestSourceWidth':
          currentValue = spriteData.chestSourceWidth;
          break;
        case 'ChestSourceHeight':
          currentValue = spriteData.chestSourceHeight;
          break;
        case 'ChestAdjustX':
          currentValue = spriteData.chestAdjustX;
          break;
        case 'ChestAdjustY':
          currentValue = spriteData.chestAdjustY;
          break;
      }

      if (currentValue != null &&
          (includeDefaults || currentValue != defaultValue)) {
        outputData[fieldName] = currentValue;
      }
    }
  }

  static void _addCommonFields(
    Map<String, dynamic> outputData,
    SpriteData spriteData,
    bool includeDefaults,
  ) {
    final commonDefaults = AppConstants.exportDefaultsMap['Common']!;

    // Headshot coordinates
    if (spriteData.headShotX != null &&
        (includeDefaults ||
            spriteData.headShotX != commonDefaults['head_shot_x'])) {
      outputData['HeadShotX'] = spriteData.headShotX;
    }

    if (spriteData.headShotY != null &&
        (includeDefaults ||
            spriteData.headShotY != commonDefaults['head_shot_y'])) {
      outputData['HeadShotY'] = spriteData.headShotY;
    }

    // Render offsets
    if (spriteData.headShotXRenderOffset != null &&
        (includeDefaults ||
            spriteData.headShotXRenderOffset !=
                commonDefaults['head_shot_x_render_offset'])) {
      outputData['HeadShotXRenderOffset'] = spriteData.headShotXRenderOffset;
    }

    if (spriteData.headShotYRenderOffset != null &&
        (includeDefaults ||
            spriteData.headShotYRenderOffset !=
                commonDefaults['head_shot_y_render_offset'])) {
      outputData['HeadShotYRenderOffset'] = spriteData.headShotYRenderOffset;
    }

    // Minimap offsets
    if (spriteData.miniMapXOffset != null &&
        (includeDefaults ||
            spriteData.miniMapXOffset != commonDefaults['mini_map_x_offset'])) {
      outputData['MiniMapXOffset'] = spriteData.miniMapXOffset;
    }

    if (spriteData.miniMapYOffset != null &&
        (includeDefaults ||
            spriteData.miniMapYOffset != commonDefaults['mini_map_y_offset'])) {
      outputData['MiniMapYOffset'] = spriteData.miniMapYOffset;
    }
  }
}
