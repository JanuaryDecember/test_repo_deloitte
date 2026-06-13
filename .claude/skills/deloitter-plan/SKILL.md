# /deloitter-plan — Generate implementation plan for a roadmap slice

## Usage

```
/deloitter-plan <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `persistence-and-seed`, `auth-login-gate`, `employee-login`, etc.).

## Inputs (read before generating)

1. **PRD:** `context/foundation/prd.md` — product requirements, functional requirements, guardrails, business logic.
2. **Roadmap:** `context/foundation/roadmap.md` — find the slice matching `<change-id>`, its outcome, prerequisites, PRD refs, risks, unknowns.
3. **Backend tech stack:** `backend/context/foundation/tech-stack.md` — Spring Boot 4.1 / Java 21 / Maven.
4. **Frontend tech stack:** `frontend/context/foundation/tech-stack.md` — Vite 8 + React 19 + TypeScript.
5. **Backend conventions:** `backend/AGENTS.md` — layout, commands, tier-specific rules.
6. **Frontend conventions:** `frontend/AGENTS.md` — layout, commands, tier-specific rules.
7. **Existing code:** scan `backend/src/` and `frontend/src/` to understand the current baseline — what already exists that the plan can build on.

## Output

Create the directory `context/changes/<change-id>/` and produce two files:

### 1. `context/changes/<change-id>/plan.md` (detailed plan)

Structure:

```markdown
---
change_id: "<change-id>"
roadmap_id: "<F-xx or S-xx>"
status: draft
created: <today YYYY-MM-DD>
prd_refs: [list from roadmap]
prerequisites: [list from roadmap]
---

# Plan: <Outcome title from roadmap>

## Context

<Brief paragraph: what this change delivers, why it's sequenced here, what it unlocks.>

## Decisions & Assumptions

<List any architectural/technology decisions made or assumed. If a decision was asked to the user during generation, record the answer here.>

## Phases

### Phase 1: <Name>

**Goal:** <one sentence>

#### Backend

- [ ] <step description — file path hint + what to create/modify>
- [ ] <step>
- [ ] ...

#### Frontend

- [ ] <step description>
- [ ] ...

#### Verification

- [ ] <how to verify this phase works — test command, manual check, etc.>

---

### Phase 2: <Name>

... (same structure)

---

### Phase N: <Name>

...

---

## Integration & Smoke Test

- [ ] <end-to-end verification that the full change works>
- [ ] <guardrail checks if applicable>

## Open Questions

<Any remaining unknowns or decisions deferred to implementation time.>
```

### 2. `context/changes/<change-id>/plan-brief.md` (executive summary)

Structure:

```markdown
# Plan Brief: <Outcome title>

**Change ID:** `<change-id>` | **Roadmap ID:** `<F-xx / S-xx>` | **Status:** draft

## What

<2-3 sentence summary of what gets built.>

## Phases at a glance

| # | Phase | Backend | Frontend | Key deliverable |
|---|-------|---------|----------|-----------------|
| 1 | ...   | ✓/—     | ✓/—      | ...             |
| 2 | ...   | ✓/—     | ✓/—      | ...             |

## Key decisions

- <bullet list of architectural choices made>

## Risks & mitigations

- <from roadmap + any new ones identified during planning>

## Estimated effort

<Relative size: S / M / L — with brief justification.>
```

## Generation rules

1. **Divide into phases.** Each phase should be independently verifiable. Order phases so earlier ones unblock later ones. Typical breakdown:
   - Phase 1: data model / schema / entities
   - Phase 2: backend API endpoints
   - Phase 3: frontend UI components + API integration
   - Phase 4: wiring, polish, edge cases
   Adjust as needed — some slices are backend-only, frontend-only, or need different phasing.

2. **Steps have checkboxes.** Use `- [ ]` for every actionable step. Steps should be concrete: mention file paths, class names, endpoint paths, component names.

3. **Respect the tech stacks.** Backend steps use Spring Boot / Java 21 / Maven conventions. Frontend steps use Vite / React 19 / TypeScript conventions. Reference patterns from the respective `AGENTS.md` files.

4. **Respect guardrails.** If the slice touches privacy (no rejection signals), scoring (explainable), or responsiveness (< 300ms), call out guardrail-specific steps and verification.

5. **Ask questions for decisions.** When generating the plan, if you encounter an architectural or technology choice that has multiple valid paths (e.g., "use JPA vs. raw JDBC?", "use React Router vs. TanStack Router?", "session cookie vs. JWT?"), **stop and ask the user** before proceeding. Frame the question with:
   - The decision point
   - 2-3 options with brief trade-offs
   - Your recommendation given the project constraints (hackathon POC, speed goal, small team)
   
   Record all decisions in the "Decisions & Assumptions" section of `plan.md`.

6. **Check prerequisites.** If the slice's prerequisites are not yet implemented (check `context/changes/` for completed plans and the codebase for evidence), note this in the plan's Context section — the plan assumes prerequisites are done.

7. **Keep scope tight.** Only plan what's in the roadmap slice's Outcome and PRD refs. Don't scope-creep into downstream slices. If the current slice is a foundation (F-xx), it should NOT include UI beyond what's needed for verification.

8. **Seed data awareness.** If the slice needs seeded data to verify (most do), include a step for test/seed data — either extending existing seeds or creating temporary test fixtures.

## Example invocation

```
/10x-plan persistence-and-seed
```

Produces:
- `context/changes/persistence-and-seed/plan.md`
- `context/changes/persistence-and-seed/plan-brief.md`

