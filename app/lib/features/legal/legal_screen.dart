import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../app.dart';
import '../../l10n/app_localizations.dart';

enum LegalDocument { privacy, terms }

/// Shows the bundled privacy policy / terms. The same Markdown files are
/// published on the web for the store listings (see docs/).
class LegalScreen extends StatelessWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  static Future<void> open(BuildContext context, LegalDocument doc) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => LegalScreen(document: doc)));

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final lang = legalLanguage(Localizations.localeOf(context));
    final asset = 'assets/legal/${document.name}_$lang.md';
    return Scaffold(
      appBar: AppBar(title: Text(document == LegalDocument.privacy ? l.privacyPolicy : l.termsOfUse)),
      body: FutureBuilder<String>(
        future: rootBundle.loadString(asset),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          return SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: renderSimpleMarkdown(context, snap.data!),
            ),
          );
        },
      ),
    );
  }
}

/// Minimal Markdown: '#'/'##' headings, '- ' bullets, paragraphs, and
/// **bold** spans. Enough for legal text without another dependency.
List<Widget> renderSimpleMarkdown(BuildContext context, String source) {
  final t = Theme.of(context).textTheme;
  final widgets = <Widget>[];
  final para = <String>[];

  void flush() {
    if (para.isEmpty) return;
    widgets.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text.rich(_inline(para.join(' '), t.bodyMedium!)),
      ),
    );
    para.clear();
  }

  for (final raw in source.split('\n')) {
    final line = raw.trimRight();
    if (line.isEmpty) {
      flush();
    } else if (line.startsWith('## ')) {
      flush();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text(line.substring(3), style: t.titleMedium),
        ),
      );
    } else if (line.startsWith('# ')) {
      flush();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(line.substring(2), style: t.headlineSmall),
        ),
      );
    } else if (line.startsWith('- ')) {
      flush();
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('•  '),
              Expanded(child: Text.rich(_inline(line.substring(2), t.bodyMedium!))),
            ],
          ),
        ),
      );
    } else {
      para.add(line);
    }
  }
  flush();
  return widgets;
}

TextSpan _inline(String text, TextStyle base) {
  final parts = text.split('**');
  return TextSpan(
    style: base,
    children: [
      for (var i = 0; i < parts.length; i++)
        TextSpan(
          text: parts[i],
          style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w700) : null,
        ),
    ],
  );
}
