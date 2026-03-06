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

// Workaround for older plugins (like device_apps) that don't specify a namespace
    val buildDescriptor = this
    val androidExtension = buildDescriptor.extensions.findByName("android")
    if (androidExtension != null) {
        val namespaceMethod = androidExtension.javaClass.methods.firstOrNull { it.name == "setNamespace" }
        if (namespaceMethod != null) {
            val group = buildDescriptor.group.toString()
            if (group.isNotEmpty()) {
                try {
                    namespaceMethod.invoke(androidExtension, group)
                } catch (e: Exception) {
                    println("Failed to inject namespace into $group")
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
