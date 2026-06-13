## F-02 · `auth-login-gate`

> Auto-generated from `context/foundation/roadmap.md` (v1).
> The roadmap is the source of truth - edit it, update `.github/roadmap-issues.json`, then re-run the deploy.

**Outcome:** email+password credentials are verified against seeded accounts, an authenticated session/token is issued, and a route-level guard ensures only an authenticated "me" can use the app (no anonymous browsing).

| Field | Value |
| --- | --- |
| Stream | Stream A - Onboarding & access |
| Type | foundation |
| PRD refs | FR-001, Access Control |
| Status | proposed |

### Dependencies
- **Blocked by:** `F-01`
- **Blocks:** `S-01`
- **Parallel with:** none

### Why / risk
Deliberately thin - seeded credentials, no security/PII hardening (explicit Non-Goal). Risk is over-engineering it; keep to verify-and-issue-session.

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: FR-001, Access Control
- [ ] No anonymous browsing: every app route requires an authenticated session.

### Next step
Run `/10x-plan auth-login-gate` -> produces `context/changes/auth-login-gate/plan.md`.

<!-- roadmap-id: F-02 | change-id: auth-login-gate | managed-by: deploy-roadmap-issues.sh -->
