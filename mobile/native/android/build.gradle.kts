plugins {
    id("com.android.application") version "8.9.3"
    id("org.jetbrains.kotlin.android") version "2.1.20"
}

layout.buildDirectory.set(file("../.once/android-build"))

val stageNative by tasks.registering(Copy::class) {
    from(providers.gradleProperty("onceNativeLibrary"))
    into(layout.buildDirectory.dir(providers.gradleProperty("onceNativeAbi").map { "jniLibs/$it" }))
}

android {
    namespace = "ai.glossia.mobile"
    compileSdk = 35
    defaultConfig {
        applicationId = "ai.glossia.mobile"
        minSdk = 26
        targetSdk = 35
        versionCode = 1
        versionName = "0.1.0"
    }
    sourceSets["main"].apply {
        manifest.srcFile("AndroidManifest.xml")
        java.setSrcDirs(listOf("src"))
        res.setSrcDirs(listOf("res"))
        jniLibs.srcDir(layout.buildDirectory.dir("jniLibs"))
    }
    // Fixtures and fake transports are JVM-test-only, never part of an APK.
    sourceSets["test"].java.setSrcDirs(listOf("test"))
    testOptions.unitTests.isIncludeAndroidResources = true
    testOptions.unitTests.all {
        it.systemProperty("artifacts", providers.gradleProperty("androidScreenshotDirectory")
            .getOrElse(layout.buildDirectory.dir("screenshots").get().asFile.absolutePath))
        it.systemProperty("robolectric.dependency.repo.url", "https://repo.maven.apache.org/maven2")
        it.testLogging { events("passed", "failed") }
    }
    signingConfigs.getByName("debug") {
        System.getenv("ANDROID_DEBUG_KEYSTORE")?.let { storeFile = file(it) }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    implementation("com.google.android.material:material:1.12.0")
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.core:core-ktx:1.15.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.14.1")
}

dependencyLocking { lockAllConfigurations() }

tasks.named("preBuild") { dependsOn(stageNative) }
tasks.register<Copy>("packageOnce") {
    dependsOn("assembleDebug")
    from(layout.buildDirectory.file("outputs/apk/debug/GlossiaAndroid-debug.apk"))
    into(providers.gradleProperty("onceOutputApk").map { file(it).parentFile })
    rename { providers.gradleProperty("onceOutputApk").map { file(it).name }.get() }
}
