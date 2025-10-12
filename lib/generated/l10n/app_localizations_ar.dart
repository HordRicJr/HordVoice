// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'HordVoice';

  @override
  String get initializing => 'جارٍ تهيئة HordVoice...';

  @override
  String get environmentConfig => 'جارٍ تكوين البيئة...';

  @override
  String get dbInitializing => 'جارٍ تهيئة قاعدة البيانات...';

  @override
  String get authChecking => 'جارٍ التحقق من المصادقة...';

  @override
  String get permissionsChecking => 'جارٍ التحقق من الأذونات...';

  @override
  String get finalizing => 'جارٍ الإنهاء...';

  @override
  String get homeWelcome => 'مرحبًا بك في HordVoice';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get selectLanguage => 'اختر اللغة';

  @override
  String get langEnglish => 'الإنجليزية';

  @override
  String get langFrench => 'الفرنسية';

  @override
  String get langSpanish => 'الإسبانية';

  @override
  String get langGerman => 'الألمانية';

  @override
  String get langArabic => 'العربية';

  @override
  String get listenHint => 'قل \'Hey Ric\' للبدء بالاستماع';

  @override
  String errorInitialization(Object error) {
    return 'خطأ أثناء التهيئة: $error';
  }

  @override
  String get retry => 'أعد المحاولة';

  @override
  String get preparingInterface => 'Preparing interface...';

  @override
  String get readyInitializingBackground => 'Ready! Initializing in background...';

  @override
  String get interfaceReadyDegraded => 'Interface ready (degraded mode)';

  @override
  String get ricIsListening => 'Ric is listening from the spatial universe...';

  @override
  String get spatialProcessing => 'Processing in spatial universe...';

  @override
  String get spatialReady => 'Ready! Say \'Hey Ric\' in the spatial universe';

  @override
  String spatialListeningError(Object error) {
    return 'Spatial listening error: $error';
  }

  @override
  String stopError(Object error) {
    return 'Stop error: $error';
  }

  @override
  String get ricConnectedSpatial => 'Ric is connected in the spatial universe';

  @override
  String get spatialModeAvailable => 'Spatial mode available';

  @override
  String get listeningInSpatial => 'Listening in the spatial universe...';
}
