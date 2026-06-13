> **Archived:** 2026-06-13 00:00 | Change ID: `select-interests` | Roadmap ID: `S-02`

# Plan Brief: Select interests & competencies

**Change ID:** `select-interests` | **Roadmap ID:** `S-02` | **Status:** draft

## What

Delivers the Profile page where a logged-in user can view and toggle their interests and competencies from the predefined catalog using chip-toggle pills (matching the design comp), persist selections to the backend, and navigate to the page via the "Profile" tab in the app shell. These selections become the inputs that drive the compatibility score in S-03.

## Phases at a glance

| #   | Phase                   | Backend | Frontend | Key deliverable                                                                                      |
| --- | ----------------------- | ------- | -------- | ---------------------------------------------------------------------------------------------------- |
| 1   | Catalog & selection API | ✓       | —        | `GET /api/catalog`, `GET /api/profile`, `GET /api/profile/selections`, `PUT /api/profile/selections` |
| 2   | API client extensions   | —       | ✓        | Typed fetch functions + profile/catalog types                                                        |
| 3   | Profile page UI         | —       | ✓        | Chip-toggle selection page matching design comp                                                      |
| 4   | Routing & navigation    | —       | ✓        | Profile tab wired, route added, active-tab indicator                                                 |
| 5   | Polish & accessibility  | —       | ✓        | Loading states, `aria-pressed`, keyboard focus, toast                                                |

## Key decisions

- **Single `PUT /api/profile/selections`** replaces all selections atomically — no per-toggle API calls; the user toggles locally and saves once
- **`GET /api/catalog`** returns both interests and competencies in one call (small catalog, ~30 items total)
- **No minimum selection enforcement** — user may save with 0 selections; S-03 handles empty gracefully
- **Design-comp-exact chip toggles**: green (oklch 0.70/0.16/145) = selected, white = unselected, 999px border-radius pill shape
- **Explicit save button** (not auto-save) — matches design comp and keeps UX predictable
- **Toast feedback** ("Profile updated") on successful save — reusable Toast component for later slices
- **Profile endpoint (`GET /api/profile`)** returns employee details for the header card, separate from auth's `/me`

## Risks & mitigations

| Risk                                                         | Mitigation                                                                               |
| ------------------------------------------------------------ | ---------------------------------------------------------------------------------------- |
| Prerequisites (F-01, S-01) not yet fully implemented in code | Plan assumes they are done; phases are independently verifiable once prerequisites land  |
| Catalog grows beyond ~30 items → chip wall becomes unwieldy  | Design shows ~15+~10 items; if it grows, group by category in a future iteration         |
| User navigates away with unsaved changes → data loss         | Acceptable for POC speed goal; no blocking modals; data is demo-only                     |
| `employee` table lacks `office` column shown in design       | Use `service_line` + `role_family` in the header card; add office column later if needed |

## Estimated effort

**M (Medium)** — One backend controller with simple CRUD logic (no scoring, no privacy-sensitive logic), one frontend page with chip components and basic state management. Moderate because it touches both tiers and requires design-comp-fidelity styling, but no algorithmic complexity. Estimated 1–2 focused sessions.
