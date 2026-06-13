#Requires -Version 7.0
<#
.SYNOPSIS
    Deploy context/foundation/roadmap.md slices as ordered, linked GitHub issues.

.DESCRIPTION
    Reads the manifest at .github/roadmap-issues.json (a machine mirror of the roadmap),
    then creates labels, one milestone per stream, and one issue per roadmap item -
    wiring `Blocked by` / `Blocks` dependency links between them.

    Idempotent: labels use --force, milestones are looked up before creation, and each
    issue carries a `<!-- roadmap-id: <ID> -->` provenance marker that is searched on
    re-run so issues are never duplicated.

.PARAMETER DryRun
    Render every issue body to .github/roadmap-issues/<ID>-<change-id>.md and print the
    plan WITHOUT touching GitHub. Dependency numbers appear as roadmap-ID placeholders.

.PARAMETER Repo
    owner/repo override. Defaults to the GitHub slug parsed from `git remote get-url origin`.

.PARAMETER ManifestPath
    Path to the manifest. Defaults to .github/roadmap-issues.json next to this repo root.

.EXAMPLE
    pwsh -File scripts/deploy-roadmap-issues.ps1 -DryRun
    pwsh -File scripts/deploy-roadmap-issues.ps1
#>
[CmdletBinding()]
param(
    [switch] $DryRun,
    [string] $Repo,
    [string] $ManifestPath
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# --- Paths -------------------------------------------------------------------
$RepoRoot   = Resolve-Path (Join-Path $PSScriptRoot '..')
$OutDir     = Join-Path $RepoRoot '.github/roadmap-issues'
if (-not $ManifestPath) { $ManifestPath = Join-Path $RepoRoot '.github/roadmap-issues.json' }

function Write-Step { param([string]$m) Write-Host "==> $m" -ForegroundColor Cyan }
function Write-Info { param([string]$m) Write-Host "    $m" -ForegroundColor DarkGray }

# --- Preflight ---------------------------------------------------------------
if (-not (Test-Path $ManifestPath)) { throw "Manifest not found: $ManifestPath" }
$raw      = Get-Content -Raw -Path $ManifestPath | ConvertFrom-Json
# Normalize JSON object to hashtable-like access for downstream code
$manifest = @{
    RoadmapVersion = $raw.roadmapVersion
    Streams        = @{}
    Items          = @()
}
foreach ($prop in $raw.streams.PSObject.Properties) { $manifest.Streams[$prop.Name] = $prop.Value }
foreach ($item in $raw.items) {
    $manifest.Items += @{
        Id        = $item.id
        ChangeId  = $item.changeId
        Type      = $item.type
        Stream    = $item.stream
        Title     = $item.title
        Outcome   = $item.outcome
        PrdRefs   = $item.prdRefs
        Status    = $item.status
        PlanReady = $item.planReady
        NorthStar = $item.northStar
        Prereqs   = @($item.prereqs)
        Parallel  = @($item.parallel)
        Risk      = $item.risk
        Guardrail = $item.guardrail
    }
}
$items = $manifest.Items
if (-not $items) { throw "Manifest has no Items." }

if (-not $DryRun) {
    if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
        throw "gh CLI not found. Install it (winget install GitHub.cli) and run 'gh auth login', or use -DryRun."
    }
    & gh auth status 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) { throw "gh is not authenticated. Run 'gh auth login' first." }

    if (-not $Repo) {
        $url = (& git -C $RepoRoot remote get-url origin).Trim()
        if ($url -match 'github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)') {
            $Repo = "$($Matches.owner)/$($Matches.repo)"
        } else {
            throw "Could not parse owner/repo from origin url: $url. Pass -Repo owner/repo."
        }
    }
    Write-Step "Target repo: $Repo"
} else {
    Write-Step "DRY RUN - no GitHub calls will be made."
}

# --- Derive the reverse dependency edge (Blocks) -----------------------------
# Blocks(X) = every item whose Prereqs contains X.
$blocksMap = @{}
foreach ($it in $items) { $blocksMap[$it.Id] = @() }
foreach ($it in $items) {
    foreach ($p in $it.Prereqs) {
        if ($blocksMap.ContainsKey($p)) { $blocksMap[$p] += $it.Id }
    }
}

# --- Label & milestone definitions -------------------------------------------
$labelDefs = @(
    @{ name = 'type:foundation'; color = '1D76DB'; desc = 'Foundation enabler (not user-visible)' }
    @{ name = 'type:slice';      color = '0E8A16'; desc = 'User-visible vertical slice' }
    @{ name = 'stream:A';        color = '5319E7'; desc = 'Stream A - Onboarding & access' }
    @{ name = 'stream:B';        color = 'B60205'; desc = 'Stream B - Match loop' }
    @{ name = 'stream:C';        color = 'FBCA04'; desc = 'Stream C - Profile maintenance' }
    @{ name = 'status:ready';    color = '0E8A16'; desc = 'Ready for /10x-plan' }
    @{ name = 'status:proposed'; color = 'C2E0C6'; desc = 'Proposed; prerequisites pending' }
    @{ name = 'status:done';     color = '6F42C1'; desc = 'Slice completed and archived' }
    @{ name = 'north-star';      color = 'D93F0B'; desc = 'North-star validation milestone' }
    @{ name = 'plan:ready';      color = '006B75'; desc = 'Ready to run /10x-plan now' }
)

# --- Body renderer (THE template) --------------------------------------------
# $numberMap: Id -> issue number (may be partial). Unknown ids render as `<ID>`.
function Format-Ref {
    param([string]$Id, [hashtable]$NumberMap)
    if ($NumberMap.ContainsKey($Id)) { return "#$($NumberMap[$Id])" }
    return "``$Id``"
}

function Format-IssueBody {
    param([hashtable]$Item, [hashtable]$NumberMap)

    $streamName = $manifest.Streams[$Item.Stream]
    $blockedBy  = if ($Item.Prereqs.Count) { ($Item.Prereqs       | ForEach-Object { Format-Ref $_ $NumberMap }) -join ', ' } else { 'none' }
    $blocks     = if ($blocksMap[$Item.Id].Count) { ($blocksMap[$Item.Id] | ForEach-Object { Format-Ref $_ $NumberMap }) -join ', ' } else { 'none' }
    $parallel   = if ($Item.Parallel.Count) { ($Item.Parallel | ForEach-Object { "``$_``" }) -join ', ' } else { 'none' }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("## $($Item.Id) · ``$($Item.ChangeId)``")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("> Auto-generated from ``context/foundation/roadmap.md`` (v$($manifest.RoadmapVersion)).")
    [void]$sb.AppendLine("> The roadmap is the source of truth - edit it, update ``.github/roadmap-issues.psd1``, then re-run the deploy.")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("**Outcome:** $($Item.Outcome)")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("| Field | Value |")
    [void]$sb.AppendLine("| --- | --- |")
    [void]$sb.AppendLine("| Stream | $streamName |")
    [void]$sb.AppendLine("| Type | $($Item.Type) |")
    [void]$sb.AppendLine("| PRD refs | $($Item.PrdRefs) |")
    [void]$sb.AppendLine("| Status | $($Item.Status) |")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("### Dependencies")
    [void]$sb.AppendLine("- **Blocked by:** $blockedBy")
    [void]$sb.AppendLine("- **Blocks:** $blocks")
    [void]$sb.AppendLine("- **Parallel with:** $parallel")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("### Why / risk")
    [void]$sb.AppendLine($Item.Risk)
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("### Acceptance")
    [void]$sb.AppendLine("- [ ] Outcome above is demonstrable end-to-end on seeded data")
    [void]$sb.AppendLine("- [ ] PRD refs satisfied: $($Item.PrdRefs)")
    if ($Item.Guardrail) { [void]$sb.AppendLine("- [ ] $($Item.Guardrail)") }
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("### Next step")
    [void]$sb.AppendLine("Run ``/10x-plan $($Item.ChangeId)`` -> produces ``context/changes/$($Item.ChangeId)/plan.md``.")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("<!-- roadmap-id: $($Item.Id) | change-id: $($Item.ChangeId) | managed-by: deploy-roadmap-issues.ps1 -->")
    return $sb.ToString()
}

function Get-ItemLabels {
    param([hashtable]$Item)
    $labels = @("type:$($Item.Type)", "stream:$($Item.Stream)", "status:$($Item.Status)")
    if ($Item.NorthStar) { $labels += 'north-star' }
    if ($Item.PlanReady) { $labels += 'plan:ready' }
    return $labels
}

# --- DRY RUN: render files and exit ------------------------------------------
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
if ($DryRun) {
    Write-Step "Rendering $($items.Count) issue bodies to $OutDir"
    foreach ($it in $items) {
        $body = Format-IssueBody -Item $it -NumberMap @{}
        $file = Join-Path $OutDir "$($it.Id)-$($it.ChangeId).md"
        Set-Content -Path $file -Value $body -Encoding utf8
        $labels = (Get-ItemLabels $it) -join ', '
        Write-Info "$($it.Id)  ->  $($it.Title)"
        Write-Info "       labels: $labels"
        Write-Info "       milestone: $($manifest.Streams[$it.Stream])"
        Write-Info "       blocked-by: $(if ($it.Prereqs.Count) { $it.Prereqs -join ', ' } else { 'none' })"
    }
    Write-Step "Dry run complete. Review the files above, then run without -DryRun."
    return
}

# --- LIVE: labels ------------------------------------------------------------
Write-Step "Ensuring labels"
foreach ($l in $labelDefs) {
    & gh label create $l.name --repo $Repo --color $l.color --description $l.desc --force 1>$null 2>$null
    Write-Info "label: $($l.name)"
}

# --- LIVE: milestones (one per used stream) ----------------------------------
Write-Step "Ensuring milestones"
$existingMs = @(& gh api "repos/$Repo/milestones?state=all&per_page=100" | ConvertFrom-Json)
$msNumber = @{}   # stream letter -> milestone number
foreach ($stream in ($items.Stream | Select-Object -Unique)) {
    $title = $manifest.Streams[$stream]
    $found = $existingMs | Where-Object { $_.title -eq $title } | Select-Object -First 1
    if ($found) {
        $msNumber[$stream] = $found.number
        Write-Info "milestone exists: $title (#$($found.number))"
    } else {
        $created = & gh api "repos/$Repo/milestones" -f title=$title -f state=open | ConvertFrom-Json
        $msNumber[$stream] = $created.number
        Write-Info "milestone created: $title (#$($created.number))"
    }
}

# --- LIVE: create pass (manifest order) --------------------------------------
Write-Step "Creating issues"
$numberMap = @{}   # roadmap Id -> issue number
foreach ($it in $items) {
    # Idempotency: search the provenance marker.
    $existing = @(& gh issue list --repo $Repo --state all --limit 100 `
        --search "`"roadmap-id: $($it.Id)`" in:body" --json number,title | ConvertFrom-Json)
    if ($existing.Count -gt 0) {
        $numberMap[$it.Id] = $existing[0].number
        Write-Info "$($it.Id)  exists  -> #$($existing[0].number)"
        continue
    }

    $body  = Format-IssueBody -Item $it -NumberMap $numberMap
    $file  = Join-Path $OutDir "$($it.Id)-$($it.ChangeId).md"
    Set-Content -Path $file -Value $body -Encoding utf8

    $ghArgs = @('issue','create','--repo',$Repo,'--title',$it.Title,'--body-file',$file,
                '--milestone',$manifest.Streams[$it.Stream])
    foreach ($lbl in (Get-ItemLabels $it)) { $ghArgs += @('--label',$lbl) }

    $url = (& gh @ghArgs).Trim()
    if ($url -match '/issues/(?<n>\d+)') {
        $numberMap[$it.Id] = [int]$Matches.n
        Write-Info "$($it.Id)  created -> #$($Matches.n)  $url"
    } else {
        throw "Unexpected gh issue create output for $($it.Id): $url"
    }
}

# --- LIVE: link pass (resolve Blocked by / Blocks now all numbers known) -----
Write-Step "Linking dependencies"
foreach ($it in $items) {
    $hasDeps = $it.Prereqs.Count -gt 0 -or $blocksMap[$it.Id].Count -gt 0
    if (-not $hasDeps) { Write-Info "$($it.Id)  no deps"; continue }

    $body = Format-IssueBody -Item $it -NumberMap $numberMap
    $file = Join-Path $OutDir "$($it.Id)-$($it.ChangeId).md"
    Set-Content -Path $file -Value $body -Encoding utf8
    & gh issue edit $numberMap[$it.Id] --repo $Repo --body-file $file 1>$null
    Write-Info "$($it.Id)  #$($numberMap[$it.Id])  links updated"
}

# --- Summary -----------------------------------------------------------------
Write-Step "Done. Summary:"
$items | ForEach-Object {
    [pscustomobject]@{
        Id        = $_.Id
        Issue     = "#$($numberMap[$_.Id])"
        Title     = $_.Title
        BlockedBy = if ($_.Prereqs.Count) { ($_.Prereqs | ForEach-Object { "#$($numberMap[$_])" }) -join ',' } else { '-' }
    }
} | Format-Table -AutoSize
