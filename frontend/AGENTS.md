# Repository Guidelines — Frontend (Deloitter SPA)

Scoped guidance for the `frontend/` tier. For product vision, guardrails, and the change pipeline, see the root [`CLAUDE.md`](../CLAUDE.md).

## Stack

Vite 8 + React 19 + TypeScript. A pure SPA/PWA shell — no bundled backend; it talks to the Spring Boot API in `backend/` over HTTP. Currently the default Vite template (`src/App.tsx`, `src/main.tsx`) with no routes, components, or API client yet.

## Commands

Run from `frontend/`.

- Dev server (HMR): `npm run dev`
- Build (typecheck + bundle): `npm run build` — runs `tsc -b` then `vite build`; a type error fails the build.
- Lint: `npm run lint` (ESLint flat config in `eslint.config.js`)
- Preview a built bundle: `npm run preview`
- No test runner is configured yet.

## Layout & conventions

- The bare template ships **no opinionated structure** — establish it as features land. Suggested: `src/components/`, `src/pages/` (or `routes/`), `src/api/` for the backend client, `src/types/` for shared models.
- Centralize all backend calls behind a single typed API-client module (`src/api/`); components should not call `fetch` directly. This keeps the HTTP contract with the Java tier in one place.
- TypeScript is strict (`tsconfig.app.json`); keep it that way. No router or component library is installed yet — add one deliberately when a slice needs it.

## Tier-specific rules

- **Desktop-browser only** for the MVP; mobile/responsive layout is not a requirement (PRD non-goal). It is an installable PWA but offline support is out of scope.
- **Swipe must feel instant** (target < ~300ms card-to-card, no load stall). Prefetch/queue the candidate stack rather than fetching per-card; this drove the React choice for its gesture/animation ecosystem.
- **Never display the compatibility score while swiping** — the card shows shared interests/competencies only. The score appears solely in the Matches view, on a confirmed mutual match. The client must also never surface any pass/like intent that isn't a mutual match (privacy guardrail).
