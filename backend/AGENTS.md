# Repository Guidelines — Backend (Deloitter API)

Scoped guidance for the `backend/` tier. For product vision, guardrails, and the change pipeline, see the root [`CLAUDE.md`](../CLAUDE.md).

## Stack

Spring Boot 4.1, Java 21, Maven (wrapper checked in). Package root `com.example.deloitter`. REST API consumed by the `frontend/` SPA over HTTP. Currently a bare scaffold: `DeloitterApplication` (the `@SpringBootApplication` entrypoint) and zero controllers.

## Commands

Run from `backend/`. Use the Maven wrapper, not a global `mvn`.

- Dev server: `./mvnw spring-boot:run` — PowerShell: `.\mvnw.cmd spring-boot:run`
- Build / package: `./mvnw clean package`
- All tests: `./mvnw test`
- Single test class: `./mvnw test -Dtest=DeloitterApplicationTests`
- Single test method: `./mvnw test -Dtest=ClassName#methodName`

## Layout & conventions

- Main code: `src/main/java/com/example/deloitter/`, resources in `src/main/resources/` (`application.properties`). Tests mirror the package under `src/test/java/`.
- As domain code lands, group by feature (e.g. `auth/`, `interests/`, `swipe/`, `match/`) rather than by layer.
- Persistence and security are **not** wired yet — they arrive with their roadmap slices: Postgres + seed in **F-01** (`persistence-and-seed`), Spring Security + sessions in **F-02** (`auth-login-gate`). Add those dependencies to `pom.xml` only as part of the consuming change, keeping the scaffold minimal until then.

## Tier-specific rules

- This is the system of record for the **privacy guardrail**: like/pass intent must never be queryable by the other party. Design swipe/match endpoints so a non-match's intent is unreachable — the reveal happens only when a match exists.
- The **compatibility score** is computed here as proportional overlap of interests/competencies/background — it must be deterministic and explainable, never random. Never send the score to the client while a candidate is still being swiped; expose it only on a confirmed mutual match.
- Demo data is **seeded and disposable** (no self-registration). Seed logic belongs in F-01.
