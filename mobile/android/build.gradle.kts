allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
// The Firebase plugins hard-code compileSdk 34 in their own `local-config.gradle`, an Android platform
// this machine does not have (and Gradle cannot fetch it here). Compile them against the same SDK as the
// app instead. Must be registered before `evaluationDependsOn` below starts evaluating projects.
subprojects {
    if (name.startsWith("firebase_")) {
        afterEvaluate {
            extensions.configure<com.android.build.api.dsl.LibraryExtension>("android") {
                compileSdk = 36
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
