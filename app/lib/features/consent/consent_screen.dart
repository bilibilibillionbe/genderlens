import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../../services/settings_store.dart';
import '../legal/legal_screen.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key, required this.settings});

  final SettingsStore settings;

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final points = [
      (Icons.phone_iphone, l.consentOnDevice),
      (Icons.info_outline, l.consentEstimate),
      (Icons.handshake_outlined, l.consentPeople),
      (Icons.sentiment_satisfied_alt, l.consentPurpose),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                children: [
                  Icon(Icons.face_retouching_natural, size: 56, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(l.consentTitle, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(l.consentIntro, style: theme.textTheme.bodyLarge),
                  const SizedBox(height: 16),
                  for (final (icon, text) in points)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(icon, color: theme.colorScheme.primary),
                          const SizedBox(width: 16),
                          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => LegalScreen.open(context, LegalDocument.privacy),
                        child: Text(l.privacyPolicy),
                      ),
                      TextButton(
                        onPressed: () => LegalScreen.open(context, LegalDocument.terms),
                        child: Text(l.termsOfUse),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 24, 16),
              child: Column(
                children: [
                  CheckboxListTile(
                    key: const Key('consent-checkbox'),
                    value: _agreed,
                    onChanged: (v) => setState(() => _agreed = v ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(l.consentCheckbox, style: theme.textTheme.bodyMedium),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    key: const Key('consent-continue'),
                    onPressed: _agreed ? widget.settings.giveConsent : null,
                    child: Text(l.consentContinue),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
