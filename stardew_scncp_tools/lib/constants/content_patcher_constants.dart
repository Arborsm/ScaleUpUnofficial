/// 内容补丁工具相关常量
class ContentPatcherConstants {
  // 条件类型
  static const String conditionTypeCharacter = 'character';
  static const String conditionTypePortrait = 'portrait';

  // 季节相关
  static const List<String> seasons = ['spring', 'summer', 'fall', 'winter'];
  static const String seasonPrefix = 'SEASON';
  static const String seasonPrecedence = '-1200';

  // 事件相关
  static const String eventPrefix = 'IS_EVENT';
  static const String eventPrecedence = '-10000';
  static const List<String> commonEvents = [
    'festival_spring24', // Flower Dance
    'festival_fall27', // Spirit's Eve
  ];

  // 位置相关
  static const String locationPrefix = 'LOCATION_NAME';
  static const String locationTargetPrefix = 'Target';
  static const String locationPrecedence = '-10001';
  static const List<String> commonLocations = [
    'IslandSouth',
    'IslandEast',
    'IslandNorth',
    'IslandWest',
    'JojaMart',
    'MovieTheater',
    'EastScarp_Village',
    'EastScarp_VillageInn',
  ];

  // 预设名称映射
  static const Map<String, String> eventPresetNames = {
    'festival_spring24': 'FlowerDance',
    'festival_fall27': 'Spirit',
  };

  static const Map<String, String> locationPresetNames = {
    'JojaMart': 'Joja',
    'MovieTheater': 'Theater',
    'IslandSouth': 'Beach',
  };

  // 岛屿相关
  static const List<String> islandLocations = [
    'IslandSouth',
    'IslandEast',
    'IslandNorth',
    'IslandWest',
  ];

  // UI 文本
  static const String uiGeneratedEntries = 'Generated Entries';
  static const String uiNoEntriesYet = 'No entries yet';
  static const String uiConfigureConditions =
      'Configure conditions and click "Add to Panel"';
  static const String uiCharacterPortrait = 'Character & Portrait';
  static const String uiConditions = 'Conditions';
  static const String uiAddToPanel = 'Add to Panel';
  static const String uiSeason = 'Season';
  static const String uiEvent = 'Event';
  static const String uiLocation = 'Location';
  static const String uiCommonEvents = 'Common Events:';
  static const String uiCommonLocations = 'Common Locations:';
  static const String uiAddCustomEvent = 'Add custom event id';
  static const String uiAddCustomLocation = 'Add custom location';
  static const String uiAdd = 'Add';
  static const String uiCancel = 'Cancel';
  static const String uiSelectPresets = 'Select Presets';
  static const String uiAddPresetToPanel = 'Add Preset to Panel';

  // 预设类别
  static const String uiSeasonPresets = 'Season Presets';
  static const String uiEventPresets = 'Event Presets';
  static const String uiLocationPresets = 'Location Presets';

  // 预设信息
  static const List<Map<String, String>> seasonPresets = [
    {
      'name': '{{CharacterName}}Spring',
      'condition': 'SEASON spring',
      'precedence': '-1200'
    },
    {
      'name': '{{CharacterName}}Summer',
      'condition': 'SEASON summer',
      'precedence': '-1200'
    },
    {
      'name': '{{CharacterName}}Fall',
      'condition': 'SEASON fall',
      'precedence': '-1200'
    },
    {
      'name': '{{CharacterName}}Winter',
      'condition': 'SEASON winter',
      'precedence': '-1200'
    },
  ];

  static const List<Map<String, String>> eventPresets = [
    {
      'name': '{{CharacterName}}FlowerDance',
      'condition': 'IS_EVENT festival_spring24',
      'precedence': '-10000'
    },
    {
      'name': '{{CharacterName}}Spirit',
      'condition': 'IS_EVENT festival_fall27',
      'precedence': '-10000'
    },
  ];

  static const List<Map<String, dynamic>> locationPresets = [
    {
      'name': '{{CharacterName}}Beach',
      'condition': 'LOCATION_NAME Target IslandSouth',
      'precedence': '-10001',
      'isIslandAttire': true
    },
    {
      'name': '{{CharacterName}}Island',
      'condition':
          'LOCATION_NAME Target IslandSouth IslandEast IslandNorth IslandWest',
      'precedence': '-10001',
      'isIslandAttire': true
    },
    {
      'name': '{{CharacterName}}Joja',
      'condition': 'LOCATION_NAME Target JojaMart',
      'precedence': '-10001',
      'isIslandAttire': false
    },
    {
      'name': '{{CharacterName}}Theater',
      'condition': 'LOCATION_NAME Target MovieTheater',
      'precedence': '-10001',
      'isIslandAttire': false
    },
  ];

  // 默认值
  static const String defaultCharacterName = 'Haley';
  static const String defaultPrecedence = '-1200';
}
