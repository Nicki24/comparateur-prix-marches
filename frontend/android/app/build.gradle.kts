import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Clé de signature de production, hors du dépôt (voir android/.gitignore).
// android/key.properties : storeFile, storePassword, keyAlias, keyPassword.
val proprietesCle = Properties().apply {
    val fichier = rootProject.file("key.properties")
    if (fichier.exists()) load(FileInputStream(fichier))
}

android {
    namespace = "com.comparateur.comparateur_prix_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.comparateur.comparateur_prix_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // 23 = Android 6.0, requis par flutter_secure_storage (Keystore).
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (proprietesCle.isNotEmpty()) {
            create("release") {
                storeFile = file(proprietesCle["storeFile"] as String)
                storePassword = proprietesCle["storePassword"] as String
                keyAlias = proprietesCle["keyAlias"] as String
                keyPassword = proprietesCle["keyPassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Clé MarketScope si android/key.properties existe ; sinon clé de
            // debug (APK de test seulement : ne pas le distribuer).
            signingConfig = if (proprietesCle.isNotEmpty()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
