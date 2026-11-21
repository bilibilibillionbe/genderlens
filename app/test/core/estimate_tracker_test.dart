import 'package:flutter_test/flutter_test.dart';
import 'package:genderlens/core/estimate_tracker.dart';

void main() {
  EstimateTracker tracker() => EstimateTracker(uncertainBelow: 0.7, minObservations: 3);

  test('shows analysing until enough observations', () {
    final t = tracker();
    t.addObservation(1, 0.95, 0);
    t.addObservation(1, 0.95, 300);
    expect(t.estimate(1).state, EstimateState.analysing);
    t.addObservation(1, 0.95, 600);
    final e = t.estimate(1);
    expect(e.state, EstimateState.male);
    expect(e.confidence, closeTo(0.95, 1e-9));
  });

  test('female when p(male) is low, with confidence 1 - p', () {
    final t = tracker();
    for (var i = 0; i < 3; i++) {
      t.addObservation(7, 0.1, i * 300);
    }
    expect(t.estimate(7).state, EstimateState.female);
    expect(t.estimate(7).confidence, closeTo(0.9, 1e-9));
  });

  test('uncertain near 0.5', () {
    final t = tracker();
    for (var i = 0; i < 3; i++) {
      t.addObservation(1, 0.6, i * 300);
    }
    expect(t.estimate(1).state, EstimateState.uncertain);
    expect(t.estimate(1).confidence, isNull);
  });

  test('a single outlier frame does not flip a stable estimate', () {
    final t = tracker();
    for (var i = 0; i < 5; i++) {
      t.addObservation(1, 0.05, i * 300);
    }
    t.addObservation(1, 0.99, 1500);
    expect(t.estimate(1).state, isNot(EstimateState.male));
  });

  test('reclassification is throttled per face', () {
    final t = EstimateTracker(uncertainBelow: 0.7, reclassifyEveryMs: 200);
    expect(t.needsClassification(1, 0), isTrue);
    t.addObservation(1, 0.5, 0);
    expect(t.needsClassification(1, 100), isFalse);
    expect(t.needsClassification(1, 200), isTrue);
    expect(t.needsClassification(2, 100), isTrue);
  });

  test('faces not seen recently are forgotten', () {
    final t = EstimateTracker(uncertainBelow: 0.7, forgetAfterMs: 1000);
    t.addObservation(1, 0.9, 0);
    t.addObservation(2, 0.9, 0);
    t.markSeen(2, 900);
    t.prune(1500);
    expect(t.trackCount, 1);
    expect(t.estimate(1).state, EstimateState.analysing);
  });
}
