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
            "Target": "{{Platonymous.ScaleUp/Assets}}",
            "Entries":
                {
                    "Playtonymous.Haley": {
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
|-----------|-------------|---------|
| `Asset` | Path to texture asset | Required |
| `Scale` | Scaling factor | 1 |
| `PaddingWidth` | Extra horizontal pixels | 0 |
| `PaddingHeight` | Extra vertical pixels | 0 |
| `UseSpriteInDetail` | Enable detailed sprite mode | false |
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

> Requires Stardew Valley 1.6 or newer
