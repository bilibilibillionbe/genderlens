import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. Create android/key.properties (never commit it):
//   storeFile=/absolute/path/upload-keystore.jks
//   storePassword=...
//   keyAlias=upload
//   keyPassword=...
// CI can instead set the same values as environment variables
// ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD.
val keystoreProperties = Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) FileInputStream(f).use { load(it) }
}
fun signingValue(prop: String, env: String): String? =
    keystoreProperties.getProperty(prop) ?: System.getenv(env)

val releaseStoreFile = signingValue("storeFile", "ANDROID_KEYSTORE_PATH")

android {
    namespace = "com.yourcompany.genderlens"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.yourcompany.genderlens"
        minSdk = maxOf(flutter.minSdkVersion, 24)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (releaseStoreFile != null) {
            create("release") {
                storeFile = file(releaseStoreFile)
                storePassword = signingValue("storePassword", "ANDROID_KEYSTORE_PASSWORD")
                keyAlias = signingValue("keyAlias", "ANDROID_KEY_ALIAS")
                keyPassword = signingValue("keyPassword", "ANDROID_KEY_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Falls back to the debug key so `flutter run --release` works locally.
            // Builds signed with the debug key are rejected by every store.
            signingConfig = signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    // The .tflite model is already compressed; storing it uncompressed lets it be memory-mapped.
    androidResources {
        noCompress += "tflite"
    }
}

// Every phone and tablet in the stores is ARM. Drop the x86 copies of the ML Kit,
// LiteRT and Flutter native libraries from release builds (~20 MB); debug builds
// keep them so emulators work. (abiFilters cannot be used: the Flutter Gradle
// plugin overrides them.)
androidComponents {
    onVariants(selector().withBuildType("release")) { variant ->
        variant.packaging.jniLibs.excludes.addAll(listOf("lib/x86/**", "lib/x86_64/**"))
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
