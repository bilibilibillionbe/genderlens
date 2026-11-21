import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:genderlens/app.dart';
import 'package:genderlens/features/settings/settings_screen.dart';
import 'package:genderlens/services/settings_store.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SettingsStore> store([Map<String, Object> values = const {}]) async {
  SharedPreferences.setMockInitialValues(values);
  return SettingsStore(await SharedPreferences.getInstance());
}

Widget app(SettingsStore s, {Locale locale = const Locale('en')}) => GenderLensApp(
  settings: s,
  scannerBuilder: (_) => Builder(
    builder: (c) => Scaffold(
      body: Column(
        children: [
          const Text('SCANNER'),
          TextButton(
            onPressed: () => Navigator.of(c).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(settings: s, modelVersion: 't', uncertainBelow: 0.7),
              ),
            ),
            child: const Text('open-settings'),
          ),
        ],
      ),
    ),
  ),
);

void main() {
  testWidgets('consent is required before scanning', (tester) async {
    final s = await store();
    await tester.pumpWidget(app(s));
    await tester.pumpAndSettle();

    expect(find.text('SCANNER'), findsNothing);
    final button = find.byKey(const Key('consent-continue'));
    expect(tester.widget<FilledButton>(button).onPressed, isNull);

    await tester.tap(find.byKey(const Key('consent-checkbox')));
    await tester.pump();
    await tester.tap(button);
    await tester.pumpAndSettle();

    expect(find.text('SCANNER'), findsOneWidget);
    expect(s.hasConsented, isTrue);
  });

  testWidgets('withdrawing consent returns to the consent screen', (tester) async {
    final s = await store({'consent_version': SettingsStore.currentConsentVersion});
    await tester.pumpWidget(app(s));
    await tester.pumpAndSettle();
    expect(find.text('SCANNER'), findsOneWidget);

    await tester.tap(find.text('open-settings'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(const Key('withdraw-consent')), 100);
    await tester.tap(find.byKey(const Key('withdraw-consent')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(find.text('SCANNER'), findsNothing);
    expect(find.byKey(const Key('consent-continue')), findsOneWidget);
    expect(s.hasConsented, isFalse);
  });

  testWidgets('older consent version asks again', (tester) async {
    final s = await store({'consent_version': 0});
    expect(s.hasConsented, isFalse);
  });

  testWidgets('privacy policy opens from the consent screen', (tester) async {
    await tester.pumpWidget(app(await store()));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Privacy Policy'), 100);
    await tester.tap(find.text('Privacy Policy'));
    await tester.pumpAndSettle();
    expect(find.textContaining('GenderLens Privacy Policy'), findsOneWidget);
  });

  group('locale resolution', () {
    final supported = [
      const Locale('en'),
      const Locale('zh'),
      const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
    ];
    test('Taiwan and Hong Kong get Traditional Chinese', () {
      expect(resolveLocale(const Locale('zh', 'TW'), supported).scriptCode, 'Hant');
      expect(resolveLocale(const Locale('zh', 'HK'), supported).scriptCode, 'Hant');
      expect(
        resolveLocale(const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'), supported).scriptCode,
        'Hant',
      );
    });
    test('mainland China gets Simplified', () {
      expect(resolveLocale(const Locale('zh', 'CN'), supported), const Locale('zh'));
    });
    test('unsupported languages fall back to English', () {
      expect(resolveLocale(const Locale('fr'), supported), const Locale('en'));
    });
  });

  group('resources', () {
    Map<String, dynamic> arb(String name) =>
        jsonDecode(File('lib/l10n/$name.arb').readAsStringSync()) as Map<String, dynamic>;
    Set<String> keys(Map<String, dynamic> m) => m.keys.where((k) => !k.startsWith('@')).toSet();

    test('every translation has every string', () {
      final en = keys(arb('app_en'));
      for (final lang in ['app_zh', 'app_zh_Hant']) {
        expect(keys(arb(lang)), en, reason: lang);
      }
    });

    test('every language has both legal documents', () {
      for (final doc in ['privacy', 'terms']) {
        for (final lang in ['en', 'zh', 'zh_Hant']) {
          expect(File('assets/legal/${doc}_$lang.md').existsSync(), isTrue, reason: '${doc}_$lang');
        }
      }
    });
  });
}
