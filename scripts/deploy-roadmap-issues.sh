#!/usr/bin/env bash
#
# Deploy context/foundation/roadmap.md slices as ordered, linked GitHub issues.
#
# Reads .github/roadmap-issues.json and creates labels, milestones, and issues
# via the gh CLI. Idempotent: labels use --force, milestones are looked up before
# creation, and each issue carries a <!-- roadmap-id: <ID> --> provenance marker.
#
# Requirements: gh (authenticated), jq
# Compatible with: bash 3.2+ (macOS default), bash 4+, zsh
#
# Usage:
#   ./scripts/deploy-roadmap-issues.sh [--dry-run] [--repo owner/repo] [--manifest path]
#
set -euo pipefail

# --- Defaults ----------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="$REPO_ROOT/.github/roadmap-issues"
MANIFEST_PATH="$REPO_ROOT/.github/roadmap-issues.json"
DRY_RUN=false
REPO=""

# --- Parse arguments ---------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)  DRY_RUN=true; shift ;;
        --repo)     REPO="$2"; shift 2 ;;
        --manifest) MANIFEST_PATH="$2"; shift 2 ;;
        -h|--help)
            echo "Usage: $0 [--dry-run] [--repo owner/repo] [--manifest path]"
            exit 0
            ;;
        *) echo "Unknown argument: $1" >&2; exit 1 ;;
    esac
done

# --- Helpers -----------------------------------------------------------------
step()  { printf '\033[36m==> %s\033[0m\n' "$1"; }
info()  { printf '\033[90m    %s\033[0m\n' "$1"; }

# --- Key-value store (bash 3.2 compatible, file-backed) ----------------------
_KV_DIR=""
kv_init() {
    _KV_DIR=$(mktemp -d)
    trap 'rm -rf "$_KV_DIR"' EXIT
}
kv_set() { printf '%s' "$2" > "$_KV_DIR/$1"; }
kv_get() { cat "$_KV_DIR/$1" 2>/dev/null || echo ""; }
kv_has() { [[ -f "$_KV_DIR/$1" ]]; }
kv_append() {
    local cur
    cur=$(kv_get "$1")
    if [[ -n "$cur" ]]; then
        kv_set "$1" "$cur $2"
    else
        kv_set "$1" "$2"
    fi
}

kv_init

# --- Preflight ---------------------------------------------------------------
if [[ ! -f "$MANIFEST_PATH" ]]; then
    echo "Manifest not found: $MANIFEST_PATH" >&2
    exit 1
fi

command -v jq >/dev/null 2>&1 || { echo "jq is required but not installed." >&2; exit 1; }

ITEM_COUNT=$(jq '.items | length' "$MANIFEST_PATH")
if [[ "$ITEM_COUNT" -eq 0 ]]; then
    echo "Manifest has no items." >&2
    exit 1
fi

if [[ "$DRY_RUN" == "true" ]]; then
    step "DRY RUN - no GitHub calls will be made."
else
    command -v gh >/dev/null 2>&1 || { echo "gh CLI not found. Install it and run 'gh auth login', or use --dry-run." >&2; exit 1; }
    gh auth status >/dev/null 2>&1 || { echo "gh is not authenticated. Run 'gh auth login' first." >&2; exit 1; }

    if [[ -z "$REPO" ]]; then
        URL=$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null || true)
        if [[ "$URL" =~ github\.com[:/]([^/]+)/([^/.]+) ]]; then
            REPO="${BASH_REMATCH[1]}/${BASH_REMATCH[2]}"
        else
            echo "Could not parse owner/repo from origin url: $URL. Pass --repo owner/repo." >&2
            exit 1
        fi
    fi
    step "Target repo: $REPO"
fi

# --- Read manifest via jq ----------------------------------------------------
get_item() { jq -r ".items[$1].$2 // empty" "$MANIFEST_PATH"; }
get_stream() { jq -r ".streams.\"$1\" // empty" "$MANIFEST_PATH"; }

# --- Build reverse dependency map (Blocks) using kv store --------------------
for ((i=0; i<ITEM_COUNT; i++)); do
    ID=$(get_item "$i" "id")
    kv_set "blocks_$ID" ""
done
for ((i=0; i<ITEM_COUNT; i++)); do
    ID=$(get_item "$i" "id")
    PREREQS=$(jq -r ".items[$i].prereqs[]?" "$MANIFEST_PATH")
    for p in $PREREQS; do
        kv_append "blocks_$p" "$ID"
    done
done

# --- Format references -------------------------------------------------------
format_ref() {
    local id="$1"
    local num
    num=$(kv_get "number_$id")
    if [[ -n "$num" ]]; then
        echo "#$num"
    else
        echo "\`$id\`"
    fi
}

# --- Issue body renderer ------------------------------------------------------
render_issue_body() {
    local idx="$1"
    local ID CHANGE_ID STREAM STREAM_NAME TYPE OUTCOME PRD_REFS STATUS RISK GUARDRAIL
    ID=$(get_item "$idx" "id")
    CHANGE_ID=$(get_item "$idx" "changeId")
    STREAM=$(get_item "$idx" "stream")
    STREAM_NAME=$(get_stream "$STREAM")
    TYPE=$(get_item "$idx" "type")
    OUTCOME=$(get_item "$idx" "outcome")
    PRD_REFS=$(get_item "$idx" "prdRefs")
    STATUS=$(get_item "$idx" "status")
    RISK=$(get_item "$idx" "risk")
    GUARDRAIL=$(get_item "$idx" "guardrail")

    local ROADMAP_VERSION
    ROADMAP_VERSION=$(jq -r '.roadmapVersion' "$MANIFEST_PATH")

    # Blocked-by refs
    local BLOCKED_BY="none"
    local prereq_ids
    prereq_ids=$(jq -r ".items[$idx].prereqs[]?" "$MANIFEST_PATH")
    if [[ -n "$prereq_ids" ]]; then
        local refs=""
        for p in $prereq_ids; do
            if [[ -n "$refs" ]]; then refs="$refs, "; fi
            refs="$refs$(format_ref "$p")"
        done
        BLOCKED_BY="$refs"
    fi

    # Blocks refs
    local BLOCKS_STR="none"
    local blocks_val
    blocks_val=$(kv_get "blocks_$ID")
    if [[ -n "$blocks_val" ]]; then
        local brefs=""
        for b in $blocks_val; do
            if [[ -n "$brefs" ]]; then brefs="$brefs, "; fi
            brefs="$brefs$(format_ref "$b")"
        done
        BLOCKS_STR="$brefs"
    fi

    # Parallel refs
    local PARALLEL_STR="none"
    local parallel_ids
    parallel_ids=$(jq -r ".items[$idx].parallel[]?" "$MANIFEST_PATH")
    if [[ -n "$parallel_ids" ]]; then
        local prefs=""
        for p in $parallel_ids; do
            if [[ -n "$prefs" ]]; then prefs="$prefs, "; fi
            prefs="$prefs\`$p\`"
        done
        PARALLEL_STR="$prefs"
    fi

    cat <<EOF
## $ID · \`$CHANGE_ID\`

> Auto-generated from \`context/foundation/roadmap.md\` (v$ROADMAP_VERSION).
> The roadmap is the source of truth - edit it, update \`.github/roadmap-issues.json\`, then re-run the deploy.

**Outcome:** $OUTCOME

| Field | Value |
| --- | --- |
| Stream | $STREAM_NAME |
| Type | $TYPE |
| PRD refs | $PRD_REFS |
| Status | $STATUS |

### Dependencies
- **Blocked by:** $BLOCKED_BY
- **Blocks:** $BLOCKS_STR
- **Parallel with:** $PARALLEL_STR

### Why / risk
$RISK

### Acceptance
- [ ] Outcome above is demonstrable end-to-end on seeded data
- [ ] PRD refs satisfied: $PRD_REFS
$(if [[ -n "$GUARDRAIL" ]]; then echo "- [ ] $GUARDRAIL"; fi)

### Next step
Run \`/10x-plan $CHANGE_ID\` -> produces \`context/changes/$CHANGE_ID/plan.md\`.

<!-- roadmap-id: $ID | change-id: $CHANGE_ID | managed-by: deploy-roadmap-issues.sh -->
EOF
}

# --- Get labels for an item ---------------------------------------------------
get_item_labels() {
    local idx="$1"
    local TYPE STREAM STATUS NORTH_STAR PLAN_READY
    TYPE=$(get_item "$idx" "type")
    STREAM=$(get_item "$idx" "stream")
    STATUS=$(get_item "$idx" "status")
    NORTH_STAR=$(jq -r ".items[$idx].northStar" "$MANIFEST_PATH")
    PLAN_READY=$(jq -r ".items[$idx].planReady" "$MANIFEST_PATH")

    local labels="type:$TYPE stream:$STREAM status:$STATUS"
    if [[ "$NORTH_STAR" == "true" ]]; then labels="$labels north-star"; fi
    if [[ "$PLAN_READY" == "true" ]]; then labels="$labels plan:ready"; fi
    echo "$labels"
}

# --- DRY RUN: render files and exit -------------------------------------------
mkdir -p "$OUT_DIR"

if [[ "$DRY_RUN" == "true" ]]; then
    step "Rendering $ITEM_COUNT issue bodies to $OUT_DIR"
    for ((i=0; i<ITEM_COUNT; i++)); do
        ID=$(get_item "$i" "id")
        CHANGE_ID=$(get_item "$i" "changeId")
        TITLE=$(get_item "$i" "title")
        LABELS=$(get_item_labels "$i")

        BODY=$(render_issue_body "$i")
        echo "$BODY" > "$OUT_DIR/${ID}-${CHANGE_ID}.md"

        STREAM=$(get_item "$i" "stream")
        STREAM_NAME=$(get_stream "$STREAM")
        PREREQS=$(jq -r ".items[$i].prereqs | if length > 0 then join(\", \") else \"none\" end" "$MANIFEST_PATH")

        info "$ID  ->  $TITLE"
        info "       labels: $LABELS"
        info "       milestone: $STREAM_NAME"
        info "       blocked-by: $PREREQS"
    done
    step "Dry run complete. Review the files above, then run without --dry-run."
    exit 0
fi

# --- LIVE: labels -------------------------------------------------------------
step "Ensuring labels"
LABEL_DEFS="type:foundation|1D76DB|Foundation enabler (not user-visible)
type:slice|0E8A16|User-visible vertical slice
stream:A|5319E7|Stream A - Onboarding & access
stream:B|B60205|Stream B - Match loop
stream:C|FBCA04|Stream C - Profile maintenance
status:ready|0E8A16|Ready for /10x-plan
status:proposed|C2E0C6|Proposed; prerequisites pending
status:done|6F42C1|Slice completed and archived
north-star|D93F0B|North-star validation milestone
plan:ready|006B75|Ready to run /10x-plan now"

while IFS='|' read -r name color desc; do
    gh label create "$name" --repo "$REPO" --color "$color" --description "$desc" --force >/dev/null 2>&1 || true
    info "label: $name"
done <<< "$LABEL_DEFS"

# --- LIVE: milestones ---------------------------------------------------------
step "Ensuring milestones"
EXISTING_MS=$(gh api "repos/$REPO/milestones?state=all&per_page=100" 2>/dev/null || echo "[]")

USED_STREAMS=$(jq -r '[.items[].stream] | unique[]' "$MANIFEST_PATH")
for stream in $USED_STREAMS; do
    TITLE=$(get_stream "$stream")
    FOUND=$(echo "$EXISTING_MS" | jq -r ".[] | select(.title == \"$TITLE\") | .number" | head -1)
    if [[ -n "$FOUND" ]]; then
        kv_set "ms_$stream" "$FOUND"
        info "milestone exists: $TITLE (#$FOUND)"
    else
        CREATED=$(gh api "repos/$REPO/milestones" -f title="$TITLE" -f state=open 2>/dev/null | jq -r '.number')
        kv_set "ms_$stream" "$CREATED"
        info "milestone created: $TITLE (#$CREATED)"
    fi
done

# --- LIVE: create pass --------------------------------------------------------
step "Creating issues"
for ((i=0; i<ITEM_COUNT; i++)); do
    ID=$(get_item "$i" "id")
    CHANGE_ID=$(get_item "$i" "changeId")
    TITLE=$(get_item "$i" "title")
    STREAM=$(get_item "$i" "stream")

    # Idempotency: search provenance marker
    EXISTING=$(gh issue list --repo "$REPO" --state all --limit 100 \
        --search "\"roadmap-id: $ID\" in:body" --json number,title 2>/dev/null || echo "[]")
    EXISTING_NUM=$(echo "$EXISTING" | jq -r '.[0].number // empty')

    if [[ -n "$EXISTING_NUM" ]]; then
        kv_set "number_$ID" "$EXISTING_NUM"
        info "$ID  exists  -> #$EXISTING_NUM"
        continue
    fi

    BODY=$(render_issue_body "$i")
    BODY_FILE="$OUT_DIR/${ID}-${CHANGE_ID}.md"
    echo "$BODY" > "$BODY_FILE"

    LABELS=$(get_item_labels "$i")
    MILESTONE=$(get_stream "$STREAM")

    # Build gh args without eval
    set -- gh issue create --repo "$REPO" --title "$TITLE" --body-file "$BODY_FILE" --milestone "$MILESTONE"
    for lbl in $LABELS; do
        set -- "$@" --label "$lbl"
    done

    URL=$("$@" 2>/dev/null)
    if [[ "$URL" =~ /issues/([0-9]+) ]]; then
        kv_set "number_$ID" "${BASH_REMATCH[1]}"
        info "$ID  created -> #${BASH_REMATCH[1]}  $URL"
    else
        echo "Unexpected gh issue create output for $ID: $URL" >&2
        exit 1
    fi
done

# --- LIVE: link pass (re-render with all numbers known) -----------------------
step "Linking dependencies"
for ((i=0; i<ITEM_COUNT; i++)); do
    ID=$(get_item "$i" "id")
    CHANGE_ID=$(get_item "$i" "changeId")

    PREREQ_COUNT=$(jq ".items[$i].prereqs | length" "$MANIFEST_PATH")
    blocks_val=$(kv_get "blocks_$ID")
    BLOCKS_COUNT=0
    if [[ -n "$blocks_val" ]]; then
        BLOCKS_COUNT=$(echo "$blocks_val" | wc -w | tr -d ' ')
    fi

    if [[ "$PREREQ_COUNT" -eq 0 && "$BLOCKS_COUNT" -eq 0 ]]; then
        info "$ID  no deps"
        continue
    fi

    BODY=$(render_issue_body "$i")
    BODY_FILE="$OUT_DIR/${ID}-${CHANGE_ID}.md"
    echo "$BODY" > "$BODY_FILE"

    NUM=$(kv_get "number_$ID")
    gh issue edit "$NUM" --repo "$REPO" --body-file "$BODY_FILE" >/dev/null 2>&1
    info "$ID  #$NUM  links updated"
done

# --- LIVE: label sync pass (ensure labels match manifest status) ---------------
step "Syncing labels"
ALL_STATUS_LABELS="status:ready status:proposed status:done"
for ((i=0; i<ITEM_COUNT; i++)); do
    ID=$(get_item "$i" "id")
    NUM=$(kv_get "number_$ID")
    if [[ -z "$NUM" ]]; then continue; fi

    DESIRED_LABELS=$(get_item_labels "$i")
    STATUS=$(get_item "$i" "status")

    # Remove stale status:* labels, add correct ones
    for sl in $ALL_STATUS_LABELS; do
        gh issue edit "$NUM" --repo "$REPO" --remove-label "$sl" >/dev/null 2>&1 || true
    done
    # Add desired labels
    for lbl in $DESIRED_LABELS; do
        gh issue edit "$NUM" --repo "$REPO" --add-label "$lbl" >/dev/null 2>&1 || true
    done

    # Auto-close issues with status:done
    if [[ "$STATUS" == "done" ]]; then
        gh issue close "$NUM" --repo "$REPO" >/dev/null 2>&1 || true
        info "$ID  #$NUM  labels: $DESIRED_LABELS  [CLOSED]"
    else
        # Reopen if it was previously closed but status changed back
        gh issue reopen "$NUM" --repo "$REPO" >/dev/null 2>&1 || true
        info "$ID  #$NUM  labels: $DESIRED_LABELS"
    fi
done

# --- Summary ------------------------------------------------------------------
step "Done. Summary:"
printf "%-6s %-8s %s\n" "ID" "Issue" "Title"
printf "%-6s %-8s %s\n" "------" "--------" "-----"
for ((i=0; i<ITEM_COUNT; i++)); do
    ID=$(get_item "$i" "id")
    TITLE=$(get_item "$i" "title")
    NUM=$(kv_get "number_$ID")
    printf "%-6s %-8s %s\n" "$ID" "#${NUM:-?}" "$TITLE"
done
