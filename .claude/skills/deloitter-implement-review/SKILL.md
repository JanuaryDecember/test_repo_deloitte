# /deloitter-implement-review — Review a completed implementation

## Usage

```
/deloitter-implement-review <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `persistence-and-seed`, `auth-login-gate`, `employee-login`, etc.).

## Purpose

Systematically review a completed implementation (actual code in the repo) against the plan, PRD guardrails, tech-stack conventions, and code quality standards. Classify each finding by severity, ask the user whether to fix or clarify, and present all results **inline as a diff** — no report file is written.

## Inputs (read before reviewing)

1. **The plan:** `context/changes/<change-id>/plan.md` — the authoritative spec of what should have been built.
2. **The plan brief:** `context/changes/<change-id>/plan-brief.md`
3. **Plan review (if exists):** `context/changes/<change-id>/review/plan-review.md` — any warnings or notes from the plan review that implementation should have heeded.
4. **PRD:** `context/foundation/prd.md` — product requirements, guardrails, business logic.
5. **Roadmap:** `context/foundation/roadmap.md` — slice definition, outcome, prerequisites.
6. **Backend tech stack:** `backend/context/foundation/tech-stack.md`
7. **Frontend tech stack:** `frontend/context/foundation/tech-stack.md`
8. **Backend conventions:** `backend/AGENTS.md`
9. **Frontend conventions:** `frontend/AGENTS.md`
10. **Actual code:** discovered via `git diff` (see Pre-flight). Read every file that was added or modified as part of this change. This is the primary artifact under review.

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

### 5. Coverage Completeness
- Does every `- [ ]` checklist item in the plan have a corresponding file/class/method in the codebase?
- Are there plan-specified files that simply don't exist yet?
- Are there plan-specified test cases that are missing or stubbed out?

### 6. Security & Data Hygiene (POC scope)
- No real credentials or PII hardcoded in source files.
- Seeded demo data is clearly fictional.
- No endpoints that inadvertently expose private match intent before mutual confirmation.

## Severity Classification

Each finding gets one of:

| Severity | Meaning | Action |
|----------|---------|--------|
| 🔴 **Critical** | Violates a PRD guardrail, introduces a security flaw, or leaves the feature fundamentally broken. | Must fix before the slice is considered done. |
| 🟠 **Major** | Significant gap vs. the plan, incorrect technical approach, or test coverage so thin the feature is unverifiable. | Should fix; ask user for confirmation. |
| 🟡 **Minor** | Convention violation, small inaccuracy, or missing edge-case handling that won't break the happy path. | Suggest fix; user may defer. |
| 🔵 **Suggestion** | Improvement idea, refactoring opportunity, or best-practice recommendation — not a defect. | Optional; record for consideration. |

## Process

### Step 1: Pre-flight

1. **Discover changed files** by running `git diff --name-only HEAD~1 HEAD` (or `git diff --name-only <base>` if the user specifies a base commit). If git history is unavailable, ask the user which files were added/modified.
2. **Check plan status.** Read `plan.md` frontmatter — `status` should be `implemented`. If it is still `revised` or `approved`, warn the user that the plan may not have been implemented yet and ask whether to proceed.
3. **Read all inputs** — plan, plan review (if exists), and every changed file discovered in step 1.
4. **Build a list of phases** from `plan.md` to review sequentially.

### Step 2: Review phase-by-phase

For each phase in the plan (Phase 1, Phase 2, …, Phase N), in order:

#### 2a. Check plan faithfulness for the phase
- Verify every `- [ ]` checklist item in the phase has a corresponding implementation in the changed files.
- Confirm file paths, class names, endpoint paths, and component names match the plan.
- Note any undocumented deviations.

#### 2b. Check technical correctness for the phase
- Read the actual code for files created/modified in this phase.
- Apply dimensions 3 (Technical Correctness), 4 (Convention Adherence), and 6 (Security & Data Hygiene) to the phase's code.

#### 2c. Check coverage completeness for the phase
- Cross-reference the plan's `#### Verification` section for this phase against the actual code.
- Confirm that any files, classes, or tests the plan required to exist do in fact exist.
- Flag anything the plan specified that is absent from the codebase.

#### 2d. Collect findings for the phase
- Record all findings from 2a–2c, tagged with the phase number.
- **Present phase findings to the user immediately** (don't batch all phases before asking):
  - For 🔴 Critical or 🟠 Major: ask whether to fix, acknowledge, or override.
  - For 🟡 Minor and 🔵 Suggestion: present as a batch for the phase and ask whether to apply.
- For any approved fix, **show the change as a unified diff** (`--- before` / `+++ after` format) before applying it to the file.
- Apply any approved fixes before moving to the next phase.

#### 2e. Write phase summary
After findings are resolved (fixes applied or declined), save a summary to:
`context/changes/<change-id>/review/impl-review-phase-<N>.md`

Use this template:

```markdown
---
change_id: "<change-id>"
phase: <N>
phase_name: "<phase name>"
reviewed: <today YYYY-MM-DD>
verdict: PASS | PASS WITH NOTES | REWORK
findings_total: <N>
critical: <N>
major: <N>
minor: <N>
suggestions: <N>
fixes_applied: <N>
---

# Phase <N> Review: <phase name>

## Summary
<2-3 sentences>

## Plan Faithfulness
| Checklist item | Status |
|---|---|
| <item> | ✅ / ❌ / ⚠️ |

## Findings

### 🔴 Critical / 🟠 Major / 🟡 Minor / 🔵 Suggestions
(omit empty tiers)

| # | Dimension | File / Location | Finding | Resolution |
|---|-----------|-----------------|---------|------------|

## Guardrail Compliance
| Guardrail | Status | Evidence |
|-----------|--------|----------|
| No rejection signals      | ✅/❌/⚠️/N/A | ... |
| Explainable score         | ✅/❌/⚠️/N/A | ... |
| Score hidden while swiping| ✅/❌/⚠️/N/A | ... |

## Verdict
**<PASS | PASS WITH NOTES | REWORK>** — <brief justification>
```

### Step 3: Integration & smoke test coverage

After all phases, check the plan's `## Integration & Smoke Test` section:
- Does the code support every integration check listed (i.e., do the required endpoints, components, and DB state exist)?
- Were guardrail-relevant paths implemented correctly (if the slice touches privacy/scoring)?

### Step 4: Run deployability check

Run a quick deployability check against the changed tiers:

**Backend (if backend files changed):**
```bash
cd backend && ./mvnw clean package -q
```

**Frontend (if frontend files changed):**
```bash
cd frontend && npm run build
```

Report the results inline. If either fails, flag as 🔴 Critical and diagnose the error.

### Step 5: Full cross-cutting review

After the phase-by-phase pass, evaluate holistically:
- **Plan review cross-reference:** If `review/plan-review.md` exists, confirm every flagged concern was addressed in the code.
- Collect any cross-cutting findings and present them to the user.

### Step 6: Present final verdict inline

After all phases are reviewed, output the verdict **directly in the conversation**. Per-phase summaries have already been written to `context/changes/<change-id>/review/impl-review-phase-<N>.md` during Step 2e. Use this structure for the overall inline verdict:

```
## Review: <change-id> — <Outcome title>

### Summary
<2-3 sentence overview>

### Phase-by-Phase Results
| # | Phase | Plan Faithfulness | Coverage | Findings | Status |
|---|-------|-------------------|----------|----------|--------|
| 1 | ...   | ✅/⚠️/❌          | ✅/⚠️/❌ | N        | ✅/⚠️/❌ |

### Findings
(tables per severity — omit empty severity tiers)

### Guardrail Compliance
| Guardrail | Status | Evidence |
|-----------|--------|----------|
| No rejection signals      | ✅/❌/⚠️ | ... |
| Explainable score         | ✅/❌/⚠️/N/A | ... |
| Score hidden while swiping| ✅/❌/⚠️/N/A | ... |

### Deployability
| Tier | Command | Result |
|------|---------|--------|
| Backend  | `./mvnw clean package` | ✅/❌ |
| Frontend | `npm run build`        | ✅/❌ |

### Verdict
**Status:** PASS | PASS WITH NOTES | REWORK
<Brief justification>
```

For every fix that was applied, include a `### Fixes Applied` section listing each change as a unified diff:

```diff
--- a/path/to/file
+++ b/path/to/file
@@ -10,6 +10,7 @@
 unchanged context
-removed line
+added line
 unchanged context
```

## Rules

1. **Review phase-by-phase, not all at once.** Review each phase's code before moving to the next. Present findings per phase so the user can approve fixes incrementally.

2. **Read the code directly.** The source of truth is the actual files in the repo — not any external report. Use `git diff` to discover what changed; read each changed file fully.

3. **Respect the "hackathon POC" context.** Don't flag acceptable POC shortcuts (e.g., hardcoded demo passwords, simplified error handling, in-memory state) as defects unless they violate guardrails or break functionality.

4. **Don't invent requirements.** Only flag missing things if they're explicitly in the plan, PRD, or tech-stack docs. Don't add scope.

5. **Ask before fixing.** Never silently change code — always present the diff and get user confirmation before applying it to source files.

6. **Per-phase summaries only.** Write `context/changes/<change-id>/review/impl-review-phase-<N>.md` after each phase (Step 2e). Do not write any other files — the overall verdict is presented inline in the conversation.

7. **Cross-reference the plan review.** If `review/plan-review.md` exists, check that any warnings it flagged were addressed during implementation. Flag as 🟠 Major if a known plan-review concern was ignored.

## Example invocation

```
/deloitter-implement-review persistence-and-seed
```

Runs `git diff` to discover changed files, reads `context/changes/persistence-and-seed/plan.md` and all changed source files, reviews against the plan and PRD guardrails, asks the user about findings, shows approved fixes as diffs, runs deployability checks, writes a summary to `context/changes/persistence-and-seed/review/impl-review-phase-<N>.md` after each phase, and presents the final verdict inline in the conversation.

## Failure modes

| Situation | Action |
|-----------|--------|
| `plan.md` does not exist | Stop — there is no spec to review against. |
| `plan.md` status is not `implemented` | Warn — implementation may be incomplete. Ask whether to proceed. |
| `git diff` is unavailable and user can't list changed files | Ask the user to provide the list of files added/modified for this change. |
| A plan-specified file is absent from the codebase | Flag as 🟠 Major — the implementation is incomplete. |
| A guardrail violation is found in code | Flag as 🔴 Critical — must fix before the slice is done, regardless of user preference. |
| Deployability check fails | Flag as 🔴 Critical — diagnose and present fix as a diff. |
