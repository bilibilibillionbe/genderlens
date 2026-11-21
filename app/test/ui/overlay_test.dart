import 'package:flutter_test/flutter_test.dart';
import 'package:genderlens/core/estimate_tracker.dart';
import 'package:genderlens/features/scanner/face_overlay_painter.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  group('CoverTransform', () {
    test('scales to cover and centres the overflow', () {
      // 480x640 frame on a 390x844 screen: height-bound, scale 844/640.
      final t = CoverTransform(const Size(480, 640), const Size(390, 844), mirror: false);
      expect(t.scale, closeTo(844 / 640, 1e-9));
      final full = t.map(const Rect.fromLTWH(0, 0, 480, 640));
      expect(full.top, closeTo(0, 1e-9));
      expect(full.center.dx, closeTo(195, 1e-9));
    });

    test('mirrors horizontally for the front camera', () {
      final t = CoverTransform(const Size(100, 100), const Size(100, 100), mirror: true);
      final r = t.map(const Rect.fromLTRB(10, 20, 30, 40));
      expect(r, const Rect.fromLTRB(70, 20, 90, 40));
    });
  });

  test('labels include rounded confidence', () {
    final labels = OverlayLabels(
      female: 'F',
      male: 'M',
      uncertain: '?',
      analysing: '…',
      poorView: '!',
      percent: (p) => '$p%',
    );
    expect(labels.textFor(const FaceEstimate(EstimateState.male, confidence: 0.876)), 'M 88%');
    expect(labels.textFor(const FaceEstimate(EstimateState.uncertain)), '?');
  });
}
