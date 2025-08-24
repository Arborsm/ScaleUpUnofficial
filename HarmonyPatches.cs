using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using StardewValley;
using System.Reflection;
using StardewValley.Menus;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public class HarmonyPatches
{
    private static readonly HashSet<string> NonScaledTextureNames = new();
    private static bool _spriteAlreadyDrawn;

    public static void PatchAll()
    {
        var harmonyInstance = new Harmony("Arborsm.ScaleUp");
        typeof(SpriteBatch)
            .GetMethods(BindingFlags.Public | BindingFlags.Instance)
            .Where(method => method.Name == "Draw")
            .Foreach(method =>
                harmonyInstance.Patch(method, prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawPrefix))));

        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getSourceRectForStandardTileSheet)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetSourceRectForStandardTileSheet)));
        harmonyInstance.Patch(
            AccessTools.Method(typeof(Game1), nameof(Game1.getSquareSourceRectForNonStandardTileSheet)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetSquareSourceRectForNonStandardTileSheet)));
        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getArbitrarySourceRect)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetArbitrarySourceRect)));
    }


    /// <summary>
    /// 一个通用的前缀补丁，用于拦截所有 SpriteBatch.Draw 的重载方法。
    /// </summary>
    /// <param name="__instance">SpriteBatch 实例。</param>
    /// <param name="__originalMethod">被拦截的原始方法信息。</param>
    /// <param name="__args">传递给原始方法的所有参数的数组。</param>
    /// <returns>返回 true 以执行原始方法，false 以跳过原始方法。</returns>
    public static bool DrawPrefix(SpriteBatch __instance, MethodBase __originalMethod, object[] __args)
    {
        var parameters = __originalMethod.GetParameters();
        var argsByName = new Dictionary<string, object>();
        for (var i = 0; i < parameters.Length; i++)
        {
            argsByName[parameters[i].Name ?? throw new InvalidOperationException()] = __args[i];
        }

        var texture = (Texture2D)argsByName["texture"];
        var color = (Color)argsByName["color"];
        var rotation = argsByName.TryGetValue("rotation", out var r) ? (float)r : 0f;
        var origin = argsByName.TryGetValue("origin", out var o) ? (Vector2)o : Vector2.Zero;
        var effects = argsByName.TryGetValue("effects", out var e) ? (SpriteEffects)e : SpriteEffects.None;
        var layerDepth = argsByName.TryGetValue("layerDepth", out var l) ? (float)l : 0f;
        var sourceRectangle = argsByName.TryGetValue("sourceRectangle", out var sr) ? (Rectangle?)sr : null;
        var scale = Vector2.One;
        if (argsByName.TryGetValue("scale", out var s))
        {
            scale = s is float floatScale ? new Vector2(floatScale, floatScale) : (Vector2)s;
        }

        Rectangle destinationRectangle;
        if (argsByName.TryGetValue("destinationRectangle", out var dr))
        {
            destinationRectangle = (Rectangle)dr;
        }
        else if (argsByName.TryGetValue("position", out var p))
        {
            var position = (Vector2)p;
            var width = sourceRectangle?.Width ?? texture.Width;
            var height = sourceRectangle?.Height ?? texture.Height;
            destinationRectangle = new Rectangle((int)position.X, (int)position.Y, (int)(width * scale.X),
                (int)(height * scale.Y));
        }
        else
        {
            return true;
        }

        return DrawLogicRouter(__instance, texture, destinationRectangle, 
            sourceRectangle, color, rotation, origin, scale, effects, layerDepth);
    }

    public static void ClearCache() => NonScaledTextureNames.Clear();

    /// <summary>尝试获取指定纹理的缩放数据。</summary>
    private static bool TryGetScaleData(string textureName, out ScaleUpData? data)
    {
        if (string.IsNullOrEmpty(textureName) || NonScaledTextureNames.Contains(textureName))
        {
            data = null;
            return false;
        }

        if (ScaleUpMod.ScalesByAsset.TryGetValue(textureName, out data) && data != null)
        {
            return true;
        }

        NonScaledTextureNames.Add(textureName);
        return false;
    }

    public static void GetSquareSourceRectForNonStandardTileSheet(ref Texture2D tileSheet, int tilePosition,
        ref int tileWidth, ref int tileHeight)
    {
        GetBounds(ref tileWidth, ref tileHeight, tilePosition, ref tileSheet);
    }


    public static void GetArbitrarySourceRect(ref Texture2D tileSheet, int tilePosition, ref int tileWidth,
        ref int tileHeight)
    {
        GetBounds(ref tileWidth, ref tileHeight, tilePosition, ref tileSheet);
    }

    public static void GetSourceRectForStandardTileSheet(ref Texture2D tileSheet, int tilePosition, ref int width,
        ref int height)
    {
        GetBounds(ref width, ref height, tilePosition, ref tileSheet);
    }

    [SuppressMessage("ReSharper", "UnusedParameter.Local")]
    private static void GetBounds(ref int width, ref int height, int tilePosition, ref Texture2D tileSheet)
    {
        ScaleUpMod.Scales ??=
            ScaleUpMod.Singleton.Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(ScaleUpMod.ScaleUpdDataAsset);

        if (tileSheet.Name is { } name)
        {
            if (NonScaledTextureNames.Contains(name)) return;
            if (TryGetScaleData(name, out var data) && data != null)
            {
                tileSheet = new Texture2D(Game1.graphics.GraphicsDevice, data.OrgWidth, data.OrgHeight);
            }
        }
    }

    /// <summary>这是所有 Draw 补丁的最终调用目标，包含了核心的逻辑切换。</summary>
    private static bool DrawLogicRouter(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects,
        float layerDepth)
    {
        if (_spriteAlreadyDrawn)
        {
            return true;
        }

        if (texture.Name == null || !TryGetScaleData(texture.Name, out var data) || data == null)
        {
            return true;
        }

        if (data.Sprite != null)
        {
            return DrawWithSpriteInDetail(__instance, texture, destination, 
                sourceRectangle, color, rotation, origin, scale, effects, layerDepth, data);
        }

        var ow = sourceRectangle?.Width ?? data.OrgWidth;
        var oh = sourceRectangle?.Height ?? data.OrgHeight;
        var newSource = data.GetScaledSource(sourceRectangle, ow, oh, out var padX, out var padY, true);

        var newScale = scale;
        newScale.X /= data.Scale;
        newScale.Y /= data.Scale;
        var newOrigin = origin * data.Scale;
        if (data.Padded)
        {
            newOrigin.X += padX / 2.0f;
            newOrigin.Y += padY;
        }

        _spriteAlreadyDrawn = true;
        __instance.Draw(texture, destination.Location.ToVector2(), newSource, color, rotation, newOrigin, newScale,
            effects, layerDepth);
        _spriteAlreadyDrawn = false;
        return false;
    }

    /// <summary>从 SpritesInDetail 移植和简化的精细渲染逻辑。</summary>
    private static bool DrawWithSpriteInDetail(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale,
        SpriteEffects effects, float layerDepth, ScaleUpData data)
    {
        Debug.Assert(data.Sprite != null, "data.Sprite != null");
        if (!sourceRectangle.HasValue)
        {
            return true;
        }
        
        const int sourceOrgWidth = 16 * 4;
        var r = sourceRectangle.Value;
        Rectangle updatedDestination;
        Rectangle updatedSource;
        Vector2 updatedOrigin;

        var isBreathingSprite = r is { Width: 8, Height: 8 or 4 };
        if (isBreathingSprite && data.Sprite.BreathType is not null and not BreathType.None)
        {
            var (srcX, srcY, srcW, srcH, adjX, adjY) = data.Sprite.BreathType switch
            {
                BreathType.Male => (
                    data.Sprite.ChestSourceX ?? 24, data.Sprite.ChestSourceY ?? 98,
                    data.Sprite.ChestSourceWidth ?? 16, data.Sprite.ChestSourceHeight ?? 16,
                    data.Sprite.ChestAdjustX ?? 0, data.Sprite.ChestAdjustY ?? 0
                ),
                BreathType.Female => (
                    data.Sprite.ChestSourceX ?? 24, data.Sprite.ChestSourceY ?? 100,
                    data.Sprite.ChestSourceWidth ?? 16, data.Sprite.ChestSourceHeight ?? 8,
                    data.Sprite.ChestAdjustX ?? 0, data.Sprite.ChestAdjustY ?? -4
                ),
                _ => default
            };

            updatedDestination = new Rectangle(
                destination.X + adjX,
                destination.Y + adjY,
                (int)(srcW * scale.X / 2),
                (int)(srcH * scale.Y / 2)
            );
            updatedSource = new Rectangle(
                16 * 4 * (r.X / 16) + srcX,
                32 * 4 * (r.Y / 32) + srcY,
                srcW,
                srcH
            );
            updatedOrigin = new Vector2(srcW / 2f, srcH / 2f + 1);
        }
        else if (isBreathingSprite)
        {
            return false;
        }
        else
        {
            const int itemSpriteWidth = 16;
            const int itemSpriteHeight = 24;
            if (r is { Width: itemSpriteWidth, Height: <32 })
            {
                if (r is { Width:16, Height:15 }) // NPC Map Locations
                {
                    scale = new Vector2(2);
                }
                var width = (int)(itemSpriteWidth * scale.X);
                var sourceX = data.Sprite.HeadShotX ?? 12;
                var sourceY = data.Sprite.HeadShotY ?? 58;
                var sourceWidth = sourceOrgWidth - 2 * sourceX;
                var sourceHeight = sourceWidth * 24 / 16;
                var xOff = (data.Sprite.HeadShotXRenderOffset ?? 0) + (int)(0.01302 * Math.Pow(sourceX, 3) - 0.34375 
                    * Math.Pow(sourceX, 2) +  5.16667 * sourceX - 15);
                var yOff = (data.Sprite.HeadShotYRenderOffset ?? 0) + (int)(0.0234375 * Math.Pow(sourceX, 3) - 0.778125 
                    * Math.Pow(sourceX, 2) + 12.6375 * sourceX - 36.7 - 3 * Math.Exp(-Math.Pow(sourceX - 12, 2) / 2));
                updatedDestination = new Rectangle(destination.X + xOff, destination.Y + yOff, width, width);
                var miniMapXOff = data.Sprite.MiniMapXOffset ?? 0;
                var miniMapYOff = data.Sprite.MiniMapYOffset ?? 0;
                updatedSource = new Rectangle(14 + miniMapXOff, 70 + miniMapYOff, width, width);
                updatedOrigin = new Vector2(16, 34);
                
                if (r is { Height: itemSpriteHeight, Width: itemSpriteWidth }) // half sprites
                {
                    var height = (int)(itemSpriteHeight * scale.Y);
                    updatedDestination.Height = height;
                    updatedSource = new Rectangle(sourceX, sourceY, sourceWidth, sourceHeight);
                    if (origin is { X: 8, Y: 12 })
                    {
                        updatedOrigin = new Vector2(32, 55);
                    }
                }
            }
            else if (r is { Width: itemSpriteWidth, Height: <32 })
            {
                var width = (int)(itemSpriteWidth * scale.X);
                var height = (int)(itemSpriteWidth * scale.Y);
                updatedDestination = new Rectangle(
                    destination.X,
                    destination.Y,
                    width,
                    height
                );
                updatedSource = new Rectangle(12, 58, width, height);
                updatedOrigin = new Vector2(16, 34);
            }
            else
            {
                const int charSpriteWidth = 32;
                const int charSpriteHeight = 64;

                var isProfileMenu = Game1.activeClickableMenu is ProfileMenu;
                var (xOff, yOff) = isProfileMenu ? (32, 112) : (0, 0);

                updatedDestination = new Rectangle(
                    destination.X + xOff,
                    destination.Y + yOff,
                    (int)(charSpriteWidth * scale.X),
                    (int)(charSpriteHeight * scale.Y)
                );
                updatedSource = data.GetScaledSource(sourceRectangle, charSpriteWidth / 2, charSpriteHeight / 2,
                                    out _, out _, false, true, isProfileMenu)
                                ?? new Rectangle(r.X * 4, r.Y * 4, r.Width * 4, r.Height * 4);
                updatedOrigin = new Vector2(data.Sprite.SpriteOriginX ?? 32, data.Sprite.SpriteOriginY ?? 112);
            }
        }

        _spriteAlreadyDrawn = true;
        __instance.Draw(texture, updatedDestination, updatedSource, color, rotation, updatedOrigin, effects,
            layerDepth);
        _spriteAlreadyDrawn = false;

        return false;
    }
}

internal static class ForeachExtension
{
    public static void Foreach<T>(this IEnumerable<T> source, Action<T> action)
    {
        foreach (var item in source)
        {
            action(item);
        }
    }
}