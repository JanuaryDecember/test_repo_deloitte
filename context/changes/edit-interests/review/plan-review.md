---
change_id: "edit-interests"
reviewed: 2026-06-13
plan_status_before: draft
plan_status_after: revised
findings_total: 4
critical: 0
major: 1
minor: 2
suggestions: 1
fixes_applied: 4
---

# Plan Review: Edit interests & competencies after initial setup

## Summary

The plan is well-structured, correctly scoped to FR-007, and respects all PRD guardrails. The main concern was a compile-time dependency on non-existent code (SwipeRepository from S-03) in Phase 1's backend steps — this has been resolved by clarifying that `hasSwiped` should be hardcoded to `false` with a TODO. With fixes applied, the plan is ready for implementation.

## Findings

### 🔴 Critical

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| — | — | None | N/A |

### 🟠 Major

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Technical Correctness | Phase 1 referenced injecting `SwipeRepository` and calling `existsByEmployeeId()` — but S-03 (which creates the swipe table/repository) isn't built. The Option A/B framing with pseudo-code would cause a compile error during implementation. | **Fixed** — rewritten to say "hardcode `false` with a TODO comment; wire the real query when S-03 lands." |

### 🟡 Minor

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Technical Correctness | Phase 2 references `frontend/src/types/profile.ts` which doesn't exist in the current codebase (it's created by S-02, the prerequisite). Could confuse an implementer. | **Fixed** — added "(created by S-02)" parenthetical. |
| 2 | Brief ↔ Plan | Brief stated "the only backend change is adding a `hasSwiped` flag to `ProfileResponse`" — technically `ProfileService` also needs a one-line change to populate the field. | **Fixed** — brief now mentions both `ProfileResponse` and `ProfileService`. |

### 🔵 Suggestions

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Feasibility | Phase 4 is entirely polish (transitions, chip counts, accessibility refinements) layered on top of FR-007 which is itself a nice-to-have. Under time pressure it's the first thing to cut. | **Fixed** — Phase 4 title now includes "(stretch — skippable under time pressure)" and the goal text clarifies Phases 1–3 fully deliver the feature. |

## Fixes Applied

1. **Phase 1 backend steps rewritten** (`plan.md` lines ~43–49): Removed the Option A/B framing and `swipeRepository.existsByEmployeeId()` pseudo-code. Replaced with clear instruction to hardcode `false` with a TODO comment, and a note on how to activate when S-03 lands.

2. **Phase 2 types reference clarified** (`plan.md` line ~75): Changed `Update frontend/src/types/profile.ts:` → `Update frontend/src/types/profile.ts (created by S-02):`.

3. **Brief backend-change description expanded** (`plan-brief.md` line ~7): Changed "adding a `hasSwiped` flag to `ProfileResponse` for conditional UI" → "adding a `hasSwiped` flag to `ProfileResponse` (and the corresponding `ProfileService` line to populate it)."

4. **Phase 4 marked as stretch** (`plan.md` line ~145): Title appended with "*(stretch — skippable under time pressure)*" and goal text updated.

5. **Plan status updated**: `draft` → `revised`.

## Verdict

**Status:** PASS WITH NOTES — implementable but watch the noted items

The plan is sound and ready for implementation. The one item to watch: when S-03 lands, remember to replace the hardcoded `hasSwiped = false` with the real SwipeRepository query — the TODO comment will serve as the reminder. Phase 4 is explicitly skippable if time runs short, which is the right call for a nice-to-have feature in a hackathon POC.

