using Microsoft.Xna.Framework;
using ScaleUpUnofficial;
using Xunit;

namespace ScaleUpUnofficial.Tests;

/// <summary>头图渲染偏移多项式(移植自 SpritesInDetail)。期望值按多项式手算,防止公式被无意改动。</summary>
public class HeadShotRenderOffsetTests
{
    [Fact]
    public void SocialPage_DefaultHeadShot_ProducesExpectedOffsets()
    {
        // 多项式在 headShotX=12: x = 19.9986→19, y = 40.4→40
        var (x, y, origin) = HarmonyPatches.HeadShotRenderOffset(12, 0, 0, 15, 36.7);
        Assert.Equal(19, x);
        Assert.Equal(40, y);
        Assert.Equal(new Vector2(16, 34), origin);
    }

    [Fact]
    public void CheatsMenu_ProducesExpectedOffsets()
    {
        // 常数项 23/50.7: x = 11.9986→11, y = 26.4→26
        var (x, y, origin) = HarmonyPatches.HeadShotRenderOffset(12, 0, 0, 23, 50.7);
        Assert.Equal(11, x);
        Assert.Equal(26, y);
        Assert.Equal(new Vector2(16, 34), origin);
    }

    [Fact]
    public void RenderOffsets_AreAdded()
    {
        // 叠加渲染偏移 5/-2: x = 19.9986+5→24, y = 40.4-2→38
        var (x, y, _) = HarmonyPatches.HeadShotRenderOffset(12, 5, -2, 15, 36.7);
        Assert.Equal(24, x);
        Assert.Equal(38, y);
    }

    [Fact]
    public void OtherHeadShotPosition_ProducesExpectedOffsets()
    {
        // headShotX=10: x = 15.3117→15, y = 34.894→34
        var (x, y, _) = HarmonyPatches.HeadShotRenderOffset(10, 0, 0, 15, 36.7);
        Assert.Equal(15, x);
        Assert.Equal(34, y);
    }
}
