## F-01 · `persistence-and-seed`

> Auto-generated from `context/foundation/roadmap.md` (v1).
> The roadmap is the source of truth - edit it, update `.github/roadmap-issues.psd1`, then re-run the deploy.

**Outcome:** PostgreSQL is connected to the Spring Boot backend, the minimal schema for employee accounts and the predefined interests/competencies catalog exists, and a seed harness populates enough demo employees that mutual matches can occur.

| Field | Value |
| --- | --- |
| Stream | Stream A - Onboarding & access |
| Type | foundation |
| PRD refs | Account provisioning note, Data handling NFR, Business Logic |
| Status | ready |

### Dependencies
- **Blocked by:** none
- **Blocks:** #3, #4, #5, #6
- **Parallel with:** none

### Why / risk
Sequenced first because nothing else is plannable or verifiable without persistence and seeded identities. Scope risk: must stay minimal (accounts + catalog + seed only) - swipe and match tables land in their consuming slices, not here.

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: Account provisioning note, Data handling NFR, Business Logic
- [ ] Seed dataset produces at least one reliable mutual match in a demo run.

### Next step
Run `/10x-plan persistence-and-seed` -> produces `context/changes/persistence-and-seed/plan.md`.

<!-- roadmap-id: F-01 | change-id: persistence-and-seed | managed-by: deploy-roadmap-issues.ps1 -->

