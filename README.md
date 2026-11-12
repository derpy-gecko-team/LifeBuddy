# lifebuddy

LifeBuddy: Flutter app, Spring Boot backend and Python AI service

## Backend setup
1. Install JDK 21 (e.g. Microsoft OpenJDK 21 or Temurin 21)
2. Open the `backend` folder in IntelliJ
3. File -> Project Structure -> Project -> SDK: 21
4. If Maven import fails with "Unable to create injector":
   Settings -> Build Tools -> Maven -> Maven home path -> Bundled (Maven 3)
5. Build: `.\mvnw.cmd clean compile` (inside `backend`)


## Database migrations (Flyway)

The database structure is managed by Flyway migrations in
`backend/src/main/resources/db/migration/`.

- Migrations run automatically when the backend starts.
- File names: `V<number>__<description>.sql`, e.g. `V2__create_quests.sql`
  (capital V, two underscores).
- To change the database, **add a new migration file**. Never edit a
  migration that is already merged into `main`.
- Use the next free number. If two PRs pick the same number, the one
  merged second must rename its file.
- Reference data the app needs (e.g. tile types) also goes in a migration.

If your local database gets out of sync, reset it:
`docker compose down -v` then `docker compose up -d`
(this deletes all local data).


## Frontend setup

1. Install the [Flutter SDK](https://docs.flutter.dev/get-started/install) and run `flutter doctor` until it is happy
2. Open the `frontend` folder (or the repo root)
3. Get dependencies: `flutter pub get` (inside `frontend`)
4. Start an emulator or connect a device, then run: `flutter run`

### Troubleshooting

- **Gradle fails with only a Java version as the error:** Gradle does not support your newest JDK. Point Flutter at JDK 21 (the same one the backend uses):
  `flutter config --jdk-dir "<path to your JDK 21>"`
  Then check that `flutter doctor -v` shows that path under "Java binary at". If you installed the JDK through IntelliJ, it is usually in `C:\Users\<you>\.jdks\`.

> [!NOTE]
> iOS builds need a Mac with Xcode. On Windows, develop and test on Android.