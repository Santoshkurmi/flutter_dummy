plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val changelogFile = file("../../assets/changelog.toml")
var jsonVersionCode = 1
var jsonVersionName = "1.0.0"

if (changelogFile.exists()) {
    try {
        val lines = changelogFile.readLines()
        var maxVersionCode = 0
        var latestVersionName = "1.0.0"
        
        var currentVersionName = ""
        var currentVersionCode = 0
        
        for (rawLine in lines) {
            val line = rawLine.trim()
            if (line.isEmpty() || line.startsWith("#")) continue
            
            if (line == "[[versions]]") {
                if (currentVersionCode > maxVersionCode) {
                    maxVersionCode = currentVersionCode
                    latestVersionName = currentVersionName
                }
                currentVersionName = ""
                currentVersionCode = 0
                continue
            }
            
            val eqIdx = line.indexOf("=")
            if (eqIdx != -1) {
                val key = line.substring(0, eqIdx).trim()
                var value = line.substring(eqIdx + 1).trim()
                if (value.endsWith(",")) {
                    value = value.substring(0, value.length - 1).trim()
                }
                if ((value.startsWith("\"") && value.endsWith("\"")) || (value.startsWith("'") && value.endsWith("'"))) {
                    value = value.substring(1, value.length - 1)
                }
                
                if (key == "version") {
                    currentVersionName = value
                } else if (key == "versionCode") {
                    currentVersionCode = value.toIntOrNull() ?: 0
                }
            }
        }
        
        // Check last version entry in the file
        if (currentVersionCode > maxVersionCode) {
            maxVersionCode = currentVersionCode
            latestVersionName = currentVersionName
        }
        
        if (maxVersionCode > 0) {
            jsonVersionCode = maxVersionCode
            jsonVersionName = latestVersionName
        }
    } catch (e: Exception) {
        println("Error parsing assets/changelog.toml: ${e.message}")
    }
}

android {
    namespace = "com.mbright.sahakari"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    buildFeatures {
        resValues = true
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mbright.sahakari"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = jsonVersionCode
        versionName = jsonVersionName
        resValue("string", "app_name", "Mbright")
    }

    signingConfigs {
        create("release") {
            storeFile = file("release-key.jks")
            storePassword = "password"
            keyAlias = "my-key-alias"
            keyPassword = "password"
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )

            ndk {
            debugSymbolLevel = "NONE"
        }
        }
        getByName("debug") {
            applicationIdSuffix = ".debug"
            resValue("string", "app_name", "Mbright🪲")
        }
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

dependencies {
    implementation("androidx.core:core-splashscreen:1.0.1")
    implementation("androidx.appcompat:appcompat:1.6.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
