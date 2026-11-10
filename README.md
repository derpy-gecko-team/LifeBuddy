# lifebuddy

LifeBuddy: Flutter app, Spring Boot backend and Python AI service

## Backend setup
1. Install JDK 21 (e.g. Microsoft OpenJDK 21 or Temurin 21)
2. Open the `backend` folder in IntelliJ
3. File -> Project Structure -> Project -> SDK: 21
4. If Maven import fails with "Unable to create injector":
   Settings -> Build Tools -> Maven -> Maven home path -> Bundled (Maven 3)
5. Build: `.\mvnw.cmd clean compile` (inside `backend`)
