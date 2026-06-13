> **Archived:** 2026-06-13 | Change ID: `persistence-and-seed` | Roadmap ID: `F-01`

# Plan Brief: Persistence & seed foundation

**Change ID:** `persistence-and-seed` | **Roadmap ID:** `F-01` | **Status:** revised

## What

Wire PostgreSQL to the Spring Boot backend via Docker Compose, create the minimal schema (employees, interests/competencies catalog, selection join tables) using Flyway migrations, and seed ~20 demo employees with varied attribute spreads so mutual matches can reliably occur during demos. This is a backend-only foundation — no frontend changes.

## Phases at a glance

| # | Phase | Backend | Frontend | Key deliverable |
|---|-------|---------|----------|-----------------|
| 1 | Infrastructure | ✓ | — | Docker Compose + JPA/Flyway/Postgres deps in pom.xml + datasource config |
| 2 | Schema | ✓ | — | Flyway migrations V1–V3: employee, catalog, and join tables |
| 3 | Entities & Repos | ✓ | — | JPA entities (Employee, Interest, Competency) + Spring Data repositories |
| 4 | Seed data | ✓ | — | Flyway V4–V5: ~15 interests, ~15 competencies, ~20 employees with overlapping selections |
| 5 | Verification | ✓ | — | Minimal REST endpoint + Testcontainers integration test confirming seeded data |

## Key decisions

- **Spring Data JPA (Hibernate)** for data access — full ORM, fastest to iterate on relational models.
- **Flyway migrations** for schema management — versioned SQL, repeatable, auditable.
- **Docker Compose** for local Postgres — reproducible, no host install needed.
- **spring-boot-docker-compose** for auto-starting Docker services on `spring-boot:run` — removes manual `docker compose up` step.
- **Testcontainers** for integration tests — tests run in CI without requiring Docker Compose to be pre-started.
- **BCrypt password hashes** in seed data — so F-02 (auth) can verify credentials without re-migration.
- **Feature-grouped packages** — `employee/` for the Employee entity/repo, `catalog/` for shared Interest & Competency items — per backend AGENTS.md convention.

## Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| Scope creep into swipe/match tables | Strict boundary: only employee + catalog + selections. Swipe/match tables land in their consuming slices (S-03/S-04). |
| Seed data too uniform → matches always score the same | Deliberate overlap clusters in V5: some employees share 5+ attributes, others share 1–2, creating score variance. |
| Docker Desktop not available on dev machines | Document the Docker prerequisite in README; Testcontainers covers CI. A local Postgres fallback profile can be added if needed. |
| Over-engineering password storage for a POC | BCrypt with a known demo password (`password123`); no rotation, no salting ceremony beyond BCrypt's built-in. |

## Estimated effort

**Size: M** (Medium) — ~3–5 hours of focused implementation. The work is straightforward (well-trodden Spring Boot + JPA + Flyway patterns), but involves multiple files across infra (Docker), config, migrations, entities, repositories, seed SQL, and tests. No novel algorithmic complexity.

