#
# Roadmap -> GitHub issues manifest.
#
# Single source the deploy script (scripts/deploy-roadmap-issues.ps1) renders issue
# bodies from. This is a machine mirror of context/foundation/roadmap.md: when the
# roadmap changes, update the matching record here and re-run the deploy (it is
# idempotent, so existing issues are skipped).
#
# Field notes:
#   Id          roadmap ID (F-01, S-04, ...) - also the provenance key in each issue.
#   ChangeId    feeds `/10x-plan <ChangeId>` and context/changes/<ChangeId>/.
#   Type        foundation | slice  -> type:* label.
#   Stream      A | B | C           -> stream:* label + milestone.
#   Prereqs     array of roadmap IDs -> rendered as `Blocked by #N`.
#   Parallel    array of roadmap IDs -> rendered verbatim under Dependencies.
#   Guardrail   optional extra acceptance line for hard product guardrails.
#   `Blocks` is NOT stored - it is derived as the reverse of every Prereqs edge.
#
@{
    RoadmapVersion = 1
    Streams = @{
        A = 'Stream A - Onboarding & access'
        B = 'Stream B - Match loop'
        C = 'Stream C - Profile maintenance'
    }
    Items = @(
        @{
            Id       = 'F-01'
            ChangeId = 'persistence-and-seed'
            Type     = 'foundation'
            Stream   = 'A'
            Title    = 'Wire Postgres + seed demo accounts and interest catalog'
            Outcome  = 'PostgreSQL is connected to the Spring Boot backend, the minimal schema for employee accounts and the predefined interests/competencies catalog exists, and a seed harness populates enough demo employees that mutual matches can occur.'
            PrdRefs  = 'Account provisioning note, Data handling NFR, Business Logic'
            Status   = 'ready'
            PlanReady = $true
            NorthStar = $false
            Prereqs  = @()
            Parallel = @()
            Risk     = 'Sequenced first because nothing else is plannable or verifiable without persistence and seeded identities. Scope risk: must stay minimal (accounts + catalog + seed only) - swipe and match tables land in their consuming slices, not here.'
            Guardrail = 'Seed dataset produces at least one reliable mutual match in a demo run.'
        }
        @{
            Id       = 'F-02'
            ChangeId = 'auth-login-gate'
            Type     = 'foundation'
            Stream   = 'A'
            Title    = 'Email+password verification and authenticated session'
            Outcome  = 'email+password credentials are verified against seeded accounts, an authenticated session/token is issued, and a route-level guard ensures only an authenticated "me" can use the app (no anonymous browsing).'
            PrdRefs  = 'FR-001, Access Control'
            Status   = 'proposed'
            PlanReady = $false
            NorthStar = $false
            Prereqs  = @('F-01')
            Parallel = @()
            Risk     = 'Deliberately thin - seeded credentials, no security/PII hardening (explicit Non-Goal). Risk is over-engineering it; keep to verify-and-issue-session.'
            Guardrail = 'No anonymous browsing: every app route requires an authenticated session.'
        }
        @{
            Id       = 'S-01'
            ChangeId = 'employee-login'
            Type     = 'slice'
            Stream   = 'A'
            Title    = 'Login screen for seeded employees'
            Outcome  = 'User can log in with seeded email+password credentials and land in the app.'
            PrdRefs  = 'FR-001'
            Status   = 'proposed'
            PlanReady = $false
            NorthStar = $false
            Prereqs  = @('F-01','F-02')
            Parallel = @()
            Risk     = 'Thin gate slice - low risk. Sequenced first among slices because every other slice needs a logged-in identity. The only failure mode is the login UX stalling the demo''s first ten seconds.'
            Guardrail = ''
        }
        @{
            Id       = 'S-02'
            ChangeId = 'select-interests'
            Type     = 'slice'
            Stream   = 'B'
            Title    = 'Interest & competency selection from catalog'
            Outcome  = 'User can pick their interests and competencies from the predefined catalog; selections persist to their profile and become the inputs the compatibility score consumes.'
            PrdRefs  = 'FR-002'
            Status   = 'proposed'
            PlanReady = $false
            NorthStar = $false
            Prereqs  = @('F-01','S-01')
            Parallel = @()
            Risk     = 'Sequenced before the swipe stack because the score (and the "shared interests" shown on each card) is computed from the logged-in user''s own selections - without them the stack has nothing to rank against. Keep the selection UI simple per the speed goal.'
            Guardrail = ''
        }
        @{
            Id       = 'S-03'
            ChangeId = 'swipe-candidate-stack'
            Type     = 'slice'
            Stream   = 'B'
            Title    = 'Ranked candidate stack with like/pass swipe'
            Outcome  = 'User can view candidate employees one card at a time (each card shows shared interests/competencies; the compatibility score is HIDDEN here) and swipe like or pass; the stack is ordered highest-compatibility-first and transitions feel instant.'
            PrdRefs  = 'FR-003, FR-004, Business Logic, Perceived-responsiveness NFR'
            Status   = 'proposed'
            PlanReady = $false
            NorthStar = $false
            Prereqs  = @('F-01','S-02')
            Parallel = @('S-05')
            Risk     = 'Heaviest slice and backend-investment focus: introduces swipe persistence and the proportional-overlap compatibility computation that ranks the stack. Two failure modes - the score is wrong/unexplainable (violating a guardrail), or transitions lag (violating the responsiveness NFR).'
            Guardrail = 'Compatibility score is hidden on cards; card-to-card transition stays under ~300ms with no load stall.'
        }
        @{
            Id       = 'S-04'
            ChangeId = 'mutual-match-reveal'
            Type     = 'slice'
            Stream   = 'B'
            Title    = 'Mutual match creation + Matches view with reveal'
            Outcome  = 'When two users have liked each other the system creates a match, and the user can open a Matches view listing each match with its (now revealed) compatibility score and the matched colleague''s contact info, so connection continues over Teams/email.'
            PrdRefs  = 'FR-005, FR-006, Privacy NFR'
            Status   = 'proposed'
            PlanReady = $false
            NorthStar = $true
            Prereqs  = @('S-03')
            Parallel = @('S-05')
            Risk     = 'The north star and second backend-investment focus. Introduces match detection and the privacy enforcement that is a hard guardrail. Getting reveal-only-on-mutual-match wrong breaks the product''s core promise.'
            Guardrail = 'A user can find no way to learn a non-match''s intent - score + contact info reveal only on a mutual match.'
        }
        @{
            Id       = 'S-05'
            ChangeId = 'edit-interests'
            Type     = 'slice'
            Stream   = 'C'
            Title    = 'Edit interests/competencies after setup'
            Outcome  = 'User can edit their interests/competencies after initial setup, changing the inputs that drive their future matches.'
            PrdRefs  = 'FR-007'
            Status   = 'proposed'
            PlanReady = $false
            NorthStar = $false
            Prereqs  = @('S-02')
            Parallel = @('S-03','S-04')
            Risk     = 'Nice-to-have (FR-007) - PRD says build only if the core flow is done. Low risk; runs on its own branch off S-02 and blocks nothing. Under the speed goal it is the first thing to drop if time runs short.'
            Guardrail = ''
        }
    )
}
