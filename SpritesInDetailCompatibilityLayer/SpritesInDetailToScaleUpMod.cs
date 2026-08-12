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
                    // 若其他模组以更高优先级（如 Exclusive）加载了目标资源，上面的 LoadFrom 会被覆盖，
                    // 用 Edit 把纹理替换回高清版，保证 FromFile 始终生效
                    e.Edit(asset =>
                    {
                        var replacement = contentPack.ModContent.Load<Texture2D>(sprite.FromFile);
                        if (!ReferenceEquals(asset.Data, replacement))
                        {
                            asset.ReplaceWith(replacement);
                        }
                    });
                }
                // PixelReplacements 不再包裹纹理:替换纹理注册到 ScaleUpMod.PixelReplacementsByAsset,
                // 由绘制补丁按源矩形命中处理,未命中时按原版纹理正常绘制
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

        ScaleUpMod.PixelReplacementsByAsset.Clear();

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

                // 像素级替换(仅当没有 FromFile 整图替换时生效,与 SpritesInDetail 一致)
                if (string.IsNullOrEmpty(sprite.FromFile) && sprite.PixelReplacements.Count > 0)
                {
                    RegisterPixelReplacements(sprite, contentPack);
                }
            }
        }

        return result;
    }

    private void RegisterPixelReplacements(Sprite sprite, IContentPack contentPack)
    {
        var replacements = new List<PixelReplacementData>();
        foreach (var pixelReplacement in sprite.PixelReplacements)
        {
            if (pixelReplacement.TargetX == null || pixelReplacement.TargetY == null ||
                string.IsNullOrEmpty(pixelReplacement.FromFile))
            {
                Monitor.Log($"Missing required fields for PixelReplacement in {sprite.Target}, skipping...", LogLevel.Warn);
                continue;
            }

            try
            {
                replacements.Add(new PixelReplacementData
                {
                    X = pixelReplacement.TargetX.Value,
                    Y = pixelReplacement.TargetY.Value,
                    Texture = contentPack.ModContent.Load<Texture2D>(pixelReplacement.FromFile)
                });
            }
            catch (Exception ex)
            {
                Monitor.Log($"Cannot load replacement texture {pixelReplacement.FromFile}, skip PixelReplacement: {ex.Message}", LogLevel.Warn);
            }
        }

        if (replacements.Count > 0)
        {
            ScaleUpMod.PixelReplacementsByAsset[sprite.Target] = replacements;
        }
    }

    private static ScaleUpData? ConvertSpriteToScaleUpData(Sprite sprite)
    {
        if (string.IsNullOrEmpty(sprite.Target)) return null;

        // 农夫(玩家)精灵由 FarmerRenderer 用内部复制的纹理绘制,走专门的 Farmer 分支,
        // 不使用 NPC 的 Sprite 细节逻辑
        var isFarmer = sprite.Target.Contains("Farmer");

        // Asset 必须是游戏资源名（Target），不能是内容包内的文件路径：
        // ScaleUp 主模组会用 GameContent.Load 加载它来读取尺寸，并按纹理名匹配绘制调用；
        // FromFile 的高清纹理已在 Content_AssetRequested 里通过 LoadFrom/Edit 替换到 Target 上
        var scaleUpData = new ScaleUpData
        {
            Asset = sprite.Target,
            IsFarmer = isFarmer
        };

        if (isFarmer)
        {
            // 有 FromFile 时 Scale 是纹理分辨率倍率(默认 4);无 FromFile 时纹理保持原版,
            // Scale=1 仅按 SpriteWidth/SpriteHeight 做屏幕放大与锚点补偿(画面会糊,仅过渡用法)
            scaleUpData.Scale = sprite.FromFile != null
                ? Math.Max(sprite.WidthScale ?? 4, sprite.HeightScale ?? 4)
                : 1;
            scaleUpData.SpriteWidth = sprite.SpriteWidth;
            scaleUpData.SpriteHeight = sprite.SpriteHeight;
            return scaleUpData;
        }

        var widthScale = sprite.WidthScale ?? 4;
        var heightScale = sprite.HeightScale ?? 4;
        scaleUpData.Scale = Math.Max(widthScale, heightScale);

        if (!isFarmer &&
            (sprite.SpriteWidth.HasValue || sprite.SpriteHeight.HasValue ||
             sprite.SpriteOriginX.HasValue || sprite.SpriteOriginY.HasValue ||
             sprite.BreathType.HasValue || sprite.ChestSourceX.HasValue))
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
        // 数据更新后,之前按"未命中"缓存的纹理名可能已变为已注册资源,需要清掉重查
        HarmonyPatches.NonScaledTextureNames.Clear();
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