# Plan Brief: Employee login

**Change ID:** `employee-login` | **Roadmap ID:** `S-01` | **Status:** revised

## What

A polished, design-comp-accurate login page and authenticated app shell. The login page features a centered card with Deloitter branding, email+password form, error handling, and the exact typography/colors from the design reference (`Figtree` font, oklch green palette, decorative blurred circles). After login, the user lands in an app shell with a sticky header (logo + nav tabs + user avatar) — the structure all future slices render within.

## Phases at a glance

| # | Phase | Backend | Frontend | Key deliverable |
|---|-------|---------|----------|-----------------|
| 1 | Global styles & design tokens | — | ✓ | Figtree font loaded, CSS custom properties, global resets matching design comp |
| 2 | Login page | — | ✓ | Real login form replacing F-02 placeholder — pixel-match to design comp |
| 3 | App shell & authenticated landing | — | ✓ | Sticky header with nav tabs + avatar, welcome page, logout |
| 4 | Polish & accessibility | — | ✓ | Autofocus, loading states, page titles, keyboard a11y, focus ring |

## Key decisions

- **Figtree font** (Google Fonts CDN) — matches design comp exactly
- **oklch color tokens** extracted from design as CSS custom properties for consistency
- **No component library** — bespoke styles match the design precisely; a library would fight it
- **CSS modules** for scoped, per-component styles
- **App shell header** from design (logo + Discover/Matches/Profile tabs + avatar) — tabs are visual placeholders until S-02+
- **Design reference is authoritative**: `frontend/context/foundation/design/Deloitter.dc.html` — all dimensions, colors, radii, and shadows are taken directly from it

## Risks & mitigations

- **Low risk overall** — this is a frontend-only UI slice on top of proven F-02 infrastructure
- **Design fidelity** — mitigated by extracting exact values from the HTML mock; verification includes visual comparison with screenshots
- **Only failure mode** (from roadmap): the login UX stalling the demo's first ten seconds → mitigated by keeping the form focused and submit fast

## Estimated effort

**S (Small)** — Primarily frontend: one login page, one shell component, one welcome page, CSS modules and tokens. No backend work. All auth plumbing (API client, context, route guard) is already in place from F-02. Estimated at 2–3 hours of implementation.

