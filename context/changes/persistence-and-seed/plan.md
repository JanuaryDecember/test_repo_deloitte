---
change_id: "persistence-and-seed"
roadmap_id: "F-01"
status: revised
created: 2026-06-13
prd_refs: [Account provisioning, Data handling NFR, Business Logic]
prerequisites: []
---

# Plan: Persistence & seed foundation

## Context

This is the first foundation slice and the prerequisite for everything else on the roadmap. It wires PostgreSQL to the Spring Boot backend, establishes the minimal schema for employee accounts and the predefined interests/competencies catalog, and populates enough demo employees (with varied attribute spreads) that mutual matches can reliably occur during a demo.

It is sequenced first because no downstream slice — login (S-01), interest selection (S-02), the swipe stack (S-03), or match reveal (S-04) — is buildable or verifiable without persistent identities and a catalog to select from.

This slice does NOT introduce:
- Auth/security (that's F-02)
- Swipe or match tables (those land in S-03/S-04)
- Any frontend UI (this is a backend-only foundation)
- API controllers beyond a minimal health/verification endpoint

## Decisions & Assumptions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | ORM / data-access layer | **Spring Data JPA (Hibernate)** | Full ORM with entity annotations, auto-generated queries, and repository interfaces — fastest to build relational models for a hackathon POC. |
| 2 | Schema management | **Flyway migrations** | Versioned SQL files (V1, V2, …) give repeatable, auditable schema evolution. Industry standard with Spring Boot. |
| 3 | Database provisioning | **Docker Compose** | A `docker-compose.yml` in `backend/` spins up Postgres in a container — reproducible, no host install needed. |
| 4 | Seed scale | **~20 demo employees, ~15 interests, ~15 competencies, 4 service lines** | Enough variety that compatibility scores vary and mutual matches can occur in demos. Disposable per PRD. |
| 5 | Password storage | **BCrypt hash** (plain-text passwords documented for demo login) | Passwords are hashed even in the POC so the auth slice (F-02) can verify them directly without migration. |
| 6 | Feature packaging | Group by feature: `employee/` package for Employee entity/repo; `catalog/` package for Interest & Competency | Per `backend/AGENTS.md` convention (group by feature, not by layer). Interest/Competency are shared catalog items distinct from the employee concept. |
| 7 | Integration testing | **Testcontainers** for `@SpringBootTest` integration tests | Tests run in CI without requiring Docker Compose to be pre-started; Spring Boot 3.1+ `@ServiceConnection` makes it zero-config. |

## Phases

### Phase 1: Infrastructure — Docker Compose + Maven dependencies

**Goal:** PostgreSQL is runnable via Docker and the Spring Boot app can connect to it.

#### Backend

- [ ] Create `backend/docker-compose.yml` with a `postgres` service:
  - Image: `postgres:16-alpine`
  - Port: `5432:5432`
  - Environment: `POSTGRES_DB=deloitter`, `POSTGRES_USER=deloitter`, `POSTGRES_PASSWORD=deloitter`
  - Volume: named volume `pgdata` for persistence across restarts
- [ ] Add dependencies to `backend/pom.xml`:
  - `spring-boot-starter-data-jpa`
  - `org.postgresql:postgresql` (runtime scope)
  - `org.flywaydb:flyway-core`
  - `org.flywaydb:flyway-database-postgresql` (Flyway's Postgres module)
  - `spring-boot-docker-compose` (runtime scope) — auto-starts Docker Compose services on `spring-boot:run`, removing the manual `docker compose up -d` prerequisite
- [ ] Configure `backend/src/main/resources/application.properties`:
  - `spring.datasource.url=jdbc:postgresql://localhost:5432/deloitter`
  - `spring.datasource.username=deloitter`
  - `spring.datasource.password=deloitter`
  - `spring.jpa.hibernate.ddl-auto=validate` (Flyway owns the schema)
  - `spring.jpa.open-in-view=false`
  - `spring.flyway.enabled=true`

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `docker compose up -d` in `backend/` — Postgres container starts and accepts connections on port 5432.
- [ ] Run `.\mvnw.cmd spring-boot:run` — app starts without connection errors. Flyway initializes (no migrations to apply yet, but no failure). With `spring-boot-docker-compose` on the classpath, the Docker Compose services auto-start so `docker compose up -d` is optional for subsequent runs.

---

### Phase 2: Schema — Flyway migrations

**Goal:** The database schema for employees, the interest/competency catalog, and the join tables exists and is repeatable.

#### Backend

- [ ] Create `backend/src/main/resources/db/migration/V1__create_employee_table.sql`:
  ```sql
  CREATE TABLE employee (
      id            BIGSERIAL PRIMARY KEY,
      email         VARCHAR(255) NOT NULL UNIQUE,
      password_hash VARCHAR(255) NOT NULL,
      first_name    VARCHAR(100) NOT NULL,
      last_name     VARCHAR(100) NOT NULL,
      service_line  VARCHAR(100),
      role_family   VARCHAR(100),
      contact_info  VARCHAR(255),  -- Teams/email handle for match reveal
      created_at    TIMESTAMP NOT NULL DEFAULT NOW()
  );
  ```
- [ ] Create `backend/src/main/resources/db/migration/V2__create_catalog_tables.sql`:
  ```sql
  CREATE TABLE interest (
      id   BIGSERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE
  );

  CREATE TABLE competency (
      id   BIGSERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL UNIQUE
  );
  ```
- [ ] Create `backend/src/main/resources/db/migration/V3__create_employee_selections.sql`:
  ```sql
  CREATE TABLE employee_interest (
      employee_id BIGINT NOT NULL REFERENCES employee(id),
      interest_id BIGINT NOT NULL REFERENCES interest(id),
      PRIMARY KEY (employee_id, interest_id)
  );

  CREATE TABLE employee_competency (
      employee_id   BIGINT NOT NULL REFERENCES employee(id),
      competency_id BIGINT NOT NULL REFERENCES competency(id),
      PRIMARY KEY (employee_id, competency_id)
  );
  ```

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `.\mvnw.cmd spring-boot:run` — Flyway applies V1, V2, V3 without errors; JPA validation passes (no entity mismatch yet — add `spring.jpa.hibernate.ddl-auto=none` temporarily or allow validate to warn until entities exist in Phase 3).

---

### Phase 3: JPA Entities & Repositories

**Goal:** Java domain model maps to the schema; repositories provide data access for downstream slices.

#### Backend

- [ ] Create package `com.example.deloitter.employee/` (feature-grouped).
- [ ] Create package `com.example.deloitter.catalog/` (shared catalog items).
- [ ] Create `backend/src/main/java/com/example/deloitter/employee/Employee.java`:
  - `@Entity` with fields mapping to the `employee` table.
  - `@ManyToMany` for `interests` (join table `employee_interest`) and `competencies` (join table `employee_competency`).
  - Fields: `id`, `email`, `passwordHash`, `firstName`, `lastName`, `serviceLine`, `roleFamily`, `contactInfo`, `createdAt`.
- [ ] Create `backend/src/main/java/com/example/deloitter/catalog/Interest.java`:
  - `@Entity` with `id`, `name`.
- [ ] Create `backend/src/main/java/com/example/deloitter/catalog/Competency.java`:
  - `@Entity` with `id`, `name`.
- [ ] Create `backend/src/main/java/com/example/deloitter/employee/EmployeeRepository.java`:
  - `extends JpaRepository<Employee, Long>`
  - `Optional<Employee> findByEmail(String email);`
- [ ] Create `backend/src/main/java/com/example/deloitter/catalog/InterestRepository.java`:
  - `extends JpaRepository<Interest, Long>`
- [ ] Create `backend/src/main/java/com/example/deloitter/catalog/CompetencyRepository.java`:
  - `extends JpaRepository<Competency, Long>`

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `.\mvnw.cmd spring-boot:run` — Hibernate validates entities against the Flyway-created schema without errors.
- [ ] Run `.\mvnw.cmd test` — existing `DeloitterApplicationTests` context-load test passes. **Note:** Docker Compose Postgres must be running (Testcontainers is added in Phase 5; until then, tests require the local database).

---

### Phase 4: Seed data — demo employees & catalog

**Goal:** The database is populated with a realistic spread of demo employees, interests, and competencies so downstream slices have data to work with immediately.

#### Backend

- [ ] Create `backend/src/main/resources/db/migration/V4__seed_catalog.sql`:
  - Insert ~15 interests (e.g., "Machine Learning", "Hiking", "Public Speaking", "Board Games", "Photography", "Sustainability", "Cooking", "Travel", "Music", "Reading", "Fitness", "Gaming", "Volunteering", "Startups", "Design Thinking").
  - Insert ~15 competencies (e.g., "Java", "Python", "Cloud Architecture", "Data Analytics", "Project Management", "UX Design", "Financial Modeling", "Cybersecurity", "Agile Coaching", "Strategy Consulting", "Change Management", "DevOps", "AI/ML Engineering", "Risk Assessment", "Stakeholder Management").
- [ ] Create `backend/src/main/resources/db/migration/V5__seed_employees.sql`:
  - Insert ~20 demo employees with:
    - Realistic names, unique emails (`firstname.lastname@deloitte.demo`)
    - BCrypt-hashed passwords (all use `password123` for demo convenience — document this)
    - Varied `service_line` values (Consulting, Audit & Assurance, Tax & Legal, Risk Advisory)
    - Varied `role_family` values (Analyst, Consultant, Senior Consultant, Manager)
    - `contact_info` as Teams/email handles
  - Assign each employee 3–7 interests and 3–6 competencies from the catalog, with deliberate overlap clusters so compatibility scores vary (some employees share many attributes, others share few).

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `.\mvnw.cmd spring-boot:run` — Flyway applies V4 and V5; no errors.
- [ ] Connect to Postgres (`docker exec -it <container> psql -U deloitter`) and verify:
  - `SELECT count(*) FROM employee;` → ~20
  - `SELECT count(*) FROM interest;` → ~15
  - `SELECT count(*) FROM competency;` → ~15
  - `SELECT count(*) FROM employee_interest;` → varied (60–140 rows)
  - `SELECT count(*) FROM employee_competency;` → varied (60–120 rows)

---

### Phase 5: Verification endpoint & integration test

**Goal:** A lightweight way to confirm the persistence layer is wired and seeded, usable by downstream slices and CI.

#### Backend

- [ ] Create `backend/src/main/java/com/example/deloitter/employee/EmployeeController.java`:
  - `@RestController @RequestMapping("/api/employees")`
  - `GET /api/employees/count` → returns `{ "count": N }` (simple health-check for persistence verification; will be expanded or replaced by downstream slices).
- [ ] Create `backend/src/test/java/com/example/deloitter/employee/EmployeeRepositoryTest.java`:
  - `@SpringBootTest` integration test that verifies:
    - The context loads (Flyway runs, JPA validates).
    - `employeeRepository.count() >= 20`
    - `interestRepository.count() >= 15`
    - `competencyRepository.count() >= 15`
    - An employee loaded by email has non-empty interests and competencies sets.
- [ ] Update `backend/pom.xml` to add test dependencies:
  - `org.testcontainers:postgresql` (test scope)
  - `org.springframework.boot:spring-boot-testcontainers` (test scope)
  - Add `<dependencyManagement>` for Testcontainers BOM if not present.
- [ ] Create `backend/src/test/java/com/example/deloitter/TestDeloitterApplication.java`:
  - Test configuration class that defines a `@ServiceConnection` `PostgreSQLContainer` bean for all integration tests.

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `.\mvnw.cmd test` — all tests pass (Testcontainers spins up a Postgres container, Flyway seeds it, JPA validates, repository queries succeed).
- [ ] Run `.\mvnw.cmd spring-boot:run` (with Docker Compose Postgres up) → `GET http://localhost:8080/api/employees/count` returns `{"count":20}` (or similar).

---

## Integration & Smoke Test

- [ ] From a clean state: `docker compose up -d` in `backend/`, then `.\mvnw.cmd spring-boot:run` — app starts, Flyway creates schema and seeds data, JPA validates.
- [ ] `curl http://localhost:8080/api/employees/count` → confirms persistence is live and seeded.
- [ ] `.\mvnw.cmd test` passes in CI without Docker Compose (Testcontainers provides the database).
- [ ] No frontend impact — the frontend is unchanged in this slice.
- [ ] **Guardrail check:** No swipe/match tables exist yet — impossible to leak intent. Schema only stores identity + catalog selections.

## Open Questions

1. **Exact number of demo employees?** Plan uses ~20. If the user wants a different count, adjust V5. Non-blocking — 20 is sufficient for demo matches.
2. **Should background attributes (service_line, role_family) be normalized into separate tables?** Plan keeps them as VARCHAR columns on `employee` for simplicity. Can normalize later if the scoring algorithm needs to enumerate all values. Non-blocking.
3. **Testcontainers Docker requirement for CI:** CI runners need Docker to run integration tests. If this is a problem, an H2-based test profile can be added as a fallback. Non-blocking for local development.
