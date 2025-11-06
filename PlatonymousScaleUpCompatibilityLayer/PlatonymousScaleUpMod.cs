using System.Diagnostics.CodeAnalysis;
using ScaleUpUnofficial;
using StardewModdingAPI;
using StardewModdingAPI.Events;

namespace PlatonymousScaleUpCompatibilityLayer;

[SuppressMessage("ReSharper", "UnusedType.Global")]
public sealed class PlatonymousScaleUpMod : Mod
{
    private static bool _init;
    private const string PlatonymousScaleUpdDataAsset = "Platonymous.ScaleUp/Assets";
    private const string PlatonymousScaleUpdData = "Platonymous.ScaleUp";
    public override void Entry(IModHelper helper)
    {
        ScaleUpMod.AssetRequested += Content_AssetRequested;
        ScaleUpMod.AssetReady += Content_AssetReady;
        ScaleUpMod.GameLaunched += GameLoop_GameLaunched;
        ScaleUpMod.OnInitMaps += InitMaps;
    }
    
    private static void InitMaps(object? sender, EventArgs e)
    {
        if (!_init && ScaleUpMod.Singleton != null)
        {
            ScaleUpMod.Singleton.Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(PlatonymousScaleUpdDataAsset);
            _init = true;
        }
    }

    private static void Content_AssetRequested(object? sender, AssetRequestedEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(PlatonymousScaleUpdData))
        {
            e.LoadFrom(() => new Dictionary<string, ScaleUpData>(), AssetLoadPriority.High);
        }
    }

    private void GameLoop_GameLaunched(object? sender, GameLaunchedEventArgs e)
    {
        var api = Helper.ModRegistry.GetApi<IContentPatcherApi>("Pathoschild.ContentPatcher");
        api?.RegisterToken(ModManifest, "Assets", new ScaleUpToken());
    }

    private void Content_AssetReady(object? sender, AssetReadyEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(PlatonymousScaleUpdData))
        {
            UpdateScalesByAssetDictionary();
        }
    }
    
    public static void UpdateScalesByAssetDictionary()
    {
        if (ScaleUpMod.Singleton == null) return;
        var scales = ScaleUpMod.Singleton.Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(PlatonymousScaleUpdDataAsset);
        foreach (var scale in scales.Values)
        {
            if (scale.Asset != null)
            {
                ScaleUpMod.ScalesByAsset.TryAdd(scale.FinalAsset(scale.Asset), scale);
            } 
        }
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
            return new[] { PlatonymousScaleUpdDataAsset };
        }
    }
}