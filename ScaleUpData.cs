using System.Diagnostics.CodeAnalysis;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace ScaleUpUnofficial;

/// <summary>定义呼吸动画的类型，移植自 SpritesInDetail。</summary>
public enum BreathType
{
    Male,
    Female,
    None
}

/// <summary>存储单个资源的缩放和渲染配置。</summary>
[SuppressMessage("ReSharper", "AutoPropertyCanBeMadeGetOnly.Global")]
[SuppressMessage("ReSharper", "UnusedAutoPropertyAccessor.Global")]
public class ScaleUpData
{
    // --- 核心属性 ---
    public string Asset { get; set; } = null!;
    public float Scale { get; set; } = 1;

    // --- 新增选项：用于切换渲染模式 ---
    /// <summary>
    /// 如果为 true，则使用 SpritesInDetail 的高清、精细渲染逻辑。
    /// 如果为 false，则使用 ScaleUpMod 的传统缩放逻辑。
    /// </summary>
    public bool UseSpriteInDetail { get; set; } = false;
        
    public int? SpriteOriginX { get; set; }
    public int? SpriteOriginY { get; set; }
    public BreathType? BreathType { get; set; }
    public int? ChestSourceX { get; set; }
    public int? ChestSourceY { get; set; }
    public int? ChestSourceWidth { get; set; }
    public int? ChestSourceHeight { get; set; }
    public int? ChestAdjustX { get; set; }
    public int? ChestAdjustY { get; set; }
        
    // --- 原始 ScaleUpMod 的内部属性和方法 ---
    public int PaddingWidth { get; set; }
    public int PaddingHeight { get; set; }
    public bool Padded => PaddingWidth + PaddingHeight > 0;
        
    // --- 内部缓存，用于避免重复加载纹理信息 ---
    #region Internal Caching
    private int _width = -1;
    private int _height = -1;
    private bool _dimensionsInitialized;
    internal int Width { get { EnsureDimensionsInitialized(); return _width; } set { _width = value; _dimensionsInitialized = true; } }
    internal int Height { get { EnsureDimensionsInitialized(); return _height; } set { _height = value; _dimensionsInitialized = true; } }

    private int _orgWidth = -1;
    private int _orgHeight = -1;
    private bool _orgDimensionsInitialized;
    internal int OrgHeight { get { EnsureOrgDimensionsInitialized(); return _orgHeight; } set { _orgHeight = value; _orgDimensionsInitialized = true; } }
    internal int OrgWidth { get { EnsureOrgDimensionsInitialized(); return _orgWidth; } set { _orgWidth = value; _orgDimensionsInitialized = true; } }

    private void EnsureDimensionsInitialized()
    {
        if (_dimensionsInitialized) return;
        try
        {
            var tex = ScaleUpMod.Singleton.Helper.GameContent.Load<Texture2D>(Asset);
            _height = tex.Height;
            _width = tex.Width;
        }
        catch { _height = 16; _width = 16; }
        _dimensionsInitialized = true;
    }

    private void EnsureOrgDimensionsInitialized()
    {
        if (_orgDimensionsInitialized) return;
        EnsureDimensionsInitialized();
        _orgHeight = (int)((Height - PaddingHeight) / Scale);
        _orgWidth = (int)((Width - PaddingWidth) / Scale);
        _orgDimensionsInitialized = true;
    }
    #endregion
        
    /// <summary>计算传统缩放模式下的源矩形。</summary>
    public Rectangle? GetScaledSource(Rectangle? source, int originalWidth, int originalHeight, out int padx, out int pady, bool force = false)
    {
        padx = 0; pady = 0;
        if (source.HasValue)
        {
            int tilesX = OrgWidth / originalWidth;
            int tilesY = OrgHeight / originalHeight;
            int x = source.Value.X / originalWidth % tilesX;
            int y = source.Value.Y / originalHeight;
            padx = (int)(PaddingWidth / (float)tilesX);
            pady = (int)(PaddingHeight / (float)tilesY);
            var tileWidth = originalWidth * Scale + padx;
            var tileHeight = originalHeight * Scale + pady;
            return GetSourceRectForStandardTileSheet(Width, y * tilesX + x, (int)tileWidth, (int)tileHeight);
        }
        else if (force)
            return new Rectangle(0, 0, Width, Height);
        return null;
    }

    private static Rectangle GetSourceRectForStandardTileSheet(int texWidth, int tilePosition, int width, int height)
    {
        if (width <= 0 || height <= 0) return Rectangle.Empty;
        int tilesPerRow = texWidth / width;
        int row = tilePosition / tilesPerRow;
        int column = tilePosition % tilesPerRow;
        int x = column * width;
        int y = row * height;
        return new Rectangle(x, y, width, height);
    }
}