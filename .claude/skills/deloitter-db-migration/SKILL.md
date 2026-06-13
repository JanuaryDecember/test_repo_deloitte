# /deloitter-db-migration — Standardize schema evolution and seed strategy

## Usage

```
/deloitter-db-migration <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `persistence-and-seed`, `swipe-candidate-stack`, etc.).

## Purpose

Validate, generate, or audit Flyway migrations for a given roadmap slice. Ensures migrations are correctly ordered, idempotent where needed, seed data is sufficient for downstream slices, and the migration set works consistently across local Docker and Azure PostgreSQL environments.

## Inputs (read before executing)

1. **The plan:** `context/changes/<change-id>/plan.md` — defines schema changes and seed requirements.
2. **Existing migrations:** `backend/src/main/resources/db/migration/` — current Flyway baseline.
3. **Backend tech stack:** `backend/context/foundation/tech-stack.md`
4. **Backend conventions:** `backend/AGENTS.md`
5. **Application config:** `backend/src/main/resources/application.properties` — datasource and Flyway settings. (If an `application-azure.properties` profile exists, check it too.)
6. **Roadmap:** `context/foundation/roadmap.md` — prerequisites and downstream consumers that will depend on this schema.
7. **PRD:** `context/foundation/prd.md` — data model requirements (entities, relationships, constraints).

## Modes

### Mode 1: Generate (`/deloitter-db-migration <change-id> generate`)

Create new migration files based on the plan's schema requirements.

**Process:**

1. Read existing migrations to determine the current version number.
2. Read the plan's Phase 2 (or schema-related phase) for table definitions.
3. Generate SQL migration files with the next sequential version numbers.
4. Validate SQL syntax is PostgreSQL-compatible (not H2-specific).
5. If the plan includes seed data, generate a separate seed migration (after schema).

**Output:** Migration files in `backend/src/main/resources/db/migration/`

**Naming convention:**
- Schema DDL: `V{N}__create_{table_name}.sql` or `V{N}__alter_{table_name}_{description}.sql`
- Seed data: `V{N}__seed_{description}.sql`
- Index/constraints: `V{N}__add_{index_or_constraint}_{table}.sql`

### Mode 2: Validate (`/deloitter-db-migration <change-id> validate`)

Check existing migrations for correctness without modifying them.

**Checks performed:**

1. **Sequential ordering** — no gaps or duplicates in version numbers.
2. **Syntax correctness** — valid PostgreSQL DDL/DML (not H2-specific functions).
3. **Forward references** — no migration references a table/column not yet created.
4. **Seed coverage** — verify seed data provides enough variety for downstream slices:
   - Enough employees for matching (min 6 for demo diversity).
   - Enough interest/competency overlap for score variance.
   - At least 2 employees per service line for filtering tests.
5. **Profile safety** — migrations work on both local (Docker) and Azure Postgres (no localhost assumptions in data, no environment-specific SQL).
6. **Idempotency check** — INSERT statements use `ON CONFLICT DO NOTHING` or are in a fresh migration (not rerunnable).
7. **Naming conventions** — file names follow the established pattern.
8. **Constraint completeness** — foreign keys have `ON DELETE` behavior, NOT NULL is used where appropriate.

**Output:** Validation report printed to console with pass/fail per check.

### Mode 3: Audit (`/deloitter-db-migration <change-id> audit`)

After implementation, audit the actual database state matches expected schema.

**Process:**

1. Connect to the target database (local or Azure based on active profile).
2. Compare `information_schema.tables` / `information_schema.columns` against migration expectations.
3. Verify seed row counts match plan requirements.
4. Check Flyway history table (`flyway_schema_history`) for failed migrations.

**Output:** Audit report with discrepancies listed.

## Migration Writing Rules

1. **One concern per migration.** Don't mix DDL and seed data in the same file. Don't create multiple unrelated tables in one migration.

2. **PostgreSQL-native syntax only.** No H2 compatibility hacks, no MySQL-isms. Use:
   - `BIGSERIAL` for auto-increment IDs
   - `TIMESTAMP` with `DEFAULT NOW()`
   - `VARCHAR(N)` with explicit lengths
   - `CREATE INDEX` separately from `CREATE TABLE`
   - `ON CONFLICT` for upsert seed data

3. **Explicit constraints.** Always specify:
   - `NOT NULL` for required fields
   - `UNIQUE` for natural keys (email, name in catalog tables)
   - `FOREIGN KEY` with `ON DELETE CASCADE` or `ON DELETE SET NULL` (document the choice)
   - `CHECK` constraints where the PRD defines bounded values

4. **Seed data requirements:**
   - All demo passwords must be BCrypt-hashed (use `$2a$10$...` literals, not plaintext)
   - Seed enough overlap: at least 3 employees sharing 3+ interests to ensure non-trivial matching
   - Include edge cases: employee with 1 interest, employee with all interests, employees in same/different service lines
   - Use realistic-looking data (Deloitte-style names, real interest/competency names)

5. **Rollback awareness.** Flyway Community doesn't support undo migrations. For safety:
   - Document rollback steps in SQL comments at the top of each migration
   - Use `IF EXISTS` / `IF NOT EXISTS` guards where safe
   - Never drop columns in the same slice that creates them (split across slices)

6. **Environment safety:**
   - No hardcoded hostnames or environment-specific values in migrations
   - Seed data should work identically on local Docker and Azure Postgres
   - Connection credentials come from application config, not from migrations

7. **Version number coordination.** When multiple team members work on different slices:
   - Check latest committed migration version before assigning new numbers
   - Leave gaps if working in parallel (e.g., slice A uses V10-V12, slice B uses V20-V22)
   - Document version allocation in the plan

## Validation Report Format

```markdown
# Migration Validation: <change-id>

## Summary
- Migrations checked: <N>
- Status: ✅ PASS / ⚠️ WARNINGS / ❌ FAIL

## Checks

| # | Check | Status | Details |
|---|-------|--------|---------|
| 1 | Sequential ordering | ✅/❌ | <notes> |
| 2 | PostgreSQL syntax | ✅/❌ | <notes> |
| 3 | No forward references | ✅/❌ | <notes> |
| 4 | Seed coverage | ✅/❌ | <notes> |
| 5 | Profile safety | ✅/❌ | <notes> |
| 6 | Idempotency | ✅/❌ | <notes> |
| 7 | Naming conventions | ✅/❌ | <notes> |
| 8 | Constraint completeness | ✅/❌ | <notes> |

## Issues Found

### ❌ Failures
<list with fix recommendations>

### ⚠️ Warnings
<list with suggestions>

## Recommendations
<prioritized list of fixes>
```

## Example Invocations

```
/deloitter-db-migration persistence-and-seed generate
```
Creates V1–V5 migration files per the persistence-and-seed plan.

```
/deloitter-db-migration persistence-and-seed validate
```
Checks existing migrations for correctness and seed coverage.

```
/deloitter-db-migration swipe-candidate-stack generate
```
Creates migrations for swipe/match tables (V6+), building on existing schema.

## Failure Modes

| Situation | Action |
|-----------|--------|
| Plan doesn't define schema changes | Inform user; this slice may not need migrations |
| Version number conflict with existing migrations | Warn user, suggest next available version |
| H2-specific syntax detected | Flag the line, provide PostgreSQL equivalent |
| Seed data insufficient for downstream slices | Warn with specific gap (e.g., "only 2 employees, need 6+ for matching variance") |
| Azure profile not configured | Note that validation is local-only; recommend configuring for full audit |
