## S-02 · `select-interests`

> Auto-generated from `context/foundation/roadmap.md` (v1).
> The roadmap is the source of truth - edit it, update `.github/roadmap-issues.json`, then re-run the deploy.

**Outcome:** User can pick their interests and competencies from the predefined catalog; selections persist to their profile and become the inputs the compatibility score consumes.

| Field | Value |
| --- | --- |
| Stream | Stream B - Match loop |
| Type | slice |
| PRD refs | FR-002 |
| Status | proposed |

### Dependencies
- **Blocked by:** #2, #4
- **Blocks:** #6, #8
- **Parallel with:** none

### Why / risk
Sequenced before the swipe stack because the score (and the "shared interests" shown on each card) is computed from the logged-in user's own selections - without them the stack has nothing to rank against. Keep the selection UI simple per the speed goal.

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: FR-002


### Next step
Run `/10x-plan select-interests` -> produces `context/changes/select-interests/plan.md`.

<!-- roadmap-id: S-02 | change-id: select-interests | managed-by: deploy-roadmap-issues.sh -->
