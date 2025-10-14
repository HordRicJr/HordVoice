# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Google Play Core (Flutter embedded deferred components)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**
-dontnote com.google.android.play.core.**

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-keep class org.tensorflow.lite.gpu.** { *; }
-keep class org.tensorflow.lite.gpu.GpuDelegateFactory** { *; }
-dontwarn org.tensorflow.lite.gpu.**

# Micrometer et Reactor Core - classes nécessaires
-keep class io.micrometer.core.instrument.** { *; }
-keep class reactor.core.** { *; }
-keep class reactor.util.** { *; }
-dontwarn io.micrometer.core.instrument.**
-dontwarn reactor.core.**
-dontwarn reactor.util.**

# Classes Sun/Oracle internes manquantes
-dontwarn sun.misc.**
-dontwarn java.lang.instrument.**

# Fix for reactor blockhound missing classes - Configuration complète
-keep class reactor.** { *; }
-dontwarn reactor.blockhound.**
-dontwarn reactor.blockhound.integration.**
-keep class reactor.blockhound.** { *; }
-keep class reactor.blockhound.integration.** { *; }
-dontwarn reactor.core.scheduler.ReactorBlockHoundIntegration
-keep class reactor.core.scheduler.ReactorBlockHoundIntegration { *; }
-keep interface reactor.blockhound.integration.BlockHoundIntegration
-keep class * implements reactor.blockhound.integration.BlockHoundIntegration

# Fix for device_calendar warnings
-keep class com.builttoroam.devicecalendar.** { *; }
-dontwarn com.builttoroam.devicecalendar.**

# Fix for wakelock_plus
-keep class dev.fluttercommunity.plus.wakelock.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.mlkit.**

# Azure Cognitive Services
-keep class com.microsoft.cognitiveservices.** { *; }
-dontwarn com.microsoft.cognitiveservices.**

# Audio packages
-keep class com.ryanheise.** { *; }
-keep class xyz.luan.** { *; }

# Permission handler
-keep class com.baseflow.permissionhandler.** { *; }

# Supabase
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Generic rules for reflection
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes InnerClasses
-keepattributes EnclosingMethod
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }

# Additional Azure Speech SDK rules
-keep class com.microsoft.** { *; }
-dontwarn com.microsoft.**

# Kotlin coroutines
-keep class kotlinx.coroutines.** { *; }
-dontwarn kotlinx.coroutines.**

# Additional Flutter rules
-keep class io.flutter.plugins.** { *; }
-keep class androidx.** { *; }
-dontwarn androidx.**

# Prevent issues with native libraries
-keep class * extends java.lang.Exception

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# R8 specific rules
-dontusemixedcaseclassnames
-dontskipnonpubliclibraryclasses
-verbose
-dontwarn kotlin.**

# R8 compatibility
-dontwarn java.lang.management.**
-dontwarn javax.management.**
-dontwarn org.slf4j.**

# Flutter plugins spécifiques à HordVoice
-keep class com.simform.audio_waveforms.** { *; }
-keep class com.yasinarik.mic_stream_recorder.** { *; }
-keep class com.builttoroam.devicecalendar.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class xyz.luan.audioplayers.** { *; }
-keep class com.dooboolab.flutter_sound.** { *; }
-keep class com.flutter_webrtc.** { *; }

# Azure Speech SDK natif
-keep class com.microsoft.cognitiveservices.speech.** { *; }
-keepclassmembers class com.microsoft.cognitiveservices.speech.** { *; }
-dontwarn com.microsoft.cognitiveservices.speech.**

# Réflexion pour les services Azure
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations

# Enum preservation pour les services vocaux
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Serialisation
-keepnames class * implements java.io.Serializable
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# OkHttp et networking
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-dontwarn okhttp3.**
-dontwarn okio.**

# JSON parsing
-keep class com.google.gson.** { *; }
-keepattributes *Annotation*
-keepattributes Signature

# Reactive extensions si utilisés
-keep class io.reactivex.** { *; }
-dontwarn io.reactivex.**

# WebView
-keep class * extends android.webkit.WebViewClient
-keep class * extends android.webkit.WebChromeClient
-keepclassmembers class * extends android.webkit.WebViewClient {
    public void *(android.webkit.WebView, java.lang.String, android.graphics.Bitmap);
    public boolean *(android.webkit.WebView, java.lang.String);
}

# Plus de packages spécifiques HordVoice
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.dooboolab.flutter_sound.** { *; }
-keep class com.baseflow.geolocator.** { *; }
-keep class com.lyokone.location.** { *; }
-keep class io.github.ponnamkarthik.toast.** { *; }
-keep class com.dexterous.flutter_local_notifications.** { *; }
-keep class dev.fluttercommunity.plus.** { *; }

# Supabase et networking
-keep class io.supabase.gotrue.** { *; }
-keep class io.supabase.storage.** { *; }
-keep class io.supabase.realtime.** { *; }

# Google services
-keep class com.google.android.gms.** { *; }
-keep class com.google.api.** { *; }
-dontwarn com.google.android.gms.**

# TensorFlow et ML
-keep class org.tensorflow.** { *; }
-dontwarn org.tensorflow.**

# Camera et image processing
-keep class io.flutter.plugins.camera.** { *; }
-keep class com.baseflow.camera.** { *; }

# WebRTC
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# Hive database
-keep class io.github.hivedb.** { *; }

# Additional rules to fix missing classes
-keep class kotlin.** { *; }
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**

# Fix DateUtils deprecated warning
-dontwarn android.text.format.DateUtils

# Global Scope usage (device_calendar)
-dontwarn kotlinx.coroutines.GlobalScope
-keep class hive.** { *; }

# Background services
-keep class id.flutter.flutter_background_service.** { *; }

# Charts et UI
-keep class com.github.mikephil.charting.** { *; }

# Kotlin incremental compilation fixes
-dontwarn org.jetbrains.kotlin.**
-keep class org.jetbrains.kotlin.** { *; }
-keep class kotlin.** { *; }
-dontwarn kotlinx.**
-keep class kotlinx.** { *; }

# Fix storage registration conflicts
-dontwarn com.google.firebase.components.**
-keep class com.google.firebase.components.** { *; }

# R8 optimisation modérée (moins agressive)
-dontobfuscate
-optimizations !code/simplification/arithmetic,!code/simplification/cast,!field/*,!class/merging/*
-keepattributes *Annotation*,InnerClasses,Signature,Exceptions,EnclosingMethod
-keepattributes SourceFile,LineNumberTable
