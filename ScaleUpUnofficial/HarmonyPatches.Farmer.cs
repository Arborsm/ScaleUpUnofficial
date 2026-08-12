using System.Diagnostics.CodeAnalysis;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;
using Netcode;
using StardewValley;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public partial class HarmonyPatches
{
    /// <summary>当前 FarmerRenderer.draw 调用中身体四格的左上角(原版坐标),无调用时为 null。</summary>
    private static Vector2? _farmerBodyAnchor;

    private static void FarmerDrawPrefix(FarmerSprite.AnimationFrame animationFrame, Vector2 position, Vector2 origin, Farmer who)
    {
        try
        {
            // 与 vanilla FarmerRenderer.draw 原样一致: xOffset/positionOffset 以 ×4 换算进内部屏幕空间
            // (贴图以 4f 放大绘制),属原版几何而非贴图倍率,任意 Scale 的农夫贴图都适用
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

    /// <summary>重建农夫 baseTexture 时保留资源名,让 SpriteBatch.Draw 补丁仍能按名字匹配 HD 纹理。</summary>
    [SuppressMessage("ReSharper", "InconsistentNaming")]
    private static bool FarmerTextureChanged(ref Texture2D? ___baseTexture, LocalizedContentManager ___farmerTextureManager, NetString ___textureName)
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

    /// <summary>农夫贴图倍率: 由总像素数相对原版 288x672 的比值开方得出(4x→4, 2x→2, 原版→1)。</summary>
    internal static int GetPixelIndexStride(int pixelCount)
    {
        const int vanillaPixelCount = 288 * 672;
        return pixelCount > vanillaPixelCount
            ? (int)Math.Round(Math.Sqrt(pixelCount / (double)vanillaPixelCount))
            : 1;
    }

    /// <summary>HD 农夫纹理的调色板参考像素索引按贴图倍率换算(移植自 SpritesInDetail,原版只认 4 倍)。</summary>
    private static bool GeneratePixelIndices(int source_color_index, string texture_name, Color[] pixels)
    {
        var stride = GetPixelIndexStride(pixels.Length);
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

        // SpriteWidth/SpriteHeight 目前是整数,精确比较即等价;容差防御未来浮点取值
        if (Math.Abs(k.X - 1f) < 0.001f && Math.Abs(k.Y - 1f) < 0.001f)
        {
            // 原版几何:源矩形与 origin 统一按分辨率倍率换算,屏幕尺寸与锚点不变
            return DrawWithReentryGuard(__instance, () => __instance.Draw(texture, destination, updatedSource, color,
                rotation, origin * resScale, effects, layerDepth));
        }

        // 放大渲染:每个绘制点绕锚点放大 k 倍;无锚点记录时(UI 绘制)退化为绕自身四格底边中心
        var vanillaTopleft = destination.Location.ToVector2() - origin * ratio;
        var center = _farmerBodyAnchor.HasValue
            ? _farmerBodyAnchor.Value + new Vector2(32, 128)
            : vanillaTopleft + new Vector2(destination.Width / 2f, destination.Height);
        var position = center + (destination.Location.ToVector2() - center) * k;
        var newScale = ratio * k / resScale;

        return DrawWithReentryGuard(__instance, () => __instance.Draw(texture, position, updatedSource, color, rotation,
            origin * resScale, newScale, effects, layerDepth));
    }

}
