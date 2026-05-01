// android/build.gradle.kts (project-level)

import org.gradle.api.file.Directory
import org.gradle.api.tasks.Delete

plugins {
    // هنا من غير version خالص – الإصدارات متعرفة في settings.gradle.kts
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
    id("dev.flutter.flutter-gradle-plugin") apply false
    id("com.google.gms.google-services") apply false
}

// Repositories لكل الـ modules (app / test / ...)
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// تغيير مكان الـ build directory (Flutter default)
val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Flutter بيخلي الـ app يتبني قبل باقي الـ subprojects
subprojects {
    project.evaluationDependsOn(":app")
}

// أمر clean لما تعمل gradle clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
