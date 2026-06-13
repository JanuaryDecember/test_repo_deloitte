# /deloitter-implement — Implement a plan and verify deployability

## Usage

```
/deloitter-implement <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `persistence-and-seed`, `auth-login-gate`, `employee-login`, etc.).

## Purpose

Take a reviewed/approved plan (`context/changes/<change-id>/plan.md`) and implement it phase-by-phase — writing all code, configuration, migrations, and tests described in the plan. After each phase, run the phase's verification steps. After all phases, run the full integration & smoke-test suite and confirm the code is deployable (compiles, tests pass, app starts).

## Inputs (read before implementing)

1. **The plan:** `context/changes/<change-id>/plan.md` — the authoritative spec for what to build. Follow it closely.
2. **PRD:** `context/foundation/prd.md` — product requirements and guardrails to never violate.
3. **Roadmap:** `context/foundation/roadmap.md` — the slice context, prerequisites, and unlocked items.
4. **Backend tech stack:** `backend/context/foundation/tech-stack.md`
5. **Frontend tech stack:** `frontend/context/foundation/tech-stack.md`
6. **Backend conventions:** `backend/AGENTS.md` — layout, commands, tier-specific rules.
7. **Frontend conventions:** `frontend/AGENTS.md` — layout, commands, tier-specific rules.
8. **Existing code:** scan `backend/src/` and `frontend/src/` to understand the current baseline and avoid conflicts.
9. **Plan review (if exists):** `context/changes/<change-id>/review/plan-review.md` — heed any warnings or notes from the review.

## Process

### Step 1: Pre-flight checks

Before writing any code:

1. **Verify plan status.** The plan's frontmatter `status` should be `revised` or `approved`. If it is `draft`, warn the user that the plan has not been reviewed and ask whether to proceed anyway.
2. **Verify prerequisites.** Check that all prerequisite changes listed in the plan's frontmatter are implemented (look for evidence in the codebase — entities, migrations, config, etc.). If prerequisites are missing, stop and inform the user.
3. **Read the full plan** and build a mental model of all phases, steps, and verification criteria.

### Step 2: Implement phase-by-phase

For each phase in the plan (Phase 1, Phase 2, …, Phase N), in order:

#### 2a. Implement all steps

- Implement every `- [ ]` checklist item in the phase.
- Follow the plan's file-path hints, class names, and endpoint paths exactly unless there's a technical reason to deviate (document any deviation).
- Write idiomatic code for the tier:
  - **Backend:** Java 21, Spring Boot 4.1, Maven. Follow `backend/AGENTS.md` conventions (feature-grouped packages, etc.).
  - **Frontend:** TypeScript, React 19, Vite 8. Follow `frontend/AGENTS.md` conventions (typed API client in `src/api/`, strict TS, etc.).
- Add all necessary imports, dependencies (`pom.xml` / `package.json`), configuration, and wiring.
- If the plan includes SQL migrations, create them with the exact version numbers and filenames specified.
- If the plan includes test code, implement the tests fully — not as stubs.

#### 2b. Run phase verification

After completing all steps in a phase, execute the verification steps listed in the plan's `#### Verification` section for that phase:

- **Backend verification commands:** Run from `backend/` using `.\mvnw.cmd` (Windows).
  - `.\mvnw.cmd spring-boot:run` — verify app starts without errors. Stop it after confirming startup.
  - `.\mvnw.cmd test` — verify tests pass.
  - `.\mvnw.cmd clean package` — verify the project packages without errors.
- **Frontend verification commands:** Run from `frontend/`.
  - `npm run build` — verify TypeScript compiles and Vite bundles without errors.
  - `npm run lint` — verify no lint errors.
- **Manual checks** (e.g., curl an endpoint, check DB state) — execute them and confirm the expected result.

If a verification step **fails**:
1. Read the error output carefully.
2. Diagnose and fix the issue (in the code just written, NOT by changing the plan).
3. Re-run the verification.
4. If stuck after 3 attempts on the same error, log the issue as a comment in the conversation and move on (or ask the user).

### Step 3: Integration & smoke test

After all phases are complete, run the `## Integration & Smoke Test` section from the plan:

- Execute each checklist item.
- Confirm the full change works end-to-end.
- Verify guardrail compliance (if applicable per the plan).

### Step 4: Final deployability check

Run a comprehensive deployability check for both tiers (if both were touched):

**Backend:**
```powershell
cd backend
.\mvnw.cmd clean package
```
- This runs compile + test + package. If it succeeds, the backend is deployable.

**Frontend:**
```powershell
cd frontend
npm run build
```
- This runs `tsc -b` (type-check) + `vite build`. If it succeeds, the frontend is deployable.

Both must pass with **zero errors** for the implementation to be considered complete.

### Step 5: Update plan status

If the implementation is fully successful (all verifications pass, deployability confirmed):
- Update the plan's frontmatter `status` from `revised`/`approved` to `implemented`.

## Rules

1. **Follow the plan faithfully.** The plan is the spec. Implement what it says. If you disagree with a plan decision, implement it anyway and note the concern in the conversation — don't unilaterally change the architecture.

2. **Phase order matters.** Implement phases sequentially. Earlier phases create foundations that later phases depend on. Never skip ahead.

3. **Verify after every phase.** Don't batch all verification to the end. Catch errors early, phase by phase. This prevents cascade failures.

4. **Fix forward, don't edit the plan.** If a plan step is slightly wrong (e.g., a typo in a class name, a missing import), fix it in the code and note the deviation in the conversation. Don't modify `plan.md` during implementation.

5. **Respect guardrails absolutely.** If implementing a step would violate a PRD guardrail (no rejection signals, explainable score, score hidden while swiping), STOP and flag it to the user rather than writing violating code.

6. **Keep scope tight.** Only implement what's in the plan. Don't add features, polish, or refactoring beyond what the plan specifies — even if you see opportunities.

7. **Dependency installation.** When adding dependencies (`pom.xml` changes, `package.json` changes), run the appropriate install/resolve command before proceeding:
   - Backend: `.\mvnw.cmd dependency:resolve` (or just let the next `spring-boot:run` / `test` pull them)
   - Frontend: `npm install`

8. **Docker awareness.** If the plan requires Docker (e.g., for Postgres via Docker Compose), check if Docker is available. If not, inform the user and suggest alternatives (e.g., H2 for tests, external Postgres).

9. **Commit-ready code.** All code written should be production-quality for a hackathon POC — properly formatted, no TODOs unless the plan explicitly defers something, no dead code, no commented-out blocks.

## Example invocation

```
/deloitter-implement persistence-and-seed
```

Reads `context/changes/persistence-and-seed/plan.md`, implements all phases, verifies each, runs the integration smoke test, and confirms `.\mvnw.cmd clean package` passes. Updates plan status to `implemented` on success.

## Failure modes

| Situation | Action |
|-----------|--------|
| Plan status is `draft` (not reviewed) | Warn user, ask to proceed or run `/deloitter-plan-review` first |
| Prerequisites not implemented | Stop, list what's missing, ask user how to proceed |
| Phase verification fails after 3 fix attempts | Log the error in conversation, ask user for guidance, continue to next phase if non-blocking |
| Docker not available but plan requires it | Inform user, suggest alternatives (H2 profile, external DB, skip Docker-dependent verification) |
| Plan step is ambiguous or incomplete | Use best judgment based on tech-stack docs and conventions, note the interpretation in the conversation |
| Guardrail violation detected | STOP immediately, flag to user, do NOT write the violating code |
