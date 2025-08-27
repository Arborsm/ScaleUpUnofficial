import 'dart:ui' as ui;
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';

class ImageUtils {
  /// Convert an Image from the image package to a Flutter ui.Image
  static Future<ui.Image> convertImageToUiImage(img.Image image) async {
    final ui.ImmutableBuffer buffer = await ui.ImmutableBuffer.fromUint8List(
      image.toUint8List(),
    );

    final ui.ImageDescriptor descriptor = ui.ImageDescriptor.raw(
      buffer,
      width: image.width,
      height: image.height,
      pixelFormat: ui.PixelFormat.rgba8888,
    );

    final ui.Codec codec = await descriptor.instantiateCodec();
    final ui.FrameInfo frameInfo = await codec.getNextFrame();

    return frameInfo.image;
  }

  /// Convert a Flutter ui.Image to an Image from the image package
  static img.Image convertUiImageToImage(ui.Image uiImage) {
    // This is a simplified conversion - you might need to implement
    // actual pixel data extraction depending on your needs
    throw UnimplementedError('UI Image to Image conversion not implemented');
  }

  /// Crop an image using the image package
  static img.Image cropImage(img.Image image, int x, int y, int width, int height) {
    return img.copyCrop(image, x: x, y: y, width: width, height: height);
  }

  /// Resize an image using the image package
  static img.Image resizeImage(img.Image image, int width, int height) {
    return img.copyResize(image, width: width, height: height, interpolation: img.Interpolation.nearest);
  }

  /// Get pixel data from an image at specific coordinates
  static img.Pixel getPixel(img.Image image, int x, int y) {
    return image.getPixel(x, y);
  }

  /// Set pixel data in an image at specific coordinates
  static void setPixel(img.Image image, int x, int y, img.Pixel pixel) {
    image.setPixel(x, y, pixel);
  }

  /// Calculate the optimal display scale for an image in a given canvas size
  static double calculateOptimalScale(Size imageSize, Size canvasSize) {
    final double scaleX = canvasSize.width / imageSize.width;
    final double scaleY = canvasSize.height / imageSize.height;
    return scaleX < scaleY ? scaleX : scaleY;
  }

  /// Calculate the offset to center an image in a canvas
  static Offset calculateCenterOffset(
    Size imageSize,
    Size canvasSize,
    double scale,
  ) {
    final double scaledWidth = imageSize.width * scale;
    final double scaledHeight = imageSize.height * scale;

    final double offsetX = (canvasSize.width - scaledWidth) / 2;
    final double offsetY = (canvasSize.height - scaledHeight) / 2;

    return Offset(offsetX, offsetY);
  }

  /// Convert canvas coordinates to image coordinates
  static Offset canvasToImageCoordinates(
    Offset canvasPoint,
    Offset displayOffset,
    double displayScale,
  ) {
    final double imageX = (canvasPoint.dx - displayOffset.dx) / displayScale;
    final double imageY = (canvasPoint.dy - displayOffset.dy) / displayScale;
    return Offset(imageX, imageY);
  }

  /// Convert image coordinates to canvas coordinates
  static Offset imageToCanvasCoordinates(
    Offset imagePoint,
    Offset displayOffset,
    double displayScale,
  ) {
    final double canvasX = imagePoint.dx * displayScale + displayOffset.dx;
    final double canvasY = imagePoint.dy * displayScale + displayOffset.dy;
    return Offset(canvasX, canvasY);
  }

  /// Check if a rectangle is within the bounds of an image
  static bool isRectWithinImageBounds(img.Image image, Rect rect) {
    return rect.left >= 0 &&
           rect.top >= 0 &&
           rect.right <= image.width &&
           rect.bottom <= image.height;
  }

  /// Create a grid pattern for overlay
  static ui.Path createGridPath(int width, int height, int spacing) {
    final ui.Path path = ui.Path();

    // Vertical lines
    for (int x = 0; x <= width; x += spacing) {
      path.moveTo(x.toDouble(), 0);
      path.lineTo(x.toDouble(), height.toDouble());
    }

    // Horizontal lines
    for (int y = 0; y <= height; y += spacing) {
      path.moveTo(0, y.toDouble());
      path.lineTo(width.toDouble(), y.toDouble());
    }

    return path;
  }

  /// Create a checkerboard pattern for transparency visualization
  static ui.Image createCheckerboardPattern(int size, int squareSize) {
    // This would create a checkerboard image for showing transparency
    // Implementation would require creating a bitmap and drawing the pattern
    throw UnimplementedError('Checkerboard pattern not implemented');
  }
}
