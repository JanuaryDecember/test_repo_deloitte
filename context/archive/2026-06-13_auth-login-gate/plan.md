> **Archived:** 2026-06-13 15:55 | Change ID: `auth-login-gate` | Roadmap ID: `F-02`

---
change_id: "auth-login-gate"
roadmap_id: "F-02"
status: revised
created: 2026-06-13
prd_refs: [FR-001, Access Control]
prerequisites: [F-01 persistence-and-seed]
---

# Plan: Auth & login gate

## Context

This is the second foundation slice. It adds email+password authentication to the Spring Boot backend and a route-level guard to the React frontend, so that every downstream slice (S-01 onward) has an authenticated "me" identity to scope against. It does NOT build the login UI — that's S-01. This slice delivers the _mechanism_: verify credentials, issue a session, protect endpoints, and redirect unauthenticated SPA navigation to a login path.

Sequenced after F-01 because it verifies credentials against the `employee` table with BCrypt-hashed passwords that F-01 seeds. Deliberately thin per the PRD non-goal of "no production security / PII hardening" — this is verify-and-issue-session, not a hardened identity provider.

**Assumes F-01 is fully implemented:** the `employee` table exists with `email` and `password_hash` columns, seeded with BCrypt-hashed passwords (all `password123`).

## Decisions & Assumptions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Auth mechanism | **Server-side session + HttpOnly cookie** | Spring Security default; simplest for same-origin SPA+API; zero frontend token management. No need for JWT complexity in a single-service hackathon POC. |
| 2 | Frontend router | **React Router v7** | Most popular, largest ecosystem, simpler setup, plenty of auth-guard examples. Speed goal favors familiarity. |
| 3 | Session storage | **In-memory (default Spring)** | No Redis/JDBC session store needed for a demo with a single instance. Sessions survive only as long as the server process — acceptable for a disposable hackathon POC. |
| 4 | CORS | **Allow `http://localhost:5173`** (Vite dev server) | The SPA runs on a different port during development; credentials (cookies) must be allowed cross-origin. |
| 5 | Login endpoint | **`POST /api/auth/login`** with JSON body `{ email, password }` | REST-style; returns the authenticated user's profile (id, name, email). No form-login redirect — the SPA controls navigation. |
| 6 | Session identity endpoint | **`GET /api/auth/me`** | Returns the currently authenticated user or 401. The frontend uses this on app load to check session validity. |
| 7 | Frontend auth pattern | **AuthContext + ProtectedRoute wrapper** | A React context provides `user`/`login`/`logout`; a `<ProtectedRoute>` component wraps routes and redirects to `/login` if unauthenticated. |
| 8 | Password encoder | **BCryptPasswordEncoder** | Matches the BCrypt hashes seeded in F-01. |
| 9 | Frontend scope | **Plumbing only — no login form UI** | F-02 delivers the auth infrastructure (API client, context, guard). The actual login page with the form is S-01's scope. A minimal placeholder at `/login` is added for verification only. |

## Phases

### Phase 1: Backend — Spring Security configuration

**Goal:** Spring Security is on the classpath, configured for session-based auth with no form-login, CORS enabled for the frontend, and all `/api/**` endpoints require authentication (except the login endpoint).

#### Backend

- [ ] Add dependency to `backend/pom.xml`:
  - `org.springframework.boot:spring-boot-starter-security`
- [ ] Create `backend/src/main/java/com/example/deloitter/auth/SecurityConfig.java`:
  - `@Configuration @EnableWebSecurity`
  - Define `SecurityFilterChain` bean:
    - Disable CSRF (the SPA uses JSON + cookie, not browser forms; acceptable for POC)
    - Configure session management: `SessionCreationPolicy.IF_REQUIRED`
    - Permit `/api/auth/login` and `/api/auth/logout` unauthenticated
    - Permit `/api/health` unauthenticated (simple connectivity check for dev/demo use)
    - Require authentication for all other `/api/**` paths
    - Return 401 (not redirect) for unauthenticated requests (`authenticationEntryPoint` returning 401 JSON)
  - Define `CorsConfigurationSource` bean:
    - Allow origin `http://localhost:5173`
    - Allow credentials (cookies)
    - Allow methods: GET, POST, PUT, DELETE, OPTIONS
    - Allow headers: Content-Type, Accept
  - Define `PasswordEncoder` bean: `BCryptPasswordEncoder`
- [ ] Add to `backend/src/main/resources/application.properties`:
  - `server.servlet.session.cookie.same-site=lax`
  - `server.servlet.session.cookie.http-only=true`
  - `server.servlet.session.timeout=30m`

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `.\mvnw.cmd spring-boot:run` — app starts without errors (Spring Security auto-configures with the custom filter chain).
- [ ] `curl http://localhost:8080/api/employees/count` → returns 401 (previously open endpoint is now protected).
- [ ] The login endpoint path (`/api/auth/login`) is reachable (will return 405 until Phase 2 adds the controller).

---

### Phase 2: Backend — Auth service & endpoints

**Goal:** A login endpoint verifies email+password against the seeded employee table, creates a session, and returns the authenticated user. A `/me` endpoint returns the current session's user. A logout endpoint invalidates the session.

#### Backend

- [ ] Create `backend/src/main/java/com/example/deloitter/auth/AuthUserDetailsService.java`:
  - Implements `UserDetailsService`
  - Loads employee by email from `EmployeeRepository`
  - Returns a Spring Security `User` with the employee's email as username, `passwordHash` as the encoded password, and a single authority `ROLE_USER`
- [ ] Create `backend/src/main/java/com/example/deloitter/auth/LoginRequest.java`:
  - Record/DTO: `String email`, `String password`
- [ ] Create `backend/src/main/java/com/example/deloitter/auth/AuthResponse.java`:
  - Record/DTO: `Long id`, `String email`, `String firstName`, `String lastName`
- [ ] Create `backend/src/main/java/com/example/deloitter/auth/AuthController.java`:
  - `@RestController @RequestMapping("/api/auth")`
  - Inject `SecurityContextRepository` (Spring provides `HttpSessionSecurityContextRepository` by default)
  - `POST /api/auth/login`:
    - Accepts `@RequestBody LoginRequest`
    - Uses `AuthenticationManager.authenticate(UsernamePasswordAuthenticationToken)` to verify credentials
    - On success: creates a new `SecurityContext`, sets authentication on it, sets it on `SecurityContextHolder`, **then calls `securityContextRepository.saveContext(context, request, response)`** to persist the authentication into the HTTP session (required in Spring Security 6+/7.x — the framework no longer auto-saves)
    - Returns `AuthResponse` (200)
    - On failure: returns 401 `{ "error": "Invalid credentials" }`
  - `GET /api/auth/me`:
    - Returns `AuthResponse` for the currently authenticated user (looked up from the SecurityContext principal)
    - Returns 401 if no session
  - `POST /api/auth/logout`:
    - Invalidates the current session
    - Returns 204 No Content
- [ ] Update `SecurityConfig.java`:
  - Add `AuthenticationManager` bean (using `AuthenticationConfiguration`)
  - Add `AuthUserDetailsService` to the auth configuration (via `DaoAuthenticationProvider` or auto-wired)

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `.\mvnw.cmd spring-boot:run` (with Postgres running + F-01 seed data applied)
- [ ] `curl -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d '{"email":"<seeded-email>","password":"password123"}' -c cookies.txt` → returns 200 with user JSON + sets session cookie
- [ ] `curl http://localhost:8080/api/auth/me -b cookies.txt` → returns 200 with same user JSON
- [ ] `curl http://localhost:8080/api/auth/me` (no cookie) → returns 401
- [ ] `curl -X POST http://localhost:8080/api/auth/login -H "Content-Type: application/json" -d '{"email":"wrong@deloitte.demo","password":"bad"}' ` → returns 401

---

### Phase 3: Frontend — API client & auth plumbing

**Goal:** The React app has a typed API client, an auth context that tracks session state, and a route guard that redirects unauthenticated users to `/login`.

#### Frontend

- [ ] Install dependencies:
  - `npm install react-router` (React Router v7)
- [ ] Create `frontend/src/api/client.ts`:
  - Base fetch wrapper that:
    - Prepends `http://localhost:8080` (or uses env var `VITE_API_URL`)
    - Sends `credentials: 'include'` (to include session cookies cross-origin)
    - Sets `Content-Type: application/json`
    - Throws on non-OK responses (with typed error)
  - Export typed functions:
    - `login(email: string, password: string): Promise<AuthUser>`
    - `logout(): Promise<void>`
    - `fetchMe(): Promise<AuthUser>`
- [ ] Create `frontend/src/types/auth.ts`:
  - `export interface AuthUser { id: number; email: string; firstName: string; lastName: string; }`
- [ ] Create `frontend/src/auth/AuthContext.tsx`:
  - React context providing: `user: AuthUser | null`, `loading: boolean`, `login(email, password): Promise<void>`, `logout(): Promise<void>`
  - On mount: calls `fetchMe()` to check existing session — sets `user` or stays null
  - `login`: calls API `login()`, sets user on success, throws on failure
  - `logout`: calls API `logout()`, clears user
- [ ] Create `frontend/src/auth/AuthProvider.tsx`:
  - Wraps children in `AuthContext.Provider`
  - Shows a loading spinner/placeholder while the initial `fetchMe()` is in flight
- [ ] Create `frontend/src/auth/ProtectedRoute.tsx`:
  - Uses `useAuth()` hook; if `user` is null and not loading → redirects to `/login` via `<Navigate to="/login" />`
  - Otherwise renders `<Outlet />` (nested route content)
- [ ] Create `frontend/src/auth/useAuth.ts`:
  - Custom hook: `useContext(AuthContext)` with a guard that throws if used outside provider
- [ ] Update `frontend/src/main.tsx`:
  - Wrap `<App />` in `<BrowserRouter>` and `<AuthProvider>`
- [ ] Update `frontend/src/App.tsx`:
  - Replace the default Vite template content with a route structure:
    - `/login` → placeholder `<LoginPlaceholder />` (just text: "Login page — coming in S-01")
    - `/*` (all other routes) → wrapped in `<ProtectedRoute>`:
      - `/` → placeholder `<Home />` (just text: "Welcome, {user.firstName}! App content coming soon.")
  - This proves the guard works: unauthenticated → redirected to `/login`; authenticated → sees Home.
- [ ] Create `frontend/src/pages/LoginPlaceholder.tsx`:
  - Minimal component: heading + "Login form will be implemented in S-01."
  - Optionally: a dev-only quick-login form (email + password fields + submit) to verify the full flow works end-to-end without waiting for S-01's polished UI. Mark it clearly as temporary/verification-only.
- [ ] Create `frontend/src/pages/Home.tsx`:
  - Minimal component displaying `"Welcome, {user.firstName}!"` using `useAuth()` — proves session is active and identity is available.
- [ ] Update `frontend/vite.config.ts`:
  - Add a dev-server proxy: `server: { proxy: { '/api': 'http://localhost:8080' } }` — this proxies all `/api` requests to the backend during development, avoiding CORS issues entirely for the dev workflow. The API client can then use relative paths (`/api/auth/login`) instead of a full URL when running under the Vite dev server.
  - Retain `VITE_API_URL` env var support in the API client as a fallback for non-proxied environments.

#### Backend

- (no backend work in this phase)

#### Verification

- [ ] `npm run build` succeeds (TypeScript compiles with no errors)
- [ ] `npm run dev` — app loads at `http://localhost:5173`:
  - Navigating to `/` with no session → redirected to `/login`
  - The LoginPlaceholder page renders
- [ ] (With backend running) Using the dev-only quick-login form or `curl` to create a session, then visiting `/` → the Home page renders with the user's first name

---

### Phase 4: End-to-end wiring & test

**Goal:** Verify the full auth round-trip (frontend → backend → database → session → frontend) and add a backend integration test for the auth endpoints.

#### Backend

- [ ] Add test dependency to `backend/pom.xml`:
  - `org.springframework.security:spring-security-test` (test scope) — provides `SecurityMockMvcRequestPostProcessors` and other security testing utilities
- [ ] Create `backend/src/test/java/com/example/deloitter/auth/AuthControllerTest.java`:
  - `@SpringBootTest` + `@AutoConfigureMockMvc` integration test:
    - Test: POST `/api/auth/login` with valid seeded credentials → 200 + session cookie
    - Test: POST `/api/auth/login` with invalid credentials → 401
    - Test: GET `/api/auth/me` with valid session → 200 + user JSON
    - Test: GET `/api/auth/me` without session → 401
    - Test: POST `/api/auth/logout` with session → 204 + session invalidated
    - Test: GET `/api/employees/count` without auth → 401
  - Uses Testcontainers (from F-01's test infra) for the database

#### Frontend

- [ ] (If not already done) Verify `npm run lint` passes with the new files

#### Verification

- [ ] `.\mvnw.cmd test` — all tests pass (existing F-01 tests + new auth tests)
- [ ] Full manual flow:
  1. Start Postgres (Docker/Podman)
  2. `.\mvnw.cmd spring-boot:run` in `backend/`
  3. `npm run dev` in `frontend/`
  4. Open `http://localhost:5173` → redirected to `/login`
  5. Log in with seeded credentials (e.g., `alice.johnson@deloitte.demo` / `password123`)
  6. → Redirected to `/` showing "Welcome, Alice!"
  7. Refresh the page → still authenticated (session persists)
  8. Logout → redirected to `/login`

---

## Integration & Smoke Test

- [ ] From a clean state: Postgres running, `.\mvnw.cmd spring-boot:run` starts, frontend `npm run dev` starts.
- [ ] Unauthenticated access to any `/api/**` endpoint (except login) → 401.
- [ ] Login with valid seeded credentials → session cookie issued, `/api/auth/me` returns user.
- [ ] Frontend route guard: unauthenticated browser → `/login`; authenticated → protected content.
- [ ] Logout invalidates session; subsequent `/api/auth/me` → 401; frontend redirects to `/login`.
- [ ] **Guardrail check:** No swipe/match intent is exposed by auth endpoints. Auth only reveals the logged-in user's own identity (id, email, name) — no other user's data is accessible through auth.
- [ ] **Guardrail check:** No compatibility score is exposed anywhere (no scoring endpoints exist yet).

## Open Questions

1. **Should the dev-only quick-login form in LoginPlaceholder be kept or removed when S-01 lands?** — It's marked temporary. S-01 replaces it with the real login UI. Non-blocking.
2. **CORS origin for production?** — Currently hardcoded to `http://localhost:5173`. For a deployed demo, this would need updating. Non-blocking for local hackathon development.
3. **Session timeout duration?** — Plan uses 30 minutes (`server.servlet.session.timeout=30m`). Acceptable for a demo; adjust if needed. Non-blocking.

