---
change_id: "mutual-match-reveal"
roadmap_id: "S-04"
status: revised
created: 2026-06-13
prd_refs: [FR-005, FR-006, Privacy NFR]
prerequisites: [S-03 swipe-candidate-stack]
---

# Plan: Mutual match reveal

## Context

This slice delivers the north-star milestone: when two users have each liked the other, the system detects the mutual match and reveals the compatibility score plus contact info to both parties. The user sees a celebratory match overlay immediately upon swiping (with confetti, overlapping avatars, the score, a shared-attribute summary, and the colleague's Teams handle), and can later browse all their matches in a dedicated Matches view.

Sequenced after S-03 because it consumes the like records that the swipe endpoint produces. This slice introduces:
1. An `employee_match` persistence table (freezing the score at match time)
2. Match-detection logic triggered inline when recording a like
3. Extension of the swipe endpoint response to include match data when a mutual match occurs
4. A `GET /api/matches` endpoint returning the authenticated user's matches (with score + contact info)
5. The Matches page UI (grid of match cards)
6. The Match overlay UI (shown immediately on mutual match)
7. Match count badge in the navigation

**Privacy guardrail (critical):** A user must never learn that someone liked or passed on them unless a mutual match exists. This plan enforces this at the API level — the swipe response only includes match data when *both* sides have `liked=true`; no endpoint ever exposes non-mutual intent.

**Assumes all prerequisites are fully implemented:** F-01 (Postgres + seed), F-02 (auth + session), S-01 (login UI + app shell), S-02 (interest/competency selection), S-03 (swipe persistence + stack endpoints + Discover page + gesture UI). Specifically assumes: `employee_swipe` table, `SwipeRepository`, `CompatibilityService`, `DiscoverService`, `DiscoverController`, `DiscoverPage` component, `AppShell` with nav tabs, React Router, AuthContext, API client with `fetchStack()` and `recordSwipe()`.

**Design reference:** `frontend/context/foundation/design/Deloitter.dc.html`:
- Match overlay: lines 283–316 (confetti, avatars, score, share summary, Teams CTA, buttons)
- Matches list view: lines 200–246 (grid cards with avatar, name, role, score badge, shared interests, Teams handle, "Message on Teams" button)
- Empty matches state: lines 206–212 (💚 emoji, "No matches yet" message, "Start swiping" CTA)
- Nav badge: line 71 (green pill with match count on "Matches" tab)

## Decisions & Assumptions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Match detection trigger | **Inline in swipe endpoint** — when a `liked=true` swipe is recorded, immediately check if the reverse (`candidate → me`, `liked=true`) exists | Simplest for POC. No async/event needed at pilot scale. Guarantees the match overlay appears on the same response as the swipe. |
| 2 | Match table design | **Single row per matched pair:** `employee_match(id, employee_1_id, employee_2_id, score, created_at)` where `employee_1_id < employee_2_id` (canonical ordering) | Prevents duplicate match rows. Single source of truth. Both users query the same row. Named `employee_match` (not `match`) to avoid SQL reserved-word issues and to be consistent with `employee_swipe`. |
| 3 | Score persistence | **Frozen at match time** — the compatibility score is computed at the moment both likes exist and stored in the `match` row | If a user later edits interests (S-05), the historical match retains the score from when they connected. This is more natural ("you matched because of what you shared *then*"). |
| 4 | Swipe response extension | **Extend `POST /api/discover/swipe` response** from `{ success }` to `{ success, match?: MatchResult }` where `MatchResult` contains score, name, initials, contactInfo, sharedInterests, sharedCompetencies, shareSummary | Allows the frontend to show the match overlay immediately without an extra round-trip. `match` field is `null` when no mutual match occurred. |
| 5 | Matches list endpoint | **`GET /api/matches`** returning `List<MatchItem>` — each item: id, matchedEmployee (name, initials, roleFamily, serviceLine, contactInfo), score, sharedInterests, sharedCompetencies | Serves the Matches page. Scoped to the authenticated user only — privacy enforced by query. |
| 6 | Privacy enforcement | **Query-level:** the matches endpoint joins on `(employee_1_id = me OR employee_2_id = me)` — a user can only see their own matches. No endpoint exposes pending likes or another user's swipe history. | Structural guarantee. |
| 7 | Frontend match overlay | **Shown inline on swipe response** — when `recordSwipe()` returns a non-null `match` field, the overlay renders with confetti, avatars, score, and CTA | Fire-and-forget for the swipe *unless* a match occurs — then the response is awaited for match data. Implementation: always await the response, but don't block the card animation (start animation immediately, show overlay after response arrives). |
| 8 | Confetti animation | **CSS-only** confetti matching the design comp (18 pieces, `dl-confetti` keyframe: translate Y + rotate, staggered delays) | No external library needed. Lightweight, matches the reference exactly. |
| 9 | Match count in nav | **Fetched as part of initial data load** (e.g., from `/api/matches` response length) and updated in-memory when a new match occurs inline | Avoids a separate count endpoint. The badge updates immediately when a match overlay is shown. |
| 10 | Package naming | **`match/`** for backend feature package | Groups match controller, service, DTOs, entity, repository. Follows AGENTS.md convention. |
| 11 | Automated tests | **Not required** — hackathon speed goal | Manual verification via seeded mutual-like scenario suffices. |
| 12 | Seed data for verification | **Two seeded mutual-like pairs** — seed `employee_swipe` rows so that when Alice likes Ben (who already liked Alice), a match triggers immediately on the first swipe | Enables instant demo of the match flow without having to log in as two users manually first. |

## Phases

### Phase 1: Backend — Match persistence (schema + entity)

**Goal:** A Flyway migration creates the `employee_match` table and a JPA entity maps it.

#### Backend

- [x] Create `backend/src/main/resources/db/migration/V7__create_employee_match_table.sql`:
  ```sql
  CREATE TABLE employee_match (
      id             BIGSERIAL PRIMARY KEY,
      employee_1_id  BIGINT NOT NULL REFERENCES employee(id),
      employee_2_id  BIGINT NOT NULL REFERENCES employee(id),
      score          INT NOT NULL,
      created_at     TIMESTAMP NOT NULL DEFAULT NOW(),
      UNIQUE (employee_1_id, employee_2_id),
      CHECK (employee_1_id < employee_2_id)
  );
  CREATE INDEX idx_match_emp1 ON employee_match(employee_1_id);
  CREATE INDEX idx_match_emp2 ON employee_match(employee_2_id);
  ```
- [x] Create `backend/src/main/java/com/example/deloitter/match/Match.java`:
  - `@Entity @Table(name = "employee_match")`
  - Fields: `@Id @GeneratedValue Long id`, `Long employee1Id`, `Long employee2Id`, `int score`, `LocalDateTime createdAt`
  - `@ManyToOne(fetch = LAZY)` relationships to `Employee` for both IDs (for convenient JPA navigation)
  - `@PrePersist` sets `createdAt` if null
  - Static factory method: `Match.create(Long empA, Long empB, int score)` — automatically puts the smaller ID in `employee1Id`
- [x] Create `backend/src/main/java/com/example/deloitter/match/MatchRepository.java`:
  - `extends JpaRepository<Match, Long>`
  - Method: `@Query("SELECT m FROM Match m WHERE m.employee1Id = :id OR m.employee2Id = :id") List<Match> findByEmployeeId(@Param("id") Long id)` — returns all matches for a given user
  - Method: `boolean existsByEmployee1IdAndEmployee2Id(Long emp1, Long emp2)` — prevents duplicate match creation

#### Frontend

- (no frontend work in this phase)

#### Verification

- [x] Run `.\mvnw.cmd spring-boot:run` — Flyway V7 migration applies without error
- [x] Verify in Postgres: `\d employee_match` shows the expected schema with constraints and indexes
- [x] Application context starts cleanly (Hibernate validates the entity against the table)

---

### Phase 2: Backend — Match detection + endpoints

**Goal:** The swipe endpoint detects mutual matches and persists them; a new matches endpoint returns the authenticated user's match list with scores and contact info.

#### Backend

- [x] Create `backend/src/main/java/com/example/deloitter/match/MatchResult.java`:
  - Record/DTO: `Long matchId`, `Long matchedEmployeeId`, `String firstName`, `String lastName`, `String initials`, `String roleFamily`, `String serviceLine`, `String contactInfo`, `int score`, `List<String> sharedInterests`, `List<String> sharedCompetencies`, `String shareSummary`
  - `initials` = `firstName.charAt(0) + "" + lastName.charAt(0)` (uppercased)
  - `shareSummary` = first 3 shared attributes joined by ", " + "+N more" if more exist (same logic as design comp)
- [x] Create `backend/src/main/java/com/example/deloitter/match/MatchItem.java`:
  - Record/DTO for the matches list: `Long matchId`, `Long matchedEmployeeId`, `String firstName`, `String lastName`, `String initials`, `String roleFamily`, `String serviceLine`, `String contactInfo`, `int score`, `List<String> sharedInterests`, `List<String> sharedCompetencies`
- [x] Create `backend/src/main/java/com/example/deloitter/match/MatchService.java`:
  - Inject `MatchRepository`, `SwipeRepository`, `EmployeeRepository`, `CompatibilityService`
  - Method: `Optional<MatchResult> detectAndCreateMatch(Employee me, Employee candidate)`:
    1. Check if reverse swipe exists: `SwipeRepository` has a row where `swiperId = candidate.id`, `candidateId = me.id`, `liked = true`
    2. If not → return `Optional.empty()` (no match)
    3. If yes → compute score via `CompatibilityService.computeScore(me, candidate)`
    4. Check idempotency: call `MatchRepository.existsByEmployee1IdAndEmployee2Id(min, max)` — if match already exists (race condition), fetch and return the existing match instead of re-creating
    5. Create `Match` entity with canonical ID ordering, score, persist via `MatchRepository.save()` — wrap in try/catch for `DataIntegrityViolationException` as a backstop (unique constraint), and return the existing match on conflict
    6. Build `MatchResult` DTO with score, candidate info, shared attributes, shareSummary
    7. Return `Optional.of(matchResult)`
  - Method: `List<MatchItem> getMatches(Employee me)`:
    1. Query `MatchRepository.findByEmployeeId(me.id)`
    2. For each match, resolve the *other* employee (the one whose ID ≠ me.id)
    3. Compute shared interests/competencies between me and the matched employee (re-compute from current selections — or use frozen? Decision: use **current** shared attributes for display, but keep the frozen score)
    4. Map to `MatchItem` DTOs
    5. Sort by `createdAt` descending (most recent first)
    6. Return list
- [x] Modify `backend/src/main/java/com/example/deloitter/swipe/SwipeResponse.java`:
  - Extend from `record SwipeResponse(boolean success)` to `record SwipeResponse(boolean success, MatchResult match)` where `match` is `@Nullable` (null when no mutual match)
  - Import `com.example.deloitter.match.MatchResult`
- [x] Modify `backend/src/main/java/com/example/deloitter/swipe/DiscoverService.java`:
  - Inject `MatchService`
  - Modify `recordSwipe()` to return `Optional<MatchResult>`:
    1. (existing) Validate candidateId, check not already swiped, persist swipe
    2. (new) If `liked == true`: call `matchService.detectAndCreateMatch(me, candidateEmployee)`
    3. Return the Optional (empty for pass, empty for like with no reverse, present for mutual match)
- [x] Modify `backend/src/main/java/com/example/deloitter/swipe/DiscoverController.java`:
  - Update `POST /api/discover/swipe` handler:
    - Call updated `discoverService.recordSwipe(...)` which now returns `Optional<MatchResult>`
    - Return `new SwipeResponse(true, matchResult.orElse(null))`
- [x] Create `backend/src/main/java/com/example/deloitter/match/MatchController.java`:
  - `@RestController @RequestMapping("/api/matches")`
  - Inject `MatchService`
  - `GET /api/matches`:
    - Resolve authenticated employee from SecurityContext
    - Call `matchService.getMatches(employee)`
    - Return `List<MatchItem>` (200 OK)
    - Empty list if no matches (never 404)
- [x] Ensure `SecurityConfig` permits `/api/matches/**` within the authenticated boundary (should already be covered)

#### Frontend

- (no frontend work in this phase)

#### Verification

- [x] Start backend with Postgres + seed data
- [x] Seed a mutual-like scenario: manually insert a swipe row where Ben liked Alice (`INSERT INTO employee_swipe (swiper_id, candidate_id, liked) SELECT b.id, a.id, true FROM employee b, employee a WHERE b.email = 'ben.martinez@deloitte.demo' AND a.email = 'alice.chen@deloitte.demo'`)
- [x] Log in as Alice, `POST /api/discover/swipe` with `{ "candidateId": <Ben's ID>, "liked": true }` → response should include `match` object with score, Ben's name, contact info, shared attributes
- [x] `GET /api/matches` (as Alice) → returns 1 match entry for Ben with score + contact
- [x] Log in as Ben, `GET /api/matches` → returns 1 match entry for Alice (same score, Alice's contact)
- [x] `POST /api/discover/swipe` with `{ "candidateId": <someone>, "liked": false }` → response has `match: null`
- [x] `POST /api/discover/swipe` with `{ "candidateId": <someone who hasn't liked me>, "liked": true }` → response has `match: null`
- [x] **Guardrail check (privacy):** No endpoint reveals who liked whom without a mutual match. The `match` field is null unless BOTH sides liked. The `GET /api/matches` only returns confirmed mutual matches for the authenticated user.
- [x] **Guardrail check (score):** The score appears ONLY in match contexts (`match` field of swipe response, matches list) — never in the stack or card responses.
- [x] All endpoints return 401 without auth cookie

---

### Phase 3: Backend — Seed mutual-like data for demo

**Goal:** Seed `employee_swipe` rows so that when the demo user (Alice) likes certain candidates, matches trigger immediately — enabling instant demo of the full match flow.

#### Backend

- [x] Create `backend/src/main/resources/db/migration/V8__seed_mutual_likes.sql`:
  - Insert swipe rows where 3–4 employees have "already liked" Alice:
    ```sql
    -- Ben likes Alice (when Alice likes Ben back → instant match demo)
    INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
    SELECT b.id, a.id, true, NOW() - INTERVAL '1 hour'
    FROM employee b, employee a
    WHERE b.email = 'ben.martinez@deloitte.demo'
      AND a.email = 'alice.chen@deloitte.demo';

    -- Chloe likes Alice
    INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
    SELECT c.id, a.id, true, NOW() - INTERVAL '2 hours'
    FROM employee c, employee a
    WHERE c.email = 'chloe.patel@deloitte.demo'
      AND a.email = 'alice.chen@deloitte.demo';

    -- Emily likes Alice
    INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
    SELECT e.id, a.id, true, NOW() - INTERVAL '3 hours'
    FROM employee e, employee a
    WHERE e.email = 'emily.zhang@deloitte.demo'
      AND a.email = 'alice.chen@deloitte.demo';

    -- Daniel likes Alice
    INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
    SELECT d.id, a.id, true, NOW() - INTERVAL '4 hours'
    FROM employee d, employee a
    WHERE d.email = 'daniel.kim@deloitte.demo'
      AND a.email = 'alice.chen@deloitte.demo';
    ```
  - This means when Alice swipes right on Ben/Chloe/Emily/Daniel, she instantly gets a match overlay
  - Also seed Alice liking some employees so other demo users get matches:
    ```sql
    -- Alice likes Frank (Frank hasn't liked Alice → no match, demonstrates privacy)
    INSERT INTO employee_swipe (swiper_id, candidate_id, liked, created_at)
    SELECT a.id, f.id, true, NOW() - INTERVAL '30 minutes'
    FROM employee a, employee f
    WHERE a.email = 'alice.chen@deloitte.demo'
      AND f.email = 'frank.wilson@deloitte.demo';
    ```

#### Frontend

- (no frontend work)

#### Verification

- [x] Run `.\mvnw.cmd spring-boot:run` — V8 migration applies without error
- [x] `GET /api/discover/stack` as Alice → Ben, Chloe, Emily, Daniel are still in the stack (they are not excluded — only Alice's own outgoing swipes exclude candidates; incoming swipes from others are invisible per privacy guardrail)
- [x] Alice swipes right on Ben → match! Response includes `match` with score + Ben's info
- [x] Alice swipes right on Frank → no match (Frank hasn't liked Alice in the seed)
- [x] **Guardrail check:** Alice has no way to know that Daniel/Chloe/Emily have liked her before she swipes on them. Their presence in the stack looks identical to non-likers.

---

### Phase 4: Frontend — API types + client extensions

**Goal:** The frontend API client has typed functions for match-related data.

#### Backend

- (no backend work)

#### Frontend

- [x] Create/update `frontend/src/types/match.ts`:
  - `export interface MatchResult { matchId: number; matchedEmployeeId: number; firstName: string; lastName: string; initials: string; roleFamily: string; serviceLine: string; contactInfo: string; score: number; sharedInterests: string[]; sharedCompetencies: string[]; shareSummary: string; }`
  - `export interface MatchItem { matchId: number; matchedEmployeeId: number; firstName: string; lastName: string; initials: string; roleFamily: string; serviceLine: string; contactInfo: string; score: number; sharedInterests: string[]; sharedCompetencies: string[]; }`
- [x] Update `frontend/src/types/discover.ts`:
  - Modify `SwipeResponse` to: `{ success: boolean; match: MatchResult | null; }`
- [x] Update `frontend/src/api/client.ts`:
  - Add typed function: `fetchMatches(): Promise<MatchItem[]>` — `GET /api/matches`
  - Ensure `recordSwipe()` return type reflects the new `SwipeResponse` shape (includes optional `match`)

#### Verification

- [x] `npm run build` succeeds (types compile)
- [x] `npm run lint` passes

---

### Phase 5: Frontend — Match overlay

**Goal:** When a swipe results in a mutual match, a celebratory overlay appears showing the score, shared summary, and CTA to message on Teams — matching the design comp exactly.

#### Backend

- (no backend work)

#### Frontend

- [x] Create `frontend/src/components/MatchOverlay.tsx`:
  - **Props:** `match: MatchResult`, `me: { initials: string }`, `onClose: () => void`, `onViewMatches: () => void`
  - **Layout** (design comp lines 283–316):
    - Fixed overlay covering viewport: `position: fixed; inset: 0; z-index: 100; background: oklch(0.45 0.1 150 / .45); backdrop-filter: blur(7px); display: flex; align-items: center; justify-content: center`
    - Confetti pieces (18 divs, absolutely positioned at top, animated with `dl-confetti` keyframe)
    - Modal card: `width: 420px; max-width: 100%; background: #fff; border-radius: 30px; padding: 36px 34px; text-align: center; box-shadow: 0 40px 90px -30px oklch(0.3 0.06 150 / .7); animation: dl-pop .45s cubic-bezier(.2,.9,.3,1.2) both`
    - "IT'S A MATCH" label: `font-size: 13px; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; color: oklch(0.62 0.13 145)`
    - "You're compatible!" title: `font-size: 29px; font-weight: 900; letter-spacing: -.02em`
    - Overlapping avatars (me left, match right with `margin-left: -18px`): both 84px circles with border + shadow
    - "You and {name}" subtitle: `font-size: 16px; font-weight: 700; color: oklch(0.4 0.02 152)`
    - Score display: `font-size: 64px; font-weight: 900; color: oklch(0.6 0.16 145); letter-spacing: -.03em`
    - "compatible" label below score: `font-size: 13px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase; color: oklch(0.6 0.08 145)`
    - Share summary: "Because you share **{shareSummary}**." — `font-size: 14px; color: oklch(0.5 0.02 152)`
    - Contact card: green-tinted row with "Reach out on" label + Teams handle + "Copy" button
    - Two action buttons side-by-side:
      - "Keep swiping" (outlined): calls `onClose`
      - "View matches" (green filled): calls `onViewMatches`
  - **Confetti generation** (from design comp lines 472–480):
    - 18 pieces, each positioned `left: (i * 5.4 + 2)%`
    - Size alternates: 8px, 12px, 16px
    - Colors cycle through palette: `["oklch(0.70 0.16 145)", "oklch(0.78 0.13 70)", "oklch(0.66 0.15 300)", "oklch(0.70 0.16 30)", "oklch(0.72 0.12 180)"]`
    - Duration: `1.5s + (i%4)*0.3s`, delay: `(i%6)*0.12s`
    - Shape alternates: circle (50% radius) vs square (2px radius)
    - Animation: `dl-confetti` — translateY(-30px → 640px), rotate(0 → 540deg), opacity 1 → 0
  - **Copy to clipboard:** on "Copy" button click, copy `match.contactInfo` to clipboard, show a toast "Copied {handle}"
  - **Accent color:** use `getAccentColor(match.matchedEmployeeId)` for the matched employee's avatar

- [x] Create `frontend/src/components/MatchOverlay.module.css`:
  - Keyframes:
    - `dl-pop`: `0% { transform: scale(.94) } 60% { transform: scale(1.02) } 100% { transform: scale(1) }`
    - `dl-confetti`: `0% { transform: translateY(-30px) rotate(0); opacity: 1 } 100% { transform: translateY(640px) rotate(540deg); opacity: 0 }`
  - Utility classes for overlay, modal, buttons

- [x] Integrate into `frontend/src/pages/DiscoverPage.tsx`:
  - After `recordSwipe()` resolves: if `response.match` is non-null, store it in state (`pendingMatch`)
  - Render `<MatchOverlay>` when `pendingMatch` is set
  - `onClose` → clear `pendingMatch` (continue swiping)
  - `onViewMatches` → navigate to `/matches`
  - **Timing:** Start the fly-off animation immediately (don't block on API response). When the response arrives after ~300ms, if there's a match, show the overlay. The overlay's entrance animation (`dl-pop`) creates a natural timing bridge.

#### Verification

- [x] Start both tiers; log in as Alice
- [x] Swipe right on Ben (seeded to have liked Alice) → card flies off, then match overlay appears
- [x] Overlay shows: "It's a match", "You're compatible!", both avatars, correct score, shared summary, Ben's Teams handle
- [x] Confetti animation plays (18 pieces falling)
- [x] "Copy" button copies Teams handle to clipboard
- [x] "Keep swiping" → overlay closes, next card visible
- [x] "View matches" → navigates to `/matches`
- [x] Swipe right on someone who hasn't liked Alice → no overlay, next card appears normally
- [x] Swipe left (pass) → no overlay regardless of who liked Alice

---

### Phase 6: Frontend — Matches page

**Goal:** A dedicated Matches page showing the user's confirmed mutual matches with score, shared interests, and contact info — matching the design comp exactly.

#### Backend

- (no backend work)

#### Frontend

- [x] Create `frontend/src/pages/MatchesPage.tsx`:
  - **On mount:** call `fetchMatches()` → store result in state
  - **Header** (design comp lines 203–204):
    - Title: "Your matches" — `font-size: 26px; font-weight: 900; letter-spacing: -.02em`
    - Subtitle: "When you both like each other, the compatibility score and contact details unlock." — `font-size: 14.5px; color: oklch(0.55 0.02 152); margin-top: 3px; margin-bottom: 28px`
  - **Empty state** (design comp lines 206–212) — shown when matches array is empty:
    - White card, centered, `border-radius: 24px; padding: 54px`
    - 💚 emoji in green circle (66px)
    - "No matches yet" title: `font-size: 19px; font-weight: 800`
    - "Keep swiping in Discover — matches show up here." subtitle
    - "Start swiping" button (green) → navigates to `/discover`
  - **Match grid** (design comp lines 216–244) — shown when matches exist:
    - `display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 340px)); gap: 18px`
    - Each match card:
      - Container: `background: #fff; border: 1px solid oklch(0.91 0.012 150); border-radius: 22px; padding: 22px; box-shadow: 0 14px 34px -26px oklch(0.4 0.05 150 / .5)`
      - Top row (flex): avatar (56px circle, accent color, initials) + name/role + score badge
      - Score badge: `background: oklch(0.93 0.06 145); border-radius: 13px; padding: 7px 11px` — score in large green text + "match" label
      - Shared interests chips: `background: oklch(0.95 0.03 145); color: oklch(0.42 0.08 148); font-size: 12px; font-weight: 700; padding: 5px 10px; border-radius: 999px`
      - Divider: `border-top: 1px solid oklch(0.93 0.01 150); padding-top: 14px`
      - Contact row: Teams handle with 💬 icon
      - "Message on Teams" button: `border: 1px solid oklch(0.85 0.06 145); background: oklch(0.97 0.02 145); color: oklch(0.42 0.1 145); font-size: 13.5px; font-weight: 800; padding: 10px; border-radius: 11px`
  - **"Message on Teams" button behavior:** copy the Teams handle to clipboard + show toast "Copied {handle}" (same as overlay copy)
  - **Loading state:** show skeleton cards while `fetchMatches()` is in-flight
  - **Error state:** simple error message with retry button

- [x] Create `frontend/src/pages/MatchesPage.module.css`:
  - Button hover effects matching design comp
  - Grid responsive utilities

- [x] Replace the `MatchesPlaceholder` route:
  - Update `frontend/src/App.tsx`: change `/matches` route from `<MatchesPlaceholder />` to `<MatchesPage />`
  - Delete `frontend/src/pages/MatchesPlaceholder.tsx` (if it was created in S-03)

#### Verification

- [x] `npm run build` succeeds
- [x] `npm run lint` passes
- [ ] Navigate to Matches tab with no matches → empty state with 💚 emoji and "Start swiping" CTA
- [ ] Create a match (swipe right on Ben) → navigate to Matches → Ben appears in the grid
- [ ] Card shows: Ben's avatar (accent color, initials), name, role, score %, shared interests chips, Teams handle, "Message on Teams" button
- [ ] "Message on Teams" copies handle to clipboard + shows toast
- [ ] Multiple matches appear in the grid (swipe right on Chloe, Emily)
- [ ] Most recent match appears first

---

### Phase 7: Frontend — Nav badge + wiring + polish

**Goal:** The Matches nav tab shows a match count badge, the full flow is polished, and edge cases are handled.

#### Backend

- (no backend work)

#### Frontend

- [x] Update `frontend/src/components/AppShell.tsx`:
  - Add match count state (fetched from `/api/matches` length on mount, or maintained in a context)
  - "Matches" tab badge (design comp line 71): green pill `background: oklch(0.70 0.16 145); color: #fff; font-size: 12px; font-weight: 800; min-width: 20px; height: 20px; padding: 0 6px; border-radius: 10px` — shows count when > 0
  - When a new match occurs (from swipe response), increment count in-memory so the badge updates immediately without a re-fetch

- [x] Create a lightweight MatchContext or extend existing state management:
  - Stores current match count (number)
  - Provides `incrementMatchCount()` callable from DiscoverPage when a match occurs
  - Provides `setMatchCount(n)` callable from MatchesPage after fetch
  - AppShell subscribes to the count for the badge

- [x] **Toast component** (design comp lines 319–321):
  - If not already created in S-03, create a simple toast: `position: fixed; bottom: 28px; left: 50%; transform: translateX(-50%); z-index: 200; background: oklch(0.27 0.03 152); color: #fff; font-size: 14px; font-weight: 700; padding: 12px 22px; border-radius: 999px; box-shadow: 0 14px 34px -14px oklch(0.3 0.06 150 / .7)`
  - Auto-dismiss after ~2 seconds
  - Used for "Copied @handle" feedback on both overlay and matches page

- [x] **Edge cases:**
  - Match overlay should not appear if the user has already navigated away from Discover (e.g., rapid tab switching)
  - Match overlay blocks further swiping until dismissed (per design comp behavior — the overlay is modal)
  - If `fetchMatches()` fails, show error state with retry
  - If no auth session, redirect to login (handled by existing ProtectedRoute)

- [x] **Document title:** "Deloitter — Matches" while on the matches page

- [x] Verify `npm run build` succeeds
- [x] Verify `npm run lint` passes

#### Verification

- [x] Match count badge visible in nav after creating a match
- [x] Badge count increments when a new match occurs during swiping (without page refresh)
- [x] Badge not visible when count is 0
- [x] Toast appears and auto-dismisses on copy actions
- [x] Page title shows "Deloitter — Matches" on matches page
- [x] Rapid swiping doesn't break the overlay (overlay is modal, blocks interaction)

---

## Integration & Smoke Test

- [ ] From clean state: Postgres running with full seed (V1–V8), backend started, frontend started
- [ ] Log in as `alice.chen@deloitte.demo` (password: `password123`) → land on Discover page
- [ ] Swipe right (like) on Ben Martinez (seeded mutual-like) → card flies off, then **match overlay appears**:
  - "It's a match" / "You're compatible!"
  - Both avatars overlapping (Alice + Ben)
  - Score shows (e.g., 40–50% based on shared ML, Startups, Travel + Strategy Consulting, Python, AI/ML Engineering + same service line)
  - "Because you share Machine Learning, Startups, Travel +N more"
  - Ben's Teams handle: `@ben.martinez`
  - Confetti animation plays
- [ ] Click "Copy" → toast "Copied @ben.martinez"
- [ ] Click "Keep swiping" → overlay closes, next card visible
- [ ] Swipe right on Chloe Patel (seeded mutual-like) → match overlay for Chloe
- [ ] Click "View matches" → navigates to Matches page
- [ ] Matches page shows grid with Ben and Chloe match cards:
  - Correct score badges
  - Shared interest chips
  - Teams handles
  - "Message on Teams" buttons
- [ ] Nav "Matches" tab shows badge with count "2"
- [ ] Swipe left (pass) on some candidates → no match overlay ever appears for passes
- [ ] Swipe right on someone who hasn't liked Alice (e.g., Frank) → no overlay (Frank's like for Alice was outgoing only)
- [ ] Log in as Ben Martinez → Matches page shows Alice as a match (same score from Ben's perspective)
- [ ] Ben's Discover stack does NOT reveal who liked him — Alice's outgoing like is invisible in Ben's stack (privacy guardrail)
- [ ] **Guardrail check (privacy):** At no point can any user learn that someone liked or passed on them without a mutual match. Test: Alice passes on Frank → Frank has no way to discover this (no API endpoint, no UI hint)
- [ ] **Guardrail check (score):** The score never appears on the Discover page — only in the match overlay and the Matches page
- [ ] **Guardrail check (explainable):** The revealed score makes sense — higher overlap of interests/competencies/service-line produces a higher score. Shared attributes shown in the overlay's "Because you share…" summary match reality
- [ ] **Design check:** Visual comparison with design comp — match overlay layout, confetti, matches grid, score badge, nav badge all match the reference

## Open Questions

1. **Should the score shown on match re-compute or use the frozen value?** — Plan says: freeze the score at match time (persisted in the `match` row). The shared attributes displayed on the Matches page are re-computed from current selections. This means after S-05 (edit interests), the displayed shared chips might drift from the frozen score. Acceptable for POC — the score is a snapshot. Non-blocking.
2. **Should there be a notification/sound on match?** — Design comp shows confetti but no audio. Plan excludes audio (non-goal for hackathon). Non-blocking.
3. **What if both users swipe each other simultaneously (race condition)?** — At pilot scale with 20 seeded users, this is nearly impossible. The `UNIQUE (employee_1_id, employee_2_id)` constraint on `employee_match` prevents duplicate match rows. If a duplicate insert occurs, catch the `DataIntegrityViolationException` and return the existing match. Non-blocking.
4. **Should the overlay wait for the API response or show optimistically?** — Plan says: start the card fly-off animation immediately (fire-and-forget feel), but await the response before deciding whether to show the overlay. The ~300ms fly-off animation covers the round-trip. If the response is slow (> 500ms), the overlay will appear after a brief pause — acceptable for POC. Non-blocking.

