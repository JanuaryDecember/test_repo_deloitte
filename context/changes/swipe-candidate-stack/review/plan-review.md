---
change_id: "swipe-candidate-stack"
reviewed: 2026-06-13
plan_status_before: draft
plan_status_after: revised
findings_total: 4
critical: 0
major: 0
minor: 1
suggestions: 3
fixes_applied: 4
---

# Plan Review: Swipe the candidate stack

## Summary

The plan is well-structured, technically sound, and fully aligned with PRD guardrails. No critical or major issues were found. The single minor finding (a repository method name typo) had a correct alternative already provided. Three suggestions were applied as non-blocking implementation notes to guide the implementer. The plan is ready for implementation.

## Findings

### 🔴 Critical

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| — | — | None | N/A |

### 🟠 Major

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| — | — | None | N/A |

### 🟡 Minor

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Technical Correctness | Phase 1 SwipeRepository: method name `existsBySwipeIdAndCandidateId` doesn't match entity field `swiperId` — Spring Data would look for property `swipeId`. Correct name is `existsBySwiperIdAndCandidateId`. The plan already provided the correct alternative (`existsById(new SwipeId(...))`). | Fixed — corrected method name in plan.md. |

### 🔵 Suggestions

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 2 | Feasibility & Risk | `DiscoverService.getStack()` accesses LAZY `interests`/`competencies` in a loop, triggering N+1 queries. Acceptable at 20 users but could be optimized with `@EntityGraph`. | Fixed — added Decision #10b noting accepted trade-off with optional EntityGraph hint. |
| 3 | PRD Alignment | PRD Business Logic mentions "shared service line / role family / career path" — plan includes only service line. PRD uses "e.g." (suggestive), so not required, but role family could be added trivially. | Fixed — added Decision #10c documenting the choice and noting the extension point. |
| 4 | Feasibility & Risk | Fire-and-forget `recordSwipe()` failure means the candidate reappears on page refresh. Plan mentions optional toast but doesn't explicitly document this as an accepted trade-off. | Fixed — added Decision #12b documenting the accepted trade-off. |

## Fixes Applied

1. **Phase 1, SwipeRepository method name** — Changed `existsBySwipeIdAndCandidateId` → `existsBySwiperIdAndCandidateId`.
2. **Decisions table, row 10b (new)** — Added N+1 lazy-loading note: accepted for POC, optional `@EntityGraph` hint.
3. **Decisions table, row 10c (new)** — Added role-family exclusion rationale and extension point.
4. **Decisions table, row 12b (new)** — Added fire-and-forget failure trade-off documentation.
5. **Frontmatter status** — Updated from `draft` to `revised`.

## Verdict

**Status:** PASS — ready for implementation

The plan covers all PRD requirements (FR-003, FR-004, Business Logic, Responsiveness NFR), respects all three hard guardrails (no rejection signals, explainable score, score hidden while swiping), stays strictly within S-03 scope (no match detection), and provides concrete verification steps for each phase. The technical approach is sound for the declared tech stack and POC scale. All fixes applied were cosmetic or informational — no structural changes to the plan were needed.

