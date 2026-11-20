group = "com.cavernlabs.banana.player.banana_player"
version = "1.0-SNAPSHOT"

object Versions {
    const val KOTLIN = "2.4.21"
    const val AGP = "9.3.1"
    const val COMPILE_SDK = 36
    const val MIN_SDK = 24
    const val MEDIA3 = "1.5.1"
    const val COROUTINES = "1.8.1"
    const val MOCKITO = "5.11.0"
    val JAVA = JavaVersion.VERSION_17
    val JVM_TARGET = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
}

buildscript {
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.3.1")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:2.4.21")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

plugins {
    id("com.android.library")
}

android {
    namespace = "com.cavernlabs.banana.player.banana_player"

    compileSdk = Versions.COMPILE_SDK

    compileOptions {
        sourceCompatibility = Versions.JAVA
        targetCompatibility = Versions.JAVA
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = Versions.MIN_SDK
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            all {
                it.useJUnitPlatform()

                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = Versions.JVM_TARGET
    }
}

dependencies {
    implementation("androidx.media3:media3-exoplayer:${Versions.MEDIA3}")
    implementation("androidx.media3:media3-exoplayer-hls:${Versions.MEDIA3}")
    implementation("androidx.media3:media3-exoplayer-dash:${Versions.MEDIA3}")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:${Versions.COROUTINES}")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.jetbrains.kotlinx:kotlinx-coroutines-test:${Versions.COROUTINES}")
    testImplementation("org.mockito:mockito-core:${Versions.MOCKITO}")
}
