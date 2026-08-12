using ScaleUpUnofficial;
using Xunit;

namespace ScaleUpUnofficial.Tests;

/// <summary>农夫贴图倍率换算: 原版 288x672 为 1 倍,其余按总像素数开方推导。</summary>
public class GetPixelIndexStrideTests
{
    [Fact]
    public void VanillaTexture_ReturnsOne()
    {
        Assert.Equal(1, HarmonyPatches.GetPixelIndexStride(288 * 672));
    }

    [Fact]
    public void TwoXTexture_ReturnsTwo()
    {
        Assert.Equal(2, HarmonyPatches.GetPixelIndexStride(576 * 1344));
    }

    [Fact]
    public void FourXTexture_ReturnsFour()
    {
        Assert.Equal(4, HarmonyPatches.GetPixelIndexStride(1152 * 2688));
    }

    [Fact]
    public void BelowOrEqualToVanilla_ReturnsOne()
    {
        Assert.Equal(1, HarmonyPatches.GetPixelIndexStride(0));
        Assert.Equal(1, HarmonyPatches.GetPixelIndexStride(1));
        Assert.Equal(1, HarmonyPatches.GetPixelIndexStride(193537));
    }
}
