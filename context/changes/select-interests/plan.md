---
change_id: "select-interests"
roadmap_id: "S-02"
status: revised
created: 2026-06-13
prd_refs: [FR-002]
prerequisites: [F-01 persistence-and-seed, S-01 employee-login]
---

# Plan: Select interests & competencies

## Context

This slice delivers the ability for a logged-in user to pick their interests and competencies from the predefined catalog. Selections persist to their profile and become the inputs the compatibility score consumes in S-03 (swipe stack ranking). It is the first feature that makes the demo interactive — FR-002 explicitly kept selection UI because "user-driven selection makes the demo interactive and the compatibility score feel earned."

Sequenced after F-01 (catalog tables + seed data exist) and S-01 (user can log in and reach the app shell). Must be done before S-03 because ranking needs the logged-in user's own selected attributes to compute compatibility.

**Assumes F-01 and S-01 are fully implemented:** Postgres running with seeded employees, interest/competency catalog tables populated (~15 items each), `employee_interest` and `employee_competency` join tables with seeded assignments, JPA entities and repositories for Employee/Interest/Competency exist, backend auth endpoints working, frontend has React Router, AuthContext, ProtectedRoute, AppShell with nav tabs, and the login flow is complete.

**Design reference:** `frontend/context/foundation/design/Deloitter.dc.html` lines 249–277 — the Profile section. This is the authoritative visual spec for the selection UI (chip-toggle pills for interests and competencies, a "Save profile" button, user header card).

## Decisions & Assumptions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | API design — catalog retrieval | **`GET /api/catalog`** returns `{ interests: [...], competencies: [...] }` in a single call | One request loads all chip options. The catalog is small (~15+~15 items), so combining reduces latency vs. two separate calls. |
| 2 | API design — read selections | **`GET /api/profile/selections`** returns the authenticated user's current interest and competency IDs | Scoped to the session user (no user ID in path — privacy by design). Separate from catalog so the UI can compose them. |
| 3 | API design — save selections | **`PUT /api/profile/selections`** with body `{ interestIds: [...], competencyIds: [...] }` → replaces all selections atomically | Full replacement is simpler than individual toggle endpoints. The UI collects all toggles and saves at once on "Save profile." Idempotent PUT semantics. |
| 4 | Minimum selections | **No enforcement in S-02** — user may save with 0 selections | Keeps scope tight. S-03 can handle a user with no selections gracefully (empty stack / prompt to pick interests). Avoids UI validation complexity. |
| 5 | Profile page route | **`/profile`** — wired to the "Profile" nav tab in the AppShell | Follows the design comp's navigation structure (Discover / Matches / Profile tabs). |
| 6 | UI pattern | **Chip-toggle pills** (tap to select/deselect) matching design comp exactly | Selected: green bg + white text. Unselected: white bg + muted text + light border. Uses the oklch palette from design tokens. |
| 7 | Save feedback | **Toast notification** ("Profile updated") | Matches the design comp's toast pattern (line 319-321). Appears on successful save, auto-dismisses. |
| 8 | Seeded user selections | **Pre-seeded selections are shown as pre-selected** | F-01 seeds employees with 3-7 interests/3-6 competencies. The logged-in user sees their seed selections already toggled on and can change them. This makes the demo feel populated from the start. |
| 9 | Profile header card | **Show user info (name, role, service line)** from the auth session or a profile endpoint | Matches design comp lines 251-257. Requires the backend to expose role/service-line in the profile response (or reuse data from the session). |
| 10 | Backend response for user profile | **Extend `GET /api/auth/me`** or add **`GET /api/profile`** with full employee fields | Plan adds a dedicated `GET /api/profile` endpoint returning name, role, serviceLine, office, initials — keeping auth endpoints thin. |
| 11 | Feature package naming | **`catalog/` and `profile/`** instead of `interests/` | AGENTS.md lists `interests/` as an example, but the catalog endpoint groups both interests *and* competencies, so `catalog/` is a better semantic fit. `profile/` groups user-facing profile + selection endpoints. |
| 12 | Automated tests | **Not included in this slice** | The hackathon speed goal favours manual verification over test scaffolding. The backend has `spring-boot-starter-webmvc-test` available — an implementer may optionally add a `@WebMvcTest` for the controllers if time allows, but it is not required for acceptance. |

## Phases

### Phase 1: Backend — Catalog & selection endpoints

**Goal:** The backend exposes the interest/competency catalog and CRUD for the authenticated user's selections.

#### Backend

- [ ] Create `backend/src/main/java/com/example/deloitter/catalog/CatalogController.java`:
  - `@RestController @RequestMapping("/api/catalog")`
  - Inject `InterestRepository` and `CompetencyRepository` (simple read-only endpoint — no service layer needed)
  - `GET /api/catalog` → returns `CatalogResponse` (list of all interests + list of all competencies)
  - Each item: `{ id, name }`
  - Public within the authenticated boundary (requires auth per SecurityConfig, but no additional role check)
- [ ] Create `backend/src/main/java/com/example/deloitter/catalog/CatalogResponse.java`:
  - Record/DTO: `List<CatalogItem> interests`, `List<CatalogItem> competencies`
- [ ] Create `backend/src/main/java/com/example/deloitter/catalog/CatalogItem.java`:
  - Record/DTO: `Long id`, `String name`
- [ ] Create `backend/src/main/java/com/example/deloitter/profile/ProfileController.java`:
  - `@RestController @RequestMapping("/api/profile")`
  - Inject `ProfileService` (the controller delegates all logic to the service)
  - `GET /api/profile` → returns `ProfileResponse` for the authenticated user:
    - Resolves employee from `SecurityContextHolder` principal (email) via `ProfileService`
    - Returns `{ id, firstName, lastName, email, serviceLine, roleFamily, contactInfo, initials }`
    - `initials` is computed as `firstName.charAt(0) + lastName.charAt(0)` (uppercased)
  - `GET /api/profile/selections` → returns `SelectionsResponse`:
    - `{ interestIds: [1, 3, 7, ...], competencyIds: [2, 5, ...] }`
    - Read from the employee's `interests` and `competencies` ManyToMany relationships
  - `PUT /api/profile/selections` → accepts `SelectionsRequest`, replaces the user's interests and competencies:
    - `@RequestBody SelectionsRequest { List<Long> interestIds, List<Long> competencyIds }`
    - Load the Interest/Competency entities by IDs, set them on the Employee, save
    - Returns 200 with updated `SelectionsResponse`
    - Validates that all IDs exist in the catalog (400 Bad Request if not)
- [ ] Create `backend/src/main/java/com/example/deloitter/profile/ProfileResponse.java`:
  - Record: `Long id`, `String firstName`, `String lastName`, `String email`, `String serviceLine`, `String roleFamily`, `String contactInfo`, `String initials`
  - `initials` is derived at mapping time: `Character.toUpperCase(firstName.charAt(0)) + "" + Character.toUpperCase(lastName.charAt(0))`
- [ ] Create `backend/src/main/java/com/example/deloitter/profile/SelectionsRequest.java`:
  - Record: `List<Long> interestIds`, `List<Long> competencyIds`
- [ ] Create `backend/src/main/java/com/example/deloitter/profile/SelectionsResponse.java`:
  - Record: `List<Long> interestIds`, `List<Long> competencyIds`
- [ ] Create `backend/src/main/java/com/example/deloitter/profile/ProfileService.java`:
  - Service class encapsulating profile lookup and selection update logic
  - Method: `Employee getAuthenticatedEmployee()` — resolves from SecurityContext
  - Method: `SelectionsResponse getSelections(Employee employee)`
  - Method: `SelectionsResponse updateSelections(Employee employee, SelectionsRequest request)` — validates IDs, replaces sets, saves
- [ ] Update `SecurityConfig.java` (if needed):
  - Ensure `/api/catalog` and `/api/profile/**` are within the authenticated boundary (they should be by default from F-02's "require auth for all `/api/**`" rule, except login)

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] Run `.\mvnw.cmd spring-boot:run` (with Postgres + seed data)
- [ ] `GET /api/catalog` (with auth cookie) → returns 200 with ~15 interests and ~15 competencies
- [ ] `GET /api/profile` (with auth cookie) → returns 200 with the logged-in employee's profile fields
- [ ] `GET /api/profile/selections` (with auth cookie) → returns 200 with the user's pre-seeded interest/competency IDs
- [ ] `PUT /api/profile/selections` with `{ "interestIds": [1,2,3], "competencyIds": [4,5] }` → returns 200 with updated selections
- [ ] `GET /api/profile/selections` after PUT → reflects the new selections
- [ ] `PUT /api/profile/selections` with invalid IDs (e.g., `[999]`) → returns 400
- [ ] All endpoints return 401 without auth cookie

---

### Phase 2: Frontend — API client extensions

**Goal:** The frontend API client has typed functions for catalog and selection endpoints, and a profile type.

#### Backend

- (no backend work)

#### Frontend

- [ ] Create `frontend/src/types/profile.ts`:
  - `export interface CatalogItem { id: number; name: string; }`
  - `export interface CatalogResponse { interests: CatalogItem[]; competencies: CatalogItem[]; }`
  - `export interface UserProfile { id: number; firstName: string; lastName: string; email: string; serviceLine: string; roleFamily: string; contactInfo: string; initials: string; }`
  - `export interface SelectionsResponse { interestIds: number[]; competencyIds: number[]; }`
  - `export interface SelectionsRequest { interestIds: number[]; competencyIds: number[]; }`
- [ ] Update `frontend/src/api/client.ts`:
  - Add typed functions:
    - `fetchCatalog(): Promise<CatalogResponse>`
    - `fetchProfile(): Promise<UserProfile>`
    - `fetchSelections(): Promise<SelectionsResponse>`
    - `updateSelections(req: SelectionsRequest): Promise<SelectionsResponse>`
  - All use the existing base fetch wrapper with `credentials: 'include'`

#### Verification

- [ ] `npm run build` succeeds (types compile)
- [ ] `npm run lint` passes

---

### Phase 3: Frontend — Profile page with selection UI

**Goal:** A Profile page matching the design comp where the user can view and toggle their interest/competency selections, and save changes.

#### Backend

- (no backend work)

#### Frontend

- [ ] Create `frontend/src/pages/ProfilePage.tsx`:
  - **Layout** (from design comp lines 249-277):
    - `padding: 24px 0 60px`, `max-width: 680px`
  - **User header card** (design lines 251-257):
    - White card, border `1px solid oklch(0.91 0.012 150)`, border-radius `22px`, padding `22px`
    - Box-shadow: `0 14px 34px -28px oklch(0.4 0.05 150 / .5)`
    - Flex row: avatar (64px circle, green bg, white initials 24px bold) + name/role info
    - Name: 21px, weight 800, letter-spacing -0.01em
    - Sub-info: 14px, color `oklch(0.55 0.02 152)`, weight 600, format: "{role} · {serviceLine}"
    - Margin-bottom 24px
  - **"Your interests" section** (design lines 259-265):
    - Section heading: 18px, weight 800, margin-bottom 5px
    - Subtitle: "These drive who you match with. Tap to toggle." — 13.5px, color `oklch(0.55 0.02 152)`, margin-bottom 14px
    - Chip container: flex-wrap, gap 9px, margin-bottom 30px
    - Each chip (`<button>`):
      - `font-size: 13.5px`, `font-weight: 700`, `padding: 9px 15px`, `border-radius: 999px`
      - `cursor: pointer`, `transition: all .12s`, `white-space: nowrap`
      - **Selected state**: `background: oklch(0.70 0.16 145)`, `color: #fff`, `border: 1.5px solid oklch(0.70 0.16 145)`
      - **Unselected state**: `background: #fff`, `color: oklch(0.42 0.02 152)`, `border: 1.5px solid oklch(0.88 0.02 150)`
    - Clicking a chip toggles its selected state (local state, not yet saved)
  - **"Your competencies" section** (design lines 267-273):
    - Same structure as interests section
    - Heading: "Your competencies"
    - Subtitle: "Skills you bring — shared skills raise your compatibility."
    - Same chip style and toggle behavior
  - **"Save profile" button** (design line 275):
    - `border: none`, `background: oklch(0.70 0.16 145)`, `color: #fff`
    - `font-size: 15px`, `font-weight: 800`, `padding: 14px 28px`, `border-radius: 14px`
    - `box-shadow: 0 12px 26px -14px oklch(0.70 0.16 145 / .9)`
    - On click: calls `updateSelections()` with current toggle state, shows toast on success
    - Disabled + loading state while saving ("Saving…")
  - **State management**:
    - On mount: fetch catalog + fetch current selections
    - Local state: `selectedInterestIds: Set<number>`, `selectedCompetencyIds: Set<number>`
    - `isDirty`: tracks whether selections differ from last-saved state (optional: enables/disables Save button)
    - Loading states: `catalogLoading`, `saving`
  - **Toast** (design lines 319-321):
    - Fixed position, bottom-center, dark bg, white text, pill shape
    - "Profile updated" — auto-dismisses after ~2s
    - Reuse a shared Toast component or inline it for now
  - **Error handling**:
    - If catalog fetch fails → show error state with retry button
    - If save fails → show toast with error message
- [ ] Create `frontend/src/pages/ProfilePage.module.css`:
  - All styles matching the design spec above
  - Chip transition/hover effects
- [ ] Create `frontend/src/components/Toast.tsx`:
  - Shared toast component (can be reused by S-03/S-04):
    - Props: `message: string | null`, `onDismiss?: () => void`
    - Style from design: fixed bottom-center, `background: oklch(0.27 0.03 152)`, `color: #fff`, `font-size: 14px`, `font-weight: 700`, `padding: 12px 22px`, `border-radius: 999px`, `box-shadow: 0 14px 34px -14px oklch(0.3 0.06 150 / .7)`
    - Auto-dismisses after 1900ms
    - Renders nothing when `message` is null
- [ ] Create `frontend/src/components/Toast.module.css`

#### Verification

- [ ] `npm run build` succeeds
- [ ] `npm run lint` passes
- [ ] Component renders with catalog items as chips
- [ ] Pre-seeded selections appear as selected (green) chips
- [ ] Clicking a chip toggles its visual state
- [ ] Clicking "Save profile" persists selections to backend and shows toast

---

### Phase 4: Routing & navigation wiring

**Goal:** The Profile tab in the AppShell navigates to the Profile page; the overall navigation between tabs works.

#### Backend

- (no backend work)

#### Frontend

- [ ] Update `frontend/src/App.tsx` route structure:
  - Add `/profile` route inside the protected/AppShell layout:
    ```
    <Route element={<ProtectedRoute />}>
      <Route element={<AppShell />}>
        <Route path="/" element={<HomePage />} />
        <Route path="/profile" element={<ProfilePage />} />
        {/* Future: /discover, /matches */}
      </Route>
    </Route>
    ```
- [ ] Update `frontend/src/components/AppShell.tsx`:
  - Wire the "Profile" nav tab to navigate to `/profile` (use React Router `<Link>` or `useNavigate()`)
  - Active tab indicator: highlight "Profile" when current path is `/profile`
  - Keep "Discover" and "Matches" tabs as non-functional or route to `/` for now
  - Use `useLocation()` to determine the active tab based on current pathname
- [ ] Update `frontend/src/pages/ProfilePage.tsx`:
  - Set `document.title = "Deloitter — Profile"` on mount
- [ ] Fetch user profile data (`GET /api/profile`) for the header card on the Profile page (or reuse data from AuthContext if extended)

#### Verification

- [ ] Clicking "Profile" tab in the header → navigates to `/profile`
- [ ] Profile page renders with user info header card + chip selections
- [ ] Active tab indicator (green underline) appears on "Profile" when on that page
- [ ] Navigating to other tabs and back preserves selection state (or re-fetches)
- [ ] Direct URL navigation to `/profile` works (authenticated)
- [ ] Unauthenticated access to `/profile` → redirects to `/login`
- [ ] Page title shows "Deloitter — Profile"

---

### Phase 5: Polish & edge cases

**Goal:** Visual refinement, loading/error states, and accessibility polish.

#### Backend

- (no backend work)

#### Frontend

- [ ] **Loading state** for catalog fetch:
  - Show skeleton/placeholder chips while loading (or a simple "Loading…" text)
  - Disable save button while catalog is loading
- [ ] **Empty catalog edge case** (shouldn't happen with seed data, but handle gracefully):
  - If catalog returns empty arrays → show "No interests/competencies available"
- [ ] **Optimistic toggle feedback**:
  - Chip toggles feel instant (local state update before save)
  - Save button saves the current local state to the server
- [ ] **Unsaved changes indicator** (optional):
  - If selections differ from last-saved state, show a subtle indicator or keep "Save profile" button prominent
  - If user navigates away with unsaved changes → no blocking (speed goal; data isn't critical)
- [ ] **Accessibility**:
  - Chips use `<button>` elements (keyboard accessible by default)
  - `aria-pressed="true|false"` on each chip to indicate toggle state
  - Section headings use `<h2>` for proper document structure
  - Toast uses `role="status"` and `aria-live="polite"`
  - Focus-visible rings on chips for keyboard navigation
- [ ] **Document title**: "Deloitter — Profile" while on the page
- [ ] **Hover effect on chips**: slight brightness/scale change on hover (matches the `transition: all .12s` in design)
- [ ] Verify `npm run lint` passes
- [ ] Verify `npm run build` succeeds

#### Verification

- [ ] Page loads without flash/jank — loading state shows briefly then chips appear
- [ ] Tab through chips with keyboard → focus ring visible on each
- [ ] Screen reader announces chip labels and pressed state
- [ ] Toast is announced by screen reader
- [ ] Save with no changes → still succeeds (idempotent)
- [ ] Large catalog (~15 items) renders without overflow issues

---

## Integration & Smoke Test

- [ ] From clean state: Postgres running with F-01 seed data, backend started, frontend started
- [ ] Log in with seeded credentials → land in app shell
- [ ] Click "Profile" tab → navigate to `/profile`
- [ ] User info card shows correct name, role, service line from the seed
- [ ] Interest chips render: pre-seeded selections appear in green, unselected in white
- [ ] Competency chips render: same behavior
- [ ] Toggle several chips (select some new ones, deselect some old ones) → chips update visually
- [ ] Click "Save profile" → toast "Profile updated" appears and auto-dismisses
- [ ] Refresh the page → selections persist (re-fetched from backend)
- [ ] Log out and log in as a different seeded user → that user's selections appear (different set)
- [ ] **Guardrail check:** No other user's selections are visible or accessible — the endpoint returns only the authenticated user's own data.
- [ ] **Guardrail check:** No compatibility score is exposed on this page — only the catalog and own selections.
- [ ] **Guardrail check:** No swipe intent or match data is accessible from any endpoint introduced here.
- [ ] **Design check:** Visual comparison with design comp Profile section (lines 249-277 of `Deloitter.dc.html`) — chip style, colors, spacing, typography all match.

## Open Questions

1. **Should the Profile page also show the user's office/location?** — The design comp shows `{{ me.role }} · {{ me.serviceLine }} · {{ me.office }}` but the `employee` table doesn't have an explicit `office` column (it has `service_line` and `role_family`). Plan uses `role_family` + `service_line`. If office is needed, a migration adds the column. Non-blocking.
2. **Should saving be automatic on each toggle (auto-save) or require explicit "Save profile" click?** — Plan follows the design comp which shows an explicit "Save profile" button. Auto-save can be added later if UX testing suggests it. Non-blocking.
3. **Should there be a minimum number of selections required before save?** — Plan says no enforcement in S-02 (Decision #4). S-03 can prompt the user to pick interests if their stack is empty. Non-blocking.
4. **Should changes to selections recompute the candidate stack immediately?** — Out of scope for S-02. S-03 computes the stack when the user navigates to Discover. If S-05 (edit after setup) is built, it could trigger a re-rank. Non-blocking.

