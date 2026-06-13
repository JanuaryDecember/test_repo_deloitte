# /deloitter-implement-review — Review a completed implementation

## Usage

```
/deloitter-implement-review <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `persistence-and-seed`, `auth-login-gate`, `employee-login`, etc.).

## Purpose

Systematically review a completed implementation (`implementation-report.md` + actual code changes) in `context/changes/<change-id>/` against the plan, PRD guardrails, tech-stack conventions, and code quality standards. Classify each finding by severity, ask the user whether to fix or clarify, and persist the review results.

## Inputs (read before reviewing)

1. **The implementation report:** `context/changes/<change-id>/implementation-report.md`
2. **The plan:** `context/changes/<change-id>/plan.md` — the authoritative spec of what should have been built.
3. **The plan brief:** `context/changes/<change-id>/plan-brief.md`
4. **Plan review (if exists):** `context/changes/<change-id>/review/plan-review.md` — any warnings or notes from the plan review that implementation should have heeded.
5. **PRD:** `context/foundation/prd.md` — product requirements, guardrails, business logic.
6. **Roadmap:** `context/foundation/roadmap.md` — slice definition, outcome, prerequisites.
7. **Backend tech stack:** `backend/context/foundation/tech-stack.md`
8. **Frontend tech stack:** `frontend/context/foundation/tech-stack.md`
9. **Backend conventions:** `backend/AGENTS.md`
10. **Frontend conventions:** `frontend/AGENTS.md`
11. **Actual code:** read every file listed in the implementation report's "Files Created/Modified" section. This is the primary artifact under review.
12. **Existing reviews (if re-running):** `context/changes/<change-id>/review/implementation-review.md` — if it exists, this is a re-review; note delta from the previous review.

## Review Checklist

Evaluate the implementation against these dimensions:

### 1. Plan Faithfulness
- Does the implementation cover **every** `- [ ]` checklist item in the plan?
- Are file paths, class names, endpoint paths, and component names consistent with what the plan specified?
- Are there any undocumented deviations from the plan? Are documented deviations justified?
- Did the implementation stay within the plan's scope (no added features, no missing pieces)?

### 2. PRD & Guardrail Compliance
- Does the code respect the **no rejection signals** rule — is there any path that reveals a one-sided like or pass?
- Is the compatibility score **explainable** (proportional overlap logic, no randomness)?
- Is the score **hidden while swiping** and revealed only on a match?
- Does the implementation stay within the roadmap slice's scope (not building downstream features)?

### 3. Technical Correctness
- Does the code use correct framework/library APIs for the declared tech stack?
  - **Backend:** Spring Boot 4.1, Java 21, JPA/Hibernate, Flyway, Spring Security conventions.
  - **Frontend:** React 19 idioms, TypeScript strict mode, Vite conventions.
- Are there obvious bugs (null pointer risks, off-by-one errors, race conditions, incorrect SQL)?
- Are dependencies added to `pom.xml` / `package.json` correctly (scope, version)?
- Are Flyway migration filenames sequential and non-conflicting?
- Do tests actually assert the right things (not vacuous assertions, not just "it compiles")?

### 4. Convention Adherence
- Does the backend follow feature-grouped package structure (`backend/AGENTS.md`)?
- Does the frontend follow `src/api/` typed client conventions (`frontend/AGENTS.md`)?
- Is code properly formatted, no dead code, no commented-out blocks, no unresolved TODOs?
- Are imports clean (no unused imports, no wildcard imports in Java unless conventional)?

### 5. Verification Integrity
- Do the verification results in the implementation report match what the plan required?
- Are the `✅` results plausible given the code written (no "passed" steps that look unimplementable)?
- Did both `.\mvnw.cmd clean package` and `npm run build` pass cleanly?
- Were any failed verifications appropriately escalated or resolved?

### 6. Report Accuracy
- Does the "Files Created/Modified" list in the report match actual code changes?
- Are deviations and issues accurately described (not minimised or omitted)?
- Is the `result` field (`SUCCESS` / `PARTIAL` / `FAILED`) consistent with the actual outcomes reported?

### 7. Security & Data Hygiene (POC scope)
- No real credentials or PII hardcoded in source files.
- Seeded demo data is clearly fictional.
- No endpoints that inadvertently expose private match intent before mutual confirmation.

## Severity Classification

Each finding gets one of:

| Severity | Meaning | Action |
|----------|---------|--------|
| 🔴 **Critical** | Violates a PRD guardrail, introduces a security flaw, or leaves the feature fundamentally broken. | Must fix before the slice is considered done. |
| 🟠 **Major** | Significant gap vs. the plan, incorrect technical approach, or test coverage so thin the feature is unverifiable. | Should fix; ask user for confirmation. |
| 🟡 **Minor** | Convention violation, small inaccuracy, misleading report entry, or missing edge-case handling that won't break the happy path. | Suggest fix; user may defer. |
| 🔵 **Suggestion** | Improvement idea, refactoring opportunity, or best-practice recommendation — not a defect. | Optional; record for consideration. |

## Process

### Step 1: Pre-flight

1. Confirm `implementation-report.md` exists and has `result: SUCCESS | PARTIAL`. If missing, stop (see Failure modes).
2. Read all inputs listed above — plan, implementation report, and every file in "Files Created/Modified".
3. Build a list of phases from `plan.md` to review sequentially.

### Step 2: Review phase-by-phase

For each phase in the plan (Phase 1, Phase 2, …, Phase N), in order:

#### 2a. Check plan faithfulness for the phase
- Verify every `- [ ]` checklist item in the phase has a corresponding implementation in the listed files.
- Confirm file paths, class names, endpoint paths, and component names match the plan.
- Note any undocumented deviations.

#### 2b. Check technical correctness for the phase
- Read the actual code for files created/modified in this phase.
- Apply dimensions 3 (Technical Correctness), 4 (Convention Adherence), and 7 (Security & Data Hygiene) to the phase's code.

#### 2c. Check phase verification results
- Confirm the verification steps listed in the plan's `#### Verification` section for that phase are present in the implementation report.
- Assess whether the reported `✅` outcomes are plausible given the code (no "passed" steps that look unimplementable).
- Flag any phase whose verification was skipped, failed without resolution, or appears inconsistent with the code.

#### 2d. Collect findings for the phase
- Record all findings from 2a–2c, tagged with the phase number.
- **Present phase findings to the user immediately** (don't batch all phases before asking):
  - For 🔴 Critical or 🟠 Major: ask whether to fix, acknowledge, or override.
  - For 🟡 Minor and 🔵 Suggestion: present as a batch for the phase and ask whether to apply.
- Apply any approved fixes before moving to the next phase.

### Step 3: Review integration & smoke test

After all phases, review the `## Integration & Smoke Test` section:
- Were all integration checklist items executed and reported?
- Do the results align with the code (e.g., if a curl check is marked ✅, does the endpoint actually exist)?
- Were guardrail checks performed (if the slice touches privacy/scoring)?

### Step 4: Review deployability results

Check the final deployability section of the implementation report:
- Did `.\mvnw.cmd clean package` pass? Does this match the code (no obvious compile errors in review)?
- Did `npm run build` pass? Does this match the TypeScript/component code?

### Step 5: Full cross-cutting review

After the phase-by-phase pass, evaluate the remaining dimensions holistically:
- **Dimension 6 (Report Accuracy):** Is the report's overall `result` consistent with the phase outcomes?
- **Plan review cross-reference:** If `review/plan-review.md` exists, confirm every flagged concern was addressed.
- Collect any cross-cutting findings and present them to the user.

### Step 6: Write the review report

Save to `context/changes/<change-id>/review/implementation-review.md` (template in Output section below).

## Output

Create (or overwrite) `context/changes/<change-id>/review/implementation-review.md`:

```markdown
---
change_id: "<change-id>"
reviewed: <today YYYY-MM-DD>
implementation_result_before: <SUCCESS | PARTIAL | FAILED>
implementation_result_after: <SUCCESS | PARTIAL | FAILED>
findings_total: <N>
critical: <N>
major: <N>
minor: <N>
suggestions: <N>
fixes_applied: <N>
---

# Implementation Review: <Outcome title>

## Summary

<2-3 sentence overview: is the implementation correct and complete? What's the main concern, if any?>

## Phase-by-Phase Results

| # | Phase | Plan Faithfulness | Verification Results | Findings | Status |
|---|-------|-------------------|----------------------|----------|--------|
| 1 | <name> | ✅ / ⚠️ / ❌ | ✅ / ⚠️ / ❌ | <count or "none"> | ✅ Pass / ⚠️ Partial / ❌ Fail |
| 2 | <name> | ✅ / ⚠️ / ❌ | ✅ / ⚠️ / ❌ | <count or "none"> | ✅ / ⚠️ / ❌ |
| ... | ... | ... | ... | ... | ... |

## Findings

### 🔴 Critical

| # | Phase | Dimension | File / Location | Finding | Resolution |
|---|-------|-----------|-----------------|---------|------------|
| 1 | <Ph N or "Integration"> | <dimension> | <file:line or "N/A"> | <description of the issue> | <fixed / acknowledged / overridden by user / N/A> |

### 🟠 Major

| # | Phase | Dimension | File / Location | Finding | Resolution |
|---|-------|-----------|-----------------|---------|------------|
| 1 | <Ph N or "Integration"> | <dimension> | <file:line or "N/A"> | <description> | <resolution> |

### 🟡 Minor

| # | Phase | Dimension | File / Location | Finding | Resolution |
|---|-------|-----------|-----------------|---------|------------|
| 1 | <Ph N or "Integration"> | <dimension> | <file:line or "N/A"> | <description> | <resolution> |

### 🔵 Suggestions

| # | Phase | Dimension | File / Location | Finding | Resolution |
|---|-------|-----------|-----------------|---------|------------|
| 1 | <Ph N or "Integration"> | <dimension> | <file:line or "N/A"> | <description> | <resolution> |

## Fixes Applied

<List of changes made to source files and/or implementation-report.md, if any. Quote the before/after or describe the edit.>

## Guardrail Compliance

| Guardrail | Status | Evidence |
|-----------|--------|----------|
| No rejection signals | ✅ / ❌ / ⚠️ | <pointer to relevant code or "N/A for this slice"> |
| Explainable score | ✅ / ❌ / ⚠️ / N/A | <pointer to scoring logic or "N/A"> |
| Score hidden while swiping | ✅ / ❌ / ⚠️ / N/A | <pointer to relevant code or "N/A"> |

## Verdict

**Status:** <PASS — implementation is correct and complete | PASS WITH NOTES — functional but watch the noted items | REWORK — must fix critical/major issues before the slice is done>

<Brief justification for the verdict.>
```

## Rules

1. **Review phase-by-phase, not all at once.** Mirror the implement skill's phase-by-phase discipline — review each phase's code and verification results before moving to the next. Present findings per phase so the user can approve fixes incrementally. Don't batch everything to the end.

2. **Read the code, don't just read the report.** The implementation report is self-reported — verify its claims against the actual source files.

2. **Respect the "hackathon POC" context.** Don't flag acceptable POC shortcuts (e.g., hardcoded demo passwords, simplified error handling, in-memory state) as defects unless they violate guardrails or break functionality.

3. **Don't invent requirements.** Only flag missing things if they're explicitly in the plan, PRD, or tech-stack docs. Don't add scope.

4. **Ask before fixing.** Never silently change code — always present findings and get user confirmation before editing source files.

5. **Update implementation report status.** If fixes are applied, update the `result` field in `implementation-report.md`. If the verdict is PASS or PASS WITH NOTES and no critical/major issues remain, add a note that the slice has been reviewed.

6. **Idempotent re-runs.** If `review/implementation-review.md` already exists, treat this as a re-review. Note which previous findings are resolved and which persist.

7. **Cross-reference the plan review.** If `review/plan-review.md` exists, check that any warnings it flagged were addressed during implementation. Flag as 🟠 Major if a known plan-review concern was ignored.

## Example invocation

```
/deloitter-implement-review persistence-and-seed
```

Reads `context/changes/persistence-and-seed/implementation-report.md`, reads every file listed in it, reviews against `plan.md` and PRD guardrails, asks the user about findings, applies approved fixes, and writes:
- `context/changes/persistence-and-seed/review/implementation-review.md`

## Failure modes

| Situation | Action |
|-----------|--------|
| `implementation-report.md` does not exist | Stop — implementation hasn't been run yet. Suggest running `/deloitter-implement <change-id>` first. |
| Report lists files that don't exist in the codebase | Flag as 🔴 Critical — the implementation is incomplete or the report is wrong. |
| All verifications in the report are `✅` but code has obvious bugs | Flag as 🟠 Major — verifications may have been recorded incorrectly. |
| A guardrail violation is found in code | Flag as 🔴 Critical — must fix before the slice is done, regardless of user preference. |
| Re-review with no new findings vs. last review | State "no new findings since last review" and confirm the previous verdict still holds. |





