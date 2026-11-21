import 'package:material_ui/material_ui.dart';

import 'features/consent/consent_screen.dart';
import 'features/scanner/scanner_screen.dart';
import 'l10n/app_localizations.dart';
import 'services/settings_store.dart';
import 'theme.dart';

class GenderLensApp extends StatelessWidget {
  const GenderLensApp({super.key, required this.settings, this.scannerBuilder});

  final SettingsStore settings;

  /// Test hook: replaces the camera screen.
  final WidgetBuilder? scannerBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: settings,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (c) => AppLocalizations.of(c).appTitle,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Without this, zh_TW / zh_HK would resolve to Simplified Chinese.
        localeResolutionCallback: resolveLocale,
        home: settings.hasConsented
            ? (scannerBuilder?.call(context) ?? ScannerScreen(settings: settings))
            : ConsentScreen(settings: settings),
      ),
    );
  }
}

Locale resolveLocale(Locale? device, Iterable<Locale> supported) {
  if (device == null) return const Locale('en');
  if (device.languageCode == 'zh') {
    final traditional = device.scriptCode == 'Hant' || const {'TW', 'HK', 'MO'}.contains(device.countryCode);
    return traditional
        ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
        : const Locale('zh');
  }
  for (final l in supported) {
    if (l.languageCode == device.languageCode) return l;
  }
  return const Locale('en');
}

/// Asset suffix for the legal documents in assets/legal/.
String legalLanguage(Locale locale) {
  if (locale.languageCode != 'zh') return 'en';
  return locale.scriptCode == 'Hant' ? 'zh_Hant' : 'zh';
}
