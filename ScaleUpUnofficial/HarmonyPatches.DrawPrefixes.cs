using System.Diagnostics.CodeAnalysis;
using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace ScaleUpUnofficial;

[SuppressMessage("ReSharper", "InconsistentNaming")]
[SuppressMessage("ReSharper", "UnusedMember.Global")]
public partial class HarmonyPatches
{
    public static bool DrawWithVector2Scale(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Rectangle? sourceRectangle,
        Color color,
        float rotation,
        Vector2 origin,
        Vector2 scale,
        SpriteEffects effects,
        float layerDepth)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var destination = new Rectangle((int)position.X, (int)position.Y,
            (int)((sourceRectangle?.Width ?? texture.Width) * scale.X),
            (int)((sourceRectangle?.Height ?? texture.Height) * scale.Y));

        return DrawLogicRouter(__instance, texture, destination,
            sourceRectangle, color, rotation, origin, scale, effects, layerDepth, data);
    }

    public static bool DrawWithFloatScale(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Rectangle? sourceRectangle,
        Color color,
        float rotation,
        Vector2 origin,
        float scale,
        SpriteEffects effects,
        float layerDepth)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var scaleVec = new Vector2(scale, scale);
        var destination = new Rectangle((int)position.X, (int)position.Y,
            (int)((sourceRectangle?.Width ?? texture.Width) * scale),
            (int)((sourceRectangle?.Height ?? texture.Height) * scale));

        return DrawLogicRouter(__instance, texture, destination,
            sourceRectangle, color, rotation, origin, scaleVec, effects, layerDepth, data);
    }

    public static bool DrawWithRectangle(
        SpriteBatch __instance,
        Texture2D texture,
        Rectangle destinationRectangle,
        Rectangle? sourceRectangle,
        Color color,
        float rotation,
        Vector2 origin,
        SpriteEffects effects,
        float layerDepth)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        return DrawLogicRouter(__instance, texture, destinationRectangle,
            sourceRectangle, color, rotation, origin, Vector2.One, effects, layerDepth, data);
    }

    public static bool DrawSimpleWithSource(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Rectangle? sourceRectangle,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var destination = new Rectangle((int)position.X, (int)position.Y,
            sourceRectangle?.Width ?? texture.Width,
            sourceRectangle?.Height ?? texture.Height);

        return DrawLogicRouter(__instance, texture, destination,
            sourceRectangle, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }

    public static bool DrawRectangleWithSource(
        SpriteBatch __instance,
        Texture2D texture,
        Rectangle destinationRectangle,
        Rectangle? sourceRectangle,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        return DrawLogicRouter(__instance, texture, destinationRectangle,
            sourceRectangle, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }

    public static bool DrawSimple(
        SpriteBatch __instance,
        Texture2D texture,
        Vector2 position,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        var destination = new Rectangle((int)position.X, (int)position.Y,
            texture.Width, texture.Height);

        return DrawLogicRouter(__instance, texture, destination,
            null, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }

    public static bool DrawRectangle(
        SpriteBatch __instance,
        Texture2D texture,
        Rectangle destinationRectangle,
        Color color)
    {
        if (_spriteAlreadyDrawn || !ShouldProcessTexture(texture, out var data))
            return true;

        return DrawLogicRouter(__instance, texture, destinationRectangle,
            null, color, 0f, Vector2.Zero, Vector2.One, SpriteEffects.None, 0f, data);
    }
}
