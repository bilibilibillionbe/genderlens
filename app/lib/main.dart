import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'services/settings_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  _registerLicenses();
  final prefs = await SharedPreferences.getInstance();
  runApp(GenderLensApp(settings: SettingsStore(prefs)));
}

void _registerLicenses() {
  LicenseRegistry.addLicense(() async* {
    yield const LicenseEntryWithLineBreaks(
      ['FairFace dataset (model training data)'],
      'FairFace: Face Attribute Dataset for Balanced Race, Gender, and Age.\n'
      'Kärkkäinen, K. and Joo, J. (2021), WACV.\n'
      'https://github.com/joojs/fairface\n\n'
      'Licensed under the Creative Commons Attribution 4.0 International '
      'License (CC BY 4.0). https://creativecommons.org/licenses/by/4.0/\n\n'
      'The bundled classifier was trained on this dataset; the dataset '
      'itself is not included in the app.',
    );
    yield const LicenseEntryWithLineBreaks([
      'MobileNetV3 ImageNet weights',
    ], 'Initial weights from Keras Applications (Apache License 2.0).');
  });
}
