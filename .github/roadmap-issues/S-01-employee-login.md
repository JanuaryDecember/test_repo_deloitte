## S-01 · `employee-login`

> Auto-generated from `context/foundation/roadmap.md` (v1).
> The roadmap is the source of truth - edit it, update `.github/roadmap-issues.psd1`, then re-run the deploy.

**Outcome:** User can log in with seeded email+password credentials and land in the app.

| Field | Value |
| --- | --- |
| Stream | Stream A - Onboarding & access |
| Type | slice |
| PRD refs | FR-001 |
| Status | proposed |

### Dependencies
- **Blocked by:** #2, #3
- **Blocks:** #5
- **Parallel with:** none

### Why / risk
Thin gate slice - low risk. Sequenced first among slices because every other slice needs a logged-in identity. The only failure mode is the login UX stalling the demo's first ten seconds.

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: FR-001

### Next step
Run `/10x-plan employee-login` -> produces `context/changes/employee-login/plan.md`.

<!-- roadmap-id: S-01 | change-id: employee-login | managed-by: deploy-roadmap-issues.ps1 -->

