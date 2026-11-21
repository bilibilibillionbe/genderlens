import 'dart:math' as math;
import 'dart:typed_data';

import 'frame.dart';

/// Axis-aligned rectangle in upright frame coordinates.
class BoxF {
  const BoxF(this.left, this.top, this.right, this.bottom);

  final double left, top, right, bottom;

  double get width => right - left;
  double get height => bottom - top;
  double get centerX => (left + right) / 2;
  double get centerY => (top + bottom) / 2;

  @override
  String toString() => 'BoxF($left, $top, $right, $bottom)';
}

/// Square crop around a detected face, grown by [scale] to match the
/// margin the classifier was trained with (FairFace padding=0.25 -> 1.5).
BoxF expandToSquare(BoxF face, double scale) {
  final side = math.max(face.width, face.height) * scale;
  return BoxF(
    face.centerX - side / 2,
    face.centerY - side / 2,
    face.centerX + side / 2,
    face.centerY + side / 2,
  );
}

/// Extracts [crop] (upright coordinates) from [frame] as a size x size RGB
/// image, row-major, values 0..255. Parts of the crop outside the frame
/// repeat the edge pixels, which is close to the reflect padding used in
/// training.
///
/// Down-scaling averages a k x k grid of samples per output pixel to avoid
/// aliasing (the training pipeline resizes with antialiasing).
Float32List extractCrop(Frame frame, BoxF crop, int size, {Float32List? into}) {
  final out = into ?? Float32List(size * size * 3);
  if (out.length != size * size * 3) {
    throw ArgumentError('output buffer has wrong length');
  }
  final step = crop.width / size;
  final k = step.round().clamp(1, 3);
  final sub = step / k;
  final tmp = Float32List(3);
  final invK2 = 1.0 / (k * k);

  var o = 0;
  for (var j = 0; j < size; j++) {
    final v0 = crop.top + j * step;
    for (var i = 0; i < size; i++) {
      final u0 = crop.left + i * step;
      var r = 0.0, g = 0.0, b = 0.0;
      for (var sj = 0; sj < k; sj++) {
        final v = v0 + (sj + 0.5) * sub;
        for (var si = 0; si < k; si++) {
          final u = u0 + (si + 0.5) * sub;
          final (x, y) = frame.uprightToRaw(u, v);
          frame.readRgb(x.floor(), y.floor(), tmp, 0);
          r += tmp[0];
          g += tmp[1];
          b += tmp[2];
        }
      }
      out[o++] = r * invK2;
      out[o++] = g * invK2;
      out[o++] = b * invK2;
    }
  }
  return out;
}
