---
name: Roadmap slice
about: A vertical slice or foundation from context/foundation/roadmap.md. Mirrors the
  shape that scripts/deploy-roadmap-issues.ps1 generates, so hand-made issues stay consistent.
title: '[slice] '
labels: type:slice
---

## <ROADMAP-ID> · `<change-id>`

> Source of truth is `context/foundation/roadmap.md`. If this slice exists there,
> prefer editing the roadmap + `.github/roadmap-issues.psd1` and re-running the deploy
> script over hand-editing this issue.

**Outcome:** <what the user can do after this ships, end-to-end>

| Field | Value |
| --- | --- |
| Stream | <A — Onboarding & access / B — Match loop / C — Profile maintenance> |
| Type | <foundation / slice> |
| PRD refs | <e.g. FR-003, Privacy NFR> |
| Status | <ready / proposed> |

### Dependencies
- **Blocked by:** <#issue, … / none>
- **Blocks:** <#issue, … / none>
- **Parallel with:** <`S-05` / none>

### Why / risk
<why this is sequenced where it is, and what can go wrong>

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: <refs>
- [ ] <slice-specific guardrail, if any>

### Next step
Run `/10x-plan <change-id>` → produces `context/changes/<change-id>/plan.md`.

<!-- roadmap-id: <ROADMAP-ID> | change-id: <change-id> | managed-by: deploy-roadmap-issues.ps1 -->
