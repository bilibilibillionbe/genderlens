import 'dart:math' as math;

import 'classifier.dart';
import 'estimate_tracker.dart';
import 'face_crop.dart';
import 'frame.dart';

/// A face as reported by the detector, in upright frame coordinates.
class DetectedFace {
  const DetectedFace({required this.id, required this.box, this.yawDegrees, this.rollDegrees});

  final int id;
  final BoxF box;
  final double? yawDegrees;
  final double? rollDegrees;
}

/// A face plus what to show for it.
class FaceResult {
  const FaceResult(this.face, this.estimate);

  final DetectedFace face;
  final FaceEstimate estimate;
}

/// Detector-agnostic processing of one frame: quality gating, cropping,
/// classification and temporal smoothing.
class FramePipeline {
  FramePipeline(
    this.classifier, {
    this.maxFaces = 5,
    this.minFacePx = 72,
    this.maxYaw = 35,
    this.maxRoll = 30,
    EstimateTracker? tracker,
  }) : tracker = tracker ?? EstimateTracker(uncertainBelow: classifier.meta.uncertainBelow);

  final GenderClassifier classifier;
  final EstimateTracker tracker;
  final int maxFaces;

  /// Faces smaller than this (in upright frame pixels) are too low-res.
  final double minFacePx;
  final double maxYaw;
  final double maxRoll;

  bool _isPoorView(DetectedFace f) =>
      math.min(f.box.width, f.box.height) < minFacePx ||
      (f.yawDegrees?.abs() ?? 0) > maxYaw ||
      (f.rollDegrees?.abs() ?? 0) > maxRoll;

  Future<List<FaceResult>> process(Frame frame, List<DetectedFace> faces, int nowMs) async {
    // Largest faces first: they are the ones the user is pointing at.
    final sorted = [...faces]
      ..sort((a, b) => (b.box.width * b.box.height).compareTo(a.box.width * a.box.height));
    final selected = sorted.take(maxFaces).toList();

    final meta = classifier.meta;
    final results = <FaceResult>[];
    for (final f in selected) {
      tracker.markSeen(f.id, nowMs);
      if (_isPoorView(f)) {
        results.add(FaceResult(f, const FaceEstimate(EstimateState.poorView)));
        continue;
      }
      if (tracker.needsClassification(f.id, nowMs)) {
        final crop = expandToSquare(f.box, meta.faceCropScale);
        final rgb = extractCrop(frame, crop, meta.inputWidth);
        final p = await classifier.predictMale(rgb);
        tracker.addObservation(f.id, p, nowMs);
      }
      results.add(FaceResult(f, tracker.estimate(f.id)));
    }
    tracker.prune(nowMs);
    return results;
  }
}
