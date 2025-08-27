class AppearanceKey {
  final String suffix;
  final Map<String, dynamic> metadata;

  const AppearanceKey({
    required this.suffix,
    required this.metadata,
  });

  String get condition => metadata['Condition'] ?? '';
  int get precedence => metadata['Precedence'] ?? -1200;
  bool get isIslandAttire => metadata['IsIslandAttire'] ?? false;

  factory AppearanceKey.fromJson(String suffix, Map<String, dynamic> metadata) {
    return AppearanceKey(
      suffix: suffix,
      metadata: metadata,
    );
  }
}
