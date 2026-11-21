import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../core/estimate_tracker.dart';
import '../../core/pipeline.dart';
import '../../l10n/app_localizations.dart';
import '../../theme.dart';

class OverlayLabels {
  const OverlayLabels({
    required this.female,
    required this.male,
    required this.uncertain,
    required this.analysing,
    required this.poorView,
    required this.percent,
  });

  factory OverlayLabels.of(AppLocalizations l) => OverlayLabels(
    female: l.labelFemale,
    male: l.labelMale,
    uncertain: l.labelUncertain,
    analysing: l.labelAnalysing,
    poorView: l.labelPoorView,
    percent: l.confidence,
  );

  final String female, male, uncertain, analysing, poorView;
  final String Function(int) percent;

  String textFor(FaceEstimate e) => switch (e.state) {
    EstimateState.female => '$female ${percent((e.confidence! * 100).round())}',
    EstimateState.male => '$male ${percent((e.confidence! * 100).round())}',
    EstimateState.uncertain => uncertain,
    EstimateState.analysing => analysing,
    EstimateState.poorView => poorView,
  };
}

Color colorFor(EstimateState s) => switch (s) {
  EstimateState.female => femaleColor,
  EstimateState.male => maleColor,
  _ => neutralColor,
};

/// Maps a frame of [frameSize] onto [canvas] the same way BoxFit.cover does,
/// optionally mirrored for the front camera preview.
class CoverTransform {
  CoverTransform(Size frameSize, Size canvas, {required this.mirror})
    : scale = math.max(canvas.width / frameSize.width, canvas.height / frameSize.height),
      _canvasW = canvas.width {
    dx = (canvas.width - frameSize.width * scale) / 2;
    dy = (canvas.height - frameSize.height * scale) / 2;
  }

  final double scale;
  final bool mirror;
  final double _canvasW;
  late final double dx, dy;

  Rect map(Rect r) {
    var l = r.left * scale + dx;
    var rr = r.right * scale + dx;
    if (mirror) (l, rr) = (_canvasW - rr, _canvasW - l);
    return Rect.fromLTRB(l, r.top * scale + dy, rr, r.bottom * scale + dy);
  }
}

class FaceOverlayPainter extends CustomPainter {
  FaceOverlayPainter({
    required this.results,
    required this.frameSize,
    required this.mirror,
    required this.labels,
    required this.textDirection,
  });

  final List<FaceResult> results;
  final Size frameSize;
  final bool mirror;
  final OverlayLabels labels;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final t = CoverTransform(frameSize, size, mirror: mirror);
    for (final r in results) {
      final b = r.face.box;
      final rect = t.map(Rect.fromLTRB(b.left, b.top, b.right, b.bottom));
      final color = colorFor(r.estimate.state);
      final confident = r.estimate.confidence != null;

      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(16)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = confident ? 3 : 2
          ..color = color.withValues(alpha: confident ? 1 : 0.7),
      );

      final tp = TextPainter(
        text: TextSpan(
          text: labels.textFor(r.estimate),
          style: const TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w700),
        ),
        textDirection: textDirection,
        maxLines: 1,
        ellipsis: '…',
      )..layout(maxWidth: math.max(rect.width, 120));
      const pad = EdgeInsets.symmetric(horizontal: 10, vertical: 5);
      final w = tp.width + pad.horizontal;
      final h = tp.height + pad.vertical;
      var left = rect.center.dx - w / 2;
      left = left.clamp(4.0, math.max(4.0, size.width - w - 4));
      var top = rect.top - h - 6;
      if (top < 4) top = rect.bottom + 6; // no room above: put it below
      final chip = Rect.fromLTWH(left, top, w, h);
      canvas.drawRRect(RRect.fromRectAndRadius(chip, Radius.circular(h / 2)), Paint()..color = color);
      tp.paint(canvas, Offset(chip.left + pad.left, chip.top + pad.top));
    }
  }

  @override
  bool shouldRepaint(FaceOverlayPainter old) =>
      old.results != results || old.frameSize != frameSize || old.mirror != mirror;
}
