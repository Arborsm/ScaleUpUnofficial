using System.Diagnostics.CodeAnalysis;
using StardewModdingAPI;
using StardewModdingAPI.Events;

namespace ScaleUpUnofficial;

public sealed class ScaleUpMod : Mod
{
    public const string ScaleUpdDataAsset = "Platonymous.ScaleUp/Assets";
    public static Dictionary<string, ScaleUpData> Scales { get; set; } = new();
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
        Scales = Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(ScaleUpdDataAsset);
        UpdateScalesByAssetDictionary();
    }

    private void GameLoop_GameLaunched(object? sender, GameLaunchedEventArgs e)
    {
        var api = Helper.ModRegistry.GetApi<IContentPatcherApi>("Pathoschild.ContentPatcher");
        api?.RegisterToken(ModManifest, "Assets", new ScaleUpToken());
    }

    private void Content_AssetReady(object? sender, AssetReadyEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath("Platonymous.ScaleUp"))
        {
            Scales = Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(ScaleUpdDataAsset);
            CheckForDuplicates();
            UpdateScalesByAssetDictionary();
            foreach (var key in Scales.Keys)
            {
                Monitor.Log($"Loaded scaling data for resource {Scales[key].Asset} (provided by {key}).");
            }
        }
    }

    private static void Content_AssetsInvalidated(object? sender, AssetsInvalidatedEventArgs e)
    {
        if (e.NamesWithoutLocale.Any(a => a.IsDirectlyUnderPath("Platonymous.ScaleUp")))
        {
            Scales.Clear();
            ScalesByAsset.Clear();
            HarmonyPatches.ClearCache();
        }
    }

    private static void Content_AssetRequested(object? sender, AssetRequestedEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath("Platonymous.ScaleUp"))
        {
            e.LoadFrom(() => new Dictionary<string, ScaleUpData>(), AssetLoadPriority.High);
        }
    }

    /// <summary>检查是否有多个Mod为同一个资源提供了缩放数据，并移除冲突项。</summary>
    private void CheckForDuplicates()
    {
        foreach (var item in Scales.Values.ToArray())
        {
            if (Scales.Values.Any(v => v != item && v.Asset == item.Asset))
            {
                var keys = Scales.Keys.Where(k => Scales[k].Asset == item.Asset).ToArray();
                foreach (var item1 in keys)
                {
                    Scales.Remove(item1);
                }

                Monitor.Log($"Resource {item.Asset} is specified by multiple mods ({string.Join(',', keys)}). " +
                            $"All related scaling data has been removed to prevent conflicts.", LogLevel.Error);
            }
        }
    }

    /// <summary>更新用于快速查找的字典缓存。</summary>
    private static void UpdateScalesByAssetDictionary()
    {
        ScalesByAsset.Clear();
        foreach (var scale in Scales.Values)
        {
            ScalesByAsset.TryAdd(scale.Asset, scale);
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