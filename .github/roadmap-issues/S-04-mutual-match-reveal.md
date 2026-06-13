## S-04 · `mutual-match-reveal`

> Auto-generated from `context/foundation/roadmap.md` (v1).
> The roadmap is the source of truth - edit it, update `.github/roadmap-issues.json`, then re-run the deploy.

**Outcome:** When two users have liked each other the system creates a match, and the user can open a Matches view listing each match with its (now revealed) compatibility score and the matched colleague's contact info, so connection continues over Teams/email.

| Field | Value |
| --- | --- |
| Stream | Stream B - Match loop |
| Type | slice |
| PRD refs | FR-005, FR-006, Privacy NFR |
| Status | proposed |

### Dependencies
- **Blocked by:** `S-03`
- **Blocks:** none
- **Parallel with:** `S-05`

### Why / risk
The north star and second backend-investment focus. Introduces match detection and the privacy enforcement that is a hard guardrail. Getting reveal-only-on-mutual-match wrong breaks the product's core promise.

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: FR-005, FR-006, Privacy NFR
- [ ] A user can find no way to learn a non-match's intent - score + contact info reveal only on a mutual match.

### Next step
Run `/10x-plan mutual-match-reveal` -> produces `context/changes/mutual-match-reveal/plan.md`.

<!-- roadmap-id: S-04 | change-id: mutual-match-reveal | managed-by: deploy-roadmap-issues.sh -->
