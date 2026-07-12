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
// Some Flutter plugins (e.g. nfc_manager 3.x) pin an old compileSdk that is
// lower than what their AndroidX transitive dependencies now require. Force
// every Android library subproject compiled against < SDK 34 up to 36.
// Reflection is used so this file needs no AGP types on its classpath.
// Registered before evaluationDependsOn(":app") so it runs before evaluation.
subprojects {
    afterEvaluate {
        val androidExt = extensions.findByName("android") ?: return@afterEvaluate
        try {
            val current = androidExt.javaClass
                .getMethod("getCompileSdkVersion")
                .invoke(androidExt) as String?
            val currentApi = current?.removePrefix("android-")?.toIntOrNull()
            if (currentApi == null || currentApi < 34) {
                androidExt.javaClass
                    .getMethod("compileSdkVersion", String::class.java)
                    .invoke(androidExt, "android-36")
            }
        } catch (_: Exception) {
            // Extension doesn't expose the expected methods — leave it as-is.
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
