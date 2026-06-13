> **Archived:** 2026-06-13 00:00 | Change ID: `swipe-candidate-stack` | Roadmap ID: `S-03`

# Plan Brief: Swipe the candidate stack

**Change ID:** `swipe-candidate-stack` | **Roadmap ID:** `S-03` | **Status:** draft

## What

Delivers the core swipe interaction: a ranked candidate stack on the Discover page where each card shows a colleague's shared interests/competencies (score hidden), and the user swipes like or pass with instant-feeling drag gestures or buttons. The backend computes proportional-overlap compatibility to rank candidates highest-first, persists every swipe decision, and excludes already-swiped candidates from the stack.

## Phases at a glance

| #   | Phase               | Backend | Frontend | Key deliverable                                                               |
| --- | ------------------- | ------- | -------- | ----------------------------------------------------------------------------- |
| 1   | Swipe persistence   | ✓       | —        | `employee_swipe` table + JPA entity (Flyway V6 migration)                     |
| 2   | Compatibility + API | ✓       | —        | `CompatibilityService`, `GET /api/discover/stack`, `POST /api/discover/swipe` |
| 3   | API client types    | —       | ✓        | TypeScript types + typed fetch functions for discover endpoints               |
| 4   | Discover page UI    | —       | ✓        | Card stack with drag-to-swipe gestures, action buttons, empty state           |
| 5   | Routing & polish    | —       | ✓        | `/discover` route wired, loading states, edge cases, accessibility            |

## Key decisions

- **Proportional overlap (Jaccard index)** for compatibility — `|intersection| / |union|` over interests + competencies + service-line signal. Deterministic, explainable, matches PRD.
- **Full stack prefetch** — `GET /api/discover/stack` returns all remaining candidates in one call. With ~20 seeded users, this guarantees instant (< 300ms) card transitions with zero per-card latency.
- **Score never sent to client** — API returns shared attributes for display but never the numeric score (guardrail enforcement at API level).
- **Hand-rolled pointer-event gestures** — matches design comp exactly, no external library.
- **Fire-and-forget swipe calls** — `POST /api/discover/swipe` is called but the UI doesn't await it before showing the next card (responsiveness NFR).
- **Single `employee_swipe` table** — records likes and passes with a boolean flag; compound PK prevents duplicates.
- **Style A (Warm) card** — green gradient header, circular avatar, shared-attribute chips. Other styles are future polish.

## Risks & mitigations

| Risk                                               | Mitigation                                                                                                                                                                       |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Score is wrong/unexplainable (guardrail violation) | Jaccard formula is transparent; verification checks ranking intuitively matches shared-attribute count. Score never displayed during swipe.                                      |
| Transitions lag (responsiveness NFR)               | Full prefetch + local-state index increment = no network call between cards. Animation is pure CSS/JS (< 300ms). Fire-and-forget swipe persistence.                              |
| Privacy leak (another user's intent exposed)       | Swipe table is only queried for the authenticated user's own records. No endpoint returns another user's likes/passes. Stack response has only profile data + shared attributes. |
| Heaviest slice — scope creep risk                  | Scope is strict: no match detection (S-04), no match overlay, no matches list. Empty deck just links to `/matches`.                                                              |
| Prerequisite not ready (S-02 profile selections)   | Plan documents the assumption; Phase 2 verification will catch it immediately if selections don't exist.                                                                         |

## Estimated effort

**Size: L (Large)** — This is the heaviest slice per the roadmap. Backend: new migration, 2 services, 1 controller, 4 DTOs. Frontend: full Discover page with custom gesture handling, animations, card rendering, 3 states (loading/cards/empty). However, the design comp provides exact layout/style/logic to replicate and the compatibility formula is straightforward. Estimated at 6–10 hours of implementation.
