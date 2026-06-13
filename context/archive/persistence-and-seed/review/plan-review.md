---
change_id: "persistence-and-seed"
reviewed: 2026-06-13
plan_status_before: draft
plan_status_after: revised
findings_total: 5
critical: 0
major: 0
minor: 2
suggestions: 3
fixes_applied: 5
---

# Plan Review: Persistence & seed foundation

## Summary

The plan is solid and ready for implementation. It correctly covers all PRD refs (Account provisioning, Data handling NFR, Business Logic), stays strictly within F-01 scope, uses proper Spring Boot / JPA / Flyway patterns for the declared tech stack, and does not violate any guardrails. No critical or major issues were found — only two minor documentation inaccuracies in verification steps and three optional improvements, all of which have been applied.

## Findings

### 🔴 Critical

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| — | — | None | N/A |

### 🟠 Major

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| — | — | None | N/A |

### 🟡 Minor

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Technical Correctness | Phase 1 verification claimed the app "will fail on missing migrations until Phase 2" — but Flyway with no migration files does NOT fail; it creates the history table and reports 0 applied. The app starts cleanly. | Fixed — verification rewritten to state the app starts successfully; Flyway initializes with nothing to apply. |
| 2 | Completeness | Phase 3 verification said to run `mvnw test` but didn't note that Docker Compose Postgres must be running (Testcontainers isn't added until Phase 5). Implementer would see a confusing connection failure if Docker is down. | Fixed — added explicit note that Docker Compose must be running for tests in Phases 1–4. |

### 🔵 Suggestions

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Brief ↔ Plan Consistency | Plan-brief listed "Testcontainers" as a key decision but the plan's numbered Decisions table didn't include it. | Fixed — added as Decision #7 in plan.md. |
| 2 | Technical Correctness | No `spring-boot-docker-compose` dependency — developers must manually run `docker compose up -d` before `spring-boot:run`. Adding it auto-starts Docker services, improving DX. | Fixed — added `spring-boot-docker-compose` (runtime scope) to Phase 1 dependencies. |
| 3 | Technical Correctness | `Interest` and `Competency` entities grouped under `employee/` package, but they're shared catalog items used across features. A separate `catalog/` package better models the domain and aligns with AGENTS.md's feature-grouping example. | Fixed — Phase 3 now creates a `catalog/` package for Interest/Competency entities and repos; Employee stays in `employee/`. |

## Fixes Applied

1. **Phase 1 verification (plan.md):** Replaced incorrect "will fail on missing migrations" note with accurate statement that Flyway initializes cleanly with no migrations. Added note about `spring-boot-docker-compose` making manual `docker compose up` optional.

2. **Phase 1 dependencies (plan.md):** Added `spring-boot-docker-compose` (runtime scope) to the Maven dependencies list.

3. **Phase 3 entities (plan.md):** Split into two packages — `com.example.deloitter.employee/` (Employee entity + repo) and `com.example.deloitter.catalog/` (Interest, Competency entities + repos).

4. **Phase 3 verification (plan.md):** Added bold note that Docker Compose Postgres must be running for tests until Testcontainers is added in Phase 5.

5. **Decisions table (plan.md):** Updated Decision #6 to reflect the `employee/` + `catalog/` split; added Decision #7 for Testcontainers.

6. **plan-brief.md:** Updated status to `revised`; added `spring-boot-docker-compose` and Testcontainers as explicit key decisions; updated package note to mention both `employee/` and `catalog/`.

## Verdict

**Status:** PASS — ready for implementation

The plan is well-structured, technically correct, properly scoped, and now free of documentation inaccuracies. All phases are independently verifiable, the schema design supports downstream slices without over-reaching, and guardrails are respected (no swipe/match data exists at this layer). The applied fixes improve clarity and developer experience but none were blocking. Proceed to implementation.

