plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hordvoice.hordvoice"
    compileSdk = 36  // Version requise pour les plugins modernes
    ndkVersion = "27.0.12077973"  // Version requise par les plugins

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }
    
    // Optimisations pour éviter les timeouts AAPT2
    aaptOptions {
        noCompress += listOf("tflite", "lite", "txt")
        ignoreAssetsPattern = "!.svn:!.git:!.DS_Store:!*.scc:.*:!CVS:!thumbs.db:!picasa.ini:!*.scc:*~"
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
            // Désactiver la minification temporairement pour éviter les timeouts
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
            isDebuggable = false
        }
        debug {
            isMinifyEnabled = false
            isShrinkResources = false
            isDebuggable = true
        }
    }
    
    // Optimisations pour éviter les timeouts de compilation
    packagingOptions {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
            excludes += "/META-INF/versions/9/previous-compilation-data.bin"
        }
    }
}

flutter {
    source = "../.."
}

// Configuration JVM Toolchain locale pour garantir la cohérence
java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(17))
    }
}

// Configuration des tâches Kotlin avec la nouvelle syntaxe DSL
tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
        freeCompilerArgs.addAll(
            "-Xno-call-assertions",
            "-Xno-param-assertions",
            "-Xno-receiver-assertions"
        )
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Azure Speech SDK (version compatible avec SDK 36 et Java 17)
    implementation("com.microsoft.cognitiveservices.speech:client-sdk:1.46.0")
    
    // Support pour les coroutines Kotlin (version récente compatible Java 17)
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    
    // Support pour les nouvelles versions Android avec Java 17
    implementation("androidx.core:core-ktx:1.17.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.8.6")
    implementation("androidx.annotation:annotation:1.9.1")
}
