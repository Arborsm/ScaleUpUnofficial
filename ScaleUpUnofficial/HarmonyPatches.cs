using System.Diagnostics.CodeAnalysis;
using HarmonyLib;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using StardewModdingAPI;
using StardewValley;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public partial class HarmonyPatches
{
    // 线程假设: 以下静态渲染状态仅在 XNA 渲染线程内访问(游戏绘制单线程),无需同步。
    public static readonly HashSet<string> NonScaledTextureNames = new();
    private static bool _spriteAlreadyDrawn;
    private static bool _init;
    private static readonly Lazy<bool> _isCJBInstalled = new(()=>ScaleUpMod.Instance!.Helper.ModRegistry.IsLoaded("CJBok.CheatsMenu"));
    private static bool isCJBInstalled => _isCJBInstalled.Value;
    private static readonly Queue<Action> _actions = new();
    /// <summary>队列上限: 防止游戏长时间不绘制时 action 无限堆积。</summary>
    private const int MaxQueuedActions = 256;
    private static bool _actionQueueFullLogged;


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

    private static readonly HashSet<string> _patchErrorsLogged = new();

    private static void LogPatchErrorOnce(string where, Exception e)
    {
        if (_patchErrorsLogged.Add(where))
        {
            ScaleUpMod.Instance?.Monitor.Log($"[ScaleUp] patch error in {where} (falling back to vanilla): {e}", LogLevel.Error);
        }
    }

    [SuppressMessage("ReSharper", "UnusedParameter.Local")]
    private static bool Draw(Game1 __instance, GameTime gameTime)
    {
        // 单个 action 抛异常时继续执行其余 action,不能炸掉整帧绘制
        while (_actions.Count > 0)
        {
            var action = _actions.Dequeue();
            try
            {
                action.Invoke();
            }
            catch (Exception e)
            {
                LogPatchErrorOnce("enqueued action", e);
            }
        }
        return true;
    }
    
    public static void EnqueueAction(Action? action)
    {
        if (action == null) return;
        if (_actions.Count >= MaxQueuedActions)
        {
            if (!_actionQueueFullLogged)
            {
                _actionQueueFullLogged = true;
                ScaleUpMod.Instance?.Monitor.Log("[ScaleUp] action queue is full, dropping queued actions", LogLevel.Warn);
            }
            return;
        }
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
            __result = (int)(__result / GetTextureScaleMultiplier(data));
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
            __result = (int)(__result / GetTextureScaleMultiplier(data));
        }
        else
        {
            __result = texture.Height;
        }
    }

    /// <summary>纹理分辨率倍率: Sprite(SpritesInDetail 规格)固定 4,其余按 Scale(与 ScaleUpData.OrgWidth 换算一致)。</summary>
    internal static float GetTextureScaleMultiplier(ScaleUpData data)
    {
        return data.Sprite != null ? 4 : (data.Scale > 0 ? data.Scale : 4);
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

    /// <summary>按 (原宽,原高) 缓存占位纹理,避免热路径上每次调用都分配 GPU 纹理(该占位纹理只被读取宽高,永不绘制)。</summary>
    private static readonly Dictionary<(int OrgWidth, int OrgHeight), Texture2D> _orgSizeTextureCache = new();

    /// <summary>随 DayStarted 清理占位纹理缓存(与 NonScaledTextureNames 同生命周期)。</summary>
    internal static void ClearOrgSizeTextureCache()
    {
        _orgSizeTextureCache.Clear();
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
                var orgSize = (data.OrgWidth, data.OrgHeight);
                if (!_orgSizeTextureCache.TryGetValue(orgSize, out var dummy))
                {
                    dummy = new Texture2D(Game1.graphics.GraphicsDevice, orgSize.OrgWidth, orgSize.OrgHeight);
                    _orgSizeTextureCache[orgSize] = dummy;
                }
                tileSheet = dummy;
            }
        }
    }
    
    /// <summary>以重入保护执行内部 Draw:即使绘制抛异常也会复位标记,避免补丁链静默失效。</summary>
    private static bool DrawWithReentryGuard(SpriteBatch spriteBatch, Action draw)
    {
        _spriteAlreadyDrawn = true;
        try
        {
            draw();
        }
        finally
        {
            _spriteAlreadyDrawn = false;
        }
        return false;
    }

    private static bool DrawLogicRouter(SpriteBatch __instance, Texture2D texture, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, Vector2 scale, SpriteEffects effects,
        float layerDepth, ScaleUpData data)
    {
        if (_spriteAlreadyDrawn)
        {
            return true;
        }

        // 农夫本体(IsFarmer)与可选跟随放大的配饰(设了 SpriteWidth/SpriteHeight)共用同一套
        // 绕身体锚点放大的渲染; 配饰不设这些字段时保持原版 1x 渲染, 与 1x 身体自动对齐
        if (data.IsFarmer || data.SpriteWidth != null || data.SpriteHeight != null)
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
        try
        {
            __instance.Draw(texture, destination.Location.ToVector2(), newSource, color, rotation, newOrigin, newScale,
                effects, layerDepth);
        }
        finally
        {
            _spriteAlreadyDrawn = false;
        }
        return false;
    }
    
    /// <summary>HD 农夫精灵绘制:源矩形按 Scale(纹理分辨率倍率)换算;SpriteWidth/SpriteHeight 决定帧的渲染画布
    /// 尺寸(默认 16x32 即原版几何)。设为 32x64 时画布绕身体锚点(底边中心)放大 2 倍,身体按画师画在帧内
    /// 的比例显示(1x 画法 = 原版屏幕大小 + 周围拓展空间),旋转也围绕同一逻辑点。</summary>
}
