---
bootstrapped_at: 2026-06-12T20:23:00Z
starter_id: spring
starter_name: Spring Boot
project_name: deloitter
language_family: java
package_manager: maven
cwd_strategy: subdir-then-move
bootstrapper_confidence: verified
phase_3_status: ok
audit_command: "null"
---

## Hand-off

Source: `backend/context/foundation/tech-stack.md` (scaffold target redirected to `backend/` per user instruction at confirmation).

```yaml
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
```

**Why this stack** (verbatim from hand-off body):

> Deloitter splits into a separate API backend and a PWA frontend; this hand-off
> covers the API tier only. Spring Boot is the recommended default for `(api,
> java)` and clears all four agent-friendly gates, with verified bootstrapper
> confidence so scaffolding is smooth. Its bundled DI, web, data, and security
> modules cover the only stack-forcing requirement — email + password auth
> (FR-001) — while the compatibility-overlap scoring is plain application logic
> that forces no particular technology. Standard path, so team size defaults to
> solo and no self-check was needed. Deployment is local-only (self-host) for the
> hackathon demo per the disposable-data, no-production-hardening non-goals; CI
> runs on GitHub Actions gated as PR → checks → merge, with deployment a separate
> manual step since there is no cloud target. Payments, realtime, AI, and
> background jobs are all out of scope per the PRD, so only `has_auth` is set.

## Pre-scaffold verification

| Signal      | Value   | Severity | Notes                                                                 |
| ----------- | ------- | -------- | --------------------------------------------------------------------- |
| npm package | not run | —        | Non-JS starter; `cmd_template` fetches from start.spring.io, not npm. |
| GitHub repo | not run | —        | `docs_url` (`https://docs.spring.io/spring-boot/`) is not a GitHub repo URL — no recency signal available. |

No staleness warning surfaced. Proceeded.

## Scaffold log

**Resolved invocation**: `curl -s https://start.spring.io/starter.tgz -d dependencies=web,devtools -d type=maven-project -d javaVersion=21 -d groupId=com.example -d artifactId=deloitter -d name=deloitter -d baseDir=.bootstrap-scaffold | tar -xzf -`
**Strategy**: subdir-then-move
**Exit code**: 0
**Files moved**: 8 (`.gitattributes`, `.gitignore`, `.mvn/`, `HELP.md`, `mvnw`, `mvnw.cmd`, `pom.xml`, `src/`)
**Conflicts (.scaffold siblings)**: none
**.gitignore handling**: moved silently (no pre-existing `.gitignore` in target)
**.bootstrap-scaffold cleanup**: deleted

**Deviations from the card's literal `cmd_template`** (recorded for the audit trail):
- The card template substitutes `{name}` (→ `.bootstrap-scaffold`) directly into `artifactId`. For this starter that value is the Maven artifactId / Java package, not a directory name, and the start.spring.io tarball flattens into cwd rather than creating its own folder. Substituting `.bootstrap-scaffold` would have baked an invalid artifact (`com.example.bootstrap_scaffold`) into `pom.xml` and the source tree.
- Resolution: used `artifactId=deloitter` / `name=deloitter` (the hand-off `project_name`) for sensible Maven coordinates + package `com.example.deloitter`, and used the starter's `baseDir=.bootstrap-scaffold` parameter to obtain the temp-dir isolation the subdir-then-move strategy requires. The conflict matrix then governed the move-up into `backend/`.
- `backend/context/` was preserved verbatim; `backend/.gitkeep` left untouched.

## Post-scaffold audit

**Tool**: skipped — no built-in audit tool for java
**Recommended external tool**: run `mvn org.owasp:dependency-check-maven:check` (OWASP Dependency-Check) or enable GitHub Dependabot / `mvn versions:display-dependency-updates` for vulnerability and update visibility.

## Hints recorded but not acted on

| Hint                    | Value           |
| ----------------------- | --------------- |
| bootstrapper_confidence | verified        |
| quality_override        | false           |
| path_taken              | standard        |
| self_check_answers      | null            |
| team_size               | solo            |
| deployment_target       | self-host       |
| ci_provider             | github-actions  |
| ci_default_flow         | manual-promotion |
| has_auth                | true            |
| has_payments            | false           |
| has_realtime            | false           |
| has_ai                  | false           |
| has_background_jobs     | false           |

Note: `has_auth: true` was flagged in the hand-off. v1 surfaces it but does not scaffold auth wiring — Spring Boot's security module was not added beyond the `web,devtools` dependencies the card specifies. Add `spring-boot-starter-security` when implementing FR-001.

## Next steps

Next: a future skill will set up agent context (CLAUDE.md, AGENTS.md). For now, your project is scaffolded and verified — happy hacking.

Useful manual steps in the meantime:
- `git init` (if you have not already) to start your own repo history.
- Review any `.scaffold` siblings the conflict policy created and decide which version of each file to keep. (None were created this run.)
- Address audit findings per your project's risk tolerance — Java has no built-in audit; see the recommended external tools above.
- Verify the build: `cd backend && ./mvnw -q compile` (or `mvnw.cmd` on Windows).
