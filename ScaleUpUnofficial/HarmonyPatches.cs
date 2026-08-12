using System.Diagnostics;
using System.Diagnostics.CodeAnalysis;
using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Netcode;
using StardewModdingAPI;
using StardewValley;
using StardewValley.Extensions;
using StardewValley.Menus;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public class HarmonyPatches
{
    public static readonly HashSet<string> NonScaledTextureNames = new();
    private static bool _spriteAlreadyDrawn;
    private static bool _init;
    private static readonly Lazy<bool> _isCJBInstalled = new(()=>ScaleUpMod.Instance!.Helper.ModRegistry.IsLoaded("CJBok.CheatsMenu"));
    private static bool isCJBInstalled => _isCJBInstalled.Value;
    private static readonly Queue<Action> _actions = new();

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
        
        harmonyInstance.Patch(AccessTools.Method(typeof(Game1), "Draw"),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(Draw)));
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

        // HD 农夫精灵支持:FarmerRenderer 会把农夫纹理复制成内部 baseTexture(名字丢失),
        // 且重着色像素索引按原版尺寸计算,两个补丁分别保留资源名与修正 HD 索引
        harmonyInstance.Patch(AccessTools.Method(typeof(FarmerRenderer), nameof(FarmerRenderer.textureChanged)),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(FarmerTextureChanged)));
        harmonyInstance.Patch(AccessTools.Method(typeof(FarmerRenderer), "_GeneratePixelIndices"),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(GeneratePixelIndices)));
        // 记录农夫身体锚点,供放大渲染时做锚点补偿
        harmonyInstance.Patch(
            AccessTools.Method(typeof(FarmerRenderer), nameof(FarmerRenderer.draw), new[]
            {
                typeof(SpriteBatch), typeof(FarmerSprite.AnimationFrame), typeof(int), typeof(Rectangle),
                typeof(Vector2), typeof(Vector2), typeof(float), typeof(int), typeof(Color),
                typeof(float), typeof(float), typeof(Farmer)
            }),
            prefix: new HarmonyMethod(typeof(HarmonyPatches), nameof(FarmerDrawPrefix)),
            finalizer: new HarmonyMethod(typeof(HarmonyPatches), nameof(FarmerDrawFinalizer)));
    }

    /// <summary>当前 FarmerRenderer.draw 调用中身体四格的左上角(原版坐标),无调用时为 null。</summary>
    private static Vector2? _farmerBodyAnchor;

    private static void FarmerDrawPrefix(FarmerSprite.AnimationFrame animationFrame, Vector2 position, Vector2 origin, Farmer who)
    {
        try
        {
            var bodyPosition = position + origin + new Vector2(animationFrame.xOffset * 4f, animationFrame.positionOffset * 4f);
            if (!FarmerRenderer.isDrawingForUI && who.swimming.Value)
            {
                bodyPosition.Y += 64f;
            }
            _farmerBodyAnchor = bodyPosition - origin * 4f;
        }
        catch (Exception e)
        {
            LogPatchErrorOnce(nameof(FarmerDrawPrefix), e);
        }
    }

    private static void FarmerDrawFinalizer()
    {
        _farmerBodyAnchor = null;
    }

    private static readonly HashSet<string> _patchErrorsLogged = new();

    private static void LogPatchErrorOnce(string where, Exception e)
    {
        if (_patchErrorsLogged.Add(where))
        {
            ScaleUpMod.Instance?.Monitor.Log($"[ScaleUp] patch error in {where} (falling back to vanilla): {e}", LogLevel.Error);
        }
    }

    /// <summary>重建农夫 baseTexture 时保留资源名,让 SpriteBatch.Draw 补丁仍能按名字匹配 HD 纹理。</summary>
    [SuppressMessage("ReSharper", "InconsistentNaming")]
    private static bool FarmerTextureChanged(ref Texture2D ___baseTexture, LocalizedContentManager ___farmerTextureManager, NetString ___textureName)
    {
        var assetName = ___textureName.Value.Replace('\\', '/');
        if (!TryGetScaleData(assetName, out var data) || data is not { IsFarmer: true })
            return true;

        if (___baseTexture != null)
        {
            ___baseTexture.Dispose();
            ___baseTexture = null;
        }
        var texture = ___farmerTextureManager.Load<Texture2D>(___textureName.Value);
        var newTexture = new Texture2D(Game1.graphics.GraphicsDevice, texture.Width, texture.Height)
        {
            Name = assetName
        };
        var pixels = new Color[texture.Width * texture.Height];
        texture.GetData(pixels, 0, pixels.Length);
        newTexture.SetData(pixels);
        ___baseTexture = newTexture;
        return false;
    }

    /// <summary>HD 农夫纹理(大于原版 288x672)的调色板槽位索引按 4 倍换算(移植自 SpritesInDetail)。</summary>
    private static bool GeneratePixelIndices(int source_color_index, string texture_name, Color[] pixels)
    {
        var stride = pixels.Length > 288 * 672 ? 4 : 1;
        var color = pixels[source_color_index * stride];
        var list = new List<int>();
        for (var i = 0; i < pixels.Length; i++)
        {
            if (pixels[i].PackedValue == color.PackedValue)
                list.Add(i);
        }
        FarmerRenderer.recolorOffsets[texture_name][source_color_index] = list;
        return false;
    }
    
    [SuppressMessage("ReSharper", "UnusedParameter.Local")]
    private static bool Draw(Game1 __instance, GameTime gameTime)
    {
        while (_actions.Count > 0) _actions.Dequeue().Invoke();
        return true;
    }
    
    public static void EnqueueAction(Action? action)
    {
        if(action == null) return;
        _actions.Enqueue(action);
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
        if (!_init && ScaleUpMod.Instance != null)
        {
            ScaleUpMod.Instance.InitMaps();
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

        if (data.IsFarmer)
        {
            try
            {
                return DrawFarmerSprite(__instance, texture, destination,
                    sourceRectangle, color, rotation, origin, effects, layerDepth, data);
            }
            catch (Exception e)
            {
                LogPatchErrorOnce(nameof(DrawFarmerSprite), e);
                return true;
            }
        }

        if (data.Sprite != null)
        {
            return DrawWithSpriteInDetail(__instance, texture, destination,
                sourceRectangle, color, rotation, origin, scale, effects, layerDepth, data);
        }

        if (texture.Name != null &&
            ScaleUpMod.PixelReplacementsByAsset.TryGetValue(texture.Name, out var pixelReplacements) &&
            pixelReplacements.Count > 0)
        {
            try
            {
                return DrawWithPixelReplacements(__instance, destination, sourceRectangle, color, rotation, origin,
                    effects, layerDepth, pixelReplacements);
            }
            catch (Exception e)
            {
                LogPatchErrorOnce(nameof(DrawWithPixelReplacements), e);
                return true;
            }
        }

        if (texture is ReplacedTexture replacedTexture)
        {
            texture = replacedTexture.NewTexture!;
        }

        var newScale = scale;
        newScale.X /= data.Scale;
        newScale.Y /= data.Scale;
        var ow = sourceRectangle?.Width ?? data.OrgWidth;
        var oh = sourceRectangle?.Height ?? data.OrgHeight;
        var newSource = data.GetScaledSource(sourceRectangle, ow, oh, out var padX, out var padY, true);
        if (newSource == null)
        {
            return true;
        }
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
    
    /// <summary>HD 农夫精灵绘制:源矩形按 Scale(纹理分辨率倍率)换算;SpriteWidth/SpriteHeight 决定屏幕渲染
    /// 尺寸(默认 16x32 即原版几何)。大于原版时,以 FarmerRenderer.draw 记录的身体锚点(底边中心)为放大中心
    /// 做补偿变换,使身体/眼睛/手臂/弹弓/配饰在任意倍率下保持对齐,旋转也围绕同一逻辑点。</summary>
    private static bool DrawFarmerSprite(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, SpriteEffects effects,
        float layerDepth, ScaleUpData data)
    {
        if (!sourceRectangle.HasValue)
        {
            return true;
        }

        if (texture is ReplacedTexture replacedTexture)
        {
            texture = replacedTexture.NewTexture!;
        }

        var r = sourceRectangle.Value;
        var resScale = data.Scale > 0 ? data.Scale : 4;
        var updatedSource = new Rectangle((int)(r.X * resScale), (int)(r.Y * resScale), (int)(r.Width * resScale), (int)(r.Height * resScale));
        var ratio = new Vector2((float)destination.Width / r.Width, (float)destination.Height / r.Height);
        var k = new Vector2((data.SpriteWidth ?? 16) / 16f, (data.SpriteHeight ?? 32) / 32f);

        if (k == Vector2.One)
        {
            // 原版几何:源矩形与 origin 统一按分辨率倍率换算,屏幕尺寸与锚点不变
            _spriteAlreadyDrawn = true;
            __instance.Draw(texture, destination, updatedSource, color, rotation, origin * resScale, effects, layerDepth);
            _spriteAlreadyDrawn = false;
            return false;
        }

        // 放大渲染:每个绘制点绕锚点放大 k 倍;无锚点记录时(UI 绘制)退化为绕自身四格底边中心
        var vanillaTopleft = destination.Location.ToVector2() - origin * ratio;
        var center = _farmerBodyAnchor.HasValue
            ? _farmerBodyAnchor.Value + new Vector2(32, 128)
            : vanillaTopleft + new Vector2(destination.Width / 2f, destination.Height);
        var position = center + (destination.Location.ToVector2() - center) * k;
        var newScale = ratio * k / resScale;

        _spriteAlreadyDrawn = true;
        __instance.Draw(texture, position, updatedSource, color, rotation, origin * resScale, newScale, effects, layerDepth);
        _spriteAlreadyDrawn = false;
        return false;
    }

    /// <summary>像素级替换绘制(移植自 SpritesInDetail):源矩形左上角命中替换点时,整张替换纹理绘制到目标区域。</summary>
    private static bool DrawWithPixelReplacements(SpriteBatch __instance, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, SpriteEffects effects,
        float layerDepth, List<PixelReplacementData> pixelReplacements)
    {
        if (!sourceRectangle.HasValue)
        {
            return true;
        }

        var r = sourceRectangle.Value;
        foreach (var pixelReplacement in pixelReplacements)
        {
            if (pixelReplacement.Texture == null || pixelReplacement.X != r.X || pixelReplacement.Y != r.Y)
            {
                continue;
            }

            var newOrigin = new Vector2(
                origin.X * pixelReplacement.Texture.Width / r.Width,
                origin.Y * pixelReplacement.Texture.Height / r.Height);

            _spriteAlreadyDrawn = true;
            __instance.Draw(pixelReplacement.Texture, destination, null, color, rotation, newOrigin, effects, layerDepth);
            _spriteAlreadyDrawn = false;
            return false;
        }

        return true;
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
            var isSmallSprite  = data.Sprite.IsSmallSprite is true;
            var isSwimmingSprite = r is { Width: 16, Height: 16 } && Game1.activeClickableMenu == null;
            if (r is { Width: itemSpriteWidth, Height: < 32 } && !isSmallSprite && !isSwimmingSprite)
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
                else if (Game1.activeClickableMenu != null && isCJBInstalled && Game1.activeClickableMenu.GetType().Name == "CheatsMenu")
                {
                    xOff = (data.Sprite.HeadShotXRenderOffset ?? 0) + (int)(0.01302 * Math.Pow(sourceX, 3) - 0.34375
                        * Math.Pow(sourceX, 2) + 5.16667 * sourceX - 23);
                    yOff = (data.Sprite.HeadShotYRenderOffset ?? 0) + (int)(0.0234375 * Math.Pow(sourceX, 3) - 0.778125
                        * Math.Pow(sourceX, 2) + 12.6375 * sourceX - 50.7 - 3 * Math.Exp(-Math.Pow(sourceX - 12, 2) / 2));
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
                var sourceHeight = r.Height;
                var targetHeight = sourceHeight * 2; 
                var isProfileMenu = Game1.activeClickableMenu is ProfileMenu;
                var (xOff, yOff) = isProfileMenu ? (32, 112) : (0, 0);

                updatedDestination = new Rectangle(
                    destination.X + xOff,
                    destination.Y + yOff,
                    (int)(charSpriteWidth * scale.X),
                    (int)(targetHeight * scale.Y)
                );

                // 部分动画（如钓鱼）给出的 X 坐标会超出原始贴图宽度，
                // 此时按行宽取模、保持行号不变；不能把溢出的 X 换算到下方行，
                // 否则会闪烁显示精灵表中钓鱼帧下方的其他行
                var sourceX = r.X;
                if (data.OrgWidth > 0)
                {
                    sourceX %= data.OrgWidth;
                }

                var calculatedSourceX = sourceX * 4;
                var calculatedSourceY = r.Y * 4;
                var calculatedSourceWidth = r.Width * 4;
                var calculatedSourceHeight = r.Height * 4;
                
                if (OperatingSystem.IsAndroid())
                {
                    WrapAndroidTextureBounds(ref calculatedSourceX, ref calculatedSourceY, calculatedSourceWidth, calculatedSourceHeight, texture);
                }
                
                updatedSource = new Rectangle(calculatedSourceX, calculatedSourceY, calculatedSourceWidth, calculatedSourceHeight);

                var finalOriginY = sourceHeight switch
                {
                    <= 16 => 96,
                    _ => data.Sprite.SpriteOriginY ?? (isSmallSprite ? 78 : 112)
                };

                updatedOrigin = new Vector2(data.Sprite.SpriteOriginX ?? 32, finalOriginY);
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