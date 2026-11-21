import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'model_meta.dart';

const modelAsset = 'assets/models/gender_classifier.tflite';
const metaAsset = 'assets/models/model_meta.json';

/// Returns p(male) for one face crop (size x size x 3, RGB, 0..255).
abstract class GenderClassifier {
  ModelMeta get meta;

  Future<double> predictMale(Float32List rgb255);

  Future<void> close();
}

class ModelLoadException implements Exception {
  ModelLoadException(this.reason, [this.cause]);

  final ModelLoadReason reason;
  final Object? cause;

  @override
  String toString() => 'ModelLoadException($reason, $cause)';
}

enum ModelLoadReason { missing, invalid, notReleaseReady }

/// TFLite implementation. Inference runs on a background isolate so the
/// camera preview never stutters.
class TfliteGenderClassifier implements GenderClassifier {
  TfliteGenderClassifier._(this.meta, this._interpreter, this._isolate);

  static Future<TfliteGenderClassifier> load({AssetBundle? bundle}) async {
    final b = bundle ?? rootBundle;
    final ModelMeta meta;
    final ByteData model;
    try {
      meta = ModelMeta.parse(await b.loadString(metaAsset));
      model = await b.load(modelAsset);
    } on FormatException catch (e) {
      throw ModelLoadException(ModelLoadReason.invalid, e);
    } catch (e) {
      throw ModelLoadException(ModelLoadReason.missing, e);
    }
    // Pipeline smoke-test exports are untrained; never ship one by accident.
    if (kReleaseMode && !meta.releaseReady) {
      throw ModelLoadException(ModelLoadReason.notReleaseReady);
    }

    final Interpreter interpreter;
    try {
      interpreter = Interpreter.fromBuffer(
        model.buffer.asUint8List(model.offsetInBytes, model.lengthInBytes),
        options: InterpreterOptions()..threads = 2,
      );
    } catch (e) {
      throw ModelLoadException(ModelLoadReason.invalid, e);
    }
    final shape = interpreter.getInputTensor(0).shape;
    final outShape = interpreter.getOutputTensor(0).shape;
    if (shape.length != 4 ||
        shape[1] != meta.inputHeight ||
        shape[2] != meta.inputWidth ||
        shape[3] != 3 ||
        outShape.last != 2) {
      interpreter.close();
      throw ModelLoadException(ModelLoadReason.invalid, 'tensor shapes $shape -> $outShape');
    }
    final isolate = await IsolateInterpreter.create(address: interpreter.address);
    return TfliteGenderClassifier._(meta, interpreter, isolate);
  }

  @override
  final ModelMeta meta;
  final Interpreter _interpreter;
  final IsolateInterpreter _isolate;
  Future<void> _queue = Future.value();

  @override
  Future<double> predictMale(Float32List rgb255) {
    // IsolateInterpreter silently drops calls made while it is busy, so
    // serialise them here.
    final result = _queue.then((_) => _run(rgb255));
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<double> _run(Float32List rgb255) async {
    final input = _normalise(rgb255);
    final out = Float32List(2);
    await _isolate.run(input.buffer.asUint8List(), out.buffer);
    return out[meta.maleIndex].toDouble();
  }

  Float32List _normalise(Float32List px) {
    if (meta.inputMin == 0 && meta.inputMax == 255) return px;
    final scale = (meta.inputMax - meta.inputMin) / 255.0;
    final out = Float32List(px.length);
    for (var i = 0; i < px.length; i++) {
      out[i] = meta.inputMin + px[i] * scale;
    }
    return out;
  }

  @override
  Future<void> close() async {
    await _queue;
    await _isolate.close();
    _interpreter.close();
  }
}
