## S-03 · `swipe-candidate-stack`

> Auto-generated from `context/foundation/roadmap.md` (v1).
> The roadmap is the source of truth - edit it, update `.github/roadmap-issues.json`, then re-run the deploy.

**Outcome:** User can view candidate employees one card at a time (each card shows shared interests/competencies; the compatibility score is HIDDEN here) and swipe like or pass; the stack is ordered highest-compatibility-first and transitions feel instant.

| Field | Value |
| --- | --- |
| Stream | Stream B - Match loop |
| Type | slice |
| PRD refs | FR-003, FR-004, Business Logic, Perceived-responsiveness NFR |
| Status | proposed |

### Dependencies
- **Blocked by:** #2, #5
- **Blocks:** #7
- **Parallel with:** `S-05`

### Why / risk
Heaviest slice and backend-investment focus: introduces swipe persistence and the proportional-overlap compatibility computation that ranks the stack. Two failure modes - the score is wrong/unexplainable (violating a guardrail), or transitions lag (violating the responsiveness NFR).

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: FR-003, FR-004, Business Logic, Perceived-responsiveness NFR
- [ ] Compatibility score is hidden on cards; card-to-card transition stays under ~300ms with no load stall.

### Next step
Run `/10x-plan swipe-candidate-stack` -> produces `context/changes/swipe-candidate-stack/plan.md`.

<!-- roadmap-id: S-03 | change-id: swipe-candidate-stack | managed-by: deploy-roadmap-issues.sh -->
