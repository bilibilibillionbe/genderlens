// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'GenderLens';

  @override
  String get consentTitle => 'Before you start';

  @override
  String get consentIntro =>
      'GenderLens uses AI to estimate whether a face in the camera looks male or female. Please read how it works:';

  @override
  String get consentOnDevice =>
      'Everything runs on your device. Camera images are analysed in memory and are never saved, uploaded or shared. The app has no internet access.';

  @override
  String get consentEstimate =>
      'Results are an estimate of appearance only. They can be wrong and say nothing about a person\'s gender identity.';

  @override
  String get consentPeople =>
      'Only scan people who have agreed to it. Do not use the app to identify, judge or discriminate against anyone.';

  @override
  String get consentPurpose =>
      'The app is intended for entertainment and is not suitable for important decisions.';

  @override
  String get consentCheckbox => 'I have read and agree to the Privacy Policy and Terms of Use';

  @override
  String get consentContinue => 'Agree and continue';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get labelFemale => 'Female';

  @override
  String get labelMale => 'Male';

  @override
  String get labelUncertain => 'Not sure';

  @override
  String get labelAnalysing => 'Analysing…';

  @override
  String get labelPoorView => 'Face the camera';

  @override
  String confidence(int percent) {
    return '$percent%';
  }

  @override
  String get scanHint => 'Point the camera at a face';

  @override
  String get disclaimerBanner => 'AI estimate of appearance · processed on device';

  @override
  String get switchCamera => 'Switch camera';

  @override
  String get settings => 'Settings';

  @override
  String get cameraPermissionTitle => 'Camera access needed';

  @override
  String get cameraPermissionBody =>
      'GenderLens needs the camera to see faces. Images never leave your device. You can allow access in system settings.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get retry => 'Try again';

  @override
  String get noCamera => 'No camera was found on this device.';

  @override
  String get cameraError => 'The camera could not be started.';

  @override
  String get modelErrorTitle => 'Model unavailable';

  @override
  String get modelMissing => 'The recognition model is missing from this build.';

  @override
  String get modelInvalid => 'The recognition model is damaged or incompatible.';

  @override
  String get modelNotReleaseReady => 'This build contains a test model that is not suitable for use.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAbout => 'About';

  @override
  String get sectionPrivacy => 'Privacy';

  @override
  String get appVersion => 'App version';

  @override
  String get modelVersion => 'Model version';

  @override
  String get howItWorks => 'How it works';

  @override
  String howItWorksBody(int percent) {
    return 'A face detector finds faces in the camera image. Each face is cropped and passed to a small neural network that runs on your phone. The network outputs a probability, which is averaged over several frames. When it is below $percent% either way, the app shows \"Not sure\".\n\nThe network was trained on FairFace, a public dataset balanced across ethnic groups, ages and genders (CC BY 4.0). Accuracy is lower for children, poor lighting, heavy make-up, masks and faces seen from the side.';
  }

  @override
  String get openSourceLicenses => 'Open-source licences';

  @override
  String get withdrawConsent => 'Withdraw consent';

  @override
  String get withdrawConsentBody => 'The app will stop using the camera and show the consent screen again.';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'Confirm';

  @override
  String get dataNotCollected => 'No data collected';

  @override
  String get dataNotCollectedBody =>
      'No images, results, identifiers or analytics are stored or transmitted.';
}
