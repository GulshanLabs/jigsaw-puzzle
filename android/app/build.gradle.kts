import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
// Release signing needs both key.properties and the keystore it points to.
// If either is missing, the build falls back to debug signing instead of failing.
val hasReleaseKeystore = keystorePropertiesFile.exists() &&
    (keystoreProperties["storeFile"] as String?)?.let { file(it).exists() } == true

android {
    namespace = "com.nousvara.puzzle"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    // Release signing is only configured when android/key.properties exists.
    // That file holds private credentials and is deliberately not in version
    // control, so a fresh clone falls back to debug signing and still builds.
    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String?
                keyPassword = keystoreProperties["keyPassword"] as String?
                storeFile = keystoreProperties["storeFile"]?.let { file(it as String) }
                storePassword = keystoreProperties["storePassword"] as String?
            }
        }
    }

    defaultConfig {
        applicationId = "com.nousvara.puzzle"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // No keystore available (e.g. a fresh clone): use debug signing so
                // `flutter build apk --release` still succeeds. Such a build is fine
                // for local testing but must not be distributed.
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}
