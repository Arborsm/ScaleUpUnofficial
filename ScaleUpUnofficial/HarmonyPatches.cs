using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using StardewValley;
using StardewValley.Menus;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public class HarmonyPatches
{
    private static readonly HashSet<string> NonScaledTextureNames = new();
    private static bool _spriteAlreadyDrawn;
    private static bool _init;

    public static void PatchAll()
    {
        var harmonyInstance = new Harmony(ScaleUpMod.ScaleUpName);
        var spriteBatchType = typeof(SpriteBatch);

        // Draw(Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth)
        harmonyInstance.Patch(
            AccessTools.Method(spriteBatchType, "Draw", new[]
            {
                typeof(Texture2D), typeof(Vector2), typeof(Rectangle?), typeof(Color),
                typeof(float), typeof(Vector2), typeof(Vector2), typeof(SpriteEffects), typeof(float)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawWithVector2Scale))
        );

        // Draw(Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, float scale, SpriteEffects effects, float layerDepth)
        harmonyInstance.Patch(
            AccessTools.Method(spriteBatchType, "Draw", new[]
            {
                typeof(Texture2D), typeof(Vector2), typeof(Rectangle?), typeof(Color),
                typeof(float), typeof(Vector2), typeof(float), typeof(SpriteEffects), typeof(float)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawWithFloatScale))
        );

        // Draw(Texture2D texture, Rectangle destinationRectangle, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, SpriteEffects effects, float layerDepth)
        harmonyInstance.Patch(
            AccessTools.Method(spriteBatchType, "Draw", new[]
            {
                typeof(Texture2D), typeof(Rectangle), typeof(Rectangle?), typeof(Color),
                typeof(float), typeof(Vector2), typeof(SpriteEffects), typeof(float)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawWithRectangle))
        );

        // Draw(Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color)
        harmonyInstance.Patch(
            AccessTools.Method(spriteBatchType, "Draw", new[]
            {
                typeof(Texture2D), typeof(Vector2), typeof(Rectangle?), typeof(Color)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawSimpleWithSource))
        );

        // Draw(Texture2D texture, Rectangle destinationRectangle, Rectangle? sourceRectangle, Color color)
        harmonyInstance.Patch(
            AccessTools.Method(spriteBatchType, "Draw", new[]
            {
                typeof(Texture2D), typeof(Rectangle), typeof(Rectangle?), typeof(Color)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawRectangleWithSource))
        );

        // Draw(Texture2D texture, Vector2 position, Color color)
        harmonyInstance.Patch(
            AccessTools.Method(spriteBatchType, "Draw", new[]
            {
                typeof(Texture2D), typeof(Vector2), typeof(Color)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawSimple))
        );

        // Draw(Texture2D texture, Rectangle destinationRectangle, Color color)
        harmonyInstance.Patch(
            AccessTools.Method(spriteBatchType, "Draw", new[]
            {
                typeof(Texture2D), typeof(Rectangle), typeof(Color)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(DrawRectangle))
        );
        
        harmonyInstance.Patch(AccessTools.PropertyGetter(typeof(AnimatedSprite), "textureWidth"),
            postfix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetTextureWidth)));
        harmonyInstance.Patch(AccessTools.PropertyGetter(typeof(AnimatedSprite), "textureHeight"),
            postfix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetTextureHeight)));
        
        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getSourceRectForStandardTileSheet)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetSourceRectForStandardTileSheet)));
        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getSquareSourceRectForNonStandardTileSheet)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetSquareSourceRectForNonStandardTileSheet)));
        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getArbitrarySourceRect)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetArbitrarySourceRect)));
    }
    
    private static void GetTextureWidth(AnimatedSprite __instance, ref int __result)
    {
        var texture = __instance.Texture;
        if (texture == null)
        {
            __result = 96;
        }
        else if (TryGetScaleData(texture.Name, out var data) && data != null)
        {
            __result /= 4;
        }
        else
        {
            __result = texture.Width;
        }
    }
    
    private static void GetTextureHeight(AnimatedSprite __instance, ref int __result)
    { 
        var texture = __instance.Texture;
        if (texture == null) 
        {
            __result = 128;
        }
        else if (TryGetScaleData(texture.Name, out var data) && data != null)
        {
            __result /= 4;
        }
        else
        {
            __result = texture.Height;
        }
    }
    
    public static bool DrawWithVector2Scale(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Rectangle? sourceRectangle,
        Color color,
        float rotation,
        Vector2 origin,
        Vector2 scale,
        SpriteEffects effects,
        float layerDepth)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var destination = new Rectangle((int)position.X, (int)position.Y,
            (int)((sourceRectangle?.Width ?? texture.Width) * scale.X),
            (int)((sourceRectangle?.Height ?? texture.Height) * scale.Y));

        return DrawLogicRouter(__instance, texture, destination,
            sourceRectangle, color, rotation, origin, scale, effects, layerDepth, data);
    }

    public static bool DrawWithFloatScale(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Rectangle? sourceRectangle,
        Color color,
        float rotation,
        Vector2 origin,
        float scale,
        SpriteEffects effects,
        float layerDepth)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var scaleVec = new Vector2(scale, scale);
        var destination = new Rectangle((int)position.X, (int)position.Y,
            (int)((sourceRectangle?.Width ?? texture.Width) * scale),
            (int)((sourceRectangle?.Height ?? texture.Height) * scale));

        return DrawLogicRouter(__instance, texture, destination,
            sourceRectangle, color, rotation, origin, scaleVec, effects, layerDepth, data);
    }

    public static bool DrawWithRectangle(
        SpriteBatch __instance,
        Texture2D texture,
        Rectangle destinationRectangle,
        Rectangle? sourceRectangle,
        Color color,
        float rotation,
        Vector2 origin,
        SpriteEffects effects,
        float layerDepth)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        return DrawLogicRouter(__instance, texture, destinationRectangle,
            sourceRectangle, color, rotation, origin, Vector2.One, effects, layerDepth, data);
    }

    public static bool DrawSimpleWithSource(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Rectangle? sourceRectangle,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var destination = new Rectangle((int)position.X, (int)position.Y,
            sourceRectangle?.Width ?? texture.Width,
            sourceRectangle?.Height ?? texture.Height);

        return DrawLogicRouter(__instance, texture, destination,
            sourceRectangle, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }

    public static bool DrawRectangleWithSource(
        SpriteBatch __instance,
        Texture2D texture,
        Rectangle destinationRectangle,
        Rectangle? sourceRectangle,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        return DrawLogicRouter(__instance, texture, destinationRectangle,
            sourceRectangle, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }

    public static bool DrawSimple(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var destination = new Rectangle((int)position.X, (int)position.Y,
            texture.Width, texture.Height);

        return DrawLogicRouter(__instance, texture, destination,
            null, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }

    public static bool DrawRectangle(
        SpriteBatch __instance,
        Texture2D texture,
        Rectangle destinationRectangle,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        return DrawLogicRouter(__instance, texture, destinationRectangle,
            null, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }

    private static bool ShouldProcessTexture(Texture2D? texture, [NotNullWhen(true)] out ScaleUpData? data)
    {
        data = null;
        return texture?.Name != null && TryGetScaleData(texture.Name, out data) && data != null;
    }

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
        data = null;
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
        if (!_init && ScaleUpMod.Singleton != null)
        {
            ScaleUpMod.Singleton.InitMaps();
            _init = true;
        }

        if (tileSheet.Name is { } name)
        {
            if (NonScaledTextureNames.Contains(name)) return;
            if (TryGetScaleData(name, out var data) && data != null)
            {
                tileSheet = new Texture2D(Game1.graphics.GraphicsDevice, data.OrgWidth, data.OrgHeight);
            }
        }
    }
    
    private static bool DrawLogicRouter(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects,
        float layerDepth, ScaleUpData data)
    {
        if (_spriteAlreadyDrawn)
        {
            return true;
        }

        if (data.Sprite != null)
        {
            return DrawWithSpriteInDetail(__instance, texture, destination,
                sourceRectangle, color, rotation, origin, scale, effects, layerDepth, data);
        }

        var newScale = scale;
        newScale.X /= data.Scale;
        newScale.Y /= data.Scale;
        var ow = sourceRectangle?.Width ?? data.OrgWidth;
        var oh = sourceRectangle?.Height ?? data.OrgHeight;
        var newSource = data.GetScaledSource(sourceRectangle, ow, oh, out var padX, out var padY, true);
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
        const int sourceOrgWidth = 16 * 4;
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

            var breathSourceX = 16 * 4 * (r.X / 16) + srcX;
            var breathSourceY = 32 * 4 * (r.Y / 32) + srcY;

            if (OperatingSystem.IsAndroid())
            {
                WrapAndroidTextureBounds(ref breathSourceX, ref breathSourceY, srcW, srcH, texture);
            }

            updatedSource = new Rectangle(breathSourceX, breathSourceY, srcW, srcH);
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
            if (r is { Width: itemSpriteWidth, Height: < 32 })
            {
                if (r is { Width: 16, Height: 15 }) // NPC Map Locations
                {
                    scale = new Vector2(2);
                }

                var width = (int)(itemSpriteWidth * scale.X);
                var sourceX = data.Sprite.HeadShotX ?? 12;
                var sourceY = data.Sprite.HeadShotY ?? 58;
                var sourceWidth = sourceOrgWidth - 2 * sourceX;
                var sourceHeight = sourceWidth * 24 / 16;
                int xOff = 0, yOff = 0;
                updatedOrigin = Vector2.Zero;
                if (Game1.activeClickableMenu is GameMenu gameMenu && gameMenu.GetCurrentPage() is SocialPage)
                {
                    xOff = (data.Sprite.HeadShotXRenderOffset ?? 0) + (int)(0.01302 * Math.Pow(sourceX, 3) - 0.34375
                        * Math.Pow(sourceX, 2) + 5.16667 * sourceX - 15);
                    yOff = (data.Sprite.HeadShotYRenderOffset ?? 0) + (int)(0.0234375 * Math.Pow(sourceX, 3) - 0.778125
                        * Math.Pow(sourceX, 2) + 12.6375 * sourceX - 36.7 - 3 * Math.Exp(-Math.Pow(sourceX - 12, 2) / 2));
                    updatedOrigin = new Vector2(16, 34);
                }

                updatedDestination = new Rectangle(destination.X + xOff, destination.Y + yOff, width, width);
                var miniMapXOff = data.Sprite.MiniMapXOffset ?? 0;
                var miniMapYOff = data.Sprite.MiniMapYOffset ?? 0;
                updatedSource = new Rectangle(14 + miniMapXOff, 70 + miniMapYOff, width, width);

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

                var calculatedSourceX = r.X * 4;
                var calculatedSourceY = r.Y * 4;
                var calculatedSourceWidth = r.Width * 4;
                var calculatedSourceHeight = r.Height * 4;
                
                if (OperatingSystem.IsAndroid())
                {
                    WrapAndroidTextureBounds(ref calculatedSourceX, ref calculatedSourceY, calculatedSourceWidth, calculatedSourceHeight, texture);
                }
                
                updatedSource = new Rectangle(calculatedSourceX, calculatedSourceY, calculatedSourceWidth, calculatedSourceHeight);
                updatedOrigin = new Vector2(data.Sprite.SpriteOriginX ?? 32, data.Sprite.SpriteOriginY ?? 112);
            }
        }

        _spriteAlreadyDrawn = true;
        __instance.Draw(texture, updatedDestination, updatedSource, color, rotation, updatedOrigin, effects, layerDepth);
        _spriteAlreadyDrawn = false;
        return false;
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