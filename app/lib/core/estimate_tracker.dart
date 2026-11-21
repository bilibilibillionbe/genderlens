/// What the overlay shows for one face.
enum EstimateState {
  /// Not enough observations yet.
  analysing,

  /// The face is too small, turned away or tilted to classify reliably.
  poorView,

  /// The model is not confident either way.
  uncertain,
  female,
  male,
}

class FaceEstimate {
  const FaceEstimate(this.state, {this.confidence});

  final EstimateState state;

  /// Confidence of the displayed label, 0.5..1. Null unless female / male.
  final double? confidence;
}

class _Track {
  _Track(this.pMale, this.lastSeen, this.lastClassified);

  double pMale;
  int observations = 1;
  int lastSeen;
  int lastClassified;
}

/// Temporally smooths per-frame predictions for each tracked face.
///
/// Single frames are noisy (motion blur, a blink, the detector box jumping),
/// so the displayed label is an exponential moving average of p(male) over
/// the face's track, and is only shown once it has [minObservations].
class EstimateTracker {
  EstimateTracker({
    required this.uncertainBelow,
    this.alpha = 0.35,
    this.minObservations = 3,
    this.reclassifyEveryMs = 200,
    this.forgetAfterMs = 1500,
  });

  final double uncertainBelow;
  final double alpha;
  final int minObservations;
  final int reclassifyEveryMs;
  final int forgetAfterMs;

  final Map<int, _Track> _tracks = {};

  /// Whether face [id] is due for a new classification at [nowMs].
  bool needsClassification(int id, int nowMs) {
    final t = _tracks[id];
    return t == null || nowMs - t.lastClassified >= reclassifyEveryMs;
  }

  void markSeen(int id, int nowMs) => _tracks[id]?.lastSeen = nowMs;

  void addObservation(int id, double pMale, int nowMs) {
    final t = _tracks[id];
    if (t == null) {
      _tracks[id] = _Track(pMale, nowMs, nowMs);
      return;
    }
    t
      ..pMale = alpha * pMale + (1 - alpha) * t.pMale
      ..observations += 1
      ..lastSeen = nowMs
      ..lastClassified = nowMs;
  }

  FaceEstimate estimate(int id) {
    final t = _tracks[id];
    if (t == null || t.observations < minObservations) {
      return const FaceEstimate(EstimateState.analysing);
    }
    final male = t.pMale >= 0.5;
    final conf = male ? t.pMale : 1 - t.pMale;
    if (conf < uncertainBelow) return const FaceEstimate(EstimateState.uncertain);
    return FaceEstimate(male ? EstimateState.male : EstimateState.female, confidence: conf);
  }

  /// Drops faces that have not been seen for [forgetAfterMs].
  void prune(int nowMs) => _tracks.removeWhere((_, t) => nowMs - t.lastSeen > forgetAfterMs);

  void clear() => _tracks.clear();

  int get trackCount => _tracks.length;
}
