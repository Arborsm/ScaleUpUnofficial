using Microsoft.Xna.Framework;
using ScaleUpUnofficial;
using Xunit;

namespace ScaleUpUnofficial.Tests;

/// <summary>ScaleUpData.GetScaledSource 瓦片换算: 行/列映射、循环取模、padding、force 分支。
/// 通过 internal 的 Width/Height setter 直接给出尺寸,避免加载游戏资源。</summary>
public class GetScaledSourceTests
{
    private static ScaleUpData Data(int width, int height, float scale, int padW = 0, int padH = 0)
    {
        var data = new ScaleUpData { Scale = scale, PaddingWidth = padW, PaddingHeight = padH };
        data.Width = width;
        data.Height = height;
        return data;
    }

    [Fact]
    public void VanillaTile_MapsToSamePosition()
    {
        // 原版 288x672: 18 列 x 21 行,源矩形 (16,32,16,32) → 瓦片 19 → 第 1 行第 1 列
        var data = Data(288, 672, 1);
        var result = data.GetScaledSource(new Rectangle(16, 32, 16, 32), 16, 32, out var padx, out var pady);
        Assert.Equal(new Rectangle(16, 32, 16, 32), result);
        Assert.Equal(0, padx);
        Assert.Equal(0, pady);
    }

    [Fact]
    public void TilePosition_MapsAcrossRows()
    {
        // 源 (32,64,16,32) → x=2, y=2 → 瓦片 38 → 第 2 行第 2 列
        var data = Data(288, 672, 1);
        var result = data.GetScaledSource(new Rectangle(32, 64, 16, 32), 16, 32, out _, out _);
        Assert.Equal(new Rectangle(32, 64, 16, 32), result);
    }

    [Fact]
    public void DefaultCycle_WrapsOverflowXWithinRow()
    {
        // 默认 cycle=false: X=320 → x=20 % 18 = 2 → 第 0 行第 2 列
        var data = Data(288, 672, 1);
        var result = data.GetScaledSource(new Rectangle(320, 0, 16, 32), 16, 32, out _, out _);
        Assert.Equal(new Rectangle(32, 0, 16, 32), result);
    }

    [Fact]
    public void CycleTrue_KeepsOverflowXForRowCalculation()
    {
        // cycle=true(钓鱼动画): X=320 → x=20 不取模 → 瓦片 20 → 第 1 行第 2 列
        var data = Data(288, 672, 1);
        var result = data.GetScaledSource(new Rectangle(320, 0, 16, 32), 16, 32, out _, out _, cycle: true);
        Assert.Equal(new Rectangle(32, 32, 16, 32), result);
    }

    [Fact]
    public void FourXWithPadding_MapsScaledTile()
    {
        // 4x + 左右共 16px / 上下共 8px 内边距: 宽 1168, 高 2696
        // padx = 16/18 = 0, pady = 8/21 = 0, 瓦片 0 → (0,0,64,128)
        var data = Data(288 * 4 + 16, 672 * 4 + 8, 4, 16, 8);
        var result = data.GetScaledSource(new Rectangle(0, 0, 16, 32), 16, 32, out var padx, out var pady);
        Assert.Equal(0, padx);
        Assert.Equal(0, pady);
        Assert.Equal(new Rectangle(0, 0, 64, 128), result);
    }

    [Fact]
    public void ForceNullSource_ReturnsFullTexture()
    {
        var data = Data(1152, 2688, 4);
        var result = data.GetScaledSource(null, 0, 0, out _, out _, force: true);
        Assert.Equal(new Rectangle(0, 0, 1152, 2688), result);
    }

    [Fact]
    public void NullSource_WithoutForce_ReturnsNull()
    {
        var data = Data(288, 672, 1);
        Assert.Null(data.GetScaledSource(null, 0, 0, out _, out _));
    }

    [Fact]
    public void ZeroOriginalSize_ReturnsNullOrFull()
    {
        var data = Data(288, 672, 1);
        var badSource = new Rectangle(0, 0, 0, 32);
        Assert.Null(data.GetScaledSource(badSource, 0, 32, out _, out _));
        Assert.Equal(new Rectangle(0, 0, 288, 672),
            data.GetScaledSource(badSource, 0, 32, out _, out _, force: true));
    }
}
