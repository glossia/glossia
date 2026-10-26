plugins {
    id("com.android.application") version "8.9.3"
    id("org.jetbrains.kotlin.android") version "2.1.20"
}

layout.buildDirectory.set(file("../.once/android-build"))

val stageNative by tasks.registering(Copy::class) {
    from(providers.gradleProperty("onceNativeLibrary"))
    into(layout.buildDirectory.dir(providers.gradleProperty("onceNativeAbi").map { "jniLibs/$it" }))
}

val stageTranslations by tasks.registering(Sync::class) {
    from("../locales") {
        include("*/android/strings.xml")
        eachFile {
            val locale = relativePath.segments.first()
            require(locale.matches(Regex("[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*"))) { "Invalid native translation locale" }
            relativePath = RelativePath(true, "values-b+${locale.replace('-', '+')}", "strings.xml")
        }
        includeEmptyDirs = false
    }
    into(layout.buildDirectory.dir("translated-resources"))
}

val generateAppLocales by tasks.registering {
    val catalogs = fileTree("../locales") { include("*/android/strings.xml") }
    val output = layout.buildDirectory.file("locale-config/xml/app_locales.xml")
    inputs.files(catalogs)
    outputs.file(output)
    doLast {
        // Discover Glossia catalogs, not the translations shipped by UI dependencies.
        // This single packaged list drives both Android Settings and our picker.
        val locales = (listOf("en") + catalogs.files.map { it.parentFile.parentFile.name }).distinct().sorted()
        locales.forEach { locale ->
            require(locale.matches(Regex("[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*"))) { "Invalid native translation locale" }
        }
        output.get().asFile.apply {
            parentFile.mkdirs()
            writeText("""<?xml version="1.0" encoding="utf-8"?>
<locale-config xmlns:android="http://schemas.android.com/apk/res/android">
${locales.joinToString("\n") { "    <locale android:name=\"$it\" />" }}
</locale-config>
""")
        }
    }
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
        // Public Firebase Android app identifiers only. Never pass a service-account key.
        mapOf("APPLICATION_ID" to "ApplicationId", "PROJECT_ID" to "ProjectId",
            "SENDER_ID" to "SenderId", "API_KEY" to "ApiKey").forEach { (field, property) ->
            val value = providers.gradleProperty("glossiaFirebase$property").getOrElse("")
            require(value.matches(Regex("[A-Za-z0-9_:.-]*"))) { "Invalid public Firebase identifier" }
            buildConfigField("String", "FIREBASE_$field", "\"$value\"")
        }
    }
    buildFeatures.buildConfig = true
    sourceSets["main"].apply {
        manifest.srcFile("AndroidManifest.xml")
        java.setSrcDirs(listOf("src"))
        res.setSrcDirs(listOf("res"))
        res.srcDir(layout.buildDirectory.dir("translated-resources"))
        res.srcDir(layout.buildDirectory.dir("locale-config"))
        jniLibs.srcDir(layout.buildDirectory.dir("jniLibs"))
    }
    // Fixtures and fake transports are JVM-test-only, never part of an APK.
    sourceSets["test"].java.setSrcDirs(listOf("test"))
    testOptions.unitTests.isIncludeAndroidResources = true
    testOptions.unitTests.all {
        it.systemProperty("nativeLocalizationSentinel", providers.gradleProperty("nativeLocalizationSentinel").getOrElse("false"))
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
    implementation("com.google.firebase:firebase-messaging:24.1.0")
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.robolectric:robolectric:4.14.1")
}

dependencyLocking { lockAllConfigurations() }

tasks.named("preBuild") { dependsOn(stageNative, stageTranslations, generateAppLocales) }
tasks.register<Copy>("packageOnce") {
    dependsOn("assembleDebug")
    from(layout.buildDirectory.file("outputs/apk/debug/GlossiaAndroid-debug.apk"))
    into(providers.gradleProperty("onceOutputApk").map { file(it).parentFile })
    rename { providers.gradleProperty("onceOutputApk").map { file(it).name }.get() }
}
