pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        requireNotNull(flutterSdkPath) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.13.0" apply false
    // START: FlutterFire Configuration
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("com.google.firebase.firebase-perf") version "1.4.1" apply false
    id("com.google.firebase.crashlytics") version "2.8.1" apply false
    // END: FlutterFire Configuration
    id("org.jetbrains.kotlin.android") version "2.1.20" apply false
    // 添加这个插件来检查版本
    id("com.github.ben-manes.versions") version "0.53.0" apply false
}

include(":app")
