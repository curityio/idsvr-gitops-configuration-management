plugins {
    kotlin("jvm") version "1.6.21"
    application
    id("org.springframework.boot") version "2.7.1"
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
    implementation("org.jetbrains.kotlin:kotlin-reflect:1.7.10")

    // Kotlin async await support
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-core:1.6.4")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-jdk8:1.6.4")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-reactor:1.6.4")

    // The API uses Spring Boot
    implementation("org.springframework.boot:spring-boot-starter:2.7.1")
    implementation("org.springframework.boot:spring-boot-starter-web:2.7.1")

    // JSON processing
    implementation("com.fasterxml.jackson.core:jackson-databind:2.13.3")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin:2.13.3")
}

application {
    mainClass.set("io.curity.githubintegration.MainKt")
}
