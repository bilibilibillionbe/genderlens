import 'dart:typed_data';

/// Pixel layout of a raw camera frame.
enum FrameFormat {
  /// Android: full-res Y plane followed by interleaved V/U at half resolution.
  nv21,

  /// iOS: 4 bytes per pixel, B G R A.
  bgra8888,
}

/// A raw camera frame as delivered by the camera plugin, before rotation.
///
/// Kept free of Flutter / plugin types so the image code can be unit tested
/// with synthetic buffers.
class Frame {
  Frame({
    required this.format,
    required this.width,
    required this.height,
    required this.bytes,
    required this.bytesPerRow,
    required this.rotationDegrees,
  }) {
    if (rotationDegrees % 90 != 0) {
      throw ArgumentError.value(rotationDegrees, 'rotationDegrees', 'must be a multiple of 90');
    }
    final minBytes = switch (format) {
      FrameFormat.nv21 => width * height + width * ((height + 1) ~/ 2),
      FrameFormat.bgra8888 => bytesPerRow * (height - 1) + width * 4,
    };
    if (bytes.length < minBytes) {
      throw ArgumentError('$format buffer too small: ${bytes.length} < $minBytes');
    }
  }

  final FrameFormat format;

  /// Raw (sensor) width and height.
  final int width;
  final int height;
  final Uint8List bytes;
  final int bytesPerRow;

  /// Clockwise rotation that turns the raw frame upright (0, 90, 180, 270).
  final int rotationDegrees;

  int get _rot => rotationDegrees % 360;

  /// Size of the frame after rotating it upright. Face boxes from ML Kit are
  /// expressed in this coordinate space.
  int get uprightWidth => (_rot == 90 || _rot == 270) ? height : width;
  int get uprightHeight => (_rot == 90 || _rot == 270) ? width : height;

  /// NV21 row stride. Some producers pad rows (bytesPerRow > width), others
  /// pack them; trust bytesPerRow only if the buffer is large enough for it.
  int get _nv21Stride {
    final padded = bytesPerRow * height + bytesPerRow * ((height + 1) ~/ 2);
    return bytes.length >= padded ? bytesPerRow : width;
  }

  /// Maps a point in upright coordinates to raw frame coordinates.
  ///
  /// Coordinates are continuous: pixel (i, j) covers [i, i+1) x [j, j+1),
  /// so sample at pixel centres (i + 0.5) and floor the result.
  (double, double) uprightToRaw(double u, double v) {
    switch (_rot) {
      case 0:
        return (u, v);
      case 90:
        return (v, height - u);
      case 180:
        return (width - u, height - v);
      case 270:
        return (width - v, u);
      default:
        throw StateError('rotation $_rot');
    }
  }

  /// Writes the RGB value of raw pixel (x, y) into [out] at [o]. Coordinates
  /// are clamped to the frame.
  void readRgb(int x, int y, Float32List out, int o) {
    if (x < 0) x = 0;
    if (y < 0) y = 0;
    if (x >= width) x = width - 1;
    if (y >= height) y = height - 1;
    switch (format) {
      case FrameFormat.bgra8888:
        final i = y * bytesPerRow + x * 4;
        out[o] = bytes[i + 2].toDouble();
        out[o + 1] = bytes[i + 1].toDouble();
        out[o + 2] = bytes[i].toDouble();
      case FrameFormat.nv21:
        final stride = _nv21Stride;
        final yy = bytes[y * stride + x].toDouble();
        final uvIndex = stride * height + (y >> 1) * stride + (x & ~1);
        final vv = bytes[uvIndex] - 128.0;
        final uu = bytes[uvIndex + 1] - 128.0;
        // BT.601 full range, as produced by Android camera HALs.
        out[o] = _clamp(yy + 1.402 * vv);
        out[o + 1] = _clamp(yy - 0.344136 * uu - 0.714136 * vv);
        out[o + 2] = _clamp(yy + 1.772 * uu);
    }
  }

  static double _clamp(double v) => v < 0 ? 0 : (v > 255 ? 255 : v);
}
