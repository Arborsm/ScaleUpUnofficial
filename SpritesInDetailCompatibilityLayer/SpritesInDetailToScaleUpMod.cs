using System.Diagnostics.CodeAnalysis;
using Microsoft.Xna.Framework.Graphics;
using ScaleUpUnofficial;
using StardewModdingAPI;
using StardewModdingAPI.Events;

namespace SpritesInDetailCompatibilityLayer;

[SuppressMessage("ReSharper", "UnusedType.Global")]
public class SpritesInDetailToScaleUpMod : Mod
{
    private const string SpritesInDetailDataAsset = "BleakCodex.SpritesInDetail/Assets";
    private const string SpritesInDetailData = "BleakCodex.SpritesInDetail";
    
    private static readonly Dictionary<IManifest, Dictionary<string, string>> Settings = new();
    private static readonly List<(string TokenKey, IManifest Manifest)> TokensToRegister = new();

    public override void Entry(IModHelper helper)
    {
        helper.Events.GameLoop.GameLaunched += GameLoop_GameLaunched;
        helper.Events.Content.AssetRequested += Content_AssetRequested;
        
        ScaleUpMod.AssetRequested += SC_Content_AssetRequested;
        ScaleUpMod.AssetReady += Content_AssetReady;
        ScaleUpMod.OnInitMaps += InitMaps;
    }

    private void Content_AssetRequested(object? sender, AssetRequestedEventArgs e)
    {
        foreach (var contentPack in Helper.ContentPacks.GetOwned())
        {
            if (!contentPack.HasFile("content.json")) continue;

            var content = contentPack.ReadJsonFile<Content>("content.json");
            if (content == null) continue;
            
            foreach (var sprite in content.Sprites.Where(sprite => e.Name.IsEquivalentTo(sprite.Target)))
            {
                if (sprite.FromFile != null) {
                    e.LoadFrom(() => contentPack.ModContent.Load<Texture2D>(sprite.FromFile), AssetLoadPriority.High);
                } 
                
                if (sprite.PixelReplacements is { Count: > 0 })
                {
                    var pixelReplacement = sprite.PixelReplacements.FirstOrDefault();
                    if (pixelReplacement?.FromFile == null) continue;
                    e.Edit(asset =>
                    {
                        if (OperatingSystem.IsAndroid())
                        {
                            ReplacedTexture replacement = null!;
                            var replace = contentPack.ModContent.Load<Texture2D>(pixelReplacement.FromFile);
                            var textureDataGathered = new ManualResetEvent(false);
                            if (OperatingSystem.IsAndroid())
                            {
                                HarmonyPatches.EnqueueAction(() =>
                                {
                                    replacement = new ReplacedTexture(asset.AsImage().Data, replace);
                                    textureDataGathered.Set();
                                });
                                textureDataGathered.WaitOne();
                                textureDataGathered.Reset();
                            }
                            asset.AsImage().ReplaceWith(replacement);
                        }
                        else
                        {
                            var replace = contentPack.ModContent.Load<Texture2D>(pixelReplacement.FromFile);
                            var replacement = new ReplacedTexture(asset.AsImage().Data, replace);
                            asset.AsImage().ReplaceWith(replacement);
                        }
                    });
                }
            }
        }
    }

    private static void InitMaps(object? sender, ScaleInitMapEventArgs e)
    {
        e.Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(SpritesInDetailDataAsset);
    }

    private void SC_Content_AssetRequested(object? sender, AssetRequestedEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(SpritesInDetailData))
        {
            e.LoadFrom(LoadSpritesInDetailData, AssetLoadPriority.High);
        }
    }

    private Dictionary<string, ScaleUpData> LoadSpritesInDetailData()
    {
        var result = new Dictionary<string, ScaleUpData>();
        
        if (ScaleUpMod.Instance == null) return result;

        var contentPackSettings = new Dictionary<string, string>();
        foreach (var contentPack in Helper.ContentPacks.GetOwned())
        {
            if (!contentPack.HasFile("content.json")) continue;

            var content = contentPack.ReadJsonFile<Content>("content.json");
            if (content == null) continue;

            Monitor.Log($"读取 SpritesInDetail content pack: {contentPack.Manifest.Name} {contentPack.Manifest.Version} 从 {contentPack.DirectoryPath}");
            
            var dynamicConfig = contentPack.ReadJsonFile<dynamic>("config.json");

            if (dynamicConfig == null)
            {
                contentPackSettings.TryAdd("Enabled", "true");
            }
            else
            {
                var config = dynamicConfig.ToObject<Dictionary<string, object>>();
                if (config != null)
                {
                    foreach (var keyValue in config)
                    {
                        if (keyValue.Value == null) continue;
                        
                        contentPackSettings.TryAdd(keyValue.Key, keyValue.Value.ToString() ?? string.Empty);
                        
                        if (keyValue.Key != "Enabled")
                        {
                            TokensToRegister.Add((keyValue.Key, contentPack.Manifest));
                        }
                    }
                }
            }
            
            if (contentPackSettings.Count > 0)
            {
                Settings[contentPack.Manifest] = contentPackSettings;
            }
            
            var enabled = true;
            if (contentPackSettings.TryGetValue("Enabled", out var setting))
            {
                enabled = setting.ToLower() == "true";
            }

            if (!enabled) continue;

            foreach (var sprite in content.Sprites)
            {
                var conditionals = new Dictionary<string, string?>();
                if (sprite.When != null)
                {
                    foreach (var when in sprite.When)
                    {
                        conditionals.Add(
                            TokensToRegister.Any(t => t.TokenKey == when.Key)
                                ? $"{contentPack.Manifest.UniqueID}/{when.Key}" : when.Key, when.Value);
                    }
                }

                var conditionsMatch = true;
                var cpApi = Helper.ModRegistry.GetApi<IContentPatcherApi>("Pathoschild.ContentPatcher");
                if (conditionals.Count > 0 && cpApi is { IsConditionsApiReady: true })
                {
                    try
                    {
                        var managedConditions = cpApi.ParseConditions(contentPack.Manifest, conditionals, new SemanticVersion("1.28.0"));
                        conditionsMatch = managedConditions.IsMatch;
                    }
                    catch
                    {
                        conditionsMatch = true;
                    }
                }

                if (!conditionsMatch) continue;

                var scaleUpData = ConvertSpriteToScaleUpData(sprite);
                if (scaleUpData != null)
                {
                    result.TryAdd(sprite.Target, scaleUpData);
                }
                
                foreach (var pixelReplacement in sprite.PixelReplacements)
                {
                    if (pixelReplacement.TargetX == null || pixelReplacement.TargetY == null || 
                        string.IsNullOrEmpty(pixelReplacement.FromFile))
                    {
                        Monitor.Log($"Missing required fields for PixelReplacement in {sprite.Target}, skipping...", LogLevel.Warn);
                        continue;
                    }

                    var pixelScaleUpData = ConvertPixelReplacementToScaleUpData(pixelReplacement, sprite.Target, contentPack);
                    
                    if (pixelScaleUpData != null)
                    {
                        if (!result.ContainsKey(sprite.Target))
                            result.TryAdd(sprite.Target, pixelScaleUpData);
                        else
                            result[sprite.Target] = pixelScaleUpData;
                    }
                }
            }
        }

        return result;
    }

    private static ScaleUpData? ConvertSpriteToScaleUpData(Sprite sprite)
    {
        if (string.IsNullOrEmpty(sprite.Target)) return null;

        var scaleUpData = new ScaleUpData
        {
            Asset = !string.IsNullOrEmpty(sprite.FromFile) ? sprite.FromFile : sprite.Target
        };

        var widthScale = sprite.WidthScale ?? 4;
        var heightScale = sprite.HeightScale ?? 4;
        scaleUpData.Scale = Math.Max(widthScale, heightScale);

        if (sprite.SpriteWidth.HasValue || sprite.SpriteHeight.HasValue || 
            sprite.SpriteOriginX.HasValue || sprite.SpriteOriginY.HasValue ||
            sprite.BreathType.HasValue || sprite.ChestSourceX.HasValue)
        {
            scaleUpData.Sprite = new ScaleUpData.SpriteData
            {
                SpriteOriginX = sprite.SpriteOriginX ?? 32,
                SpriteOriginY = sprite.SpriteOriginY ?? 112,
                BreathType = sprite.BreathType,
                ChestSourceX = sprite.ChestSourceX,
                ChestSourceY = sprite.ChestSourceY,
                ChestSourceWidth = sprite.ChestSourceWidth,
                ChestSourceHeight = sprite.ChestSourceHeight,
                ChestAdjustX = sprite.ChestAdjustX,
                ChestAdjustY = sprite.ChestAdjustY
            };
        }

        return scaleUpData;
    }

    private ScaleUpData? ConvertPixelReplacementToScaleUpData(
        PixelReplacement pixelReplacement, 
        string targetAsset, 
        IContentPack contentPack)
    {
        if (string.IsNullOrEmpty(pixelReplacement.FromFile) || 
            pixelReplacement.TargetX == null || 
            pixelReplacement.TargetY == null)
        {
            return null;
        }

        try
        {
            Texture2D? originalTexture = null;
            try
            {
                originalTexture = Helper.GameContent.Load<Texture2D>(targetAsset);
            }
            catch
            {
                Monitor.Log($"Cannot load original texture {targetAsset}，using default scale 1.0f", LogLevel.Warn);
            }
            
            Texture2D? replacementTexture;
            try
            {
                replacementTexture = contentPack.ModContent.Load<Texture2D>(pixelReplacement.FromFile);
            }
            catch
            {
                Monitor.Log($"Cannot load replacement texture {pixelReplacement.FromFile}，skip PixelReplacement", LogLevel.Warn);
                return null;
            }
            
            float scale = 1.0f;
            if (originalTexture != null && replacementTexture != null)
            {
                float widthScale = (float)replacementTexture.Width / originalTexture.Width;
                float heightScale = (float)replacementTexture.Height / originalTexture.Height;
                scale = Math.Max(widthScale, heightScale);
            }
            else if (replacementTexture != null)
            {
                scale = 4f;
            }
            
            var scaleUpData = new ScaleUpData
            {
                Asset = targetAsset,
                Scale = scale
            };

            return scaleUpData;
        }
        catch (Exception ex)
        {
            Monitor.Log($"Parse PixelReplacement Error: {ex.Message}", LogLevel.Error);
            return null;
        }
    }

    private void GameLoop_GameLaunched(object? sender, GameLaunchedEventArgs e)
    {
        var cpApi = Helper.ModRegistry.GetApi<IContentPatcherApi>("Pathoschild.ContentPatcher");

        if (cpApi == null) return;
        
        foreach (var (tokenKey, manifest) in TokensToRegister)
        {
            cpApi.RegisterToken(manifest, tokenKey, () =>
            {
                if (Settings.ContainsKey(manifest) && Settings[manifest].ContainsKey(tokenKey))
                {
                    return new[] { Settings[manifest][tokenKey] };
                }
                return null;
            });
        }
        
        cpApi.RegisterToken(ModManifest, "Assets", new SpritesInDetailToken());
    }

    private void Content_AssetReady(object? sender, AssetReadyEventArgs e)
    {
        if (e.NameWithoutLocale.IsDirectlyUnderPath(SpritesInDetailData))
        {
            UpdateScalesByAssetDictionary();
        }
    }

    private void UpdateScalesByAssetDictionary()
    {
        if (ScaleUpMod.Instance == null) return;
        var scales = Helper.GameContent.Load<Dictionary<string, ScaleUpData>>(SpritesInDetailDataAsset);
        foreach (var (targetAsset, scaleUpData) in scales)
        {
            ScaleUpMod.ScalesByAsset.TryAdd(targetAsset, scaleUpData);
        }
    }

    [SuppressMessage("ReSharper", "UnusedMember.Global")]
    [SuppressMessage("ReSharper", "UnusedParameter.Global")]
    internal sealed class SpritesInDetailToken
    {
        public bool IsMutable() => false;
        public bool AllowsInput() => false;
        public bool RequiresInput() => false;
        public bool CanHaveMultipleValues(string? input = null) => false;
        public bool UpdateContext() => false;
        public bool IsReady() => true;
        public IEnumerable<string> GetValues(string input)
        {
            return new[] { SpritesInDetailDataAsset };
        }
    }
}

public interface IContentPatcherApi
{
    bool IsConditionsApiReady { get; }
    IManagedConditions ParseConditions(IManifest manifest, IDictionary<string, string?>? rawConditions, ISemanticVersion formatVersion, string[]? assumeModIds = null);
    void RegisterToken(IManifest mod, string name, Func<IEnumerable<string>?> getValue);
    void RegisterToken(IManifest mod, string name, object token);
}

public interface IManagedConditions
{
    [SuppressMessage("ReSharper", "UnusedMember.Global")]
    bool IsValid { get; }
    string? ValidationError { get; }
    bool IsReady { get; }
    bool IsMatch { get; }
    bool IsMutable { get; }
    IEnumerable<int> UpdateContext();
    string? GetReasonNotMatched();
}