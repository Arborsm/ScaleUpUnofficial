using System.Diagnostics.CodeAnalysis;
using System.Text.RegularExpressions;
using Microsoft.Xna.Framework.Graphics;
using StardewModdingAPI;
using StardewModdingAPI.Events;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "ClassNeverInstantiated.Global")]
public sealed class ScaleUpMod : Mod
{
    public const string ScaleUpName = "Arborsm.ScaleUpUnofficial";
    public const string ScaleUpdDataAsset = $"{ScaleUpName}/Assets";
    public static Dictionary<string, ScaleUpData?> ScalesByAsset { get; } = new();
    /// <summary>像素级替换表(运行时数据,不走资源序列化),键为游戏资源名。</summary>
    public static Dictionary<string, List<PixelReplacementData>> PixelReplacementsByAsset { get; } = new();
    public static ScaleUpMod? Instance { get; private set; }
    
    public override void Entry(IModHelper helper)
    {
        Instance = this;
        HarmonyPatches.PatchAll();
        helper.Events.Content.AssetRequested += Content_AssetRequested;
        helper.Events.Content.AssetReady += Content_AssetReady;
        helper.Events.GameLoop.GameLaunched += GameLoop_GameLaunched;
        helper.Events.GameLoop.DayStarted += GameLoop_DayStarted;
    }
    
    private static void Content_AssetRequested(object? sender, AssetRequestedEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(ScaleUpName))
        {
            e.LoadFrom(() => new Dictionary<string, List<ScaleUpData>>(), AssetLoadPriority.High);
        }
        AssetRequested.Invoke(sender, e);
    }
    
    private static void GameLoop_DayStarted(object? sender, DayStartedEventArgs e)
    {
        UpdateScalesByAssetDictionary();
    }

    private void GameLoop_GameLaunched(object? sender, GameLaunchedEventArgs e)
    {
        var api = Helper.ModRegistry.GetApi<IContentPatcherApi>("Pathoschild.ContentPatcher");
        api?.RegisterToken(ModManifest, "Assets", new ScaleUpToken());
    }

    private static void Content_AssetReady(object? sender, AssetReadyEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(ScaleUpName))
        {
            UpdateScalesByAssetDictionary();
        }
        AssetReady.Invoke(sender, e);
    }

    public void InitMaps()
    {
        Helper.GameContent
            .Load<Dictionary<string, List<ScaleUpData>>>(ScaleUpdDataAsset);
        try
        {
            OnInitMaps.Invoke(this, new ScaleInitMapEventArgs(Helper));
        }
        catch (Exception e)
        {
            Monitor.Log($"Error Initializing ScaleUp Map: {e}", LogLevel.Error);
        }
    }
    
    /// <summary>像素级替换的注册入口(本模组配置与兼容层映射共用): 替换纹理需已加载到 Texture,按目标资产名覆盖注册。</summary>
    public static void RegisterPixelReplacements(string targetAsset, List<PixelReplacementData> replacements)
    {
        if (string.IsNullOrEmpty(targetAsset) || replacements is not { Count: > 0 })
        {
            return;
        }
        PixelReplacementsByAsset[targetAsset] = replacements;
    }

    private static void UpdateScalesByAssetDictionary()
    {
        if (Instance == null) return;
        var scales = Instance.Helper.GameContent.Load<Dictionary<string, List<ScaleUpData>>>(ScaleUpdDataAsset);
        foreach (var scale in scales.Values.SelectMany(item => item))
        {
            if (scale.Asset != null)
            {
                ScalesByAsset.TryAdd(scale.FinalAsset(scale.Asset), scale);
            } 
            else if (scale.Assets != null)
            {
                foreach (var asset in Regex.Replace(scale.Assets, @"\s", "").Split(','))
                {
                    ScalesByAsset.TryAdd(scale.FinalAsset(asset), scale);
                }
            }

            // 像素级替换(本模组直接配置): 按 FromAsset 资产名加载替换纹理并注册到绘制补丁
            if (scale.Asset != null && scale.PixelReplacements is { Count: > 0 })
            {
                var replacements = new List<PixelReplacementData>();
                foreach (var pixelReplacement in scale.PixelReplacements)
                {
                    if (string.IsNullOrEmpty(pixelReplacement.FromAsset))
                    {
                        Instance.Monitor.Log($"Missing FromAsset for PixelReplacement on {scale.Asset}, skipping", LogLevel.Warn);
                        continue;
                    }
                    try
                    {
                        replacements.Add(new PixelReplacementData
                        {
                            X = pixelReplacement.X,
                            Y = pixelReplacement.Y,
                            Texture = Instance.Helper.GameContent.Load<Texture2D>(pixelReplacement.FromAsset)
                        });
                    }
                    catch (Exception e)
                    {
                        Instance.Monitor.Log($"Cannot load replacement texture {pixelReplacement.FromAsset}: {e.Message}", LogLevel.Warn);
                    }
                }
                RegisterPixelReplacements(scale.Asset, replacements);
            }
        }
        HarmonyPatches.NonScaledTextureNames.Clear();
        HarmonyPatches.ClearOrgSizeTextureCache();
    }

    public static event EventHandler<AssetRequestedEventArgs> AssetRequested = (_, _) => { };
    public static event EventHandler<AssetReadyEventArgs> AssetReady = (_, _) => { };
    public static event EventHandler<ScaleInitMapEventArgs> OnInitMaps = (_, _) => { };
}

public record ScaleInitMapEventArgs(IModHelper Helper);

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