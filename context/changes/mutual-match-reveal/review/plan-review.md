---
change_id: "mutual-match-reveal"
reviewed: 2026-06-13
plan_status_before: draft
plan_status_after: revised
findings_total: 6
critical: 0
major: 0
minor: 3
suggestions: 3
fixes_applied: 3
---

# Plan Review: Mutual match reveal

## Summary

The plan is solid and implementation-ready. It correctly covers all PRD refs (FR-005, FR-006, Privacy NFR), enforces all three hard guardrails at the API level, and stays within scope. No critical or major issues were found. Three minor fixes were applied: renaming the `match` table to `employee_match` (SQL reserved word + naming consistency), replacing an unintuitive repository method with a `@Query`-annotated alternative, and adding an explicit idempotency guard to the match detection flow.

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
| 1 | Technical Correctness | Table name `match` is a SQL reserved keyword in many dialects. While PostgreSQL classifies it as non-reserved, it's unconventional and inconsistent with the existing `employee_swipe` naming pattern. | **Fixed** — renamed to `employee_match` throughout plan.md and plan-brief.md (migration, entity annotation, decisions, verification steps, open questions). |
| 2 | Technical Correctness | `MatchRepository.findByEmployee1IdOrEmployee2Id(Long emp1, Long emp2)` requires passing the same ID for both params — unintuitive API that's easy to misuse. | **Fixed** — replaced with `@Query("SELECT m FROM Match m WHERE m.employee1Id = :id OR m.employee2Id = :id") List<Match> findByEmployeeId(@Param("id") Long id)`. |
| 3 | Completeness | `detectAndCreateMatch()` step-by-step didn't include the idempotency guard mentioned in Open Question 3. The code path jumped from "reverse swipe exists → compute score → persist" without handling the race condition or existing match. | **Fixed** — added step 4 (pre-check via `existsByEmployee1IdAndEmployee2Id`) and updated step 5 to wrap `save()` in try/catch for `DataIntegrityViolationException` as a backstop. |

### 🔵 Suggestions

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Technical Correctness | Bidirectional coupling between `swipe/` and `match/` packages: MatchService injects SwipeRepository (in `swipe/`) while DiscoverService injects MatchService (in `match/`). This creates a tight package-level cycle. | Acknowledged — acceptable for POC speed. Alternative (moving match detection into DiscoverService) trades coupling for a bloated swipe service. Left as-is. |
| 2 | Brief ↔ Plan Consistency | Brief says "4 seeded mutual likes" but Phase 3 actually seeds 4 incoming likes PLUS 1 outgoing like (Alice → Frank) for no-match testing. | Acknowledged — the brief's summary is imprecise but not misleading. Left as-is. |
| 3 | Feasibility & Risk | Phase 5 has extremely detailed CSS values from the design comp. Implementer should treat these as reference targets — slight deviations acceptable for POC speed as long as layout and feel match. | Acknowledged — the plan's detail is helpful rather than harmful; implementer can deviate where needed. Left as-is. |

## Fixes Applied

1. **Table rename `match` → `employee_match`:** Updated migration filename (`V7__create_employee_match_table.sql`), DDL (`CREATE TABLE employee_match`), index names (`ON employee_match(...)`), entity annotation (`@Table(name = "employee_match")`), Decision #2 rationale, Phase 1 goal/verification, Open Question 3, and plan-brief references.

2. **Repository method rename:** Changed `findByEmployee1IdOrEmployee2Id(Long emp1, Long emp2)` to `@Query`-annotated `findByEmployeeId(@Param("id") Long id)`. Updated the `getMatches()` call site to use the new method name.

3. **Idempotency guard in `detectAndCreateMatch()`:** Added step 4 (pre-check `existsByEmployee1IdAndEmployee2Id(min, max)`) and updated step 5 to wrap `save()` in try/catch for `DataIntegrityViolationException`, returning the existing match on conflict. Updated plan-brief risk table to reference the explicit exception type.

## Verdict

**Status:** PASS WITH NOTES — implementable but watch the noted items

The plan is ready for implementation. The three minor fixes make it more robust and idiomatic. The three suggestions (bidirectional coupling, brief precision, CSS exactness) are acceptable trade-offs for POC speed and don't require changes. The privacy guardrail enforcement is thorough and correct. The implementer should note the package coupling between `swipe/` and `match/` (Suggestion #1) but need not refactor it.

