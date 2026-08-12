using System.Collections.Generic;
using ScaleUpUnofficial;

namespace SpritesInDetailCompatibilityLayer;

public class Content
{
    public List<Sprite> Sprites { get; set; } = new();
}

public class Sprite
{
    public string Target { get; set; } = string.Empty;
    public string? FromFile { get; set; }
    public int? SpriteWidth { get; set; }
    public int? SpriteHeight { get; set; }
    public int? SpriteOriginX { get; set; }
    public int? SpriteOriginY { get; set; }

    public int? WidthScale { get; set; }
    public int? HeightScale { get; set; }

    public BreathType? BreathType { get; set; }
    public int? ChestSourceX { get; set; }
    public int? ChestSourceY { get; set; }
    public int? ChestSourceWidth { get; set; }
    public int? ChestSourceHeight { get; set; }
    public int? ChestAdjustX { get; set; }
    public int? ChestAdjustY { get; set; }

    public Dictionary<string, string>? When { get; set; }

    public List<PixelReplacement> PixelReplacements { get; set; } = new();
}

/// <summary>SID 格式的像素级替换(FromFile 为内容包内文件路径),由兼容层映射到本模组的 PixelReplacementData。</summary>
public class PixelReplacement
{
    public int? TargetX { get; set; }
    public int? TargetY { get; set; }
    public string? FromFile { get; set; }
}

