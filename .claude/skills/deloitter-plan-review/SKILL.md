# /deloitter-plan-review — Review a generated implementation plan

## Usage

```
/deloitter-plan-review <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `persistence-and-seed`, `auth-login-gate`, etc.).

## Purpose

Systematically review a generated plan (`plan.md` + `plan-brief.md`) in `context/changes/<change-id>/` for correctness, completeness, consistency, and alignment with the PRD, roadmap, and tech-stack conventions. Classify each finding by severity, ask the user whether to fix or clarify, and persist the review results.

## Inputs (read before reviewing)

1. **The plan itself:**
   - `context/changes/<change-id>/plan.md`
   - `context/changes/<change-id>/plan-brief.md`
2. **PRD:** `context/foundation/prd.md` — product requirements, guardrails, business logic.
3. **Roadmap:** `context/foundation/roadmap.md` — slice definition, prerequisites, outcome, PRD refs.
4. **Backend tech stack:** `backend/context/foundation/tech-stack.md`
5. **Frontend tech stack:** `frontend/context/foundation/tech-stack.md`
6. **Backend conventions:** `backend/AGENTS.md`
7. **Frontend conventions:** `frontend/AGENTS.md`
8. **Existing code:** scan `backend/src/` and `frontend/src/` for current state (what exists that the plan should reference or build on).
9. **Existing reviews (if re-running):** `context/changes/<change-id>/review/plan-review.md` — if it exists, this is a re-review; note delta from the previous review.

## Review Checklist

Evaluate the plan against these dimensions:

### 1. PRD Alignment
- Does the plan cover all PRD refs listed in the roadmap slice?
- Does it violate any **hard guardrails** (no rejection signals, explainable score, score hidden while swiping)?
- Does it stay within scope (not building downstream slices)?
- Does it respect Non-Goals?

### 2. Roadmap Consistency
- Does the plan's `roadmap_id`, `change_id`, `prerequisites`, and `prd_refs` match the roadmap?
- Does the plan assume prerequisites are met? Does it correctly identify what's not yet built?
- Does it deliver the stated Outcome?

### 3. Technical Correctness
- Do the steps use the correct framework/library APIs for the declared tech stack?
- Are file paths and package names consistent with project conventions (`backend/AGENTS.md`, `frontend/AGENTS.md`)?
- Are there missing steps (e.g., forgotten imports, missing config, undeclared dependencies)?
- Are migration versions sequential and non-conflicting?
- Are test strategies sound (correct test scope, realistic assertions)?

### 4. Completeness
- Is every phase independently verifiable?
- Are verification steps concrete and actionable?
- Does the Integration & Smoke Test section cover end-to-end?
- Are all decisions/assumptions documented?
- Are open questions reasonable (not blocking issues disguised as questions)?

### 5. Brief ↔ Plan Consistency
- Does `plan-brief.md` accurately summarize `plan.md`?
- Are phase counts, key decisions, and risks consistent between the two files?

### 6. Feasibility & Risk
- Are there steps that are unrealistic given the tech stack or time budget?
- Are risks identified in the roadmap slice addressed in the plan?
- Are there new risks the plan introduces but doesn't acknowledge?

## Severity Classification

Each finding gets one of:

| Severity | Meaning | Action |
|----------|---------|--------|
| 🔴 **Critical** | Violates a PRD guardrail, breaks a hard constraint, or makes the plan unimplementable. | Must fix before implementation. |
| 🟠 **Major** | Significant gap, incorrect technical approach, or missing phase/step that would cause rework. | Should fix; ask user for confirmation. |
| 🟡 **Minor** | Small inaccuracy, style issue, missing detail that won't block implementation but reduces clarity. | Suggest fix; user may defer. |
| 🔵 **Suggestion** | Improvement idea, optimization, or best-practice recommendation — not a defect. | Optional; record for consideration. |

## Process

1. **Read all inputs** listed above.
2. **Run the review checklist** — evaluate each dimension, noting findings.
3. **Classify each finding** by severity.
4. **Present findings to the user** — for each 🔴 Critical or 🟠 Major finding, ask the user:
   - "Should I fix this in the plan?" (provide the proposed fix)
   - "Should I leave it as-is with a note?" (user clarifies intent)
   - "Is this actually correct and I'm wrong?" (user overrides)
5. **For 🟡 Minor and 🔵 Suggestion findings** — present them as a batch and ask: "Should I apply these minor fixes, or leave them as-is?"
6. **Apply fixes** — for any finding the user approves fixing:
   - Edit `context/changes/<change-id>/plan.md` and/or `context/changes/<change-id>/plan-brief.md` accordingly.
   - Keep edits minimal and surgical — don't rewrite sections that aren't broken.
7. **Write the review report** — save to `context/changes/<change-id>/review/plan-review.md`.

## Output

Create (or overwrite) `context/changes/<change-id>/review/plan-review.md`:

```markdown
---
change_id: "<change-id>"
reviewed: <today YYYY-MM-DD>
plan_status_before: <draft|revised|approved>
plan_status_after: <draft|revised|approved>
findings_total: <N>
critical: <N>
major: <N>
minor: <N>
suggestions: <N>
fixes_applied: <N>
---

# Plan Review: <Outcome title>

## Summary

<2-3 sentence overview: is the plan ready for implementation? What's the main concern?>

## Findings

### 🔴 Critical

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | <dimension> | <description of the issue> | <fixed / acknowledged / overridden by user / N/A> |

### 🟠 Major

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | <dimension> | <description> | <resolution> |

### 🟡 Minor

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | <dimension> | <description> | <resolution> |

### 🔵 Suggestions

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | <dimension> | <description> | <resolution> |

## Fixes Applied

<List of changes made to plan.md and/or plan-brief.md, if any. Quote the before/after or describe the edit.>

## Verdict

**Status:** <PASS — ready for implementation | PASS WITH NOTES — implementable but watch the noted items | REVISE — needs another round of fixes before implementation>

<Brief justification for the verdict.>
```

## Rules

1. **Be thorough but not pedantic.** Focus on findings that would cause real implementation problems or guardrail violations. Don't nitpick formatting unless it creates ambiguity.

2. **Respect the "hackathon POC" context.** The project optimizes for speed. Don't flag things as issues that are acceptable shortcuts for a POC (e.g., hardcoded demo passwords, no prod-grade error handling).

3. **Don't invent requirements.** Only flag missing things if they're explicitly in the PRD, roadmap, or tech-stack docs. Don't add scope.

4. **Ask before fixing.** Never silently change the plan — always present findings and get user confirmation before editing `plan.md` or `plan-brief.md`.

5. **Update plan status.** If fixes are applied, update the `status` field in `plan.md` frontmatter from `draft` to `revised`. If the user approves the plan as-is (no critical/major findings or all resolved), recommend setting status to `approved`.

6. **Idempotent re-runs.** If `review/plan-review.md` already exists, treat this as a re-review. Note which previous findings are resolved and which persist.

## Example invocation

```
/10x-plan-review persistence-and-seed
```

Reads the plan at `context/changes/persistence-and-seed/`, reviews it, asks the user about findings, applies approved fixes, and writes:
- `context/changes/persistence-and-seed/review/plan-review.md`

