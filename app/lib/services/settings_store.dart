import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The only thing the app persists: whether (and to which version of the
/// notice) the user consented. Bump [currentConsentVersion] whenever the
/// consent text or privacy policy changes materially, so users are asked again.
class SettingsStore extends ChangeNotifier {
  SettingsStore(this._prefs);

  static const currentConsentVersion = 1;
  static const _consentKey = 'consent_version';

  final SharedPreferences _prefs;

  bool get hasConsented => (_prefs.getInt(_consentKey) ?? 0) >= currentConsentVersion;

  Future<void> giveConsent() async {
    await _prefs.setInt(_consentKey, currentConsentVersion);
    notifyListeners();
  }

  Future<void> withdrawConsent() async {
    await _prefs.remove(_consentKey);
    notifyListeners();
  }
}
