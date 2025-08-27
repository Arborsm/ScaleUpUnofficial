import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/sprite_provider.dart';

class PreviewPanels extends StatelessWidget {
  const PreviewPanels({super.key});

  @override
  Widget build(BuildContext context) {
    final spriteProvider = Provider.of<SpriteProvider>(context);

    return Column(
      children: [
        // Character Preview
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Character Preview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: spriteProvider.hasSprites
                      ? _buildCharacterPreview(context, spriteProvider)
                      : _buildEmptyPreview(context, 'No sprites loaded'),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Map Icon Preview
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Map Icon Preview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Expanded(
                  child: spriteProvider.hasSprites
                      ? _buildMapIconPreview(context, spriteProvider)
                      : _buildEmptyPreview(context, 'No sprites loaded'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterPreview(
      BuildContext context, SpriteProvider spriteProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: CharacterPreviewPainter(
          spriteProvider: spriteProvider,
          context: context,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildMapIconPreview(
      BuildContext context, SpriteProvider spriteProvider) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: CustomPaint(
        painter: MapIconPreviewPainter(
          spriteProvider: spriteProvider,
          context: context,
        ),
        size: Size.infinite,
      ),
    );
  }

  Widget _buildEmptyPreview(BuildContext context, String message) {
    return Center(
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class CharacterPreviewPainter extends CustomPainter {
  final SpriteProvider spriteProvider;
  final BuildContext context;

  CharacterPreviewPainter({
    required this.spriteProvider,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!spriteProvider.hasSprites) return;

    final displayImage = spriteProvider.currentDisplayImage;
    if (displayImage == null) return;

    final selectionRect = spriteProvider.selectionRect;
    final spriteData = spriteProvider.spriteData;

    // Calculate preview scale to maximize the image while fitting in the available space
    final scaleX = size.width / selectionRect.width;
    final scaleY = size.height / selectionRect.height;

    // Use the smaller scale to ensure the entire image fits in the preview area
    final scale = min(scaleX, scaleY);

    // Center the image in the available space
    final offsetX = (size.width - selectionRect.width * scale) / 2;
    final offsetY = (size.height - selectionRect.height * scale) / 2;

    // Draw the character/headshot area
    final srcRect = Rect.fromLTWH(
      selectionRect.left.toDouble(),
      selectionRect.top.toDouble(),
      selectionRect.width.toDouble(),
      selectionRect.height.toDouble(),
    );

    final dstRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      selectionRect.width * scale,
      selectionRect.height * scale,
    );

    canvas.drawImageRect(displayImage, srcRect, dstRect, Paint());

    // Draw breathing animation chest area if applicable
    if (spriteData.breathType != null && spriteData.breathType! > 0) {
      final chestX = spriteData.chestSourceX ?? 0;
      final chestY = spriteData.chestSourceY ?? 0;
      final chestWidth = spriteData.chestSourceWidth ?? 0;
      final chestHeight = spriteData.chestSourceHeight ?? 0;

      if (chestWidth > 0 && chestHeight > 0) {
        final chestSrcRect = Rect.fromLTWH(
          chestX.toDouble(),
          chestY.toDouble(),
          chestWidth.toDouble(),
          chestHeight.toDouble(),
        );

        // Calculate chest position relative to headshot
        final relativeChestX = chestX - selectionRect.left;
        final relativeChestY = chestY - selectionRect.top;

        final chestDstRect = Rect.fromLTWH(
          offsetX + relativeChestX * scale,
          offsetY + relativeChestY * scale,
          chestWidth * scale,
          chestHeight * scale,
        );

        canvas.drawImageRect(displayImage, chestSrcRect, chestDstRect, Paint());
      }
    }

    // Draw centerlines if enabled
    if (spriteProvider.showCenterlines) {
      final paint = Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Vertical centerline
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );

      // Horizontal centerline
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CharacterPreviewPainter oldDelegate) {
    return oldDelegate.spriteProvider != spriteProvider;
  }
}

class MapIconPreviewPainter extends CustomPainter {
  final SpriteProvider spriteProvider;
  final BuildContext context;

  MapIconPreviewPainter({
    required this.spriteProvider,
    required this.context,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!spriteProvider.hasSprites) return;

    final displayImage = spriteProvider.currentDisplayImage;
    if (displayImage == null) return;

    final spriteData = spriteProvider.spriteData;

    // Map icon is typically from coordinates around (14, 70) with size 32x32
    const double iconSize = 32.0;
    final miniMapXOff = spriteData.miniMapXOffset ?? 0;
    final miniMapYOff = spriteData.miniMapYOffset ?? 0;

    final srcRect = Rect.fromLTWH(
      14.0 + miniMapXOff,
      70.0 + miniMapYOff,
      iconSize,
      iconSize,
    );

    // Calculate scale to fit icon in preview area
    final scale = size.width / iconSize;
    final dstRect = Rect.fromLTWH(
      0,
      (size.height - iconSize * scale) / 2,
      iconSize * scale,
      iconSize * scale,
    );

    canvas.drawImageRect(displayImage, srcRect, dstRect, Paint());

    // Draw centerlines if enabled
    if (spriteProvider.showCenterlines) {
      final paint = Paint()
        ..color = Colors.red.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;

      // Vertical centerline
      canvas.drawLine(
        Offset(size.width / 2, 0),
        Offset(size.width / 2, size.height),
        paint,
      );

      // Horizontal centerline
      canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MapIconPreviewPainter oldDelegate) {
    return oldDelegate.spriteProvider != spriteProvider;
  }
}
