import 'dart:convert';

/// Contract between the training pipeline (ml/export_tflite.py) and the app.
class ModelMeta {
  const ModelMeta({
    required this.version,
    required this.releaseReady,
    required this.inputWidth,
    required this.inputHeight,
    required this.inputMin,
    required this.inputMax,
    required this.labels,
    required this.faceCropScale,
    required this.uncertainBelow,
  });

  factory ModelMeta.fromJson(Map<String, dynamic> json) {
    final schema = json['schema'];
    if (schema != 1) {
      throw FormatException('unsupported model_meta schema: $schema');
    }
    final input = json['input'] as Map<String, dynamic>;
    final output = json['output'] as Map<String, dynamic>;
    final range = (input['range'] as List).cast<num>();
    final labels = (output['labels'] as List).cast<String>();
    if (input['channels'] != 3 || input['order'] != 'RGB') {
      throw const FormatException('model must take 3-channel RGB input');
    }
    if (input['width'] != input['height']) {
      throw const FormatException('model input must be square');
    }
    if (output['type'] != 'softmax' ||
        labels.length != 2 ||
        !labels.contains('female') ||
        !labels.contains('male')) {
      throw FormatException('unexpected model output: $output');
    }
    return ModelMeta(
      version: json['version'] as String,
      releaseReady: json['release_ready'] as bool,
      inputWidth: input['width'] as int,
      inputHeight: input['height'] as int,
      inputMin: range[0].toDouble(),
      inputMax: range[1].toDouble(),
      labels: labels,
      faceCropScale: (json['face_crop_scale'] as num).toDouble(),
      uncertainBelow: (json['uncertain_below'] as num).toDouble(),
    );
  }

  factory ModelMeta.parse(String source) => ModelMeta.fromJson(jsonDecode(source) as Map<String, dynamic>);

  final String version;
  final bool releaseReady;
  final int inputWidth;
  final int inputHeight;
  final double inputMin;
  final double inputMax;
  final List<String> labels;
  final double faceCropScale;
  final double uncertainBelow;

  int get maleIndex => labels.indexOf('male');
}
