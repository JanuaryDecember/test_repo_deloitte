---
change_id: "edit-interests"
roadmap_id: "S-05"
status: revised
created: 2026-06-13
prd_refs: [FR-007]
prerequisites: [S-02 select-interests]
---

# Plan: Edit interests & competencies after initial setup

## Context

This slice delivers the ability for a user to **re-edit** their interests and competencies after initial setup (S-02), changing the inputs that drive future match ranking. FR-007 is a "nice-to-have" — build only if the core match flow (S-01 → S-04) is complete.

Sequenced after S-02 (`select-interests`) which builds the Profile page with the initial chip-toggle + save flow. S-05 is parallel with S-03/S-04 and blocks nothing downstream.

**Assumes S-02 is fully implemented:** The Profile page at `/profile` exists with the chip-toggle UI for interests and competencies, the `PUT /api/profile/selections` endpoint persists changes, and the catalog + selections fetch is working. The core edit mechanism is already in place from S-02 — this slice adds the re-edit-specific UX: an informational notice that changes affect future recommendations, navigation affordances from other pages to the Profile edit view, and graceful handling of the "selections changed after swiping" edge case.

**Design reference:** `frontend/context/foundation/design/Deloitter.dc.html` lines 249–277 — the Profile section is the authoritative visual spec. The design shows the same chip-toggle interface for both initial setup and later editing (no separate "edit mode"). The chip styling, "Save profile" button, section headings, and user header card are all defined there.

## Decisions & Assumptions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Separate "edit" UI vs. reuse S-02 Profile page | **Reuse the same Profile page** from S-02 | The design comp shows a single Profile section with toggleable chips and a "Save profile" button — no distinction between initial setup and edit. Simpler, consistent, matches the design. |
| 2 | Impact notice when editing after swiping | **Inline info banner** below the user header card, shown only when user has at least one swipe recorded | "Updating your interests will change future recommendations but won't affect existing matches." Keeps expectations clear. Non-blocking (user can still save freely). |
| 3 | Candidate stack invalidation on edit | **No automatic reset** — the next time the user visits Discover, the stack is re-ranked with updated selections | Backend scoring already reads current selections at query time. No migration or reset logic needed. If user has already swiped everyone, no new candidates appear — this is acceptable for the demo. |
| 4 | Edit link from other views | **"Edit your interests" link on the Discover page** (visible when stack is empty or as a subtle link) | Helps discoverability: if a user finishes the stack they're nudged to refine interests, which could surface new candidates in a larger dataset. |
| 5 | Minimum selections enforcement | **Soft nudge, no hard block** — if user deselects all, show a subtle warning but allow save | PRD says matching needs overlap inputs; an empty profile produces an empty stack. A gentle prompt ("Pick at least one interest for better matches") is sufficient. |
| 6 | Timestamp / "last updated" display | **Not included** | Over-engineering for a demo. Profile page just shows current state. |
| 7 | Unsaved changes warning on navigate-away | **Not included** | Speed goal; data loss is minor (user can re-toggle). S-02's plan explicitly deferred this. |
| 8 | Backend changes | **None** — all endpoints from S-02 already support re-editing | `PUT /api/profile/selections` is idempotent and works regardless of whether it's the first save or the tenth. |

## Phases

### Phase 1: Backend — Swipe-count endpoint for conditional UI

**Goal:** Expose a lightweight signal so the frontend knows whether the user has already swiped (to conditionally show the "changes affect future recommendations" notice).

#### Backend

- [ ] Add a `hasSwiped` boolean field to `ProfileResponse` in `backend/src/main/java/com/example/deloitter/profile/ProfileResponse.java`
- [ ] Update `ProfileService.getProfile()` to populate the new field:
  - **Hardcode `false`** for now — S-03 (which introduces the swipe table and repository) is not yet built.
  - Add a `// TODO: wire SwipeRepository.existsByEmployeeId() once S-03 lands` comment so it's trivial to activate later.
  - When S-03 is implemented, replace the hardcoded value with a real query (e.g., `swipeRepository.existsByEmployeeId(employee.getId())`). No optional injection or conditional bean logic needed — a simple code change in one line.

#### Frontend

- (no frontend work in this phase)

#### Verification

- [ ] `GET /api/profile` returns a response with the `hasSwiped` field (true/false)
- [ ] If S-03 is not yet implemented, the field is always `false`
- [ ] Backend compiles and tests pass: `.\mvnw.cmd test`

---

### Phase 2: Frontend — Edit notice & soft validation

**Goal:** Add contextual UI elements that differentiate the re-edit experience from first-time setup: an info banner, empty-selection warning, and page title update.

#### Backend

- (no backend work)

#### Frontend

- [ ] Update `frontend/src/types/profile.ts` (created by S-02):
  - Add `hasSwiped: boolean` to the `UserProfile` interface
- [ ] Create or update `frontend/src/pages/ProfilePage.tsx` (extending what S-02 built):
  - **Info banner** (below user header card, above interest chips):
    - Conditionally rendered when `profile.hasSwiped === true`
    - Style: subtle info card matching the design language:
      - `background: oklch(0.97 0.02 145)` (light green tint)
      - `border: 1px solid oklch(0.9 0.04 150)`
      - `border-radius: 14px`
      - `padding: 14px 18px`
      - Icon: ℹ️ or a subtle info SVG
      - Text: "Updating your interests will change future recommendations but won't affect existing matches."
      - Font: `13.5px`, color `oklch(0.45 0.03 152)`, weight 600
    - Margin-bottom: 24px
  - **Empty-selection nudge**:
    - If all interest chips are deselected, show a subtle inline message below the interest chips:
      - "Pick at least one interest for better matches"
      - Style: `font-size: 12.5px`, `color: oklch(0.6 0.1 30)` (warm amber/muted), `margin-top: 8px`
    - Same for competencies (optional — competencies can be 0 without breaking anything)
    - Does NOT block save — just informational
  - **Page title**: `document.title = "Deloitter — Edit Profile"` (update from "Profile" to clarify intent)
- [ ] Update `frontend/src/pages/ProfilePage.module.css`:
  - Add styles for `.infoBanner`, `.nudgeText`

#### Verification

- [ ] When `hasSwiped` is true, the info banner appears between header card and interest section
- [ ] When `hasSwiped` is false (fresh user / S-03 not built), no banner appears
- [ ] Deselecting all interests shows the nudge text; re-selecting one hides it
- [ ] Save still works even with 0 selections (no hard block)
- [ ] `npm run build` succeeds
- [ ] `npm run lint` passes

---

### Phase 3: Frontend — Navigation affordances from other views

**Goal:** Make the edit flow discoverable from the Discover page (especially when the stack is empty) and ensure the Profile tab navigation works for re-editing.

#### Backend

- (no backend work)

#### Frontend

- [ ] Update `frontend/src/pages/HomePage.tsx` (or future DiscoverPage if S-03 is built):
  - If the candidate stack is empty / the page shows a "You're all caught up" state:
    - Add a secondary link/button: "Edit your interests" that navigates to `/profile`
    - Style (from design comp lines 97-103, the empty-deck card):
      - Below the "View your matches" button, add a text link:
      - `font-size: 13.5px`, `color: oklch(0.55 0.02 152)`, `text-decoration: underline`, `cursor: pointer`
      - Text: "or edit your interests"
    - Uses React Router `<Link to="/profile">`
  - If the deck is NOT empty, do not show the link (keep Discover focused on swiping)
- [ ] Ensure the AppShell "Profile" nav tab navigates to `/profile` (should already work from S-02's Phase 4):
  - Verify the active-tab indicator (green underline) highlights when on `/profile`
  - Verify clicking "Profile" from any page navigates correctly

#### Verification

- [ ] On the Discover/Home page, when the stack is empty (or for the current placeholder), an "edit your interests" link appears
- [ ] Clicking the link navigates to `/profile`
- [ ] The Profile tab in the nav header is highlighted when on `/profile`
- [ ] After editing and saving on the Profile page, navigating back to Discover loads a fresh stack (if S-03 is built)
- [ ] `npm run build` succeeds
- [ ] `npm run lint` passes

---

### Phase 4: Polish — Loading, transitions, and accessibility *(stretch — skippable under time pressure)*

**Goal:** Ensure the re-edit flow is smooth and accessible. This entire phase is polish on top of FR-007 (itself a nice-to-have). Skip if time is tight — Phases 1–3 fully deliver the feature.

#### Backend

- (no backend work)

#### Frontend

- [ ] **Transition on info banner**: fade-in animation when banner appears (prevents layout jank):
  - `animation: dl-rise 0.3s ease both`
- [ ] **Save button state awareness**:
  - If selections haven't changed from what's persisted, the Save button text reads "Saved ✓" (muted style) instead of "Save profile"
  - On any toggle, it reverts to "Save profile" (active/green style)
  - While saving: "Saving…" (disabled)
  - After successful save: briefly show "Saved ✓" then persist that state until next change
- [ ] **Accessibility for info banner**:
  - `role="note"` or wrapped in an `<aside>` with `aria-label="Profile edit information"`
  - Nudge text uses `role="status"` with `aria-live="polite"` so it's announced when it appears
- [ ] **Chip count indicator** (optional nice touch from design):
  - Below each section heading, show a subtle count: "3 selected" / "0 selected"
  - `font-size: 12px`, `color: oklch(0.6 0.015 152)`, `font-weight: 600`
- [ ] **Hover effect on chips**: confirm `transition: all 0.12s` works on hover (brightness or subtle scale)
- [ ] Verify full keyboard navigation: Tab through chips, Space/Enter to toggle, visible focus rings
- [ ] `npm run build` succeeds
- [ ] `npm run lint` passes

#### Verification

- [ ] Info banner fades in smoothly (no layout shift)
- [ ] Save button reflects current dirty/clean state accurately
- [ ] Screen reader announces the nudge text when interests are deselected
- [ ] Keyboard-only user can toggle chips and save without a mouse
- [ ] Visual comparison with design comp (lines 249-277) — still matches after additions

---

## Integration & Smoke Test

- [ ] From clean state: Postgres running, backend started, frontend started, S-02 implemented
- [ ] Log in with seeded credentials → navigate to Profile
- [ ] Profile page shows pre-seeded selections as green chips (from S-02)
- [ ] If S-03 is implemented and user has swiped: info banner appears explaining impact of changes
- [ ] Toggle several chips (add new interests, remove existing ones)
- [ ] Empty-selection nudge appears if all interests are deselected
- [ ] Click "Save profile" → toast "Profile updated" appears
- [ ] Refresh page → selections persist correctly
- [ ] Navigate to Discover → candidate stack (if S-03 is built) reflects the updated interests in ranking
- [ ] Navigate back to Profile → saved selections still shown correctly
- [ ] From the "all caught up" / empty-stack state on Discover: "edit your interests" link is visible and works
- [ ] **Guardrail check:** No other user's selections are visible or accessible.
- [ ] **Guardrail check:** No compatibility score is exposed on the Profile page.
- [ ] **Guardrail check:** No swipe intent or match data is accessible from Profile endpoints.
- [ ] **Design check:** Visual comparison with design comp Profile section (lines 249-277 of `Deloitter.dc.html`) — chip style, colors, spacing, typography all match. Info banner and nudge are additive and don't break the existing design language.
- [ ] Log out, log in as a different user → that user's distinct selections and profile appear

## Open Questions

1. **Should editing interests invalidate already-seen candidates?** — Plan says no: candidates swiped stay swiped. If the candidate pool were larger, a user could edit interests and see new people they hadn't swiped yet. For the demo's small seed set this has limited value. Non-blocking.
2. **Should there be a confirmation dialog before saving if user has swiped?** — Plan says no — the info banner sets expectations, and a modal adds friction under the speed goal. Non-blocking.
3. **Is S-03's swipe table available?** — If not yet implemented, the `hasSwiped` field defaults to `false` and the info banner never shows. The plan is forward-compatible; once S-03 lands, the banner activates automatically. Non-blocking.

