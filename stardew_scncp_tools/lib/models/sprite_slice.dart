import 'package:image/image.dart' as img;

class SpriteSlice {
  final img.Image image;
  final int x;
  final int y;
  final int width;
  final int height;

  const SpriteSlice({
    required this.image,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  SpriteSlice copyWith({
    img.Image? image,
    int? x,
    int? y,
    int? width,
    int? height,
  }) {
    return SpriteSlice(
      image: image ?? this.image,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
    );
  }
}
