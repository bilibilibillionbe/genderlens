import 'dart:io';
import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/classifier.dart';
import '../../core/estimate_tracker.dart';
import '../../l10n/app_localizations.dart';
import '../../services/settings_store.dart';
import '../settings/settings_screen.dart';
import 'face_overlay_painter.dart';
import 'scanner_controller.dart';

/// Loads the model, then shows the live scanner.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late Future<GenderClassifier> _model = TfliteGenderClassifier.load();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<GenderClassifier>(
      future: _model,
      builder: (context, snap) {
        if (snap.hasError) {
          return _ModelError(
            error: snap.error!,
            onRetry: () => setState(() => _model = TfliteGenderClassifier.load()),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return _LiveScanner(classifier: snap.data!, settings: widget.settings);
      },
    );
  }
}

class _LiveScanner extends StatefulWidget {
  const _LiveScanner({required this.classifier, required this.settings});

  final GenderClassifier classifier;
  final SettingsStore settings;

  @override
  State<_LiveScanner> createState() => _LiveScannerState();
}

class _LiveScannerState extends State<_LiveScanner> with WidgetsBindingObserver {
  late final ScannerController _c = ScannerController(widget.classifier);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _c.start();
  }

  bool _inSettings = false;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      // Not `inactive`: iOS sends it for the camera permission dialog and for
      // Control Center, and closing the camera there would interrupt start-up.
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _c.pause();
      case AppLifecycleState.resumed:
        if (!_inSettings) _c.start();
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _c.dispose();
    super.dispose();
  }

  Future<void> _openSettings() async {
    _inSettings = true;
    await _c.pause();
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          settings: widget.settings,
          modelVersion: widget.classifier.meta.version,
          uncertainBelow: widget.classifier.meta.uncertainBelow,
        ),
      ),
    );
    _inSettings = false;
    // Consent may have been withdrawn; then this screen is being replaced.
    if (mounted && widget.settings.hasConsented) await _c.start();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(l.appTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l.settings,
            onPressed: _openSettings,
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _c,
        builder: (context, _) => switch (_c.status) {
          ScannerStatus.running => _buildRunning(context, l),
          ScannerStatus.starting => const Center(child: CircularProgressIndicator()),
          ScannerStatus.permissionDenied => _Message(
            icon: Icons.no_photography_outlined,
            title: l.cameraPermissionTitle,
            body: l.cameraPermissionBody,
            actions: [
              if (Platform.isIOS)
                FilledButton(
                  onPressed: () => launchUrl(Uri.parse('app-settings:')),
                  child: Text(l.openSettings),
                ),
              OutlinedButton(onPressed: _c.start, child: Text(l.retry)),
            ],
          ),
          ScannerStatus.noCamera => _Message(icon: Icons.videocam_off_outlined, body: l.noCamera),
          ScannerStatus.error => _Message(
            icon: Icons.error_outline,
            body: l.cameraError,
            actions: [OutlinedButton(onPressed: _c.start, child: Text(l.retry))],
          ),
        },
      ),
    );
  }

  Widget _buildRunning(BuildContext context, AppLocalizations l) {
    final cam = _c.camera;
    if (cam == null || !cam.value.isInitialized) return const SizedBox.shrink();
    // previewSize is reported in sensor (landscape) orientation.
    final p = cam.value.previewSize!;
    final upright = _c.frameSize ?? Size(math.min(p.width, p.height), math.max(p.width, p.height));
    final results = _c.results;

    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(width: upright.width, height: upright.height, child: CameraPreview(cam)),
          ),
        ),
        CustomPaint(
          painter: FaceOverlayPainter(
            results: results,
            frameSize: upright,
            mirror: _c.isFrontCamera,
            labels: OverlayLabels.of(l),
            textDirection: Directionality.of(context),
          ),
        ),
        Semantics(
          liveRegion: true,
          label: _describe(l, results.map((r) => r.estimate).toList()),
          child: const SizedBox.expand(),
        ),
        SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (results.isEmpty) _Pill(text: l.scanHint, strong: true),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _Pill(text: l.disclaimerBanner)),
                      if (_c.canSwitchCamera) ...[
                        const SizedBox(width: 12),
                        IconButton.filledTonal(
                          iconSize: 28,
                          tooltip: l.switchCamera,
                          onPressed: _c.switchCamera,
                          icon: const Icon(Icons.cameraswitch_outlined),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _describe(AppLocalizations l, List<FaceEstimate> estimates) {
    if (estimates.isEmpty) return l.scanHint;
    final labels = OverlayLabels.of(l);
    return estimates.map(labels.textFor).join(', ');
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, this.strong = false});

  final String text;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: strong ? 16 : 13,
            fontWeight: strong ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, this.title, required this.body, this.actions = const []});

  final IconData icon;
  final String? title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.white70),
            const SizedBox(height: 16),
            if (title != null) ...[
              Text(
                title!,
                style: t.titleLarge?.copyWith(color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],
            Text(
              body,
              style: t.bodyMedium?.copyWith(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            for (final a in actions) Padding(padding: const EdgeInsets.only(bottom: 8), child: a),
          ],
        ),
      ),
    );
  }
}

class _ModelError extends StatelessWidget {
  const _ModelError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final reason = error is ModelLoadException
        ? (error as ModelLoadException).reason
        : ModelLoadReason.invalid;
    final body = switch (reason) {
      ModelLoadReason.missing => l.modelMissing,
      ModelLoadReason.invalid => l.modelInvalid,
      ModelLoadReason.notReleaseReady => l.modelNotReleaseReady,
    };
    return Scaffold(
      appBar: AppBar(title: Text(l.appTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.memory, size: 56),
              const SizedBox(height: 16),
              Text(l.modelErrorTitle, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              OutlinedButton(onPressed: onRetry, child: Text(l.retry)),
            ],
          ),
        ),
      ),
    );
  }
}
