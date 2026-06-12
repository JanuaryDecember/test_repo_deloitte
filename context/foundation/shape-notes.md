---
project: "Deloitter"
context_type: greenfield
created: 2026-06-12
updated: 2026-06-12
quality_cross_check: accepted (all elements present; no gaps)
checkpoint:
  current_phase: 8
  phases_completed: [1, 2, 3, 4, 5, 6, 7]
  gray_areas_resolved: [pain-category, trigger-moment, insight, auth-model, role-model, mvp-flow, timeline, secondary, guardrails, accounts, interests-input, user-stories, business-logic, nfrs, product-type, scale, non-goals]
  frs_drafted: 7
  quality_check_status: accepted
product_type: web-app
target_scale:
  users: medium
timeline_budget:
  mvp_weeks: 1
  hard_deadline: null   # fixed hackathon date, exact day TBD
  after_hours_only: false   # focused effort during the hackathon event
---

# Shape Notes — Deloitter

> Seed idea (verbatim, from idea.md): A Tinder-style app that connects people
> with similar interests or competencies. The target user is a Deloitte employee
> who wants to meet people within their organization.

<!-- Sections below are filled phase by phase. They anticipate the greenfield
     PRD schema (10 sections) so /10x-prd can map cleanly. -->

## Vision & Problem Statement

In a firm the size of Deloitte, the colleague who shares your interests or has the
competency you need is almost certainly already inside the organization — but there
is no low-friction way to discover them. People stay siloed by office and current
project, no system surfaces what they have in common, and cold outreach over
Teams/email feels too awkward to attempt. As a result, employees fall back on their
immediate team or never connect at all.

**Pain (what blocks internal connection today):**
- No discovery mechanism — you can only network with people you already know.
- No shared-interest signal — even when you meet someone, you don't know what you
  have in common (hobbies, expertise, background).
- Siloed by office/project — people stay locked inside their service line, office,
  or current engagement.
- Too high-friction to reach out — cold-messaging a stranger lacks a shared signal
  or mutual opt-in, so it rarely happens.

**Trigger moments (when the need is felt):**
- Between projects / on the bench — looking for the next engagement and for teams
  or people to work with.
- Wanting community — colleagues who share an interest, for belonging rather than
  a specific work task.

**Insight (the edge over org chart / Teams / LinkedIn):**
Playful, low-stakes swiping makes networking feel light and fun, so people actually
do it — versus the perpetual "I should network someday" that never converts. The
mutual opt-in match model removes the awkwardness of cold outreach.

## User & Persona

**Primary persona — The connection-seeking employee**
- Who: any Deloitte employee motivated to expand their network inside the firm
  (not limited to a single role, service line, or seniority).
- Scope: individuals across the whole organization, opting in personally.
- Goal: discover and connect with colleagues who share interests or competencies,
  without the friction of cold outreach.

## Access Control

Employees sign in with an **email + password account**. Authentication is required
to use the app (no anonymous browsing of other employees).

- User model: **flat** — every user is an equal employee. No admin, member, or
  guest tiers in the MVP. All users swipe, match, and view matches identically.
- Identity is per-individual; each employee opts in with their own account.

> Smallest viable access model: a single flat user type behind login is enough to
> make the MVP useful — matching only has meaning between authenticated identities.

## Success Criteria

### Primary
The end-to-end match flow works: a user logs in, swipes through a stack of other
employees (each card showing shared interests/competencies and a compatibility
score), and when two users like each other they become a mutual **match**, visible
in a Matches view. If this flow works, the product works.

First-session sequence:
1. User logs in (email + password).
2. User sees a candidate card — another employee with shared interests &
   competencies and a compatibility score.
3. User swipes like or pass.
4. Repeat through the candidate stack.
5. Two users who liked each other become a match.
6. User opens the Matches view listing their matches with compatibility scores.

### Secondary
- Users can edit their own profile — the interests & competencies that drive their
  matches. (Build only if core flow is done.)

### Guardrails (must not break)
- **No mutual reveal without a match** — a user never learns that someone passed or
  liked them; identities/intent are revealed only on a mutual match.
- **Compatibility score is explainable** — the score reflects actual shared
  interests/competencies, not a black-box or random number.
- **Swipe feels instant** — card-to-card transitions are snappy, no laggy load
  between swipes.

## Functional Requirements

- FR-001: User can log in with email + password. Priority: must-have
  > Socrates: Counter-argument considered: "pre-seeded accounts make real auth
  > optional — a user-picker would do." Resolution: kept; login proves identity,
  > is called out in idea.md as POC value, and matching needs a logged-in 'me'.
- FR-002: User can select their interests and competencies from a predefined list. Priority: must-have
  > Socrates: Counter-argument considered: "seeded profiles could ship interests
  > pre-set; no selection UI needed." Resolution: kept; user-driven selection makes
  > the demo interactive and the compatibility score feel earned.
- FR-003: User can view candidate employees one card at a time, each card showing shared interests/competencies. The compatibility score is HIDDEN here and revealed only on a match (see FR-006). Priority: must-have
  > Socrates: Counter-argument considered: "showing the score on the card biases
  > swiping — people chase high numbers, killing organic discovery." Resolution:
  > REVISED — score hidden on the card; swiping is on shared interests alone, and
  > the score becomes the reveal/payoff at match time.
- FR-004: User can swipe like or pass on a candidate. Priority: must-have
  > Socrates: Counter-argument considered: "a swipe is just a like/pass button;
  > the gesture isn't worth the build." Resolution: kept; the playful swipe IS the
  > insight (low-stakes framing) and the core pitch.
- FR-005: System creates a match when two users have liked each other. Priority: must-have
  > Socrates: Counter-argument considered: "mutual-like gating means a cold-start
  > app with zero matches." Resolution: kept mutual-like only; seed enough demo
  > users that matches occur. A one-way 'interested' signal was rejected because it
  > would break the no-mutual-reveal guardrail.
- FR-006: User can view their list of matches, each showing the compatibility score and the matched colleague's contact info (e.g., Teams/email handle) so connection can continue outside the app. Priority: must-have
  > Socrates: Counter-argument considered: "with chat a non-goal, the matches list
  > is a dead end." Resolution: REVISED — on match, reveal name + contact info so
  > the user can reach out via existing channels; the app is the introduction, not
  > the conversation.
- FR-007: User can edit their interests/competencies after initial setup. Priority: nice-to-have
  > Socrates: Counter-argument considered: "if interests are picked once, edit is
  > unneeded." Resolution: kept as nice-to-have — optional, build only if the core
  > flow is done.

> Account provisioning: accounts are **pre-seeded** into the database for the
> demo (no self-registration in the MVP). Login (FR-001) still required. Profiles
> may be seeded with baseline data; users select/refine interests via FR-002.

## User Stories

> The user opted to skip explicit Given/When/Then user stories for the MVP — the
> FR list above is the acceptance surface. /10x-prd may infer stories if needed.

## Business Logic

**Domain rule (one sentence):** Deloitter scores how compatible two employees are
by the proportional overlap of their interests, competencies, and professional
background, and surfaces the highest-compatibility colleagues first to swipe on.

Supporting detail:
- **Inputs the rule consumes:** a user's selected interests, selected competencies,
  and common professional background (e.g., shared service line / role family /
  career path). All three are treated as *overlap* signals — shared attributes
  raise the score. Complementary (non-overlapping) skills are explicitly out of
  scope for the MVP.
- **Output:** a single compatibility score per pair of employees, expressing how
  much of what they could share they actually share (proportional overlap — two
  people sharing 4 of 5 attributes score higher than 4 of 20). This keeps the
  score *explainable* per the guardrail.
- **How the user encounters it:** the candidate stack is ordered highest
  compatibility first, so the best potential connections appear earliest. The
  score itself is hidden while swiping (FR-003) and revealed as the payoff on a
  mutual match (FR-006).

## Non-Functional Requirements

- **Perceived responsiveness:** swiping feels instant — user-perceived card-to-card
  response stays fast (target ≈ < 300ms), with no visible load stall between cards.
- **Privacy — no rejection signals:** the system never exposes who passed on or
  liked whom; only mutual matches are ever revealed to either party. Externally
  observable: a user can find no way to learn a non-match's intent.
- **Platform reach:** runs in a modern desktop/laptop web browser for the demo;
  mobile/responsive layout is not a requirement for the MVP.
- **Data handling:** demo runs on seeded, disposable data — profiles and matches
  are demo content wiped after the hackathon; no real-employee PII commitment for
  the POC.

## Non-Goals

Functional non-goals (capabilities the MVP will NOT build):
- **No in-app chat / messaging** — the app makes the introduction; conversation
  continues via existing channels (Teams/email). Connection ≠ conversation.
- **Not romantic matching** — strictly professional networking between colleagues,
  not dating.
- **No filtering by job title / seniority** — matching is on interest/competency/
  background overlap, never on rank; the app does not discriminate connections by
  title or competency level.
- **No mobile-native app** — desktop-browser PWA only; no iOS/Android native build.

Non-functional non-goals (quality dimensions the MVP will NOT aim for):
- **No firm-wide scale** — pilot scale (dozens–hundred) only; not engineered for
  10k+ users.
- **No production security / PII hardening** — demo runs on disposable data; no
  production-grade auth/security/compliance for the POC.
- **No offline support** — installable PWA, but offline operation is out of scope.

## Forward: tech-stack

> Informational hand-off for /10x-tech-stack-selector — NOT part of the PRD schema.
- **Architecture lean:** delivered as an **API backend + PWA frontend** (user's
  stated product shape). Product type recorded as web-app in the PRD; the api/pwa
  split is a stack decision for downstream.
- User mentioned (idea.md): credentials stored in a **PostgreSQL** database for the
  POC. Captured here as a stack lean, not committed in the PRD.
- A real deployment would likely prefer Deloitte SSO over self-managed credentials;
  email + password is a deliberate hackathon-MVP simplification.
