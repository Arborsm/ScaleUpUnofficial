using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using StardewValley;
using StardewValley.Menus;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public partial class HarmonyPatches
{
    // SpritesInDetail 移植常量: 16x32 瓦片在 HD 纹理上的帧尺寸(4 倍)与固定渲染尺寸
    private const int HdScale = 4;
    private const int SpriteFrameWidth = 16 * HdScale;   // 64
    private const int SpriteFrameHeight = 32 * HdScale;  // 128
    private const int ItemSpriteWidth = 16;
    private const int ItemSpriteHeight = 24;
    private const int CharacterSpriteWidth = 32;
    private static readonly Vector2 HeadShotOrigin = new(16, 34);
    private static readonly Vector2 HalfSpriteOrigin = new(32, 55);

    /// <summary>头图渲染偏移(移植自 SpritesInDetail): 三次多项式仅常数项因菜单而异。</summary>
    internal static (int x, int y, Vector2 origin) HeadShotRenderOffset(int headShotX, int renderX, int renderY,
        double xConst, double yConst)
    {
        var xOff = renderX + (int)(0.01302 * Math.Pow(headShotX, 3) - 0.34375
            * Math.Pow(headShotX, 2) + 5.16667 * headShotX - xConst);
        var yOff = renderY + (int)(0.0234375 * Math.Pow(headShotX, 3) - 0.778125
            * Math.Pow(headShotX, 2) + 12.6375 * headShotX - yConst - 3 * Math.Exp(-Math.Pow(headShotX - 12, 2) / 2));
        return (xOff, yOff, HeadShotOrigin);
    }

    /// <summary>SpritesInDetail 精灵绘制调度: 呼吸帧 / 头图(16 宽小精灵) / 角色帧(32 宽)三分支。</summary>
    private static bool DrawWithSpriteInDetail(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale,
        SpriteEffects effects, float layerDepth, ScaleUpData data)
    {
        Debug.Assert(data.Sprite != null, "data.Sprite != null");
        if (!sourceRectangle.HasValue)
        {
            return true;
        }

        var r = sourceRectangle.Value;
        var sprite = data.Sprite;
        return r is { Width: 8, Height: 8 or 4 }
            ? DrawBreathingSprite(__instance, texture, destination, r, color, rotation, origin, scale, effects, layerDepth, sprite)
            : DrawHeadShotOrCharacterSprite(__instance, texture, destination, r, color, rotation, origin, scale, effects, layerDepth, sprite, data);
    }

    /// <summary>呼吸动画帧(8x8/8x4): 从胸部区域裁一块小图做上下浮动。</summary>
    private static bool DrawBreathingSprite(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle source, Color color, float rotation, Vector2 origin, Vector2 scale,
        SpriteEffects effects, float layerDepth, ScaleUpData.SpriteData sprite)
    {
        if (sprite.BreathType is null or BreathType.None)
        {
            return false;
        }

        var (srcX, srcY, srcW, srcH, adjX, adjY) = sprite.BreathType switch
        {
            BreathType.Male => (
                sprite.ChestSourceX ?? 24, sprite.ChestSourceY ?? 98,
                sprite.ChestSourceWidth ?? 16, sprite.ChestSourceHeight ?? 16,
                sprite.ChestAdjustX ?? 0, sprite.ChestAdjustY ?? 0
            ),
            BreathType.Female => (
                sprite.ChestSourceX ?? 24, sprite.ChestSourceY ?? 100,
                sprite.ChestSourceWidth ?? 16, sprite.ChestSourceHeight ?? 8,
                sprite.ChestAdjustX ?? 0, sprite.ChestAdjustY ?? -4
            ),
            _ => default
        };

        var updatedDestination = new Rectangle(
            destination.X + adjX,
            destination.Y + adjY,
            (int)(srcW * scale.X / 2),
            (int)(srcH * scale.Y / 2)
        );

        var breathSourceX = SpriteFrameWidth * (source.X / 16) + srcX;
        var breathSourceY = SpriteFrameHeight * (source.Y / 32) + srcY;

        if (OperatingSystem.IsAndroid())
        {
            WrapAndroidTextureBounds(ref breathSourceX, ref breathSourceY, srcW, srcH, texture);
        }

        var updatedSource = new Rectangle(breathSourceX, breathSourceY, srcW, srcH);
        var updatedOrigin = new Vector2(srcW / 2f, srcH / 2f + 1);
        return DrawWithReentryGuard(__instance, () => __instance.Draw(texture, updatedDestination, updatedSource, color,
            rotation, updatedOrigin, effects, layerDepth));
    }

    /// <summary>头图(16 宽, 高 &lt; 32)与角色帧(其余)的分派。</summary>
    private static bool DrawHeadShotOrCharacterSprite(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle source, Color color, float rotation, Vector2 origin, Vector2 scale,
        SpriteEffects effects, float layerDepth, ScaleUpData.SpriteData sprite, ScaleUpData data)
    {
        var isSmallSprite = sprite.IsSmallSprite is true;
        var isSwimmingSprite = source is { Width: 16, Height: 16 } && Game1.activeClickableMenu == null;
        if (source is { Width: ItemSpriteWidth, Height: < 32 } && !isSmallSprite && !isSwimmingSprite)
        {
            return DrawHeadShotSprite(__instance, texture, destination, source, color, rotation, origin, scale, effects, layerDepth, sprite);
        }

        return DrawCharacterSprite(__instance, texture, destination, source, color, rotation, origin, scale, effects, layerDepth, sprite, data);
    }

    /// <summary>头图/小精灵(社交页头像、迷你地图、CJB 菜单、半身精灵)。</summary>
    private static bool DrawHeadShotSprite(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle source, Color color, float rotation, Vector2 origin, Vector2 scale,
        SpriteEffects effects, float layerDepth, ScaleUpData.SpriteData sprite)
    {
        if (source is { Width: 16, Height: 15 }) // NPC Map Locations
        {
            scale = new Vector2(2);
        }

        var width = (int)(ItemSpriteWidth * scale.X);
        var headShotX = sprite.HeadShotX ?? 12;
        var headShotY = sprite.HeadShotY ?? 58;
        var sourceWidth = SpriteFrameWidth - 2 * headShotX;
        var sourceHeight = sourceWidth * ItemSpriteHeight / 16;
        int xOff = 0, yOff = 0;
        var updatedOrigin = Vector2.Zero;
        if (Game1.activeClickableMenu is GameMenu gameMenu && gameMenu.GetCurrentPage() is SocialPage)
        {
            (xOff, yOff, updatedOrigin) = HeadShotRenderOffset(headShotX,
                sprite.HeadShotXRenderOffset ?? 0, sprite.HeadShotYRenderOffset ?? 0, 15, 36.7);
        }
        else if (Game1.activeClickableMenu != null && isCJBInstalled && Game1.activeClickableMenu.GetType().Name == "CheatsMenu")
        {
            (xOff, yOff, updatedOrigin) = HeadShotRenderOffset(headShotX,
                sprite.HeadShotXRenderOffset ?? 0, sprite.HeadShotYRenderOffset ?? 0, 23, 50.7);
        }

        var updatedDestination = new Rectangle(destination.X + xOff, destination.Y + yOff, width, width);
        var miniMapXOff = sprite.MiniMapXOffset ?? 0;
        var miniMapYOff = sprite.MiniMapYOffset ?? 0;
        var updatedSource = new Rectangle(14 + miniMapXOff, 70 + miniMapYOff, width, width);

        if (source is { Height: ItemSpriteHeight, Width: ItemSpriteWidth }) // half sprites
        {
            var height = (int)(ItemSpriteHeight * scale.Y);
            updatedDestination.Height = height;
            updatedSource = new Rectangle(headShotX, headShotY, sourceWidth, sourceHeight);
            if (origin is { X: 8, Y: 12 })
            {
                updatedOrigin = HalfSpriteOrigin;
            }
        }

        return DrawWithReentryGuard(__instance, () => __instance.Draw(texture, updatedDestination, updatedSource, color,
            rotation, updatedOrigin, effects, layerDepth));
    }

    /// <summary>角色帧(32 宽): 含钓鱼溢出 X 取模与 Android 纹理越界包裹。</summary>
    private static bool DrawCharacterSprite(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle source, Color color, float rotation, Vector2 origin, Vector2 scale,
        SpriteEffects effects, float layerDepth, ScaleUpData.SpriteData sprite, ScaleUpData data)
    {
        var sourceHeight = source.Height;
        var targetHeight = sourceHeight * 2;
        var isProfileMenu = Game1.activeClickableMenu is ProfileMenu;
        var (xOff, yOff) = isProfileMenu ? (32, 112) : (0, 0);

        var updatedDestination = new Rectangle(
            destination.X + xOff,
            destination.Y + yOff,
            (int)(CharacterSpriteWidth * scale.X),
            (int)(targetHeight * scale.Y)
        );

        // 部分动画（如钓鱼）给出的 X 坐标会超出原始贴图宽度，
        // 此时按行宽取模、保持行号不变；不能把溢出的 X 换算到下方行，
        // 否则会闪烁显示精灵表中钓鱼帧下方的其他行
        var sourceX = source.X;
        if (data.OrgWidth > 0)
        {
            sourceX %= data.OrgWidth;
        }

        var calculatedSourceX = sourceX * HdScale;
        var calculatedSourceY = source.Y * HdScale;
        var calculatedSourceWidth = source.Width * HdScale;
        var calculatedSourceHeight = source.Height * HdScale;

        if (OperatingSystem.IsAndroid())
        {
            WrapAndroidTextureBounds(ref calculatedSourceX, ref calculatedSourceY, calculatedSourceWidth, calculatedSourceHeight, texture);
        }

        var updatedSource = new Rectangle(calculatedSourceX, calculatedSourceY, calculatedSourceWidth, calculatedSourceHeight);

        var finalOriginY = sourceHeight switch
        {
            <= 16 => 96,
            _ => sprite.SpriteOriginY ?? (sprite.IsSmallSprite is true ? 78 : 112)
        };

        var updatedOrigin = new Vector2(sprite.SpriteOriginX ?? 32, finalOriginY);
        return DrawWithReentryGuard(__instance, () => __instance.Draw(texture, updatedDestination, updatedSource, color,
            rotation, updatedOrigin, effects, layerDepth));
    }

    private static void WrapAndroidTextureBounds(ref int sourceX, ref int sourceY, int sourceWidth, int sourceHeight, Texture2D texture)
    {
        var actualWidth = texture.Width;
        var actualHeight = texture.Height;

        try
        {
            var actualWidthProp = texture.GetType().GetProperty("ActualWidth");
            var actualHeightProp = texture.GetType().GetProperty("ActualHeight");
            if (actualWidthProp != null && actualHeightProp != null)
            {
                var actualW = (int)(actualWidthProp.GetValue(texture) ?? throw new InvalidOperationException());
                var actualH = (int)(actualHeightProp.GetValue(texture) ?? throw new InvalidOperationException());
                if (actualW > 0 && actualH > 0)
                {
                    actualWidth = actualW;
                    actualHeight = actualH;
                }
            }
        }
        catch (Exception)
        {
            // ignored
        }

        var tilesX = actualWidth / sourceWidth;
        var tilesY = actualHeight / sourceHeight;

        if (tilesX > 0 && sourceX >= actualWidth)
        {
            var tileIndex = sourceX / sourceWidth;
            sourceX = tileIndex % tilesX * sourceWidth;
        }

        if (tilesY > 0 && sourceY >= actualHeight)
        {
            var tileIndex = sourceY / sourceHeight;
            sourceY = tileIndex % tilesY * sourceHeight;
        }

        if (sourceX < 0) sourceX = 0;
        if (sourceY < 0) sourceY = 0;
    }
}
