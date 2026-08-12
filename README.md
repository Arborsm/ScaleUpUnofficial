# ScaleUp Unofficial Mod

`ScaleUp Unofficial` is an enhanced version of Platonymous's original ScaleUp mod for Stardew Valley, integrating some functionality from the SpritesInDetail mod. This powerful combination enables players and modders to implement high-resolution textures and detailed character sprites while maintaining compatibility with game mechanics.

## Key Features

### 🖼️ High-Resolution Texture Support

- Add larger and higher resolution textures than vanilla
- Simple configuration through Content Patcher
- Automatic texture scaling and padding

### 👤 Detailed Character Sprites

- High-resolution character sprites (64x128 pixels)
- Adjustable chest/breather region positioning

### 🧑‍🌾 HD Farmer Sprites

- High-resolution farmer (player) sprite sheets (e.g. 4x `Characters/Farmer/farmer_base`)
- Keeps vanilla proportions and anchors, so eyes/arms/slingshot/swimming/mini-portraits all stay aligned
- `SpriteWidth`/`SpriteHeight` extend the render canvas around the body (wings, capes, auras) while the body itself stays at vanilla screen size
- Preserves skin/sleeve/shoe/eye recoloring on HD textures

### 🏪 Shop Portraits (Pixel Replacements)

- Native `PixelReplacements` support (e.g. HD shopkeeper portraits for `Portraits/B*` shop textures, like OO's Shop Portrait pack) — no SpritesInDetail pack required
- Register the replacement texture via Content Patcher (`Load` to a `Mods/...` asset) and reference it in the `PixelReplacements` list of the target asset's ScaleUp entry
- The HD replacement texture is drawn into the vanilla portrait area when the source rectangle matches
- Example packs are provided under [`Examples/`](Examples)

### ⚙️ Dual Rendering Modes

1. **Traditional Scaling Mode**  
Preserves original ScaleUp logic - ideal for items and tiles
2. **Detailed Sprite Mode**  
Implements SpritesInDetail technology - perfect for characters and NPCs

## Requirements

- [SMAPI](https://smapi.io/) (latest version)
- [Content Patcher](https://www.nexusmods.com/stardewvalley/mods/1915) (latest version)

## Configuration Example

```json
{
    "Format": "2.0.0",
    "Changes": [
        {
            "Action": "Load",
            "Target": "Characters/Haley",
            "FromFile": "HDSprites/MikaHD.png"
        },
        {
            "Action": "EditData",
            "Target": "{{Arborsm.ScaleUpUnofficial/Assets}}",
            "Entries":
                {
                    "YourMod.Haley": {
                        "Asset": "Characters/Haley",
                        "Sprite": {}
                    }
                }
        },
    ]
}
```

### Configuration Options

| Parameter | Description | Default |
| --- | --- | --- |
| `Asset` | Path to texture asset | Required |
| `Scale` | Texture resolution multiplier (e.g. 4 for a 4x sheet) | 1 |
| `PaddingWidth` | Extra horizontal pixels | 0 |
| `PaddingHeight` | Extra vertical pixels | 0 |
| `Sprite` | Detailed sprite mode (SpritesInDetail-style characters) | null |
| `IsFarmer` | Farmer (player) sprite mode, keeps vanilla geometry | false |
| `SpriteWidth` | Farmer frame render canvas width in game units (16 = vanilla) | 16 |
| `SpriteHeight` | Farmer frame render canvas height in game units (32 = vanilla) | 32 |
| `PixelReplacements` | HD pixel replacement list: replace source-rectangle hits with a full-texture draw | null |
| `BreathType` | Breathing animation type (Male/Female/None) | None |
| `SpriteOriginX` | Sprite origin X coordinate | - |
| `SpriteOriginY` | Sprite origin Y coordinate | - |
| `ChestSourceX` | Breather region X position | - |
| `ChestSourceY` | Breather region Y position | - |
| `ChestSourceWidth` | Breather region width | - |
| `ChestSourceHeight` | Breather region height | - |
| `ChestAdjustX` | Breather region horizontal adjustment | - |
| `ChestAdjustY` | Breather region vertical adjustment | - |

## Usage Examples

### Adding High-Resolution Crop Textures

```json
{
  "YourMod.HighResCrop": {
    "Asset": "Mods/YourMod/Crops/AncientFruit",
    "Scale": 4,
    //"PaddingWidth": 32,
    //"PaddingHeight": 16
  }
}
```

### Adding Detailed Character Sprites

```json
{
   "YourMod.DetailedLewis":
   ﻿{
      ﻿﻿"Asset": "Characters/Lewis",
﻿      "Sprite": {
﻿﻿      "BreathType": "Female",
         "ChestSourceX": 24,
         "ChestSourceY": 100,
         "ChestSourceWidth": 16,
         "ChestSourceHeight": 8,
         "HeadShotX": 12,
         "HeadShotY": 53,
         "HeadShotXRenderOffset": 0,
         "HeadShotYRenderOffset": 0,
         "MiniMapXOffset": 0,
         "MiniMapYOffset": 0
﻿      }
   }
}
```

### Adding an HD Farmer Sprite

```json
{
   "YourMod.HDFarmer":
   {
      "Asset": "Characters/Farmer/farmer_base",
      "IsFarmer": true,
      "Scale": 4,
      "SpriteWidth": 32,
      "SpriteHeight": 64
   }
}
```

- The HD sheet must be a `Scale`× upscale of the vanilla 288x672 layout (e.g. 1152x2688 at 4x), loaded onto the same asset via Content Patcher.
- `SpriteWidth`/`SpriteHeight` (game units per frame, vanilla is 16x32) set the render canvas size, anchored at the farmer's feet. Omit them (or set 16x32) to keep vanilla geometry.
- With `SpriteWidth`/`SpriteHeight` set to 32x64, the frame becomes a 2x canvas but **the body stays at vanilla screen size**: draw the body at 16x32 proportions (2x resolution, i.e. the bottom-center 32x64 texels of each 64x128 HD frame) and use the rest of the frame for content that extends beyond the vanilla outline — wings, capes, auras, taller hats. The example textures mark this as the green (body) and red (extension) zones.
- Accessory textures (`hairstyles`, `shirts`, `pants`, `hats`, `accessories`, ...) keep their vanilla rendering and align automatically with a 1x body. To scale them along with a larger body, register the accessory asset with the same `SpriteWidth`/`SpriteHeight` (plus `Asset` and `Scale`).

See `Examples/[CP] ExampleHDFarmer` for a complete male+female pack, and `Examples/[CP] ExamplePixelReplacementPortrait` for a plain portrait pixel replacement.

### Adding a PixelReplacement (HD Portrait)

```json
{
   "YourMod.HDPortrait":
   {
      "Asset": "Portraits/Pierre",
      "PixelReplacements": [
         {
            "FromAsset": "Mods/YourMod/Pierre_Face_HD",
            "X": 0,
            "Y": 0
         }
      ]
   }
}
```

- `FromAsset` is a Content Patcher texture asset (load it with `"Action": "Load"`), not a file path.
- When the game draws the target texture with a source rectangle whose top-left matches `X`/`Y`, the replacement texture is drawn into that draw call's destination instead.
- Pixel replacement itself needs no `Load` — it only swaps what gets drawn for an **existing** asset (like `Portraits/Pierre` above). A custom portrait asset such as `Portraits/BSeedShop` is created by a regular CP `Load` elsewhere (OO's main pack does this); the replacement pack only references it.

## Performance Notes

The mod is optimized for performance, but consider these factors:

1. High-resolution textures increase VRAM usage
2. Rendering many detailed sprites may impact lower-end GPUs
3. Recommended maximum texture size: 2048x2048
4. Collision detection remains unchanged for performance consistency

## Troubleshooting

**Q: Why aren't my high-res textures appearing?**  
A: Check:

1. Mod enabled
2. Correct asset paths in configuration
3. Content Patcher installed/enabled
4. Game logs for error messages

**Q: How do I adjust breathing animation position?**  
A: Use `ChestAdjustX/Y` parameters.

**Q: Why don't collision boxes match the visual appearance?**  
A: This is intentional - visual enhancements don't affect game logic or collision detection

## Technical Notes

- Uses Harmony for non-invasive patching
- Implements smart caching for performance
- Automatically resolves mod conflicts
- Supports Content Patcher conditionals and tokens

## Developer Notes

`HarmonyPatches` is split into one partial class per concern; each patch falls back to vanilla behavior on any exception:

| File | Responsibility |
| --- | --- |
| `HarmonyPatches.cs` | `PatchAll()` registration (16 patches), `DrawLogicRouter`, tile-sheet bounds patches (`getSourceRectForStandardTileSheet` etc.), `AnimatedSprite` texture width/height, deferred action queue |
| `HarmonyPatches.DrawPrefixes.cs` | The 7 `SpriteBatch.Draw` overload prefixes that route into `DrawLogicRouter` |
| `HarmonyPatches.Farmer.cs` | Farmer-only: body-anchor capture for scale-up rendering, `baseTexture` rebuild that preserves the asset name, palette pixel-index stride, `DrawFarmerSprite` |
| `HarmonyPatches.SpriteInDetail.cs` | SpritesInDetail-style NPC rendering (breathing / headshot / character frame dispatch), headshot offset polynomial, Android texture bounds wrapping |
| `HarmonyPatches.PixelReplacement.cs` | SpritesInDetail `PixelReplacements` (HD shop portraits) |
| `ScaleUpData.cs` | Config model (incl. native `PixelReplacements` with `FromAsset`), `GetScaledSource` tile math (scale/padding/cycle) |
| `ScaleUpMod.cs` | SMAPI entry, asset events, per-asset scale dictionary, `RegisterPixelReplacements` registration API |
| `ScaleUpUnofficial.Tests/` | Offline pure-math regression tests (no game required): `dotnet test ScaleUpUnofficial.Tests/ScaleUpUnofficial.Tests.csproj` |

All static render state lives on the XNA render thread only (game drawing is single-threaded); texture-size placeholder textures and the negative texture-name cache are cleared on day start.

### Compatibility Layers

The compatibility layers are thin **mappers**, not duplicate implementations: they read legacy pack formats and convert them into this mod's native data structures.

- `PlatonymousScaleUpCompatibilityLayer` maps the original `{{Platonymous.ScaleUp/Assets}}` data format into `ScalesByAsset`.
- `SpritesInDetailCompatibilityLayer` maps SpritesInDetail's `Sprites` content-pack format (incl. `PixelReplacements`) into native `ScaleUpData` / `RegisterPixelReplacements`, so legacy SID packs such as OO's Shop Portrait keep working. Pixel replacement rendering itself is always handled by this mod's draw patches.

New packs should use the native Content Patcher format shown above instead.

> Requires Stardew Valley 1.6 or newer
