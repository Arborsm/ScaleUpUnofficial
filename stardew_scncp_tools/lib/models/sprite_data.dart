class SpriteData {
  int? spriteOriginX;
  int? spriteOriginY;
  int? breathType;
  int? chestSourceX;
  int? chestSourceY;
  int? chestSourceWidth;
  int? chestSourceHeight;
  int? chestAdjustX;
  int? chestAdjustY;
  int? headShotX;
  int? headShotY;
  int? headShotXRenderOffset;
  int? headShotYRenderOffset;
  int? miniMapXOffset;
  int? miniMapYOffset;

  SpriteData({
    this.spriteOriginX,
    this.spriteOriginY,
    this.breathType,
    this.chestSourceX,
    this.chestSourceY,
    this.chestSourceWidth,
    this.chestSourceHeight,
    this.chestAdjustX,
    this.chestAdjustY,
    this.headShotX,
    this.headShotY,
    this.headShotXRenderOffset,
    this.headShotYRenderOffset,
    this.miniMapXOffset,
    this.miniMapYOffset,
  });

  SpriteData copyWith({
    int? spriteOriginX,
    int? spriteOriginY,
    int? breathType,
    int? chestSourceX,
    int? chestSourceY,
    int? chestSourceWidth,
    int? chestSourceHeight,
    int? chestAdjustX,
    int? chestAdjustY,
    int? headShotX,
    int? headShotY,
    int? headShotXRenderOffset,
    int? headShotYRenderOffset,
    int? miniMapXOffset,
    int? miniMapYOffset,
  }) {
    return SpriteData(
      spriteOriginX: spriteOriginX ?? this.spriteOriginX,
      spriteOriginY: spriteOriginY ?? this.spriteOriginY,
      breathType: breathType ?? this.breathType,
      chestSourceX: chestSourceX ?? this.chestSourceX,
      chestSourceY: chestSourceY ?? this.chestSourceY,
      chestSourceWidth: chestSourceWidth ?? this.chestSourceWidth,
      chestSourceHeight: chestSourceHeight ?? this.chestSourceHeight,
      chestAdjustX: chestAdjustX ?? this.chestAdjustX,
      chestAdjustY: chestAdjustY ?? this.chestAdjustY,
      headShotX: headShotX ?? this.headShotX,
      headShotY: headShotY ?? this.headShotY,
      headShotXRenderOffset: headShotXRenderOffset ?? this.headShotXRenderOffset,
      headShotYRenderOffset: headShotYRenderOffset ?? this.headShotYRenderOffset,
      miniMapXOffset: miniMapXOffset ?? this.miniMapXOffset,
      miniMapYOffset: miniMapYOffset ?? this.miniMapYOffset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (spriteOriginX != null) 'spriteOriginX': spriteOriginX,
      if (spriteOriginY != null) 'spriteOriginY': spriteOriginY,
      if (breathType != null) 'breathType': breathType,
      if (chestSourceX != null) 'chestSourceX': chestSourceX,
      if (chestSourceY != null) 'chestSourceY': chestSourceY,
      if (chestSourceWidth != null) 'chestSourceWidth': chestSourceWidth,
      if (chestSourceHeight != null) 'chestSourceHeight': chestSourceHeight,
      if (chestAdjustX != null) 'chestAdjustX': chestAdjustX,
      if (chestAdjustY != null) 'chestAdjustY': chestAdjustY,
      if (headShotX != null) 'headShotX': headShotX,
      if (headShotY != null) 'headShotY': headShotY,
      if (headShotXRenderOffset != null) 'headShotXRenderOffset': headShotXRenderOffset,
      if (headShotYRenderOffset != null) 'headShotYRenderOffset': headShotYRenderOffset,
      if (miniMapXOffset != null) 'miniMapXOffset': miniMapXOffset,
      if (miniMapYOffset != null) 'miniMapYOffset': miniMapYOffset,
    };
  }

  factory SpriteData.fromJson(Map<String, dynamic> json) {
    return SpriteData(
      spriteOriginX: json['spriteOriginX'],
      spriteOriginY: json['spriteOriginY'],
      breathType: json['breathType'],
      chestSourceX: json['chestSourceX'],
      chestSourceY: json['chestSourceY'],
      chestSourceWidth: json['chestSourceWidth'],
      chestSourceHeight: json['chestSourceHeight'],
      chestAdjustX: json['chestAdjustX'],
      chestAdjustY: json['chestAdjustY'],
      headShotX: json['headShotX'],
      headShotY: json['headShotY'],
      headShotXRenderOffset: json['headShotXRenderOffset'],
      headShotYRenderOffset: json['headShotYRenderOffset'],
      miniMapXOffset: json['miniMapXOffset'],
      miniMapYOffset: json['miniMapYOffset'],
    );
  }
}
