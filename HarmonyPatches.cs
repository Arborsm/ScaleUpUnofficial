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

    public static void PatchAll()
    {
        var harmonyInstance = new Harmony("Platonymous.ScaleUp");
            
        foreach (var method in AccessTools.GetDeclaredMethods(typeof(HarmonyPatches)).Where(m => m.Name.Contains("Draw")))
        {
            var types = method.GetParameters()
                .Select(p => p.ParameterType.IsByRef ? p.ParameterType.GetElementType() : p.ParameterType)
                .Where(t => t != null && !t.Name.Contains("SpriteBatch"))
                .ToArray();
            if (AccessTools.Method(typeof(SpriteBatch), nameof(SpriteBatch.Draw), types) is { } target)
                harmonyInstance.Patch(target, new HarmonyMethod(method));
        }

        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getSourceRectForStandardTileSheet)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetSourceRectForStandardTileSheet)));

        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getSquareSourceRectForNonStandardTileSheet)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetSquareSourceRectForNonStandardTileSheet)));

        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), nameof(Game1.getArbitrarySourceRect)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GetArbitrarySourceRect)));
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
        
    public static void GetSquareSourceRectForNonStandardTileSheet(ref Texture2D tileSheet, int tilePosition, ref int tileWidth, ref int tileHeight)
    {
        GetBounds(ref tileWidth, ref tileHeight, tilePosition, ref tileSheet);
    }


    public static void GetArbitrarySourceRect(ref Texture2D tileSheet, int tilePosition, ref int tileWidth, ref int tileHeight)
    {
        GetBounds(ref tileWidth, ref tileHeight, tilePosition, ref tileSheet);
    }

    public static void GetSourceRectForStandardTileSheet(ref Texture2D tileSheet, int tilePosition, ref int width, ref int height)
    {
        GetBounds(ref width, ref height, tilePosition, ref tileSheet);
    }

    public static void GetBounds(ref int width, ref int height, int tilePosition, ref Texture2D tileSheet)
    {
        ScaleUpMod.Scales ??= ScaleUpMod.Singleton.Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(ScaleUpMod.ScaleUpdDataAsset);

        if (tileSheet?.Name is { } name)
        {
            if (NonScaledTextureNames.Contains(name)) return;
            if (TryGetScaleData(name, out var data) && data != null)
            {
                tileSheet = new Texture2D(Game1.graphics.GraphicsDevice, data.OrgWidth, data.OrgHeight);
            }
        }
    }

    /// <summary>这是所有 Draw 补丁的最终调用目标，包含了核心的逻辑切换。</summary>
    private static bool DrawLogicRouter(SpriteBatch __instance, Texture2D texture, Rectangle destination, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth)
    {
        if (_spriteAlreadyDrawn) return true;

        if (texture?.Name == null || !TryGetScaleData(texture.Name, out var data) || data == null)
        {
            return true;
        }
            
        if (data.UseSpriteInDetail)
        {
            return DrawWithSpriteInDetail(__instance, texture, destination, sourceRectangle, color, rotation, origin, scale, effects, layerDepth, data);
        }
        else
        {
            var ow = sourceRectangle?.Width ?? data.OrgWidth;
            var oh = sourceRectangle?.Height ?? data.OrgHeight;
            var newSource = data.GetScaledSource(sourceRectangle, ow, oh, out int padX, out int padY, true);
                
            var newScale = scale;
            newScale.X /= data.Scale;
            newScale.Y /= data.Scale;
            var newOrigin = origin * data.Scale;
            if (data.Padded) { newOrigin.X += padX / 2.0f; newOrigin.Y += padY; }
                
            _spriteAlreadyDrawn = true;
            __instance.Draw(texture, destination.Location.ToVector2(), newSource, color, rotation, newOrigin, newScale, effects, layerDepth);
            _spriteAlreadyDrawn = false;
            return false;
        }
    }

    /// <summary>从 SpritesInDetail 移植和简化的精细渲染逻辑。</summary>
    private static bool DrawWithSpriteInDetail(SpriteBatch __instance, Texture2D texture, Rectangle destination, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth, ScaleUpData data)
    {
        if (!sourceRectangle.HasValue) return true;

        Rectangle r = new Rectangle(sourceRectangle.Value.X, sourceRectangle.Value.Y, 
            sourceRectangle.Value.Width, sourceRectangle.Value.Height);
        Rectangle updatedDestination;
        Rectangle updatedSource;
        Vector2 updatedOrigin;

        // 检查是否是呼吸动画的贴图 (通常是 8x8 或 8x4)
        bool isBreathingSprite = r is { Width: 8, Height: 8 or 4 };

        if (isBreathingSprite && data.BreathType.HasValue && data.BreathType != BreathType.None)
        {
            int chestSourceX = 0;
            int chestSourceY = 0;
            int chestSourceWidth = 0;
            int chestSourceHeight = 0;
            int chestAdjustX = 0;
            var chestAdjustY = 0;
            if (data.BreathType == BreathType.Male)
            {
                chestSourceX = data.ChestSourceX ?? 24;
                chestSourceY = data.ChestSourceY ?? 98;
                chestSourceWidth = data.ChestSourceWidth ?? 16;
                chestSourceHeight = data.ChestSourceHeight ?? 16;
                chestAdjustX = data.ChestAdjustX ?? 0;
                chestAdjustY = data.ChestAdjustY ?? 0;
            } else if (data.BreathType == BreathType.Female)
            {
                chestSourceX = data.ChestSourceX ?? 24;
                chestSourceY = data.ChestSourceY ?? 100;
                chestSourceWidth = data.ChestSourceWidth ?? 16;
                chestSourceHeight = data.ChestSourceHeight ?? 8;
                chestAdjustX = data.ChestAdjustX ?? 0;
                chestAdjustY = data.ChestAdjustY ?? -4;
            }

            updatedDestination = new Rectangle(destination.X + chestAdjustX, destination.Y + chestAdjustY, (int)(chestSourceWidth * scale.X / 2), (int)(chestSourceHeight * scale.Y / 2));
            updatedSource = new Rectangle(16 * 4 * (r.X / 16) + chestSourceX, 32 * 4 * (r.Y / 32) + chestSourceY, chestSourceWidth, chestSourceHeight);
            updatedOrigin = new Vector2(chestSourceWidth / 2f, chestSourceHeight / 2f + 1);
        }
        else if (isBreathingSprite)
        {
            return false;
        }
        else
        {
            int spriteWidth = 32;
            int spriteHeight = 64;
                
            updatedDestination = new Rectangle(destination.X, destination.Y, (int)(spriteWidth * scale.X), (int)(spriteHeight * scale.Y));
            updatedSource = data.GetScaledSource(sourceRectangle, spriteWidth / 2, spriteHeight / 2, out _, out _) ?? new Rectangle(r.X * 4, r.Y * 4, r.Width * 4, r.Height * 4);
            updatedOrigin = new Vector2(data.SpriteOriginX ?? 32, data.SpriteOriginY ?? 112);

            if (Game1.activeClickableMenu is ProfileMenu)
            {
                updatedDestination = new Rectangle(destination.X + 32, destination.Y, (int)(spriteWidth * scale.X), (int)(spriteHeight * scale.Y));
            }
                
            if (r is { Height: 24, Width: 16 })
            {
                updatedDestination = new Rectangle(destination.X, destination.Y, (int)(spriteWidth/2f * scale.X), (int)(spriteHeight/2f * scale.Y));
                updatedSource = new Rectangle(0, 0, 16 * 4, 24 * 4);
                updatedOrigin = origin is { X: 8, Y: 12 } ? new Vector2(32, 55) : new Vector2(16, 34);
            }
        }

        _spriteAlreadyDrawn = true;
        __instance.Draw(texture, updatedDestination, updatedSource, color, rotation, updatedOrigin, effects, layerDepth);
        _spriteAlreadyDrawn = false;
        return false;
    }
        
    public static bool Draw(SpriteBatch __instance, Texture2D texture, Rectangle destinationRectangle, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, SpriteEffects effects, float layerDepth)
        => DrawLogicRouter(__instance, texture, destinationRectangle, sourceRectangle, color, rotation, origin, Vector2.One, effects, layerDepth);

    public static bool Draw(SpriteBatch __instance, Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects, float layerDepth)
    {
        var r = sourceRectangle ?? new Rectangle(0, 0, texture.Width, texture.Height);
        var dest = new Rectangle((int)position.X, (int)position.Y, (int)(r.Width * scale.X), (int)(r.Height * scale.Y));
        return DrawLogicRouter(__instance, texture, dest, r, color, rotation, origin, scale, effects, layerDepth);
    }

    public static bool Draw(SpriteBatch __instance, Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, float scale, SpriteEffects effects, float layerDepth)
        => Draw(__instance, texture, position, sourceRectangle, color, rotation, origin, new Vector2(scale, scale), effects, layerDepth);
        
    public static bool Draw(SpriteBatch __instance, Texture2D texture, Rectangle destinationRectangle, Rectangle? sourceRectangle, Color color)
        => Draw(__instance, texture, destinationRectangle, sourceRectangle, color, 0f, Vector2.Zero, SpriteEffects.None, 0f);

    public static bool Draw(SpriteBatch __instance, Texture2D texture, Rectangle destinationRectangle, Color color)
        => Draw(__instance, texture, destinationRectangle, new Rectangle(0,0,texture.Width, texture.Height), color);

    public static bool Draw(SpriteBatch __instance, Texture2D texture, Vector2 position, Rectangle? sourceRectangle, Color color)
    {
        var r = sourceRectangle ?? new Rectangle(0, 0, texture.Width, texture.Height);
        var dest = new Rectangle((int)position.X, (int)position.Y, r.Width, r.Height);
        return DrawLogicRouter(__instance, texture, dest, r, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f);
    }
        
    public static bool Draw(SpriteBatch __instance, Texture2D texture, Vector2 position, Color color)
        => Draw(__instance, texture, position, null, color);
}