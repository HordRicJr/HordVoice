import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('fr'),
    Locale('en'),
    Locale('es'),
    Locale('de'),
    Locale('ar'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HordVoice'**
  String get appTitle;

  /// No description provided for @initializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing HordVoice...'**
  String get initializing;

  /// No description provided for @environmentConfig.
  ///
  /// In en, this message translates to:
  /// **'Configuring environment...'**
  String get environmentConfig;

  /// No description provided for @dbInitializing.
  ///
  /// In en, this message translates to:
  /// **'Initializing database...'**
  String get dbInitializing;

  /// No description provided for @authChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking authentication...'**
  String get authChecking;

  /// No description provided for @permissionsChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking permissions...'**
  String get permissionsChecking;

  /// No description provided for @finalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing...'**
  String get finalizing;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to HordVoice'**
  String get homeWelcome;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @selectLanguage.
  ///
  /// In en, this message translates to:
  /// **'Select language'**
  String get selectLanguage;

  /// No description provided for @langEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get langEnglish;

  /// No description provided for @langFrench.
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get langFrench;

  /// No description provided for @langSpanish.
  ///
  /// In en, this message translates to:
  /// **'Spanish'**
  String get langSpanish;

  /// No description provided for @langGerman.
  ///
  /// In en, this message translates to:
  /// **'German'**
  String get langGerman;

  /// No description provided for @langArabic.
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get langArabic;

  /// No description provided for @listenHint.
  ///
  /// In en, this message translates to:
  /// **'Say \'Hey Ric\' to start listening'**
  String get listenHint;

  /// No description provided for @errorInitialization.
  ///
  /// In en, this message translates to:
  /// **'Error during initialization: {error}'**
  String errorInitialization(Object error);

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @preparingInterface.
  ///
  /// In en, this message translates to:
  /// **'Preparing interface...'**
  String get preparingInterface;

  /// No description provided for @readyInitializingBackground.
  ///
  /// In en, this message translates to:
  /// **'Ready! Initializing in background...'**
  String get readyInitializingBackground;

  /// No description provided for @interfaceReadyDegraded.
  ///
  /// In en, this message translates to:
  /// **'Interface ready (degraded mode)'**
  String get interfaceReadyDegraded;

  /// No description provided for @ricIsListening.
  ///
  /// In en, this message translates to:
  /// **'Ric is listening from the spatial universe...'**
  String get ricIsListening;

  /// No description provided for @spatialProcessing.
  ///
  /// In en, this message translates to:
  /// **'Processing in spatial universe...'**
  String get spatialProcessing;

  /// No description provided for @spatialReady.
  ///
  /// In en, this message translates to:
  /// **'Ready! Say \'Hey Ric\' in the spatial universe'**
  String get spatialReady;

  /// No description provided for @spatialListeningError.
  ///
  /// In en, this message translates to:
  /// **'Spatial listening error: {error}'**
  String spatialListeningError(Object error);

  /// No description provided for @stopError.
  ///
  /// In en, this message translates to:
  /// **'Stop error: {error}'**
  String stopError(Object error);

  /// No description provided for @ricConnectedSpatial.
  ///
  /// In en, this message translates to:
  /// **'Ric is connected in the spatial universe'**
  String get ricConnectedSpatial;

  /// No description provided for @spatialModeAvailable.
  ///
  /// In en, this message translates to:
  /// **'Spatial mode available'**
  String get spatialModeAvailable;

  /// No description provided for @listeningInSpatial.
  ///
  /// In en, this message translates to:
  /// **'Listening in the spatial universe...'**
  String get listeningInSpatial;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'fr', 'ar', 'de', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
