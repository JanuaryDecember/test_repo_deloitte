# /deloitter-release-readiness — Pre-demo checklist for deployable state

## Usage

```
/deloitter-release-readiness [scope]
```

Where `[scope]` is optional:
- No argument: full readiness check across all implemented slices.
- `<change-id>`: verify readiness for a specific slice only.
- `demo`: focused demo-day checklist (subset of full check, speed-oriented).

## Purpose

Run a structured pre-demo or pre-release verification that confirms the application is in a deployable, demonstrable state. Catches "works on my machine" issues, missing environment config, broken seeds, and unfinished wiring before stakeholders see the product.

## Inputs (read/check during execution)

1. **Roadmap:** `context/foundation/roadmap.md` — which slices should be implemented.
2. **Implementation reports:** `context/changes/*/implementation-report.md` — status of each slice.
3. **PRD:** `context/foundation/prd.md` — guardrails and demo expectations.
4. **Backend config:** `backend/src/main/resources/application.properties` (and any profile-specific variants if present).
5. **Frontend config:** `frontend/package.json`, `frontend/vite.config.ts`
6. **Docker Compose:** `backend/docker-compose.yml` or `backend/docker-compose.postgres.yml` (once created by F-01).
7. **Environment templates:** `.env` example files in `backend/` (once created; check `.gitignore` for ignored env files).
8. **Actual running state:** attempt to start both tiers and hit key endpoints.

## Process

### Step 1: Environment Pre-checks

| Check | How | Pass condition |
|-------|-----|----------------|
| Java available | `java -version` | Java 21+ |
| Node available | `node -v` | Node 18+ |
| Maven wrapper executable | `ls -la backend/mvnw` | Has `+x` permission |
| Container runtime available | `docker --version` or `podman --version` | Either responds (needed for local Postgres) |
| Compose available | `docker compose version` or `podman compose version` | Either responds |
| npm dependencies installed | `ls frontend/node_modules` | Exists and non-empty |
| Maven dependencies resolved | `backend/target/` or `.m2` cache | Present from recent build |

### Step 2: Backend Startup

1. **Start database** (if a Docker Compose file exists in `backend/`):
   ```bash
   # Use whichever container runtime is available:
   cd backend && docker compose up -d   # Docker users
   cd backend && podman compose up -d   # Podman users
   ```
   Wait for health check or port 5432 accepting connections. If no Docker Compose file exists yet (pre-F-01), skip and note as a known limitation.

2. **Start backend:**
   ```bash
   cd backend && ./mvnw spring-boot:run
   ```
   - Must start without exceptions.
   - Must complete Flyway migrations (check logs for "Successfully applied N migrations").
   - Must seed demo data (verify via log or endpoint).

3. **Verify key endpoints** (based on implemented slices):
   - Health/root: `GET http://localhost:8080/` → 200 or known response
   - Auth (if F-02 done): `POST /api/auth/login` with seed credentials → token
   - Matching (if on matching-logic branch): `POST /api/matching/best-match` → valid response
   - Candidates (if S-03 done): `GET /api/swipe/candidates` → list of candidates

### Step 3: Frontend Startup

1. **Build check:**
   ```bash
   cd frontend && npm run build
   ```
   Must complete with zero TypeScript errors and zero build errors.

2. **Dev server:**
   ```bash
   cd frontend && npm run dev
   ```
   Must start and be accessible at `http://localhost:5173` (default Vite port).

3. **Browser smoke:**
   - Page loads without console errors.
   - If login UI exists: can complete login flow with seed credentials.
   - If swipe UI exists: cards render, swipe gestures work.

### Step 4: Integration Verification

1. **Frontend → Backend connection:**
   - API calls from frontend reach backend (no CORS errors, no connection refused).
   - Auth token (if applicable) is passed correctly.

2. **Data flow:**
   - Seed data appears in UI (employee names, interests, etc.).
   - If matching exists: a match request returns a valid scored result.

3. **Guardrail spot-check:**
   - Score is NOT visible on swipe cards (check rendered DOM / API response).
   - No endpoint exposes one-sided like/pass intent.

### Step 5: Known Limitations Documentation

List any known issues or limitations that a demo presenter should be aware of:
- Features not yet implemented (upcoming roadmap slices).
- Demo-specific workarounds (e.g., "refresh after login to see candidates").
- Environment requirements (e.g., "must be on VPN for Azure DB").

## Output

Create or update `context/release-readiness.md`:

```markdown
---
checked: <today YYYY-MM-DD HH:MM>
scope: <full | change-id | demo>
result: <READY | READY_WITH_NOTES | NOT_READY>
---

# Release Readiness Report

## Summary

<1-2 sentences: Is the app ready for demo/deployment? What's the main risk?>

## Environment

| Check | Status | Notes |
|-------|--------|-------|
| Java 21+ | ✅/❌ | <version found> |
| Node 18+ | ✅/❌ | <version found> |
| Container runtime (Docker or Podman) | ✅/❌ | <version or "not available"> |
| Maven wrapper | ✅/❌ | <executable yes/no> |
| npm modules | ✅/❌ | <installed yes/no> |

## Backend

| Check | Status | Notes |
|-------|--------|-------|
| Database starts | ✅/❌ | <Docker / Azure / H2> |
| App starts clean | ✅/❌ | <startup time, any warnings> |
| Migrations applied | ✅/❌ | <N migrations, any failures> |
| Seed data present | ✅/❌ | <row counts or endpoint check> |
| Key endpoints respond | ✅/❌ | <list checked endpoints + status codes> |

## Frontend

| Check | Status | Notes |
|-------|--------|-------|
| Build succeeds | ✅/❌ | <any warnings> |
| Dev server starts | ✅/❌ | <port, any issues> |
| Page loads | ✅/❌ | <console errors?> |
| Core UI renders | ✅/❌ | <which views verified> |

## Integration

| Check | Status | Notes |
|-------|--------|-------|
| API connectivity | ✅/❌ | <CORS, auth, connection> |
| Data flows end-to-end | ✅/❌ | <seed data visible in UI?> |
| Guardrail compliance | ✅/❌ | <score hidden? intent hidden?> |

## Implemented Slices Status

| Slice | Status | Verified |
|-------|--------|----------|
| F-01 persistence-and-seed | ✅ Implemented / ⏳ Partial / ❌ Missing | ✅/❌ |
| F-02 auth-login-gate | ... | ... |
| S-01 employee-login | ... | ... |
| ... | ... | ... |

## Known Limitations

<Bulleted list of things a demo presenter should know about.>

## Blockers (if NOT_READY)

<What specifically prevents readiness and how to fix it.>

## Recommendations

<Prioritized list of actions to reach READY state.>
```

## Rules

1. **Actually run things.** Don't just check file existence — start the apps, hit the endpoints, verify responses. A file existing doesn't mean it works.

2. **Fail fast, report clearly.** If Step 2 (backend startup) fails, don't skip to Step 3 — report the failure with the error and stop. Fix-forward instructions are more useful than a half-complete report.

3. **Environment-aware.** Check which database profile is active (local Docker vs. Azure). If Azure is configured, verify connectivity. If Docker, verify container is running.

4. **Non-destructive.** Don't modify code or config during readiness checks. Only read, start, and verify. If something needs fixing, report it — don't auto-fix.

5. **Demo-day mode is fast.** When invoked with `demo`, skip build verification and focus on: "Can I start both apps right now and show the product?" Check runtime behavior only.

6. **Realistic timing.** Note startup times. If backend takes >30s to start (Flyway + JPA init), note it as a demo risk.

7. **Port conflicts.** Check if ports 8080 and 5173 are already in use before starting. Report conflicts.

8. **Seed credential documentation.** Always include the demo login credentials in the report (they're in the seed data, not secret) so the presenter doesn't have to hunt for them.

## Example Invocations

```
/deloitter-release-readiness
```
Full readiness check: environment, backend, frontend, integration, all slices.

```
/deloitter-release-readiness demo
```
Quick demo-day check: can both apps start and show the core flow?

```
/deloitter-release-readiness persistence-and-seed
```
Focused check: is F-01 specifically working correctly?

## Failure Modes

| Situation | Action |
|-----------|--------|
| Neither Docker nor Podman installed/running | Report as blocker; suggest H2 fallback or "start Docker Desktop / Podman machine" |
| Port 8080 already in use | Report which process holds it; suggest `lsof -i :8080` to identify |
| Frontend build fails (TS errors) | Report the specific errors; mark frontend as NOT_READY |
| Database connection refused | Check Docker status, verify port mapping, check credentials |
| Flyway migration failure | Report which version failed and the SQL error; mark backend as NOT_READY |
| No slices implemented yet | Report that the app is a bare scaffold; set result to READY_WITH_NOTES |
