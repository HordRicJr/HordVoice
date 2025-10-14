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
  String get preparingInterface => 'جارٍ تحضير الواجهة...';

  @override
  String get readyInitializingBackground => 'جاهز! جارٍ التهيئة في الخلفية...';

  @override
  String get interfaceReadyDegraded => 'الواجهة جاهزة (الوضع المحدود)';

  @override
  String get ricIsListening => 'ريك يستمع من الكون المكاني...';

  @override
  String get spatialProcessing => 'معالجة في الكون المكاني...';

  @override
  String get spatialReady => 'جاهز! قل \'Hey Ric\' في الكون المكاني';

  @override
  String spatialListeningError(Object error) {
    return 'خطأ في الاستماع المكاني: $error';
  }

  @override
  String stopError(Object error) {
    return 'خطأ في الإيقاف: $error';
  }

  @override
  String get ricConnectedSpatial => 'ريك متصل في الكون المكاني';

  @override
  String get spatialModeAvailable => 'الوضع المكاني متاح';

  @override
  String get listeningInSpatial => 'الاستماع في الكون المكاني...';
}
