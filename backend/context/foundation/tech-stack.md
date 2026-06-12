---
starter_id: spring
package_manager: maven
project_name: deloitter
hints:
  language_family: java
  team_size: solo
  deployment_target: self-host
  ci_provider: github-actions
  ci_default_flow: manual-promotion
  bootstrapper_confidence: verified
  path_taken: standard
  quality_override: false
  self_check_answers: null
  has_auth: true
  has_payments: false
  has_realtime: false
  has_ai: false
  has_background_jobs: false
---

## Why this stack

Deloitter splits into a separate API backend and a PWA frontend; this hand-off
covers the API tier only. Spring Boot is the recommended default for `(api,
java)` and clears all four agent-friendly gates, with verified bootstrapper
confidence so scaffolding is smooth. Its bundled DI, web, data, and security
modules cover the only stack-forcing requirement — email + password auth
(FR-001) — while the compatibility-overlap scoring is plain application logic
that forces no particular technology. Standard path, so team size defaults to
solo and no self-check was needed. Deployment is local-only (self-host) for the
hackathon demo per the disposable-data, no-production-hardening non-goals; CI
runs on GitHub Actions gated as PR → checks → merge, with deployment a separate
manual step since there is no cloud target. Payments, realtime, AI, and
background jobs are all out of scope per the PRD, so only `has_auth` is set.
