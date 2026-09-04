import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}


android {
    namespace = "example.simpson.com"
<<<<<<< Updated upstream
    compileSdk = 36
    ndkVersion = "28.2.13676358"
=======

    compileSdk = 36

    ndkVersion = "28.2.13676358" 
>>>>>>> Stashed changes
    defaultConfig {
        applicationId = "example.simpson.com"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = 1
        versionName = "0.0.1"
    }

     signingConfigs {
    if (keystorePropertiesFile.exists()) {
        create("release") {
<<<<<<< Updated upstream
        if (keystorePropertiesFile.exists()) {
            storeFile = file(keystoreProperties["storeFile"] as String)
            storePassword = keystoreProperties["storePassword"] as String
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
        }
    }
}
=======
            storeFile = file(
                keystoreProperties["storeFile"]?.toString()
                    ?: error("storeFile missing in key.properties")
            )

            storePassword =
                keystoreProperties["storePassword"]?.toString()
                    ?: error("storePassword missing in key.properties")

            keyAlias =
                keystoreProperties["keyAlias"]?.toString()
                    ?: error("keyAlias missing in key.properties")

            keyPassword =
                keystoreProperties["keyPassword"]?.toString()
                    ?: error("keyPassword missing in key.properties")
        }
    }
}

>>>>>>> Stashed changes
buildTypes {
    getByName("release") {
        if (keystorePropertiesFile.exists()) {
            signingConfig =
                signingConfigs.getByName("release")
        }

        isMinifyEnabled = false
        isShrinkResources = false
    }
}


    // Required when using multiple flavors
    flavorDimensions += "environment"

    productFlavors {
        create("dev") {
            dimension = "environment"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            manifestPlaceholders["appName"]="autopeepal-app"
        }

        create("stage") {
            dimension = "environment"
            applicationIdSuffix = ".stage"
            versionNameSuffix = "-stage"
            manifestPlaceholders["appName"]="Stage Hrms Erp"
        }

        create("prod") {
            dimension = "environment"
            // No suffix for production
             manifestPlaceholders["appName"]="Hrms Erp"
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}


flutter {
    source = "../.."
}
