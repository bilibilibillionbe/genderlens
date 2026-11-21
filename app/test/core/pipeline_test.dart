import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:genderlens/core/classifier.dart';
import 'package:genderlens/core/estimate_tracker.dart';
import 'package:genderlens/core/face_crop.dart';
import 'package:genderlens/core/frame.dart';
import 'package:genderlens/core/model_meta.dart';
import 'package:genderlens/core/pipeline.dart';

class FakeClassifier implements GenderClassifier {
  FakeClassifier(this.pMale);

  final double pMale;
  int calls = 0;
  Float32List? lastInput;

  @override
  final ModelMeta meta = const ModelMeta(
    version: 'test',
    releaseReady: true,
    inputWidth: 16,
    inputHeight: 16,
    inputMin: 0,
    inputMax: 255,
    labels: ['female', 'male'],
    faceCropScale: 1.5,
    uncertainBelow: 0.7,
  );

  @override
  Future<double> predictMale(Float32List rgb255) async {
    calls++;
    lastInput = rgb255;
    return pMale;
  }

  @override
  Future<void> close() async {}
}

Frame greyFrame() => Frame(
  format: FrameFormat.bgra8888,
  width: 640,
  height: 480,
  bytes: Uint8List(640 * 480 * 4)..fillRange(0, 640 * 480 * 4, 120),
  bytesPerRow: 640 * 4,
  rotationDegrees: 90,
);

DetectedFace face(int id, {double size = 200, double? yaw}) =>
    DetectedFace(id: id, box: BoxF(100, 100, 100 + size, 100 + size), yawDegrees: yaw);

void main() {
  test('classifies a face and converges to a label', () async {
    final c = FakeClassifier(0.1);
    final p = FramePipeline(c);
    late List<FaceResult> r;
    for (var t = 0; t < 1000; t += 250) {
      r = await p.process(greyFrame(), [face(1)], t);
    }
    expect(r.single.estimate.state, EstimateState.female);
    expect(c.lastInput!.length, 16 * 16 * 3);
    expect(c.lastInput!.first, 120);
  });

  test('small or turned faces are not classified', () async {
    final c = FakeClassifier(0.9);
    final p = FramePipeline(c);
    final r = await p.process(greyFrame(), [face(1, size: 30), face(2, yaw: 60)], 0);
    expect(r.map((e) => e.estimate.state), everyElement(EstimateState.poorView));
    expect(c.calls, 0);
  });

  test('caps the number of faces, keeping the largest', () async {
    final c = FakeClassifier(0.9);
    final p = FramePipeline(c, maxFaces: 2);
    final r = await p.process(greyFrame(), [face(1, size: 80), face(2, size: 250), face(3, size: 150)], 0);
    expect(r.map((e) => e.face.id), [2, 3]);
    expect(c.calls, 2);
  });

  test('does not reclassify the same face on every frame', () async {
    final c = FakeClassifier(0.9);
    final p = FramePipeline(c);
    await p.process(greyFrame(), [face(1)], 0);
    await p.process(greyFrame(), [face(1)], 50);
    await p.process(greyFrame(), [face(1)], 100);
    expect(c.calls, 1);
  });
}
