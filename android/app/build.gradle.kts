plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hordvoice.hordvoice"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true
    }



    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.hordvoice.hordvoice"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Configuration pour éviter les erreurs Vulkan/OpenGL
        renderscriptTargetApi = 21
        renderscriptSupportModeEnabled = true
    }

    buildTypes {
        release {
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            // La minification est activée pour la version release
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            isDebuggable = false
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
    }
}

flutter {
    source = "../.."
}

// Configuration des tâches Kotlin avec la nouvelle syntaxe DSL
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_11)
        freeCompilerArgs.addAll(
            "-Xno-call-assertions",
            "-Xno-param-assertions",
            "-Xno-receiver-assertions"
        )
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    
    // Azure Speech SDK
    implementation("com.microsoft.cognitiveservices.speech:client-sdk:1.46.0")
    
    // Support pour les coroutines Kotlin (nécessaire pour Azure Speech)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
