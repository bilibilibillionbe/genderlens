import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genderlens/core/model_meta.dart';

Map<String, dynamic> sample() => {
  'schema': 1,
  'name': 'genderlens-gender-classifier',
  'version': '2026.11.21',
  'release_ready': true,
  'input': {
    'width': 224,
    'height': 224,
    'channels': 3,
    'order': 'RGB',
    'range': [0.0, 255.0],
  },
  'output': {
    'type': 'softmax',
    'labels': ['female', 'male'],
  },
  'face_crop_scale': 1.5,
  'uncertain_below': 0.7,
};

void main() {
  // Keeps the Python exporter and the app in sync: the fixture is a real file
  // written by ml/export_tflite.py (via ml/smoke_test.py).
  test('parses a file produced by the training pipeline', () {
    final m = ModelMeta.parse(File('test/fixtures/model_meta_from_pipeline.json').readAsStringSync());
    expect(m.labels, ['female', 'male']);
    expect(m.inputWidth, 224);
    expect(m.releaseReady, isFalse, reason: 'smoke-test export must be flagged');
  });

  test('parses the file written by ml/export_tflite.py', () {
    final m = ModelMeta.parse(jsonEncode(sample()));
    expect(m.inputWidth, 224);
    expect(m.maleIndex, 1);
    expect(m.faceCropScale, 1.5);
    expect(m.releaseReady, isTrue);
  });

  test('label order comes from the file', () {
    final j = sample();
    (j['output'] as Map)['labels'] = ['male', 'female'];
    expect(ModelMeta.fromJson(j).maleIndex, 0);
  });

  test('rejects unknown schema', () {
    expect(() => ModelMeta.fromJson(sample()..['schema'] = 2), throwsFormatException);
  });

  test('rejects unexpected labels', () {
    final j = sample();
    (j['output'] as Map)['labels'] = ['a', 'b'];
    expect(() => ModelMeta.fromJson(j), throwsFormatException);
  });

  test('rejects non-square input', () {
    final j = sample();
    (j['input'] as Map)['height'] = 200;
    expect(() => ModelMeta.fromJson(j), throwsFormatException);
  });
}
