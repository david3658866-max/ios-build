import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

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
subprojects {
    project.evaluationDependsOn(":app")
}

// file_picker(11.x)/mobile_scanner 等插件在 AGP 9 下会“有条件地跳过”应用 kotlin-android，
// 期望使用 AGP 内置 Kotlin；但本项目 builtInKotlin=false，导致这些插件的 Kotlin 源码不会被编译，
// 进而 GeneratedPluginRegistrant 找不到插件类(如 FilePickerPlugin)。
// 这里为所有缺少 kotlin-android 的 Android library 子项目强制补上该插件。
subprojects {
    pluginManager.withPlugin("com.android.library") {
        if (!pluginManager.hasPlugin("org.jetbrains.kotlin.android")) {
            pluginManager.apply("org.jetbrains.kotlin.android")
        }
    }
}

// 插件子项目 Kotlin 默认 JVM target 可能与 Java 不一致。
// 统一 Kotlin=17；Java 侧差异由 gradle.properties 中
// kotlin.jvm.target.validation.mode=warning 放行。
subprojects {
    tasks.withType<KotlinCompile>().configureEach {
        compilerOptions {
            jvmTarget.set(JvmTarget.JVM_17)
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
