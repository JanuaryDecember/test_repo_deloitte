---
project: "Deloitter"
version: 1
status: draft
created: 2026-06-12
updated: 2026-06-12
prd_version: 1
main_goal: speed
top_blocker: time
---

# Roadmap: Deloitter

> Derived from `context/foundation/prd.md` (v1) + auto-researched codebase baseline.
> Edit-in-place; archive when superseded.
> Slices below are listed in dependency order. The "At a glance" table is the index.

## Vision recap

Deloitter is a Tinder-style internal networking app: a Deloitte employee logs in,
swipes through colleagues ranked by shared interests and competencies, and when two
people like each other they become a mutual match with each other's compatibility
score and contact info revealed. The product's edge is making networking feel
playful and low-stakes — and the mutual opt-in match model removes the awkwardness
of cold outreach. For the MVP this is a hackathon POC on seeded, disposable data:
prove the match loop works and the product works.

## North star

**S-04: User sees a mutual match revealed in Matches (score + contact info)** — this
is the validation milestone, the payoff of the primary Success Criterion ("if this
flow works, the product works"), placed as early as its swipe prerequisite allows
because everything upstream only matters if the match reveal lands.

> "North star" here means the smallest end-to-end slice whose successful delivery
> would prove the core product hypothesis — sequenced as early as its Prerequisites
> permit, because the rest of the roadmap only pays off if this one works.

## At a glance

| ID   | Change ID             | Outcome (user can …)                                               | Prerequisites | PRD refs                                           | Status   |
| ---- | --------------------- | ------------------------------------------------------------------ | ------------- | -------------------------------------------------- | -------- |
| F-01 | persistence-and-seed  | (foundation) Postgres wired + accounts/catalog seeded              | —             | Account provisioning, Data handling NFR            | done     |
| F-02 | auth-login-gate       | (foundation) email+password verified, authenticated session issued | F-01          | FR-001, Access Control                             | done     |
| S-01 | employee-login        | log in with seeded credentials and reach the app                   | F-01, F-02    | FR-001                                             | done     |
| S-02 | select-interests      | pick interests & competencies that drive matching                  | F-01, S-01    | FR-002                                             | done     |
| S-03 | swipe-candidate-stack | swipe like/pass through a stack ranked by shared interests         | F-01, S-02    | FR-003, FR-004, Business Logic, Responsiveness NFR | done     |
| S-04 | mutual-match-reveal   | see mutual matches with revealed score + contact info              | S-03          | FR-005, FR-006, Privacy NFR                        | done     |
| S-05 | edit-interests        | edit interests/competencies after initial setup                    | S-02          | FR-007                                             | proposed |

## Streams

Navigation aid — groups items that share a Prerequisites chain. Canonical ordering still lives in the dependency graph below; this table is the proposed reading order across parallel tracks.

| Stream | Theme               | Chain                    | Note                                                                                         |
| ------ | ------------------- | ------------------------ | -------------------------------------------------------------------------------------------- |
| A      | Onboarding & access | `F-01` → `F-02` → `S-01` | The gate: persistence, seeded accounts, and the login the whole app sits behind.             |
| B      | Match loop          | `S-02` → `S-03` → `S-04` | The north-star path (joins Stream A at `S-01`); strict must-have spine under the speed goal. |
| C      | Profile maintenance | `S-05`                   | Nice-to-have edit; branches from `S-02` (Stream B), parallel with `S-03`/`S-04`.             |

## Baseline

What's already in place in the codebase as of `2026-06-12` (auto-researched + user-confirmed).
Foundations below assume these are present and do NOT re-scaffold them.

- **Frontend:** partial — Vite + React 19 + TypeScript scaffold (`frontend/src/App.tsx`); default bootstrap template, no routes/components/auth UI, no router or component library.
- **Backend / API:** partial — Spring Boot 4.1 / Java 21 with `spring-boot-starter-webmvc` (`backend/pom.xml`, `DeloitterApplication.java`); single application class, zero controllers.
- **Data:** absent — no JPA/JDBC dependency, no PostgreSQL driver, no migration tooling, no entities (shape-notes leans Postgres, but nothing is wired).
- **Auth:** absent — no Spring Security dependency, no auth code paths.
- **Deploy / infra:** absent — no Dockerfile, no `.github/workflows`.
- **Observability:** absent — default Spring Boot logging only.

## Foundations

### F-01: Persistence & seed foundation

- **Outcome:** (foundation) PostgreSQL is connected to the Spring Boot backend, the minimal schema for employee accounts and the predefined interests/competencies catalog exists, and a seed harness populates enough demo employees that mutual matches can occur.
- **Change ID:** persistence-and-seed
- **PRD refs:** Account provisioning note (pre-seeded accounts), Data handling NFR (seeded, disposable demo data), Business Logic (catalog of interests/competencies/background as overlap inputs)
- **Unlocks:** S-01 (login needs seeded accounts), S-02 (interest selection needs the catalog + a profile to write to), S-03 (the candidate stack needs seeded employees to rank). Also reduces the "what's in the seed dataset" unknown so downstream slices are plannable.
- **Prerequisites:** —
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:**
  - How many demo employees and which attribute spread to seed so matches reliably occur in a demo? — Owner: user. Block: no (sensible defaults suffice to start).
- **Risk:** Sequenced first because nothing else is plannable or verifiable without persistence and seeded identities. Scope risk: must stay minimal (accounts + catalog + seed only) — swipe and match tables land in their consuming slices, not here.
- **Status:** ready

### F-02: Auth & login gate

- **Outcome:** (foundation) email+password credentials are verified against seeded accounts, an authenticated session/token is issued, and a route-level guard ensures only an authenticated "me" can use the app (no anonymous browsing).
- **Change ID:** auth-login-gate
- **PRD refs:** FR-001, Access Control (flat user model, auth required; no PII hardening per Non-Goals)
- **Unlocks:** S-01 (the login UI), and the authenticated "me" that every downstream slice (S-02 onward) needs to scope a user's own profile, swipes, and matches.
- **Prerequisites:** F-01
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Deliberately thin — seeded credentials, no security/PII hardening (explicit Non-Goal). Risk is over-engineering it; keep to verify-and-issue-session. Sequenced after F-01 because it verifies against the seeded accounts table.
- **Status:** proposed

## Slices

### S-01: Employee login

- **Outcome:** User can log in with seeded email+password credentials and land in the app.
- **Change ID:** employee-login
- **PRD refs:** FR-001
- **Prerequisites:** F-01, F-02
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Thin gate slice — low risk. Sequenced first among slices because every other slice needs a logged-in identity. The only failure mode is the login UX stalling the demo's first ten seconds.
- **Status:** proposed

### S-02: Select interests & competencies

- **Outcome:** User can pick their interests and competencies from the predefined catalog; selections persist to their profile and become the inputs the compatibility score consumes.
- **Change ID:** select-interests
- **PRD refs:** FR-002
- **Prerequisites:** F-01, S-01
- **Parallel with:** —
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Sequenced before the swipe stack because the score (and the "shared interests" shown on each card) is computed from the logged-in user's own selections — without them the stack has nothing to rank against. Keep the selection UI simple per the speed goal.
- **Status:** proposed

### S-03: Swipe the candidate stack

- **Outcome:** User can view candidate employees one card at a time (each card shows shared interests/competencies; the compatibility score is HIDDEN here) and swipe like or pass; the stack is ordered highest-compatibility-first and transitions feel instant.
- **Change ID:** swipe-candidate-stack
- **PRD refs:** FR-003, FR-004, Business Logic (proportional-overlap scoring drives the ranking), Perceived-responsiveness NFR (< ~300ms card-to-card, no load stall)
- **Prerequisites:** F-01, S-02
- **Parallel with:** S-05
- **Blockers:** —
- **Unknowns:** —
- **Risk:** This is the heaviest slice and the backend-investment focus: it introduces the swipe persistence and the proportional-overlap compatibility computation that ranks the stack. Two things can go wrong — the score is wrong/unexplainable (violating a guardrail), or transitions lag (violating the responsiveness NFR). Sequenced after S-02 because ranking needs the user's own selected attributes.
- **Status:** proposed

### S-04: Mutual match reveal

- **Outcome:** When two users have liked each other the system creates a match, and the user can open a Matches view listing each match with its (now revealed) compatibility score and the matched colleague's contact info, so connection continues over Teams/email.
- **Change ID:** mutual-match-reveal
- **PRD refs:** FR-005, FR-006, Privacy NFR (no rejection signals — intent revealed only on a mutual match)
- **Prerequisites:** S-03
- **Parallel with:** S-05
- **Blockers:** —
- **Unknowns:** —
- **Risk:** The north star and the second backend-investment focus. It introduces match detection and the privacy enforcement that is a hard guardrail: a user must find no way to learn a non-match's intent. Getting the reveal-only-on-mutual-match logic wrong breaks the product's core promise. Sequenced last on the spine because it consumes the likes produced by S-03.
- **Status:** proposed

### S-05: Edit interests & competencies

- **Outcome:** User can edit their interests/competencies after initial setup, changing the inputs that drive their future matches.
- **Change ID:** edit-interests
- **PRD refs:** FR-007
- **Prerequisites:** S-02
- **Parallel with:** S-03, S-04
- **Blockers:** —
- **Unknowns:** —
- **Risk:** Nice-to-have (FR-007) — PRD says build only if the core flow is done. Low risk; runs on its own branch off S-02 and blocks nothing. Under the speed goal it is the first thing to drop if time runs short.
- **Status:** proposed

## Backlog Handoff

| Roadmap ID | Change ID             | Suggested issue title                                   | Ready for `/10x-plan` | Notes                                     |
| ---------- | --------------------- | ------------------------------------------------------- | --------------------- | ----------------------------------------- |
| F-01       | persistence-and-seed  | Wire Postgres + seed demo accounts and interest catalog | yes                   | Run `/10x-plan persistence-and-seed`      |
| F-02       | auth-login-gate       | Email+password verification and authenticated session   | no                    | Needs F-01                                |
| S-01       | employee-login        | Login screen for seeded employees                       | no                    | Needs F-01, F-02                          |
| S-02       | select-interests      | Interest & competency selection from catalog            | no                    | Needs F-01, S-01                          |
| S-03       | swipe-candidate-stack | Ranked candidate stack with like/pass swipe             | no                    | Needs F-01, S-02; backend scoring focus   |
| S-04       | mutual-match-reveal   | Mutual match creation + Matches view with reveal        | no                    | North star; needs S-03; privacy guardrail |
| S-05       | edit-interests        | Edit interests/competencies after setup                 | no                    | Nice-to-have; needs S-02                  |

## Open Roadmap Questions

1. **What are the explicit Given/When/Then user stories?** — Owner: user. Block: roadmap-wide, but non-blocking — the PRD elects the FR list as the acceptance surface; resolve only if downstream review or implementation needs per-story acceptance criteria.
2. **What is the exact hard deadline (hackathon date)?** — Owner: user. Block: roadmap-wide (sets the time budget the whole sequence plans around); resolve before scheduling implementation work.

## Parked

- **In-app chat / messaging** — Why parked: PRD §Non-Goals — the app makes the introduction; conversation continues via Teams/email.
- **Romantic matching** — Why parked: PRD §Non-Goals — strictly professional networking, not dating.
- **Filtering by job title / seniority** — Why parked: PRD §Non-Goals — matching is on interest/competency/background overlap, never on rank.
- **Mobile-native app** — Why parked: PRD §Non-Goals — desktop-browser only for the MVP; no iOS/Android build, no responsive layout.
- **Firm-wide scale** — Why parked: PRD §Non-Goals — pilot scale (dozens–hundred) only; not engineered for 10k+ users.
- **Production security / PII hardening** — Why parked: PRD §Non-Goals — demo runs on disposable data; no production-grade auth/security/compliance.
- **Offline support** — Why parked: PRD §Non-Goals — installable PWA, but offline operation is out of scope.

## Done

(Empty on first generation. `/10x-archive` appends entries here when a change whose `Change ID` matches a roadmap item is archived.)
