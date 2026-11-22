# Build diagnostics

The original Flutter 3.35.7 template selected Kotlin 2.1.0. Firebase Auth 25.0.0 is compiled with Kotlin metadata 2.4.0, so the first Android release compilation failed. The application now selects Kotlin 2.4.21 and uses the typed compilerOptions JVM target DSL, as required by the updated plugin.

The build uses JDK 21, Gradle 8.12, and Android Gradle Plugin 8.9.1. Gradle heap is limited to 2 GB and two workers for this 8 GB host. The dedicated release signing key and password are outside Git.

Official compatibility references:
https://kotlinlang.org/docs/whatsnew24.html
https://kotlinlang.org/docs/gradle-configure-project.html
https://docs.flutter.dev/deployment/android

Build output and final artifact hash must be recorded after the successful final build. Compiler output by itself is not runtime evidence.
