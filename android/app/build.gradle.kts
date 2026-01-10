plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.hexapod.hexapod_control"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }
    defaultConfig {
        applicationId = "com.hexapod.hexapod_control"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }
    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

// Rename APK output to robot-spider.apk
afterEvaluate {
    tasks.register<Copy>("renameApk") {
        val apkDir = file("${project.rootDir.parent}/build/app/outputs/apk/debug")
        from(apkDir) {
            include("app-debug.apk")
        }
        into(apkDir)
        rename("app-debug.apk", "robot-spider.apk")
        mustRunAfter("createDebugApkListingFileRedirect")
    }

    tasks.named("assembleDebug") {
        finalizedBy("renameApk")
    }
}
