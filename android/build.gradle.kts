import org.gradle.api.file.Directory

// Top-level Gradle build file. Do not apply the Android application plugin here.
// The Android app configuration belongs in :app/build.gradle.kts.

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Add Google Services plugin classpath for Firebase
buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.google.gms:google-services:4.4.2")
    }
}

// Redirect build directories (optional, retained from previous configuration)
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
    project.evaluationDependsOn(":app")
}
