allprojects {
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://jitpack.io") }
    }
}

ext {
    set("androidXVersion", "1.3.1")
    set("versionCompiler", 34)
    set("versionTarget", 34)
    set("minSdkVersion", 23)
    set("versionCode", 127)
    set("versionNameString", "3.4.2")
    set("javaSourceCompatibility", JavaVersion.VERSION_1_8)
    set("javaTargetCompatibility", JavaVersion.VERSION_1_8)
    set("ndkVersion", "27.0.12077973")
    set("kotlinCoreVersion", "1.3.2")
    set("materialVersion", "1.3.0")
    set("constraintlayoutVersion", "2.0.4")
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

subprojects {
    configurations.all {
        resolutionStrategy {
            force("androidx.test:runner:1.2.0")
            force("androidx.test:rules:1.2.0")
            force("androidx.test.espresso:espresso-core:3.2.0")
        }
    }
}
