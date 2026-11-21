import 'package:material_ui/material_ui.dart';

import 'package:package_info_plus/package_info_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../services/settings_store.dart';
import '../legal/legal_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({
    super.key,
    required this.settings,
    required this.modelVersion,
    required this.uncertainBelow,
  });

  final SettingsStore settings;
  final String modelVersion;
  final double uncertainBelow;

  Future<void> _withdraw(BuildContext context) async {
    final l = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(l.withdrawConsent),
        content: Text(l.withdrawConsentBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: Text(l.cancel)),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: Text(l.confirm)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).popUntil((r) => r.isFirst);
    await settings.withdrawConsent();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    Widget header(String s) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(s, style: t.labelLarge?.copyWith(color: Theme.of(context).colorScheme.primary)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settingsTitle)),
      body: ListView(
        children: [
          header(l.sectionPrivacy),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: Text(l.dataNotCollected),
            subtitle: Text(l.dataNotCollectedBody),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: Text(l.privacyPolicy),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => LegalScreen.open(context, LegalDocument.privacy),
          ),
          ListTile(
            leading: const Icon(Icons.gavel_outlined),
            title: Text(l.termsOfUse),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => LegalScreen.open(context, LegalDocument.terms),
          ),
          ListTile(
            key: const Key('withdraw-consent'),
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text(l.withdrawConsent, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => _withdraw(context),
          ),
          header(l.sectionAbout),
          ExpansionTile(
            leading: const Icon(Icons.psychology_outlined),
            title: Text(l.howItWorks),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            children: [Text(l.howItWorksBody((uncertainBelow * 100).round()))],
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(l.appVersion),
            trailing: FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (_, s) => Text(s.hasData ? '${s.data!.version} (${s.data!.buildNumber})' : ''),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.memory),
            title: Text(l.modelVersion),
            trailing: Text(modelVersion),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l.openSourceLicenses),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(context: context, applicationName: l.appTitle),
          ),
        ],
      ),
    );
  }
}
