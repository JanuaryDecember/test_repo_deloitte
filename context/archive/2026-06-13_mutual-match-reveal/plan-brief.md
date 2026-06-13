> **Archived:** 2026-06-13 00:00 | Change ID: `mutual-match-reveal` | Roadmap ID: `S-04`

# Plan Brief: Mutual match reveal

**Change ID:** `mutual-match-reveal` | **Roadmap ID:** `S-04` | **Status:** revised

## What

When two users have each liked the other, the system detects the mutual match, freezes the compatibility score, and reveals it alongside the matched colleague's contact info. The user sees a celebratory overlay (confetti, avatars, score, Teams handle) immediately upon the triggering swipe, and can browse all their matches in a dedicated Matches grid view. This is the north-star milestone — the payoff of the entire swipe loop.

## Phases at a glance

| #   | Phase                       | Backend | Frontend | Key deliverable                                                       |
| --- | --------------------------- | ------- | -------- | --------------------------------------------------------------------- |
| 1   | Match persistence           | ✓       | —        | `employee_match` table (Flyway V7) + JPA entity + repository          |
| 2   | Match detection + endpoints | ✓       | —        | `detectAndCreateMatch()`, extended swipe response, `GET /api/matches` |
| 3   | Seed mutual likes           | ✓       | —        | V8 migration: 4 employees pre-like Alice for instant demo             |
| 4   | API types + client          | —       | ✓        | `MatchResult`, `MatchItem` types, `fetchMatches()` client fn          |
| 5   | Match overlay               | —       | ✓        | Confetti + avatars + score + Teams CTA modal after mutual swipe       |
| 6   | Matches page                | —       | ✓        | Grid of match cards with score badge, shared chips, contact info      |
| 7   | Nav badge + polish          | —       | ✓        | Match count pill on tab, toast on copy, edge cases                    |

## Key decisions

- **Match detection is inline** in the swipe endpoint — no async/event system; the response includes `match: MatchResult | null`
- **Single `employee_match` table** with canonical ID ordering (`employee_1_id < employee_2_id`) prevents duplicates
- **Score is frozen** at match creation time — reflects the moment of connection, not future edits
- **4 seeded mutual likes** for Alice ensure the demo triggers matches on the first few swipes
- **Card fly-off animation starts immediately** (fire-and-forget feel); overlay appears after API response arrives (~300ms)
- **CSS-only confetti** (18 animated pieces) — no external library

## Risks & mitigations

| Risk                                                    | Mitigation                                                                                                                                                                                  |
| ------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Privacy guardrail violation — leaking non-mutual intent | Enforced at API level: `match` field only populated when both sides liked. No endpoint exposes pending likes.                                                                               |
| Score leaking during swipe                              | Score computed on backend only for ranking; never serialized in stack response. Exposed only in match/matches responses.                                                                    |
| Race condition on simultaneous mutual swipe             | `UNIQUE` constraint on `employee_match` prevents duplicate rows; pre-check + catch `DataIntegrityViolationException` and return existing match on conflict. Negligible risk at pilot scale. |
| Overlay timing mismatch with fly-off animation          | Fly-off is 300ms; typical API round-trip < 200ms locally. If slow, overlay appears with a natural delay — acceptable for POC.                                                               |
| Score drift after interest edits (S-05)                 | Score frozen at match time (design decision). Shared chips re-computed for display. Documented trade-off.                                                                                   |

## Estimated effort

**M (Medium)** — The slice touches both tiers with new persistence, two endpoints, and three frontend components (overlay, matches page, nav badge). However, the logic is straightforward (match detection is a single reverse-lookup), the UI closely follows the detailed design comp, and the seeded data enables instant verification. The heaviest part is pixel-matching the overlay and matches grid to the design reference.
