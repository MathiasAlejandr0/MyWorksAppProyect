import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Cargar propiedades del keystore si existe
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "cl.myworksapp.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        // Identidad de la app en Android y Google Play. Cambiarla después de
        // publicar equivale a crear otra app. El paquete Kotlin coincide
        // con este id: cl.myworksapp.app.
        applicationId = "cl.myworksapp.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                val storeFilePath = keystoreProperties["storeFile"] as String?
                storeFile = storeFilePath?.let { file(it) }
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Release firmado con android/key.properties (no versionado; ver
            // docs/FIRMA_RELEASE_ANDROID.md). Sin ese archivo se firma con la
            // clave debug SOLO para pruebas locales, y con
            // REQUIRE_RELEASE_SIGNING=true el build falla en vez de hacerlo.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                if (System.getenv("REQUIRE_RELEASE_SIGNING") == "true") {
                    throw GradleException(
                        "Falta android/key.properties: no se puede firmar el release. " +
                            "Ver docs/FIRMA_RELEASE_ANDROID.md"
                    )
                }
                logger.warn(
                    "ADVERTENCIA: android/key.properties no existe; el release se firma " +
                        "con la clave DEBUG. No distribuyas esta APK."
                )
                signingConfigs.getByName("debug")
            }
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = false
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
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
