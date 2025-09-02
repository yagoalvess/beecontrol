allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define diretório de build unificado
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// Tarefa clean
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
