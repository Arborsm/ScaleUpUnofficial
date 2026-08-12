using ScaleUpUnofficial;
using Xunit;

namespace ScaleUpUnofficial.Tests;

/// <summary>纹理分辨率倍率: Sprite 规格固定 4,其余按 Scale(非法值回退 4)。</summary>
public class GetTextureScaleMultiplierTests
{
    private static ScaleUpData Data(int? scale = null, bool withSprite = false)
    {
        var data = new ScaleUpData();
        if (scale.HasValue)
        {
            data.Scale = scale.Value;
        }
        if (withSprite)
        {
            data.Sprite = new ScaleUpData.SpriteData();
        }
        return data;
    }

    [Fact]
    public void DefaultScale_ReturnsOne()
    {
        Assert.Equal(1, HarmonyPatches.GetTextureScaleMultiplier(Data()));
    }

    [Fact]
    public void ScaleTwo_ReturnsTwo()
    {
        Assert.Equal(2, HarmonyPatches.GetTextureScaleMultiplier(Data(2)));
    }

    [Fact]
    public void SpriteIgnoresScale_ReturnsFour()
    {
        Assert.Equal(4, HarmonyPatches.GetTextureScaleMultiplier(Data(2, withSprite: true)));
    }

    [Fact]
    public void InvalidScale_FallsBackToFour()
    {
        Assert.Equal(4, HarmonyPatches.GetTextureScaleMultiplier(Data(0)));
        Assert.Equal(4, HarmonyPatches.GetTextureScaleMultiplier(Data(-1)));
    }
}
