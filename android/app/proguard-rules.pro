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
-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**

# R8 compatibility
-dontwarn java.lang.management.**
-dontwarn javax.management.**
-dontwarn org.slf4j.**
