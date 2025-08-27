import 'dart:ui';

import '../models/appearance_key.dart';

class AppConstants {
  // Sprite dimensions
  static const int sliceWidth = 64;
  static const int sliceHeight = 128;
  static const double aspectRatio = 16 / 24;

  // UI constants
  static const int handleSize = 8;
  static const int rulerSpace = 40;

  // Default selection rectangle
  static const Rect defaultSelectionRect = Rect.fromLTWH(12, 58, 40, 60);

  // Window settings
  static const Size defaultWindowSize = Size(1600, 900);
  static const Size minWindowSize = Size(1280, 720);
  static const String windowTitle = "Stardew SC&CP Tools";

  // Appearance keys for Content Patcher
  static const List<AppearanceKey> appearanceKeys = [
    AppearanceKey(
      suffix: 'Spring',
      metadata: {'Condition': 'SEASON spring', 'Precedence': -1200},
    ),
    AppearanceKey(
      suffix: 'Summer',
      metadata: {'Condition': 'SEASON Summer', 'Precedence': -1200},
    ),
    AppearanceKey(
      suffix: 'Fall',
      metadata: {'Condition': 'SEASON Fall', 'Precedence': -1200},
    ),
    AppearanceKey(
      suffix: 'Winter',
      metadata: {'Condition': 'SEASON Winter', 'Precedence': -1200},
    ),
    AppearanceKey(
      suffix: 'FlowerDance',
      metadata: {
        'Condition': 'IS_EVENT festival_spring24, {{FestivalOutfits}}',
        'Precedence': -10000
      },
    ),
    AppearanceKey(
      suffix: 'Spirit',
      metadata: {
        'Condition':
            'ANY "IS_EVENT festival_fall27, {{FestivalOutfits}}" "SEASON Fall, DAY_OF_MONTH 27, LOCATION_NAME Target EastScarp_Village EastScarp_VillageInn, {{FestivalOutfits}}"',
        'Precedence': -10000
      },
    ),
    AppearanceKey(
      suffix: 'Beach',
      metadata: {'IsIslandAttire': true, 'Precedence': -10001},
    ),
    AppearanceKey(
      suffix: 'Island',
      metadata: {
        'Condition':
            'LOCATION_NAME Target IslandSouth IslandEast IslandNorth IslandWest',
        'Precedence': -10001
      },
    ),
    AppearanceKey(
      suffix: 'Joja',
      metadata: {
        'Condition':
            'LOCATION_NAME Target JojaMart, !PLAYER_HAS_SEEN_EVENT Any 191393',
        'Precedence': -10001
      },
    ),
    AppearanceKey(
      suffix: 'Theater',
      metadata: {
        'Condition':
            'LOCATION_NAME Target MovieTheater, !PLAYER_HAS_SEEN_EVENT Any 502261',
        'Precedence': -10001
      },
    ),
  ];

  // Default values for breath types
  static const Map<int, Map<String, int>> breathTypeDefaults = {
    0: {
      'ChestSourceX': 0,
      'ChestSourceY': 0,
      'ChestSourceWidth': 0,
      'ChestSourceHeight': 0,
      'ChestAdjustX': 0,
      'ChestAdjustY': 0,
    },
    1: {
      'ChestSourceX': 24,
      'ChestSourceY': 98,
      'ChestSourceWidth': 16,
      'ChestSourceHeight': 16,
      'ChestAdjustX': 0,
      'ChestAdjustY': 0,
    },
    2: {
      'ChestSourceX': 24,
      'ChestSourceY': 100,
      'ChestSourceWidth': 16,
      'ChestSourceHeight': 8,
      'ChestAdjustX': 0,
      'ChestAdjustY': -4,
    },
  };

  // Export defaults mapping
  static const Map<String, Map<String, int>> exportDefaultsMap = {
    'Male': {
      'chest_source_x': 24,
      'chest_source_y': 98,
      'chest_source_width': 16,
      'chest_source_height': 16,
    },
    'Female': {
      'chest_source_x': 24,
      'chest_source_y': 100,
      'chest_source_width': 16,
      'chest_source_height': 8,
    },
    'Common': {
      'head_shot_x': 12,
      'head_shot_y': 58,
      'head_shot_x_render_offset': 0,
      'head_shot_y_render_offset': 0,
      'mini_map_x_offset': 0,
      'mini_map_y_offset': 0,
    },
  };

  // JSON key mapping for export
  static const Map<String, String> jsonKeyMap = {
    'breath_type': 'BreathType',
    'chest_source_x': 'ChestSourceX',
    'chest_source_y': 'ChestSourceY',
    'chest_source_width': 'ChestSourceWidth',
    'chest_source_height': 'ChestSourceHeight',
    'head_shot_x': 'HeadShotX',
    'head_shot_y': 'HeadShotY',
    'head_shot_x_render_offset': 'HeadShotXRenderOffset',
    'head_shot_y_render_offset': 'HeadShotYRenderOffset',
    'mini_map_x_offset': 'MiniMapXOffset',
    'mini_map_y_offset': 'MiniMapYOffset',
  };

  static const List<String> presetBachelors = [
    'Alex',
    'Elliott',
    'Harvey',
    'Sam',
    'Sebastian',
    'Shane',
  ];

  static const List<String> presetBachelorettes = [
    'Abigail',
    'Emily',
    'Haley',
    'Leah',
    'Maru',
    'Penny',
  ];

  static const List<String> presetNonMarriage = [
    'Caroline',
    'Clint',
    'Demetrius',
    'Dwarf',
    'Evelyn',
    'George',
    'Gus',
    'Jas',
    'Jodi',
    'Kent',
    'Krobus',
    'Leo',
    'Lewis',
    'Linus',
    'Marnie',
    'Pam',
    'Pierre',
    'Robin',
    'Sandy',
    'Vincent',
    'Willy',
    'Wizard',
  ];

  static const List<String> presetNonGiftable = [
    'Birdie',
    'Bouncer',
    'Fizz',
    'Gil',
    'Governor',
    'Grandpa',
    'Gunther',
    'Henchman',
    'Marlon',
    'Morris',
    'Mr. Qi',
    'Professor Snail',
  ];
}
