> **Archived:** 2026-06-13 00:00 | Change ID: `select-interests` | Roadmap ID: `S-02`

---

change_id: "select-interests"
reviewed: 2026-06-13
plan_status_before: draft
plan_status_after: revised
findings_total: 5
critical: 0
major: 0
minor: 3
suggestions: 2
fixes_applied: 5

---

# Plan Review: Select interests & competencies

## Summary

The plan is well-structured, comprehensive, and solidly aligned with the PRD (FR-002), roadmap (S-02), and tech stack conventions. It respects all hard guardrails (no rejection signals, no score exposure, privacy enforcement) and closely follows the design comp. No critical or major issues were found — only minor clarity gaps in the controller/service layering and missing specification details, plus two optional improvements that the user elected to apply.

## Findings

### 🔴 Critical

_None._

### 🟠 Major

_None._

### 🟡 Minor

| #   | Dimension             | Finding                                                                                                                                                                                                                                                                            | Resolution                                                                                                                                                                                         |
| --- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Technical Correctness | **Controller vs. Service injection ambiguity.** Phase 1's `ProfileController` bullet said "Inject `EmployeeRepository`, `InterestRepository`, `CompetencyRepository`" but the same phase creates a `ProfileService`. An implementer wouldn't know which layer owns the repo calls. | **Fixed** — controller now injects `ProfileService` only; service owns repository access.                                                                                                          |
| 2   | Completeness          | **`initials` field computation unspecified.** `ProfileResponse` included `initials` but never defined how to derive it.                                                                                                                                                            | **Fixed** — added `Character.toUpperCase(firstName.charAt(0)) + "" + Character.toUpperCase(lastName.charAt(0))` in both the ProfileResponse record and the ProfileController endpoint description. |
| 3   | Completeness          | **`CatalogController` dependencies not stated.** Unlike `ProfileController`, `CatalogController` didn't list what it injects.                                                                                                                                                      | **Fixed** — added "Inject `InterestRepository` and `CompetencyRepository` (simple read-only endpoint — no service layer needed)".                                                                  |

### 🔵 Suggestions

| #   | Dimension             | Finding                                                                                                                                                                | Resolution                                                                                                                               |
| --- | --------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| 1   | Technical Correctness | **Feature folder diverges from AGENTS.md example.** AGENTS.md suggests `interests/` but the plan uses `catalog/` and `profile/`. Defensible, but undocumented.         | **Fixed** — added Decision #11 explicitly noting the naming choice and rationale.                                                        |
| 2   | Completeness          | **No automated tests planned.** No unit or integration test code in any phase; backend has `spring-boot-starter-webmvc-test` available. Acceptable for POC speed goal. | **Fixed** — added Decision #12 explicitly acknowledging this as a deliberate speed-goal tradeoff with an optional note for implementers. |

## Fixes Applied

1. **ProfileController injection** (Phase 1, bullet 4): Changed "Inject `EmployeeRepository`, `InterestRepository`, `CompetencyRepository`" → "Inject `ProfileService` (the controller delegates all logic to the service)". Also updated the sub-bullet to say "Resolves employee … via `ProfileService`".
2. **`initials` computation** (Phase 1, ProfileResponse bullet + ProfileController bullet): Added explicit derivation formula: `Character.toUpperCase(firstName.charAt(0)) + "" + Character.toUpperCase(lastName.charAt(0))`.
3. **CatalogController dependencies** (Phase 1, bullet 1): Added "Inject `InterestRepository` and `CompetencyRepository` (simple read-only endpoint — no service layer needed)".
4. **Decision #11 added**: Documents `catalog/` + `profile/` package naming choice vs. AGENTS.md's `interests/` suggestion, with rationale.
5. **Decision #12 added**: Documents the deliberate omission of automated tests under the speed goal, noting the option for implementers.
6. **Status field** updated from `draft` → `revised`.

## Verdict

**Status:** PASS WITH NOTES — ready for implementation.

The plan is comprehensive and correctly scoped. The minor fixes applied improve implementation clarity but none were blocking. Watch items during implementation:

- Ensure the `ProfileService` layer is actually used by the controller (don't short-circuit to repos).
- The `initials` derivation assumes non-empty first/last names — reasonable for seeded data but add a null guard if paranoid.
- If time allows, a quick `@WebMvcTest` for `CatalogController` and `ProfileController` would validate the endpoint contract cheaply.
