> **Archived:** 2026-06-13 00:00 | Change ID: `swipe-candidate-stack` | Roadmap ID: `S-03`

---

change_id: "swipe-candidate-stack"
roadmap_id: "S-03"
status: implemented
created: 2026-06-13
prd_refs: [FR-003, FR-004, Business Logic, Perceived-responsiveness NFR]
prerequisites: [F-01 persistence-and-seed, S-02 select-interests]

---

# Plan: Swipe the candidate stack

## Context

This slice delivers the core interaction loop: a logged-in user opens the Discover tab, sees a stack of candidate colleagues ranked by compatibility (highest first), and swipes like or pass on each card. Each card shows the candidate's name, role, service line, office, and the _shared_ interests/competencies — but **not** the compatibility score (which is hidden until a mutual match, per FR-003 and the privacy guardrail). Swiping feels instant (< 300ms card-to-card, NFR) via full-stack prefetch.

Sequenced after S-02 because the compatibility ranking depends on the logged-in user's own selected interests/competencies. This slice introduces:

1. Swipe persistence (the table recording like/pass decisions)
2. The proportional-overlap compatibility computation that ranks the stack
3. The Discover page UI with drag-to-swipe gestures and button actions

It does **not** introduce match detection or the Matches view — those belong to S-04. The like endpoint records the decision and returns a simple success response; S-04 will extend it to detect mutual matches.

**Assumes all prerequisites are fully implemented:** F-01 (Postgres + seeded employees + catalog), F-02 (auth + session), S-01 (login UI + app shell with nav tabs), S-02 (interest/competency selection endpoints + profile page). Specifically assumes: authenticated session via cookie, `Employee` entity with `interests`/`competencies` ManyToMany sets, `EmployeeRepository`, `InterestRepository`, `CompetencyRepository`, React Router, AuthContext, ProtectedRoute, AppShell with Discover/Matches/Profile tabs.

**Design reference:** `frontend/context/foundation/design/Deloitter.dc.html` lines 83–198 — the Discover/Swipe section. This is the authoritative visual spec for the card stack layout, card styles (Style A: Warm is the default), action buttons, gesture behavior, and empty-deck state.

## Decisions & Assumptions

| #   | Decision                      | Choice                                                                                                                                                                   | Rationale                                                                                                                                                                                                                              |
| --- | ----------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --- | ----- | --------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Swipe table design            | Single `employee_swipe` table: `(swiper_id, candidate_id, liked BOOLEAN, created_at)`                                                                                    | Records every swipe. Simpler than separate like/pass tables. `liked=true` means like, `liked=false` means pass. Compound PK `(swiper_id, candidate_id)` prevents duplicate swipes.                                                     |
| 2   | Candidate stack API           | **`GET /api/discover/stack`** — returns the full ranked list in one call                                                                                                 | With ~20 seeded employees, the full list is tiny. Single fetch enables instant card transitions (no per-card latency). No pagination needed at pilot scale.                                                                            |
| 3   | Stack response shape          | Array of `CandidateCard` objects: `{ id, firstName, lastName, initials, roleFamily, serviceLine, contactInfo, sharedInterests: string[], sharedCompetencies: string[] }` | Provides everything the card UI needs. **Does NOT include the score** — enforcing the guardrail at the API level. `sharedInterests`/`sharedCompetencies` are the intersection of the candidate's attributes with the logged-in user's. |
| 4   | Compatibility score formula   | **Proportional overlap (Jaccard index):** `score =                                                                                                                       | intersection                                                                                                                                                                                                                           | /   | union | ` over the combined set of (interests + competencies + service-line signal) | Matches PRD Business Logic: "proportional overlap … two people sharing 4 of 5 score higher than 4 of 20." Deterministic, explainable. Matches the design comp's `computeCandidates()` logic. Service line included as a signal (if same, it counts as 1 shared attribute). |
| 5   | Swipe API endpoint            | **`POST /api/discover/swipe`** with body `{ candidateId: Long, liked: boolean }` → returns `{ success: true }`                                                           | Single endpoint, clear semantics. Does NOT return match info (S-04's scope). Returns 409 if already swiped.                                                                                                                            |
| 6   | Stack excludes already-swiped | Candidates the user has already liked or passed are filtered out of the stack response                                                                                   | Ensures the user never sees the same person twice.                                                                                                                                                                                     |
| 7   | Frontend gesture handling     | **Hand-rolled pointer events** matching the design comp                                                                                                                  | The design comp provides the exact pointer-down/move/up logic with fly-off animation. No external gesture library needed — keeps bundle small and matches the reference precisely.                                                     |
| 8   | Card style                    | **Style A (Warm)** as default and only style for MVP                                                                                                                     | The design comp shows 3 card styles (A/B/C). Style A is the default and the simplest — green gradient header, circular avatar, clean info layout. Other styles are polish that can be added later.                                     |
| 9   | Empty deck state              | Match design comp exactly — "You're all caught up" message with CTA to "View your matches"                                                                               | Appears when all candidates are swiped. Links to `/matches` (S-04 will make this functional).                                                                                                                                          |
| 10  | Score stored in swipe table?  | **No** — score is computed on-the-fly when building the stack                                                                                                            | Avoids staleness if the user changes their interests (S-05). The score is cheap to compute for 20 users. Only S-04 will persist the score (on the match record).                                                                       |
| 10b | N+1 lazy loading              | **Accepted for POC scale** — `getStack()` accesses LAZY `interests`/`competencies` in a loop                                                                             | With 20 users this is negligible. Implementer may optionally add `@EntityGraph(attributePaths = {"interests", "competencies"})` on the repository query if Hibernate logging looks chatty.                                             |
| 10c | Role family in score          | **Not included** — only service line used as professional-background signal                                                                                              | PRD says "e.g., shared service line / role family / career path" (suggestive). Service line alone is sufficient for POC. Role family could be added trivially (`"rf:" + roleFamily`) if desired.                                       |
| 11  | Package naming                | **`swipe/`** for backend feature package                                                                                                                                 | Groups swipe controller, service, DTOs, repository. Follows AGENTS.md convention of feature-based grouping.                                                                                                                            |
| 12  | Automated tests               | **Not required** — hackathon speed goal                                                                                                                                  | Implementer may optionally add a `@WebMvcTest` for the swipe controller. Manual verification suffices for acceptance.                                                                                                                  |
| 12b | Fire-and-forget failure       | **Accepted trade-off** — if `recordSwipe()` fails silently, the candidate reappears on page refresh                                                                      | For POC this is acceptable. The alternative (blocking the transition on API response) violates the < 300ms NFR. A subtle toast on failure is optional polish.                                                                          |
| 13  | Frontend routing              | `/discover` route wired to the "Discover" nav tab                                                                                                                        | The Discover tab is the landing page after login (also accessible via `/` redirect).                                                                                                                                                   |

## Phases

### Phase 1: Backend — Swipe persistence (schema + entity)

**Goal:** A Flyway migration creates the `employee_swipe` table and a JPA entity maps it.

#### Backend

- [x] Create `backend/src/main/resources/db/migration/V6__create_employee_swipe.sql`:
  ```sql
  CREATE TABLE employee_swipe (
      swiper_id    BIGINT NOT NULL REFERENCES employee(id),
      candidate_id BIGINT NOT NULL REFERENCES employee(id),
      liked        BOOLEAN NOT NULL,
      created_at   TIMESTAMP NOT NULL DEFAULT NOW(),
      PRIMARY KEY (swiper_id, candidate_id),
      CHECK (swiper_id <> candidate_id)
  );
  CREATE INDEX idx_swipe_swiper ON employee_swipe(swiper_id);
  ```
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/SwipeId.java`:
  - Composite key class implementing `Serializable`: fields `Long swiperId`, `Long candidateId`
  - Override `equals()`/`hashCode()` based on both fields
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/EmployeeSwipe.java`:
  - `@Entity @Table(name = "employee_swipe") @IdClass(SwipeId.class)`
  - Fields: `@Id swiperId`, `@Id candidateId`, `boolean liked`, `LocalDateTime createdAt`
  - `@ManyToOne(fetch = LAZY)` relationships to `Employee` for both IDs (optional — for convenient JPA navigation if needed)
  - `@PrePersist` sets `createdAt` if null
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/SwipeRepository.java`:
  - `extends JpaRepository<EmployeeSwipe, SwipeId>`
  - Method: `List<EmployeeSwipe> findBySwiperId(Long swiperId)` — returns all swipes by a user
  - Method: `boolean existsBySwiperIdAndCandidateId(Long swiperId, Long candidateId)` or use `existsById(new SwipeId(...))`

#### Frontend

- (no frontend work in this phase)

#### Verification

- [x] Run `.\mvnw.cmd spring-boot:run` — Flyway V6 migration applies without error
- [x] Verify in Postgres: `\d employee_swipe` shows the expected schema
- [x] Application context starts cleanly (Hibernate validates the entity against the table)

---

### Phase 2: Backend — Compatibility service + stack + swipe endpoints

**Goal:** The backend computes compatibility scores, serves a ranked candidate stack (without exposing the score), and persists swipe decisions.

#### Backend

- [x] Create `backend/src/main/java/com/example/deloitter/swipe/CompatibilityService.java`:
  - Service class with method: `int computeScore(Employee me, Employee candidate)`
  - Logic:
    1. Build `meAttrs` set: all interest names + all competency names + `"sl:" + me.serviceLine`
    2. Build `candAttrs` set: all interest names + all competency names + `"sl:" + candidate.serviceLine`
    3. `intersection = meAttrs ∩ candAttrs`
    4. `union = meAttrs ∪ candAttrs`
    5. `score = union.isEmpty() ? 0 : Math.round(100.0 * intersection.size() / union.size())`
  - Return as integer percentage (0–100)
  - Method: `List<String> sharedInterests(Employee me, Employee candidate)` — names of interests both share
  - Method: `List<String> sharedCompetencies(Employee me, Employee candidate)` — names of competencies both share
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/CandidateCard.java`:
  - Record/DTO: `Long id`, `String firstName`, `String lastName`, `String initials`, `String roleFamily`, `String serviceLine`, `String contactInfo`, `List<String> sharedInterests`, `List<String> sharedCompetencies`
  - `initials` computed as `firstName.charAt(0) + "" + lastName.charAt(0)` (uppercased)
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/SwipeRequest.java`:
  - Record: `Long candidateId`, `boolean liked`
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/SwipeResponse.java`:
  - Record: `boolean success`
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/DiscoverService.java`:
  - Inject `EmployeeRepository`, `SwipeRepository`, `CompatibilityService`
  - Method: `List<CandidateCard> getStack(Employee me)`:
    1. Fetch all employees except `me` from `EmployeeRepository`
    2. Fetch all swipe IDs where `swiperId = me.id` → build exclusion set
    3. Filter out already-swiped candidates
    4. For each remaining candidate, compute score + shared attributes
    5. Sort by score descending
    6. Map to `CandidateCard` DTOs (without score!)
    7. Return the list
  - Method: `void recordSwipe(Employee me, Long candidateId, boolean liked)`:
    1. Validate `candidateId` exists and is not self
    2. Check not already swiped (throw 409 if so)
    3. Create `EmployeeSwipe` entity, save
- [x] Create `backend/src/main/java/com/example/deloitter/swipe/DiscoverController.java`:
  - `@RestController @RequestMapping("/api/discover")`
  - Inject `DiscoverService`
  - `GET /api/discover/stack`:
    - Resolve authenticated employee from SecurityContext (email → EmployeeRepository)
    - Call `discoverService.getStack(employee)`
    - Return `List<CandidateCard>` (200 OK)
  - `POST /api/discover/swipe`:
    - `@RequestBody SwipeRequest`
    - Resolve authenticated employee
    - Call `discoverService.recordSwipe(employee, request.candidateId(), request.liked())`
    - Return `SwipeResponse(true)` (200 OK)
    - If already swiped → return 409 Conflict with error body
    - If candidateId invalid → return 400 Bad Request
- [x] Ensure `SecurityConfig` permits `/api/discover/**` within the authenticated boundary (should already be covered by the "require auth for all `/api/**`" rule from F-02)

#### Frontend

- (no frontend work in this phase)

#### Verification

- [x] Start backend with Postgres + seed data
- [x] Log in as `alice.chen@deloitte.demo` (who has 5 interests + 5 competencies)
- [x] `GET /api/discover/stack` (with auth cookie) → returns 200 with 19 candidates, sorted by score desc
- [x] Top candidate should share multiple interests/competencies with Alice (verify overlap is correct)
- [x] Response does **not** contain a `score` field anywhere
- [x] `POST /api/discover/swipe` with `{ "candidateId": <first candidate ID>, "liked": true }` → 200
- [x] `GET /api/discover/stack` again → first candidate is no longer in the list (18 remaining)
- [x] `POST /api/discover/swipe` with same candidateId again → 409 Conflict
- [x] `POST /api/discover/swipe` with `{ "candidateId": <own ID>, "liked": true }` → 400
- [x] `POST /api/discover/swipe` with invalid candidateId → 400
- [x] All endpoints return 401 without auth cookie
- [x] **Guardrail check:** No endpoint exposes the compatibility score or any other user's like/pass decisions

---

### Phase 3: Frontend — API types + client extensions

**Goal:** The frontend API client has typed functions for the discover/swipe endpoints.

#### Backend

- (no backend work)

#### Frontend

- [x] Create `frontend/src/types/discover.ts`:
  - `export interface CandidateCard { id: number; firstName: string; lastName: string; initials: string; roleFamily: string; serviceLine: string; contactInfo: string; sharedInterests: string[]; sharedCompetencies: string[]; }`
  - `export interface SwipeRequest { candidateId: number; liked: boolean; }`
  - `export interface SwipeResponse { success: boolean; }`
- [x] Update `frontend/src/api/client.ts`:
  - Add typed functions:
    - `fetchStack(): Promise<CandidateCard[]>` — `GET /api/discover/stack`
    - `recordSwipe(req: SwipeRequest): Promise<SwipeResponse>` — `POST /api/discover/swipe`
  - Both use the existing base fetch wrapper with `credentials: 'include'`

#### Verification

- [x] `npm run build` succeeds (types compile)
- [x] `npm run lint` passes

---

### Phase 4: Frontend — Discover page with swipe UI

**Goal:** A Discover page matching the design comp where the user sees a stack of candidate cards, can drag-to-swipe or use buttons, and the deck empties as candidates are exhausted.

#### Backend

- (no backend work)

#### Frontend

- [x] Create `frontend/src/pages/DiscoverPage.tsx`:
  - **Layout** (design comp lines 84–197):
    - `display: flex; flex-direction: column; align-items: center; padding: 18px 0 40px`
  - **Header section** (lines 86–91):
    - Title: "Discover colleagues" — `font-size: 20px; font-weight: 800; letter-spacing: -0.01em`
    - Subtitle: "Ranked by what you share · score hidden until you match" — `font-size: 13.5px; color: oklch(0.55 0.02 152)`
  - **Card stack container** (line 94):
    - `position: relative; width: 360px; height: 540px`
  - **Back cards** (decorative, lines 106–112):
    - Back card 2: `transform: scale(.88) translateY(34px); opacity: .55; z-index: 10`
    - Back card 1: `transform: scale(.94) translateY(17px); opacity: .8; z-index: 20`
    - Both are plain white rounded divs with border + shadow
    - Render conditionally based on remaining cards (back1 if ≥2 remaining, back2 if ≥3)
  - **Top card — Style A: Warm** (lines 119–139):
    - `z-index: 30; border-radius: 28px; background: #fff; border + box-shadow; cursor: grab; touch-action: none; user-select: none`
    - LIKE badge (top-left, hidden until dragged): green border/text, rotated -12deg
    - PASS badge (top-right, hidden until dragged): red-orange border/text, rotated 12deg
    - Gradient header: `height: 236px; background: linear-gradient(150deg, oklch(0.88 0.09 150), oklch(0.83 0.08 178))`
    - Avatar: 112px circle with candidate accent color, white initials 42px bold
    - Info section (padding 20px 22px):
      - Name: `font-size: 24px; font-weight: 800; letter-spacing: -0.02em`
      - Role + service line: `font-size: 14.5px; color: oklch(0.5 0.02 152); font-weight: 600`
      - Office (contact info): `font-size: 13px; color: oklch(0.6 0.015 152)`
      - "You both share" label: `font-size: 11.5px; font-weight: 800; letter-spacing: 0.08em; text-transform: uppercase; color: oklch(0.62 0.13 145)`
      - Shared interests chips: `background: oklch(0.93 0.06 145); color: oklch(0.4 0.1 148); font-size: 13px; font-weight: 700; padding: 7px 13px; border-radius: 999px`
      - Shared competencies chips: `background: #fff; border: 1.5px solid oklch(0.88 0.03 150); color: oklch(0.45 0.02 152); font-size: 13px; font-weight: 700; padding: 6px 12px; border-radius: 999px`
  - **Action buttons** (lines 191–194):
    - Pass button: `width: 66px; height: 66px; border-radius: 50%; background: #fff; border: 1.5px solid oklch(0.88 0.04 30); color: oklch(0.6 0.18 25); font-size: 27px` — displays ✕
    - Like button: `width: 78px; height: 78px; border-radius: 50%; background: oklch(0.70 0.16 145); color: #fff; font-size: 34px` — displays ♥
    - Gap: 22px, margin-top: 30px
  - **Footer text** (line 195):
    - "Drag the card or use the buttons · N colleagues left" — `font-size: 12.5px; color: oklch(0.6 0.015 152); margin-top: 16px`
  - **Empty deck state** (lines 96–103):
    - White rounded card filling the stack area with centered content
    - Floating emoji (🌱) with `animation: dl-float 3s ease-in-out infinite`
    - "You're all caught up" title
    - "You've seen everyone for now. Check who you matched with." subtitle
    - "View your matches" button → navigates to `/matches`
  - **State management**:
    - On mount: `fetchStack()` → stores full candidate array in state
    - `currentIndex: number` — pointer into the array (starts at 0)
    - Current card = `stack[currentIndex]`
    - Remaining count = `stack.length - currentIndex`
    - On swipe (like or pass): call `recordSwipe()`, increment `currentIndex`
    - Fire-and-forget swipe API call (don't block the transition for responsiveness)
  - **Gesture handling** (from design comp lines 389–431):
    - `onPointerDown`: capture start position, set `dragging = true`, remove CSS transition
    - `onPointerMove`: calculate `dx`/`dy`, apply `transform: translate(dx, dy) rotate(dx*0.05 deg)` to card, show LIKE badge opacity proportional to `dx/110`, PASS badge proportional to `-dx/110`
    - `onPointerUp`: if `dx > 110` → fly off right (like); if `dx < -110` → fly off left (pass); else spring back
    - `flyOff(direction)`: animate card out of viewport with rotation, then after 300ms commit the swipe
    - `springBack()`: transition card back to center with cubic-bezier easing
    - Use `setPointerCapture` for reliable drag tracking
  - **Button handlers**:
    - Like button: trigger `flyOff("like")` programmatically
    - Pass button: trigger `flyOff("pass")` programmatically
    - Disabled when no top card or animation in progress

- [x] Create `frontend/src/pages/DiscoverPage.module.css`:
  - Keyframe animations:
    - `dl-float`: `0%,100% { transform: translateY(0) } 50% { transform: translateY(-7px) }` (for empty state emoji)
  - Card hover/grab cursor states
  - Button hover effects: `transform: translateY(-3px) scale(1.05)`
  - Transition utilities for fly-off and spring-back

- [x] Create `frontend/src/utils/accentColor.ts`:
  - Helper to assign consistent accent colors to candidates based on ID/name hash:
    - Palette: `["oklch(0.70 0.16 145)", "oklch(0.78 0.13 70)", "oklch(0.66 0.15 300)", "oklch(0.70 0.16 30)", "oklch(0.72 0.12 180)"]`
    - `export function getAccentColor(id: number): string` — maps `id % palette.length` to a color

#### Verification

- [x] `npm run build` succeeds
- [x] `npm run lint` passes
- [ ] Page renders with the first candidate card showing name, role, shared interests/competencies
- [ ] Back cards visible behind the top card (stacked effect)
- [ ] Dragging the card shows LIKE/PASS badge and card follows pointer
- [ ] Releasing past threshold flies the card off and shows the next card
- [ ] Releasing before threshold springs the card back
- [ ] Like/Pass buttons work (card animates out, next card appears)
- [ ] Footer shows remaining count, decrements on each swipe
- [ ] After all candidates swiped → empty deck state appears
- [ ] **Guardrail check:** No compatibility score visible anywhere on the page
- [ ] **Responsiveness check:** Card-to-card transition feels instant (< 300ms perceived)

---

### Phase 5: Routing, wiring & polish

**Goal:** The Discover page is wired into the app navigation, page loads feel instant, and edge cases are handled.

#### Backend

- (no backend work)

#### Frontend

- [x] Update `frontend/src/App.tsx` route structure:
  - Add `/discover` route inside the protected/AppShell layout
  - Make `/` redirect to `/discover` (the default authenticated landing page)
  ```
  <Route element={<ProtectedRoute />}>
    <Route element={<AppShell />}>
      <Route path="/" element={<Navigate to="/discover" replace />} />
      <Route path="/discover" element={<DiscoverPage />} />
      <Route path="/profile" element={<ProfilePage />} />
      <Route path="/matches" element={<MatchesPlaceholder />} />
    </Route>
  </Route>
  ```
- [x] Update `frontend/src/components/AppShell.tsx`:
  - Wire the "Discover" nav tab to navigate to `/discover`
  - Active tab indicator: highlight "Discover" when current path is `/discover` or `/`
  - "Matches" tab navigates to `/matches` (placeholder page until S-04)
- [x] Create `frontend/src/pages/MatchesPlaceholder.tsx` (temporary until S-04):
  - Show the "No matches yet" empty state from design comp (lines 206–212):
    - 💚 emoji in green circle
    - "No matches yet" title
    - "Keep swiping in Discover — matches show up here."
    - "Start swiping" button → navigates to `/discover`
- [x] **Loading state** for stack fetch:
  - Show a skeleton/pulsing placeholder card while `fetchStack()` is in-flight
  - Prevents a flash of empty content on page load
- [x] **Error handling**:
  - If `fetchStack()` fails → show a simple error message with retry button
  - If `recordSwipe()` fails → log error but don't block the UI (fire-and-forget for responsiveness); optionally show a subtle toast
- [x] **Prefetch behavior**:
  - Fetch the stack once on mount; the full array lives in memory
  - Card transitions are purely local state (index increment) — no per-card API call
  - This guarantees < 300ms card-to-card transitions (NFR)
- [x] **Edge case — user with no selections**:
  - If the stack returns empty because the user has no interests/competencies selected, show a message: "Pick some interests first to find colleagues" with a CTA to `/profile`
- [x] **Accessibility**:
  - Action buttons have `title` attributes ("Like", "Pass")
  - Card content is readable by screen readers (proper heading hierarchy within card)
  - Keyboard support: buttons are focusable and activatable with Enter/Space
  - LIKE/PASS badges have `aria-hidden="true"` (visual-only feedback)
- [x] **Document title**: "Deloitter — Discover" while on the page
- [x] Verify `npm run lint` passes
- [x] Verify `npm run build` succeeds

#### Verification

- [x] Clicking "Discover" tab → navigates to `/discover`
- [x] After login → lands on `/discover` by default
- [x] "Matches" tab → navigates to `/matches` with placeholder UI
- [x] Stack loads without visible stall (loading state flashes briefly)
- [ ] All swipe interactions work (drag + buttons)
- [ ] After swiping all candidates → empty state shows "View your matches" CTA
- [ ] Refreshing `/discover` after swiping some → those candidates are gone (persisted server-side)
- [x] Page title shows "Deloitter — Discover"
- [ ] Tab through action buttons with keyboard → focus ring visible, Enter activates

---

## Integration & Smoke Test

- [ ] From clean state: Postgres running with seed data, backend started, frontend started
- [ ] Log in as `alice.chen@deloitte.demo` (password: `password123`) → land on Discover page
- [ ] Verify stack shows candidates ordered by compatibility — first candidates should share the most interests/competencies with Alice (Machine Learning, Travel, Startups, Design Thinking, Photography + Java, Python, AI/ML Engineering, Strategy Consulting, Agile Coaching)
- [ ] Cards show "You both share" with correct overlap (e.g., first card for Alice should show shared interests like Machine Learning, Startups, etc.)
- [ ] Drag a card right past threshold → flies off, LIKE badge visible during drag → next card appears instantly
- [ ] Drag a card left past threshold → flies off, PASS badge visible during drag → next card appears instantly
- [ ] Use ♥ button → same effect as right-drag
- [ ] Use ✕ button → same effect as left-drag
- [ ] Swipe through 3–4 candidates, then refresh the page → those candidates do not reappear (server-side persistence)
- [ ] Navigate to Profile tab → change interests (toggle some off/on, save) → navigate back to Discover → remaining candidates are re-ranked based on new selections (stack re-fetched)
- [ ] Swipe all remaining candidates → empty deck state appears with "You're all caught up" and "View your matches" CTA
- [ ] Log in as a different user (`ben.martinez@deloitte.demo`) → that user has their own fresh stack (not affected by Alice's swipes)
- [ ] **Guardrail check (privacy):** No API response from `/api/discover/stack` or `/api/discover/swipe` exposes another user's like/pass decisions. The response contains only candidate profile data + shared attributes.
- [ ] **Guardrail check (score hidden):** No `score` field appears anywhere in the Discover page API responses or rendered UI. The score exists only internally for ranking order.
- [ ] **Guardrail check (explainable):** The ranking order makes intuitive sense — candidates sharing more attributes appear first. Can be verified by comparing the "You both share" chips (more chips = higher position).
- [ ] **Responsiveness check:** Card-to-card transitions complete in < 300ms with no perceptible lag or loading stall between cards.
- [ ] **Design check:** Visual comparison with design comp Discover section (lines 83–198 of `Deloitter.dc.html`) — card dimensions, typography, colors, button styles, badge positions, gradient, chip styles all match.

## Open Questions

1. **Should the stack be re-fetched when navigating back to Discover after editing interests?** — Plan says yes (re-fetch on mount). This keeps ranking fresh. If the stack is large in a real deployment, a cache-invalidation strategy would be needed. Non-blocking for the POC.
2. **Should we cap the number of shared attributes shown on a card?** — The design comp shows ~3 interest chips + ~2 competency chips. If overlap is very high (7+ shared), truncating with "+N more" could improve card readability. Implementer's discretion. Non-blocking.
3. **Should the service-line match be shown as a chip?** — The design comp shows it as "Same service line" in some logic but not as a chip on the card. Plan excludes it from the card chips but includes it in the score calculation. Non-blocking.
4. **What happens if two candidates have identical scores?** — Secondary sort by employee ID (stable ordering). Non-blocking; unlikely to cause a visible issue with 20 users.
