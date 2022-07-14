plugins {
    kotlin("jvm") version "1.6.21"
    application
    id("com.github.johnrengelman.shadow") version "7.1.2"
}

group = "io.curity"
version = "0.0.1-SNAPSHOT"
java.sourceCompatibility = JavaVersion.VERSION_11

repositories {
    mavenCentral()
}

dependencies {

    // Kotlin base support
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.6.21")

    // The API uses the Spark framework
    implementation("com.sparkjava:spark-core:2.9.3")

    // JSON processing
    implementation("com.fasterxml.jackson.core:jackson-databind:2.13.3")

    // Base logging support
    implementation("org.slf4j:slf4j-simple:1.7.36")
}

application {
    mainClass.set("io.curity.githubintegration.MainKt")
}
