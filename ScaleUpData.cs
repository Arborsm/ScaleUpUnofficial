using System.Diagnostics.CodeAnalysis;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
// ReSharper disable UnusedMember.Global

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
[SuppressMessage("ReSharper", "ClassNeverInstantiated.Global")]
public class ScaleUpData
{
    public string Asset { get; set; } = null!;
    public float Scale { get; set; } = 1;
    public int PaddingWidth { get; set; }
    public int PaddingHeight { get; set; }
    public bool Padded => PaddingWidth + PaddingHeight > 0;
    
    public SpriteData? Sprite { get; set; } = null;
    public class SpriteData
    {
        public int? SpriteOriginX { get; set; }
        public int? SpriteOriginY { get; set; }
        public BreathType? BreathType { get; set; }
        public int? ChestSourceX { get; set; }
        public int? ChestSourceY { get; set; }
        public int? ChestSourceWidth { get; set; }
        public int? ChestSourceHeight { get; set; }
        public int? ChestAdjustX { get; set; }
        public int? ChestAdjustY { get; set; }
        public int? HeadShotX { get; set; }
        public int? HeadShotY { get; set; }
        public int? HeadShotXRenderOffset { get; set; }
        public int? HeadShotYRenderOffset { get; set; }
        public int? MiniMapXOffset { get; set; }
        public int? MiniMapYOffset { get; set; }
    }
    
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
        var scale = Sprite != null ? 4 : Scale;
        if (_orgDimensionsInitialized) return;
        EnsureDimensionsInitialized();
        _orgHeight = (int)((Height - PaddingHeight) / scale);
        _orgWidth = (int)((Width - PaddingWidth) / scale);
        _orgDimensionsInitialized = true;
    }
    #endregion
        
    /// <summary>计算缩放模式下的源矩形。</summary>
    public Rectangle? GetScaledSource(Rectangle? source, int originalWidth, int originalHeight, out int padx, out int pady, bool force = false, bool cycle = false)
    {
        padx = 0; pady = 0;
        if (source.HasValue)
        {
            var tilesX = OrgWidth / originalWidth;
            var tilesY = OrgHeight / originalHeight;
            var x = source.Value.X / originalWidth;
            if (!cycle)
                x %= tilesX;
            var y = source.Value.Y / originalHeight;
            padx = (int)(PaddingWidth / (float)tilesX);
            pady = (int)(PaddingHeight / (float)tilesY);
            var tileWidth = originalWidth * Scale + padx;
            var tileHeight = originalHeight * Scale + pady;
            return GetSourceRectForStandardTileSheet(Width, y * tilesX + x, (int)tileWidth, (int)tileHeight);
        }

        if (force)
            return new Rectangle(0, 0, Width, Height);
        return null;
    }

    private static Rectangle GetSourceRectForStandardTileSheet(int texWidth, int tilePosition, int width, int height)
    {
        if (width <= 0 || height <= 0) return Rectangle.Empty;
        var tilesPerRow = texWidth / width;
        var row = tilePosition / tilesPerRow;
        var column = tilePosition % tilesPerRow;
        var x = column * width;
        var y = row * height;
        return new Rectangle(x, y, width, height);
    }
}

internal class ReplacedTexture : Texture2D
{
    private ReplacedTexture(Texture2D texture, int width, int height)
        : base(texture.GraphicsDevice, 1, 1)
    {
        CopyFromTexture(texture);
        SetImageSize(width, height);
    }
    
    public static Texture2D Create(Texture2D texture)
    {
        var width = texture.Width;
        var height = texture.Height;
        if (width > 64)
        {
            width /= 4;
            height /= 4;
        }
        return new ReplacedTexture(texture, width, height);
    }
}