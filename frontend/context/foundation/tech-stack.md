---
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
---

## Why this stack

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
