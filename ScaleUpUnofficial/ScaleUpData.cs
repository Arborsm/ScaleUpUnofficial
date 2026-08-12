using System.Diagnostics.CodeAnalysis;
using System.Text.RegularExpressions;
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
    public string? Target { get; set; }
    public string? Asset { get; set; }
    public string? Assets { get; set; }
    public float Scale { get; set; } = 1;
    public int PaddingWidth { get; set; }
    public int PaddingHeight { get; set; }
    public bool Padded => PaddingWidth + PaddingHeight > 0;
    /// <summary>是否为农夫(玩家)精灵。农夫由 FarmerRenderer 用内部复制的纹理绘制,需要专门处理。</summary>
    public bool IsFarmer { get; set; }
    /// <summary>农夫帧的屏幕渲染宽度(游戏单位,原版为 16)。&gt;16 时按比例放大渲染并保持锚点对齐。</summary>
    public int? SpriteWidth { get; set; }
    /// <summary>农夫帧的屏幕渲染高度(游戏单位,原版为 32)。&gt;32 时按比例放大渲染并保持锚点对齐。</summary>
    public int? SpriteHeight { get; set; }
    public SpriteData? Sprite { get; set; }
    public class SpriteData
    {
        public bool? IsSmallSprite { get; set; } 
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
    public string FinalAsset(string asset) => Target != null ? $"{Target}/{asset}" : asset;

    private void EnsureDimensionsInitialized()
    {
        if (_dimensionsInitialized) return;
        if (Asset != null)
        {
            var tex = ScaleUpMod.Instance!.Helper.GameContent.Load<Texture2D>(FinalAsset(Asset));
            Init(tex);
        }
        else if (Assets != null)
        {
            var assets = Regex.Replace(Assets, @"\s", "").Split(',');
            foreach (var asset in assets)
            {
                if (_height > 0 && _width > 0) continue;
                var tex = ScaleUpMod.Instance!.Helper.GameContent.Load<Texture2D>(FinalAsset(asset));
                Init(tex);
            }
        }
        else
        {
            throw new Exception("Asset or Assets must be set.");
        }
        _dimensionsInitialized = true;
        return;

        void Init(Texture2D tex)
        {
            if (tex is ReplacedTexture replacedTexture)
            {
                tex = replacedTexture.NewTexture!;
            }
            _height = tex.Height;
            _width = tex.Width;
        }
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
            // 防止除零错误
            if (originalWidth <= 0 || originalHeight <= 0)
            {
                if (force)
                    return new Rectangle(0, 0, Width, Height);
                return null;
            }

            var tilesX = OrgWidth / originalWidth;
            var tilesY = OrgHeight / originalHeight;

            // 防止 tilesX 或 tilesY 为 0 导致的除零错误
            if (tilesX <= 0 || tilesY <= 0)
            {
                if (force)
                    return new Rectangle(0, 0, Width, Height);
                return null;
            }

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

/// <summary>像素级替换(SpritesInDetail PixelReplacements):绘制源矩形左上角命中 (X, Y) 时,整张替换纹理绘制到目标区域。</summary>
public class PixelReplacementData
{
    public int X { get; set; }
    public int Y { get; set; }
    public Texture2D? Texture { get; set; }
}

public class ReplacedTexture : Texture2D
{
    public Texture2D OriginalTexture {get; set;}
    public Texture2D? NewTexture { get; set; }
        
    public ReplacedTexture(Texture2D originalTexture, Texture2D? newTexture) 
        : base(originalTexture.GraphicsDevice, originalTexture.Width, originalTexture.Height)
    {
        OriginalTexture = originalTexture;
        NewTexture = newTexture;
        CopyFromTexture(originalTexture);
    }
}