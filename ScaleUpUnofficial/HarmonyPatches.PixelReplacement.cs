using System.Diagnostics.CodeAnalysis;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public partial class HarmonyPatches
{
    private static bool DrawWithPixelReplacements(SpriteBatch __instance, Rectangle destination,
        Rectangle? sourceRectangle, Color color, float rotation, Vector2 origin, SpriteEffects effects,
        float layerDepth, List<PixelReplacementData> pixelReplacements)
    {
        if (!sourceRectangle.HasValue)
        {
            return true;
        }

        var r = sourceRectangle.Value;
        foreach (var pixelReplacement in pixelReplacements)
        {
            if (pixelReplacement.Texture == null || pixelReplacement.X != r.X || pixelReplacement.Y != r.Y)
            {
                continue;
            }

            var newOrigin = new Vector2(
                origin.X * pixelReplacement.Texture.Width / r.Width,
                origin.Y * pixelReplacement.Texture.Height / r.Height);

            _spriteAlreadyDrawn = true;
            try
            {
                __instance.Draw(pixelReplacement.Texture, destination, null, color, rotation, newOrigin, effects, layerDepth);
            }
            finally
            {
                _spriteAlreadyDrawn = false;
            }
            return false;
        }

        return true;
    }
}
