import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../core/classifier.dart';
import '../../core/face_crop.dart';
import '../../core/frame.dart';
import '../../core/pipeline.dart';

enum ScannerStatus { starting, running, permissionDenied, noCamera, error }

/// Owns the camera, the face detector and the pipeline. Nothing it handles
/// (frames, crops, results) is written to disk or sent anywhere.
class ScannerController extends ChangeNotifier {
  ScannerController(this._classifier) : _pipeline = FramePipeline(_classifier);

  final GenderClassifier _classifier;
  final FramePipeline _pipeline;
  final FaceDetector _detector = FaceDetector(
    options: FaceDetectorOptions(
      enableTracking: true,
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.08,
    ),
  );

  CameraController? camera;
  List<CameraDescription> _cameras = const [];
  int _cameraIndex = 0;
  ScannerStatus status = ScannerStatus.starting;
  Object? lastError;

  /// Faces of the most recent processed frame, in upright frame coordinates.
  List<FaceResult> results = const [];

  /// Upright size of the frames being analysed (what [results] refer to).
  Size? frameSize;

  bool _busy = false;
  bool _disposed = false;
  _IouTracker _fallbackIds = _IouTracker();

  /// What the UI wants. Camera operations run one at a time on [_ops] and
  /// converge on this, so overlapping lifecycle events (e.g. iOS pausing the
  /// app for the permission dialog while the camera is initialising) cannot
  /// leave the camera half-open or stuck.
  bool _wantRunning = false;
  Future<void> _ops = Future.value();

  bool get isFrontCamera => camera?.description.lensDirection == CameraLensDirection.front;
  bool get canSwitchCamera => _cameras.length > 1;

  /// Opens the camera (or retries after an error).
  Future<void> start() {
    _wantRunning = true;
    return _enqueue(_reconcile);
  }

  /// Releases the camera so other apps can use it and the privacy indicator
  /// turns off. Call when the app is backgrounded or another page is shown.
  Future<void> pause() {
    _wantRunning = false;
    return _enqueue(_reconcile);
  }

  Future<void> switchCamera() => _enqueue(() async {
    if (!_wantRunning || !canSwitchCamera || _disposed) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    await _closeCamera();
    await _reconcile();
  });

  Future<void> _enqueue(Future<void> Function() op) {
    final next = _ops.then((_) => op());
    _ops = next.catchError((Object e) {
      if (kDebugMode) debugPrint('camera op failed: $e');
    });
    return _ops;
  }

  Future<void> _reconcile() async {
    if (_disposed) return;
    if (!_wantRunning) {
      await _closeCamera();
      if (status == ScannerStatus.running) _set(ScannerStatus.starting);
      return;
    }
    if (camera != null) return; // already running
    try {
      if (_cameras.isEmpty) {
        _cameras = await availableCameras();
        if (_cameras.isEmpty) {
          _set(ScannerStatus.noCamera);
          return;
        }
        final front = _cameras.indexWhere((c) => c.lensDirection == CameraLensDirection.front);
        _cameraIndex = front >= 0 ? front : 0;
      }
      _set(ScannerStatus.starting);
      await _open(_cameras[_cameraIndex]);
    } on CameraException catch (e) {
      lastError = e;
      await _closeCamera();
      _set(_isPermissionError(e.code) ? ScannerStatus.permissionDenied : ScannerStatus.error);
    } catch (e) {
      lastError = e;
      await _closeCamera();
      _set(ScannerStatus.error);
    }
  }

  static bool _isPermissionError(String code) => const {
    'CameraAccessDenied',
    'CameraAccessDeniedWithoutPrompt',
    'CameraAccessRestricted',
    'cameraPermission',
  }.contains(code);

  Future<void> _open(CameraDescription description) async {
    final c = CameraController(
      description,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid ? ImageFormatGroup.nv21 : ImageFormatGroup.bgra8888,
    );
    camera = c;
    await c.initialize();
    await c.lockCaptureOrientation(DeviceOrientation.portraitUp);
    await c.startImageStream(_onFrame);
    await WakelockPlus.enable();
    _set(ScannerStatus.running);
  }

  Future<void> _closeCamera() async {
    final c = camera;
    camera = null;
    results = const [];
    frameSize = null;
    _pipeline.tracker.clear();
    _fallbackIds = _IouTracker();
    if (c == null) return;
    await WakelockPlus.disable();
    try {
      if (c.value.isStreamingImages) await c.stopImageStream();
    } catch (_) {}
    await c.dispose();
  }

  Future<void> _onFrame(CameraImage image) async {
    if (_busy || _disposed) return;
    final c = camera;
    if (c == null) return;
    _busy = true;
    try {
      final rotation = _rotationFor(c);
      final frame = _toFrame(image, rotation);
      if (frame == null) return;
      final input = InputImage.fromBytes(
        bytes: frame.bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(rotation) ?? InputImageRotation.rotation0deg,
          format: Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
      final faces = await _detector.processImage(input);
      final now = DateTime.now().millisecondsSinceEpoch;
      final detected = [
        for (final f in faces)
          DetectedFace(
            id: f.trackingId ?? _fallbackIds.idFor(f.boundingBox),
            box: BoxF(f.boundingBox.left, f.boundingBox.top, f.boundingBox.right, f.boundingBox.bottom),
            yawDegrees: f.headEulerAngleY,
            rollDegrees: f.headEulerAngleZ,
          ),
      ];
      _fallbackIds.endFrame();
      final out = await _pipeline.process(frame, detected, now);
      if (_disposed || camera != c) return;
      results = out;
      frameSize = Size(frame.uprightWidth.toDouble(), frame.uprightHeight.toDouble());
      notifyListeners();
    } catch (e, st) {
      // A single bad frame must not kill the stream.
      if (kDebugMode) debugPrint('frame error: $e\n$st');
    } finally {
      _busy = false;
    }
  }

  static const _deviceDegrees = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  /// Clockwise rotation that makes the raw frame upright.
  static int _rotationFor(CameraController c) {
    final sensor = c.description.sensorOrientation;
    if (Platform.isIOS) return sensor;
    final device = _deviceDegrees[c.value.deviceOrientation] ?? 0;
    return c.description.lensDirection == CameraLensDirection.front
        ? (sensor + device) % 360
        : (sensor - device + 360) % 360;
  }

  static Frame? _toFrame(CameraImage image, int rotation) {
    if (image.planes.length != 1) return null; // nv21 / bgra are single-plane
    final plane = image.planes.first;
    final format = switch (image.format.group) {
      ImageFormatGroup.nv21 => FrameFormat.nv21,
      ImageFormatGroup.bgra8888 => FrameFormat.bgra8888,
      _ => null,
    };
    if (format == null) return null;
    return Frame(
      format: format,
      width: image.width,
      height: image.height,
      bytes: plane.bytes,
      bytesPerRow: plane.bytesPerRow,
      rotationDegrees: rotation,
    );
  }

  void _set(ScannerStatus s) {
    if (_disposed) return;
    status = s;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _wantRunning = false;
    // Queue behind any in-flight open so the camera is never leaked.
    unawaited(
      _ops.then((_) async {
        await _closeCamera();
        await _detector.close();
        await _classifier.close();
      }),
    );
    super.dispose();
  }
}

/// Assigns stable ids by box overlap when the detector gives no tracking id.
class _IouTracker {
  final Map<int, Rect> _prev = {};
  final Map<int, Rect> _cur = {};
  int _next = 1 << 30;

  int idFor(Rect box) {
    var best = -1;
    var bestIou = 0.3;
    _prev.forEach((id, r) {
      final iou = _iou(r, box);
      if (iou > bestIou && !_cur.containsKey(id)) {
        best = id;
        bestIou = iou;
      }
    });
    final id = best >= 0 ? best : _next++;
    _cur[id] = box;
    return id;
  }

  void endFrame() {
    _prev
      ..clear()
      ..addAll(_cur);
    _cur.clear();
  }

  static double _iou(Rect a, Rect b) {
    final i = a.intersect(b);
    if (i.width <= 0 || i.height <= 0) return 0;
    final inter = i.width * i.height;
    return inter / (a.width * a.height + b.width * b.height - inter);
  }
}
