plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.pradeep.carermeds"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.pradeep.carermeds"
        minSdk = 21
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Release signing — reads from environment variables set by the CI workflow.
    // For local release builds, set the same variables in your shell or a
    // local.properties file (never commit credentials to version control).
    signingConfigs {
        create("release") {
            storeFile     = file("carermeds.jks")
            storePassword = System.getenv("ANDROID_STORE_PASSWORD") ?: ""
            keyAlias      = System.getenv("ANDROID_KEY_ALIAS")      ?: ""
            keyPassword   = System.getenv("ANDROID_KEY_PASSWORD")   ?: ""
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled   = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
