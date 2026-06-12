---
bootstrapped_at: 2026-06-12T19:01:52Z
starter_id: vite-react
starter_name: Vite + React
project_name: deloitter
language_family: js
package_manager: npm
cwd_strategy: subdir-then-move
bootstrapper_confidence: verified
phase_3_status: ok
audit_command: npm audit --json
---

## Hand-off

Source: `frontend/context/foundation/tech-stack.md`

```yaml
starter_id: vite-react
package_manager: npm
project_name: deloitter
hints:
  language_family: js
  team_size: small
  deployment_target: localhost
  ci_provider: github-actions
  ci_default_flow: auto-deploy-on-merge
  bootstrapper_confidence: verified
  path_taken: custom
  quality_override: true
  self_check_answers:
    typed: true
    from_official_starter: true
    conventions: true
    docs_current: true
    can_judge_agent: true
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: false
  has_background_jobs: false
```

### Why this stack (verbatim)

Deloitter is a split monorepo: a Spring Boot backend already lives in /backend,
so this frontend needs a pure SPA/PWA shell that consumes the existing Java API
rather than a full-stack starter that bundles its own backend. That ruled out
the registry default (10x Astro Starter) and the other meta-frameworks. Within
the frontend-only SPA set, the small team chose Vite + React (TypeScript) for
its unmatched swipe/gesture/UI component ecosystem — a real advantage for a
Tinder-style swipe interaction with snappy, instant card transitions. React +
Vite are typed, popular, and well-documented; they fail only the convention
gate (the bare template ships no opinionated structure), so quality_override is
set and the bootstrap step must add a conventional src/ layout, an API-client
pattern against the Spring backend, and a CLAUDE.md/AGENTS.md documenting them.
The self-check came back clean on all five points. Auth is the one in-scope
feature (login UI against the backend); payments, realtime, and AI are out of
scope per the PRD. Deployment is localhost-only for the hackathon demo; CI runs
on GitHub Actions.

## Pre-scaffold verification

| Signal      | Value                                    | Severity | Notes                                          |
| ----------- | ---------------------------------------- | -------- | ---------------------------------------------- |
| npm package | create-vite v9.0.7 published 2026-05-11  | fresh    | resolved from cmd_template (`npm create vite`) |
| GitHub repo | not run                                  | n/a      | card.docs_url is vitejs.dev, not a GitHub repo |

## Scaffold log

**Resolved invocation**: `npm create vite@latest .bootstrap-scaffold -- --template react-ts`
**Strategy**: subdir-then-move
**Exit code**: 0
**Files moved**: 15 files (11 top-level entries: `.gitignore`, `README.md`, `eslint.config.js`, `index.html`, `package.json`, `public/`, `src/`, `tsconfig.app.json`, `tsconfig.json`, `tsconfig.node.json`, `vite.config.ts`)
**Conflicts (.scaffold siblings)**: none
**.gitignore handling**: moved silently (absent in cwd)
**.bootstrap-scaffold cleanup**: deleted (one transient Windows "device busy" on the directory handle; removed on retry — all files moved cleanly, no leftovers)

Preserved in cwd by the conflict policy: `.gitkeep`, `context/` (untouched).

## Post-scaffold audit

**Tool**: `npm audit --json`
**Status**: failed to run
**Reason**: ENOLOCK — no lockfile. The Vite template ships no install step, and bootstrapper does not install dependencies or otherwise modify the scaffold, so no `package-lock.json` exists to audit.
**Partial output (if any)**:

```
npm error code ENOLOCK
npm error audit This command requires an existing lockfile.
npm error audit Try creating one first with: npm i --package-lock-only
npm error audit Original error: loadVirtual requires existing shrinkwrap file
```

To get an audit: run `npm install` (writes `package-lock.json`), then `npm audit`.

## Hints recorded but not acted on

v1 surfaces these but takes no compensating action. A future agent-context skill (CLAUDE.md / AGENTS.md) may act on them.

| Hint                    | Value                                                                                  |
| ----------------------- | -------------------------------------------------------------------------------------- |
| bootstrapper_confidence | verified                                                                               |
| quality_override        | true                                                                                   |
| path_taken              | custom                                                                                 |
| self_check_answers      | typed: true, from_official_starter: true, conventions: true, docs_current: true, can_judge_agent: true |
| team_size               | small                                                                                  |
| deployment_target       | localhost                                                                              |
| ci_provider             | github-actions                                                                         |
| ci_default_flow         | auto-deploy-on-merge                                                                    |
| has_auth                | true                                                                                   |
| has_payments            | false                                                                                  |
| has_realtime            | false                                                                                  |
| has_ai                  | false                                                                                  |
| has_background_jobs     | false                                                                                  |

**Note on `quality_override: true`**: during stack selection you proceeded past the convention gate. The bare Vite + React template ships no opinionated `src/` structure, no API-client pattern against the Spring backend, and no agent-context files. The hand-off rationale calls for those to be added as a follow-up — v1 bootstrapper does not generate them.

## Next steps

Next: a future skill will set up agent context (CLAUDE.md, AGENTS.md). For now, your project is scaffolded and verified — happy hacking.

Useful manual steps in the meantime:
- `cd frontend && npm install` to install dependencies and generate `package-lock.json` (then `npm audit` will run).
- `git init` is not needed — this repo already has git history; `frontend/` lives inside it.
- Add the conventional `src/` layout, the API-client pattern against the Spring Boot backend in `/backend`, and CLAUDE.md/AGENTS.md called for by the hand-off rationale (the convention-gate gap behind `quality_override: true`).
- Address audit findings per your project's risk tolerance once a lockfile exists — the full breakdown will be in this log on a re-run.
