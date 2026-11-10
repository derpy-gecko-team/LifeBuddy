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