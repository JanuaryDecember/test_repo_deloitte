# /deloitter-archive — Archive a completed roadmap slice

## Usage

```
/deloitter-archive <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `persistence-and-seed`, `auth-login-gate`, etc.).

## Purpose

Move a finished slice from active development (`context/changes/`) into the read-only archive (`context/archive/`), and update all tracking artifacts (roadmap table, JSON manifest, GitHub issue label) to reflect the `done` state.

## Prerequisites (warn but do not block)

Before archiving, check for the existence of:
- `context/changes/<change-id>/review/plan-review.md`
- `context/changes/<change-id>/review/impl-review-phase-*.md` (at least one)

If any of these are missing, **warn the user** with a message like:
> ⚠️ Implementation review files are missing for `<change-id>`. Archiving anyway — consider running `/deloitter-implement-review <change-id>` first.

This is advisory only — the archive proceeds regardless.

## Inputs (read before archiving)

1. **Roadmap:** `context/foundation/roadmap.md` — locate the row matching `<change-id>` in the "At a glance" table.
2. **JSON manifest:** `.github/roadmap-issues.json` — locate the item with matching `changeId`.
3. **Change folder:** `context/changes/<change-id>/` — must exist (error if it doesn't).
4. **Archive folder:** `context/archive/` — destination.

## Process

### Step 1: Validate

1. Confirm `context/changes/<change-id>/` exists. If not, error: "Change folder not found: `context/changes/<change-id>/`. Nothing to archive."
2. Confirm no folder matching `context/archive/<YYYY-MM-DD>_<change-id>/` already exists. If it does, error: "Already archived: folder exists."
3. Check for review files (warn if missing, per above).

### Step 2: Move the change folder and stamp with archive date

Use the current date and time: `YYYY-MM-DD` for the folder prefix and `YYYY-MM-DD HH:mm` for the file header.

```bash
mv context/changes/<change-id>/ context/archive/<YYYY-MM-DD>_<change-id>/
```

The folder name is prefixed with the archive date (e.g. `2026-06-13_persistence-and-seed`).

All contents (plan.md, plan-brief.md, review/, etc.) move as-is.

After moving, prepend an archive header to **all markdown files** in the archived folder (`plan.md`, `plan-brief.md`, and every file under `review/`) at the very top of the file, **before** any existing frontmatter or content:

```markdown
> **Archived:** <YYYY-MM-DD HH:mm> | Change ID: `<change-id>` | Roadmap ID: `<roadmap-id>`
```

This line goes at line 1 of each file, followed by a blank line, then the original content.

### Step 3: Update `context/foundation/roadmap.md`

In the "At a glance" table, find the row where the Change ID column matches `<change-id>` and change its Status cell from `ready` or `proposed` to `done`.

**Example before:**
```
| F-01 | persistence-and-seed   | (foundation) Postgres wired + accounts/catalog seeded | — | Account provisioning, Data handling NFR | ready    |
```

**Example after:**
```
| F-01 | persistence-and-seed   | (foundation) Postgres wired + accounts/catalog seeded | — | Account provisioning, Data handling NFR | done     |
```

### Step 4: Update `.github/roadmap-issues.json`

Find the item in the `items` array where `"changeId"` equals `<change-id>` and set:
- `"status": "done"`

Leave all other fields unchanged.

### Step 4b: Update `.github/roadmap-issues.psd1` (keep in sync)

Find the item block in the `Items` array where `Id` matches the roadmap ID (e.g. `'F-01'`) and change:
- `Status   = 'ready'` (or `'proposed'`) → `Status   = 'done'`

This keeps the legacy PowerShell manifest in sync with the JSON source of truth.

### Step 5: Update GitHub issue label (if gh available)

If the `gh` CLI is authenticated and a repo can be resolved from `git remote get-url origin`:

1. Find the issue by searching for the provenance marker: `<!-- roadmap-id: <ID> -->` (where `<ID>` is the roadmap ID from the manifest, e.g. `F-01`).
2. Remove labels `status:ready` and `status:proposed` from the issue.
3. Add label `status:done` to the issue.

If `gh` is not available or not authenticated, skip this step and inform the user:
> ℹ️ gh CLI not available/authenticated — skipping GitHub label update. Run the deploy script to sync labels.

### Step 6: Summary

Print a confirmation:

```
✓ Archived: <change-id> (<roadmap-id>)
  - Moved context/changes/<change-id>/ → context/archive/<YYYY-MM-DD>_<change-id>/
  - Roadmap status: done
  - Manifest status: done
  - GitHub label: status:done (or "skipped — gh not available")
```

## Error handling

- If `<change-id>` is not found in the roadmap or manifest, error clearly naming which file is missing the entry.
- If the move fails (permissions, etc.), error before updating roadmap/manifest (keep state consistent).
- Never modify `context/archive/` contents beyond the initial move — archive is read-only by convention.

## What this skill does NOT do

- Does not close the GitHub issue (only updates the label).
- Does not remove the change from the roadmap table (the row stays, marked `done`).
- Does not modify any source code files.
- Does not run tests or verification — that's `/deloitter-release-readiness`.
