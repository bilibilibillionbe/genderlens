import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];

  /// App name shown in the app bar and task switcher.
  ///
  /// In en, this message translates to:
  /// **'GenderLens'**
  String get appTitle;

  /// No description provided for @consentTitle.
  ///
  /// In en, this message translates to:
  /// **'Before you start'**
  String get consentTitle;

  /// No description provided for @consentIntro.
  ///
  /// In en, this message translates to:
  /// **'GenderLens uses AI to estimate whether a face in the camera looks male or female. Please read how it works:'**
  String get consentIntro;

  /// No description provided for @consentOnDevice.
  ///
  /// In en, this message translates to:
  /// **'Everything runs on your device. Camera images are analysed in memory and are never saved, uploaded or shared. The app has no internet access.'**
  String get consentOnDevice;

  /// No description provided for @consentEstimate.
  ///
  /// In en, this message translates to:
  /// **'Results are an estimate of appearance only. They can be wrong and say nothing about a person\'s gender identity.'**
  String get consentEstimate;

  /// No description provided for @consentPeople.
  ///
  /// In en, this message translates to:
  /// **'Only scan people who have agreed to it. Do not use the app to identify, judge or discriminate against anyone.'**
  String get consentPeople;

  /// No description provided for @consentPurpose.
  ///
  /// In en, this message translates to:
  /// **'The app is intended for entertainment and is not suitable for important decisions.'**
  String get consentPurpose;

  /// No description provided for @consentCheckbox.
  ///
  /// In en, this message translates to:
  /// **'I have read and agree to the Privacy Policy and Terms of Use'**
  String get consentCheckbox;

  /// No description provided for @consentContinue.
  ///
  /// In en, this message translates to:
  /// **'Agree and continue'**
  String get consentContinue;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @labelFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get labelFemale;

  /// No description provided for @labelMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get labelMale;

  /// No description provided for @labelUncertain.
  ///
  /// In en, this message translates to:
  /// **'Not sure'**
  String get labelUncertain;

  /// No description provided for @labelAnalysing.
  ///
  /// In en, this message translates to:
  /// **'Analysing…'**
  String get labelAnalysing;

  /// No description provided for @labelPoorView.
  ///
  /// In en, this message translates to:
  /// **'Face the camera'**
  String get labelPoorView;

  /// No description provided for @confidence.
  ///
  /// In en, this message translates to:
  /// **'{percent}%'**
  String confidence(int percent);

  /// No description provided for @scanHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a face'**
  String get scanHint;

  /// No description provided for @disclaimerBanner.
  ///
  /// In en, this message translates to:
  /// **'AI estimate of appearance · processed on device'**
  String get disclaimerBanner;

  /// No description provided for @switchCamera.
  ///
  /// In en, this message translates to:
  /// **'Switch camera'**
  String get switchCamera;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @cameraPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Camera access needed'**
  String get cameraPermissionTitle;

  /// No description provided for @cameraPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'GenderLens needs the camera to see faces. Images never leave your device. You can allow access in system settings.'**
  String get cameraPermissionBody;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @noCamera.
  ///
  /// In en, this message translates to:
  /// **'No camera was found on this device.'**
  String get noCamera;

  /// No description provided for @cameraError.
  ///
  /// In en, this message translates to:
  /// **'The camera could not be started.'**
  String get cameraError;

  /// No description provided for @modelErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Model unavailable'**
  String get modelErrorTitle;

  /// No description provided for @modelMissing.
  ///
  /// In en, this message translates to:
  /// **'The recognition model is missing from this build.'**
  String get modelMissing;

  /// No description provided for @modelInvalid.
  ///
  /// In en, this message translates to:
  /// **'The recognition model is damaged or incompatible.'**
  String get modelInvalid;

  /// No description provided for @modelNotReleaseReady.
  ///
  /// In en, this message translates to:
  /// **'This build contains a test model that is not suitable for use.'**
  String get modelNotReleaseReady;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @sectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get sectionAbout;

  /// No description provided for @sectionPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get sectionPrivacy;

  /// No description provided for @appVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get appVersion;

  /// No description provided for @modelVersion.
  ///
  /// In en, this message translates to:
  /// **'Model version'**
  String get modelVersion;

  /// No description provided for @howItWorks.
  ///
  /// In en, this message translates to:
  /// **'How it works'**
  String get howItWorks;

  /// No description provided for @howItWorksBody.
  ///
  /// In en, this message translates to:
  /// **'A face detector finds faces in the camera image. Each face is cropped and passed to a small neural network that runs on your phone. The network outputs a probability, which is averaged over several frames. When it is below {percent}% either way, the app shows \"Not sure\".\n\nThe network was trained on FairFace, a public dataset balanced across ethnic groups, ages and genders (CC BY 4.0). Accuracy is lower for children, poor lighting, heavy make-up, masks and faces seen from the side.'**
  String howItWorksBody(int percent);

  /// No description provided for @openSourceLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get openSourceLicenses;

  /// No description provided for @withdrawConsent.
  ///
  /// In en, this message translates to:
  /// **'Withdraw consent'**
  String get withdrawConsent;

  /// No description provided for @withdrawConsentBody.
  ///
  /// In en, this message translates to:
  /// **'The app will stop using the camera and show the consent screen again.'**
  String get withdrawConsentBody;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @dataNotCollected.
  ///
  /// In en, this message translates to:
  /// **'No data collected'**
  String get dataNotCollected;

  /// No description provided for @dataNotCollectedBody.
  ///
  /// In en, this message translates to:
  /// **'No images, results, identifiers or analytics are stored or transmitted.'**
  String get dataNotCollectedBody;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh':
      {
        switch (locale.scriptCode) {
          case 'Hant':
            return AppLocalizationsZhHant();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
