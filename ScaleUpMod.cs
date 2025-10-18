using System.Diagnostics.CodeAnalysis;
using System.Text.RegularExpressions;
using StardewModdingAPI;
using StardewModdingAPI.Events;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "ClassNeverInstantiated.Global")]
public sealed class ScaleUpMod : Mod
{
    public const string ScaleUpName = "Arborsm.ScaleUpUnofficial";
    public const string ScaleUpdDataAsset = $"{ScaleUpName}/Assets";
    public static Dictionary<string, ScaleUpData?> ScalesByAsset { get; } = new();
    public static ScaleUpMod Singleton { get; private set; } = null!;
    
    public override void Entry(IModHelper helper)
    {
        Singleton = this;
        HarmonyPatches.PatchAll();
        helper.Events.Content.AssetRequested += Content_AssetRequested;
        helper.Events.Content.AssetsInvalidated += Content_AssetsInvalidated;
        helper.Events.Content.AssetReady += Content_AssetReady;
        helper.Events.GameLoop.GameLaunched += GameLoop_GameLaunched;
        helper.Events.GameLoop.DayStarted += GameLoop_DayStarted;
    }

    private void GameLoop_DayStarted(object? sender, DayStartedEventArgs e)
    {
        UpdateScalesByAssetDictionary();
    }

    private void GameLoop_GameLaunched(object? sender, GameLaunchedEventArgs e)
    {
        var api = Helper.ModRegistry.GetApi<IContentPatcherApi>("Pathoschild.ContentPatcher");
        api?.RegisterToken(ModManifest, "Assets", new ScaleUpToken());
    }

    private void Content_AssetReady(object? sender, AssetReadyEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(ScaleUpName))
        {
            UpdateScalesByAssetDictionary();
        }
    }

    private static void Content_AssetsInvalidated(object? sender, AssetsInvalidatedEventArgs e)
    {
        if (e.NamesWithoutLocale.Any(a => a.IsDirectlyUnderPath(ScaleUpName)))
        {
            ScalesByAsset.Clear();
        }
    }

    private static void Content_AssetRequested(object? sender, AssetRequestedEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(ScaleUpName))
        {
            e.LoadFrom(() => new Dictionary<string, List<ScaleUpData>>(), AssetLoadPriority.High);
        }
        if (e.NameWithoutLocale.IsDirectlyUnderPath("Characters"))
        {
            e.Edit(asset =>
            {
                var replacement = ReplacedTexture.Create(asset.AsImage().Data);
                asset.AsImage().ReplaceWith(replacement);
            }, AssetEditPriority.Late);
        }
    }

    /// <summary>更新用于快速查找的字典缓存。</summary>
    private void UpdateScalesByAssetDictionary()
    {
        var scales = Helper.GameContent.Load<Dictionary<string, List<ScaleUpData>>>(ScaleUpdDataAsset);
        ScalesByAsset.Clear();
        foreach (var scale in scales.Values.SelectMany(item => item))
        {
            if (scale.Asset != null)
            {
                ScalesByAsset.TryAdd(scale.FinalAsset, scale);
            } 
            else if (scale.Assets != null)
            {
                foreach (var asset in Regex.Replace(scale.Assets, @"\s", "").Split(','))
                {
                    ScalesByAsset.TryAdd(asset, scale);
                }
            }
        }
    }
}

public interface IContentPatcherApi
{
    void RegisterToken(IManifest mod, string name, object token);
}

[SuppressMessage("ReSharper", "UnusedMember.Global")]
[SuppressMessage("ReSharper", "UnusedParameter.Global")]
internal sealed class ScaleUpToken
{
    public bool IsMutable() => false;
    public bool AllowsInput() => false;
    public bool RequiresInput() => false;
    public bool CanHaveMultipleValues(string? input = null) => false;
    public bool UpdateContext() => false;
    public bool IsReady() => true;
    public IEnumerable<string> GetValues(string input)
    {
        return new[] { ScaleUpMod.ScaleUpdDataAsset };
    }
}