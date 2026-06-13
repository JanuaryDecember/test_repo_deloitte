# Plan Brief: Edit interests & competencies after initial setup

**Change ID:** `edit-interests` | **Roadmap ID:** `S-05` | **Status:** revised

## What

Extends the Profile page (built in S-02) to support re-editing interests and competencies after the user has already swiped candidates. Adds an informational notice about how changes affect future recommendations, a soft nudge when no selections are made, a navigation link from the empty-stack state on Discover, and save-state polish. The backend already supports the edit via `PUT /api/profile/selections` — the only backend change is adding a `hasSwiped` flag to `ProfileResponse` (and the corresponding `ProfileService` line to populate it).

## Phases at a glance

| # | Phase | Backend | Frontend | Key deliverable |
|---|-------|---------|----------|-----------------|
| 1 | Swipe-count signal | ✓ | — | `hasSwiped` field on `GET /api/profile` for conditional info banner |
| 2 | Edit notice & soft validation | — | ✓ | Info banner when user has swiped; empty-selection nudge |
| 3 | Navigation affordances | — | ✓ | "Edit your interests" link from Discover empty-stack state |
| 4 | Polish & accessibility | — | ✓ | Save-button state, transitions, keyboard/screen reader support |

## Key decisions

- **Reuse S-02's Profile page** — no separate "edit mode"; the same chip-toggle UI serves both initial setup and later editing (matches design comp exactly).
- **No candidate stack reset** — editing interests changes future ranking but does not un-swipe anyone. The backend scoring reads current selections at query time.
- **Soft nudge, no hard block** — empty selections produce a warning but are still saveable. S-03 handles the empty-stack edge case gracefully.
- **Info banner is conditional** — only appears if the user has at least one recorded swipe (forward-compatible with S-03; defaults to hidden if S-03 isn't built yet).
- **No unsaved-changes modal** — speed goal; minor data loss isn't worth the friction.

## Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| S-03 not yet implemented → `hasSwiped` field has no swipe table to query | Default to `false`; banner simply doesn't appear. Plan is forward-compatible. |
| Editing interests after swiping everyone provides no new candidates in the small demo dataset | Acceptable for a hackathon demo — real dataset would be larger. The empty-stack link still nudges users productively. |
| Scope creep into "auto-recalculate stack" or "unsaved changes" modals | Explicitly out of scope (Decisions #3 and #7). |

## Estimated effort

**S (Small)** — The core edit mechanism (backend endpoint + frontend chip UI) is already fully built by S-02. This slice adds ~1 conditional banner, ~1 text link, and UX polish. Minimal backend change (one boolean field). Mostly frontend refinement work, estimated at 2–4 hours.

