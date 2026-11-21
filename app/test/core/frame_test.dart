import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genderlens/core/face_crop.dart';
import 'package:genderlens/core/frame.dart';

/// BGRA frame whose red channel encodes x and green channel encodes y.
Frame coordFrame(int w, int h, int rotation, {int padding = 0}) {
  final bpr = w * 4 + padding;
  final bytes = Uint8List(bpr * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final i = y * bpr + x * 4;
      bytes[i] = 0; // B
      bytes[i + 1] = y; // G
      bytes[i + 2] = x; // R
      bytes[i + 3] = 255;
    }
  }
  return Frame(
    format: FrameFormat.bgra8888,
    width: w,
    height: h,
    bytes: bytes,
    bytesPerRow: bpr,
    rotationDegrees: rotation,
  );
}

/// Raw (x, y) of the upright pixel (u, v), sampled at its centre.
(int, int) rawAtUpright(Frame f, num u, num v) {
  final px = Float32List(3);
  final (x, y) = f.uprightToRaw(u + 0.5, v + 0.5);
  f.readRgb(x.floor(), y.floor(), px, 0);
  return (px[0].toInt(), px[1].toInt());
}

void main() {
  const w = 6, h = 4;

  group('upright size', () {
    test('swaps for 90 and 270', () {
      expect(coordFrame(w, h, 90).uprightWidth, h);
      expect(coordFrame(w, h, 90).uprightHeight, w);
      expect(coordFrame(w, h, 270).uprightWidth, h);
      expect(coordFrame(w, h, 0).uprightWidth, w);
      expect(coordFrame(w, h, 180).uprightHeight, h);
    });

    test('rejects rotations that are not multiples of 90', () {
      expect(() => coordFrame(w, h, 45), throwsArgumentError);
    });
  });

  group('uprightToRaw', () {
    test('0 degrees is the identity', () {
      expect(rawAtUpright(coordFrame(w, h, 0), 2, 1), (2, 1));
    });

    test('90 degrees clockwise: raw top-left ends up top-right', () {
      final f = coordFrame(w, h, 90);
      expect(rawAtUpright(f, h - 1, 0), (0, 0));
      expect(rawAtUpright(f, 0, 0), (0, h - 1));
      expect(rawAtUpright(f, 0, w - 1), (w - 1, h - 1));
    });

    test('180 degrees: raw top-left ends up bottom-right', () {
      final f = coordFrame(w, h, 180);
      expect(rawAtUpright(f, w - 1, h - 1), (0, 0));
      expect(rawAtUpright(f, 0, 0), (w - 1, h - 1));
    });

    test('270 degrees: raw top-left ends up bottom-left', () {
      final f = coordFrame(w, h, 270);
      expect(rawAtUpright(f, 0, w - 1), (0, 0));
      expect(rawAtUpright(f, h - 1, w - 1), (0, h - 1));
      expect(rawAtUpright(f, 0, 0), (w - 1, 0));
    });

    test('every rotation is a bijection over the frame', () {
      for (final r in [0, 90, 180, 270]) {
        final f = coordFrame(w, h, r);
        final seen = <(int, int)>{};
        for (var v = 0; v < f.uprightHeight; v++) {
          for (var u = 0; u < f.uprightWidth; u++) {
            seen.add(rawAtUpright(f, u, v));
          }
        }
        expect(seen.length, w * h, reason: 'rotation $r');
      }
    });
  });

  group('pixel formats', () {
    test('BGRA honours row padding', () {
      final f = coordFrame(w, h, 0, padding: 16);
      expect(rawAtUpright(f, 5, 3), (5, 3));
    });

    test('NV21 neutral chroma gives grey', () {
      const fw = 4, fh = 4;
      final bytes = Uint8List(fw * fh * 3 ~/ 2)..fillRange(0, fw * fh, 100);
      bytes.fillRange(fw * fh, bytes.length, 128);
      final f = Frame(
        format: FrameFormat.nv21,
        width: fw,
        height: fh,
        bytes: bytes,
        bytesPerRow: fw,
        rotationDegrees: 0,
      );
      final px = Float32List(3);
      f.readRgb(1, 1, px, 0);
      expect(px, [100, 100, 100]);
    });

    test('NV21 strong V (Cr) is red', () {
      const fw = 2, fh = 2;
      final bytes = Uint8List.fromList([80, 80, 80, 80, /* V */ 240, /* U */ 90]);
      final f = Frame(
        format: FrameFormat.nv21,
        width: fw,
        height: fh,
        bytes: bytes,
        bytesPerRow: fw,
        rotationDegrees: 0,
      );
      final px = Float32List(3);
      f.readRgb(0, 0, px, 0);
      expect(px[0], greaterThan(200));
      expect(px[1], lessThan(40));
      expect(px[2], lessThan(40));
    });

    test('NV21 with padded rows uses bytesPerRow', () {
      const fw = 2, fh = 2, stride = 8;
      final bytes = Uint8List(stride * fh + stride * 1);
      bytes[stride + 1] = 200; // Y at (1, 1)
      bytes.fillRange(stride * fh, bytes.length, 128);
      final f = Frame(
        format: FrameFormat.nv21,
        width: fw,
        height: fh,
        bytes: bytes,
        bytesPerRow: stride,
        rotationDegrees: 0,
      );
      final px = Float32List(3);
      f.readRgb(1, 1, px, 0);
      expect(px[0], 200);
    });

    test('rejects a truncated buffer', () {
      expect(
        () => Frame(
          format: FrameFormat.bgra8888,
          width: 10,
          height: 10,
          bytes: Uint8List(10),
          bytesPerRow: 40,
          rotationDegrees: 0,
        ),
        throwsArgumentError,
      );
    });
  });

  group('extractCrop', () {
    test('expandToSquare centres a square of the requested scale', () {
      final s = expandToSquare(const BoxF(10, 20, 30, 60), 1.5);
      expect(s.width, 60);
      expect(s.height, 60);
      expect(s.centerX, 20);
      expect(s.centerY, 40);
    });

    test('crop is upright for a rotated frame', () {
      final f = coordFrame(8, 8, 90);
      // Whole frame, one output pixel per input pixel.
      final out = extractCrop(f, const BoxF(0, 0, 8, 8), 8);
      // Output pixel (u=7, v=0) must be raw (0, 0); (u=0, v=0) raw (0, 7).
      expect([out[(0 * 8 + 7) * 3], out[(0 * 8 + 7) * 3 + 1]], [0, 0]);
      expect([out[0], out[1]], [0, 7]);
    });

    test('down-scaling averages neighbouring pixels', () {
      final f = coordFrame(8, 8, 0);
      final out = extractCrop(f, const BoxF(0, 0, 8, 8), 4);
      // First output pixel averages raw x in {0, 1} -> 0.5.
      expect(out[0], closeTo(0.5, 1e-6));
      expect(out.length, 4 * 4 * 3);
    });

    test('regions outside the frame repeat edge pixels', () {
      final f = coordFrame(4, 4, 0);
      final out = extractCrop(f, const BoxF(-4, -4, 0, 0), 2);
      expect(out.every((v) => v == 0 || v == 0.0), isTrue);
    });
  });
}
