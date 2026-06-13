---
change_id: "employee-login"
roadmap_id: "S-01"
status: revised
created: 2026-06-13
prd_refs: [FR-001]
prerequisites: [F-01 persistence-and-seed, F-02 auth-login-gate]
---

# Plan: Employee login

## Context

This is the first user-facing slice. It delivers the real login page — a styled email+password form matching the design comp — so that a Deloitte employee can log in with seeded credentials and land in the authenticated app shell. It replaces the verification-only LoginPlaceholder from F-02.

Sequenced after F-01 and F-02 because it depends on seeded accounts in Postgres (F-01) and the backend auth endpoints + frontend auth plumbing — API client, AuthContext, ProtectedRoute, React Router (F-02). Every downstream slice (S-02 onward) requires a logged-in identity, making this the gate that must work before any feature is reachable.

**Assumes F-01 and F-02 are fully implemented:** Postgres running with seeded employees (BCrypt `password123`), backend `POST /api/auth/login` + `GET /api/auth/me` + `POST /api/auth/logout` working, frontend has React Router, AuthContext/AuthProvider, ProtectedRoute, typed API client (`login`, `logout`, `fetchMe`), and routing structure with `/login` path and a protected `/` path.

**Design reference:** `frontend/context/foundation/design/Deloitter.dc.html` — the authoritative visual spec. This plan implements the Login screen and the App Shell header exactly as defined there.

## Decisions & Assumptions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| 1 | Font | **Figtree** (Google Fonts, weights 400–900) | Matches design comp exactly. Loaded via `<link>` in `index.html`. |
| 2 | Color system | **oklch palette from design comp** | Primary green `oklch(0.70 0.16 145)`, page bg `oklch(0.985 0.012 135)`, dark text `oklch(0.26 0.03 152)`, muted text `oklch(0.53 0.02 152)` etc. All values taken directly from the HTML mock. |
| 3 | Component library | **None — hand-written CSS** | The design is bespoke with oklch colors and specific radii. A component library would fight the design. Speed goal favors matching the comp directly. |
| 4 | CSS approach | **CSS modules** | Scoped styles, zero-config in Vite, no global pollution. One module per page/component. |
| 5 | Layout | **Design comp login layout** | Centered card (400px, border-radius 28px), decorative blurred background circles, inputs with 13px border-radius, full-width green CTA button with shadow. |
| 6 | Post-login landing | **App shell with nav header** (from design comp) | The design shows a 72px sticky header with logo, nav tabs (Discover, Matches, Profile), and user avatar. S-01 delivers the shell; tab content comes in later slices. |
| 7 | Form handling | **Controlled inputs with React state** | No form library needed for two fields. |
| 8 | Error feedback | **Inline error message below the form** | Styled red/error color, consistent with design card padding. |
| 9 | Accessibility | **Standard form semantics** | `<form>`, `<label>`, `type="email"`, `type="password"`, `aria-invalid`, `role="alert"`. |
| 10 | Global styles | **Reset + Figtree applied in `index.css`** | The design specifies `*{box-sizing:border-box}`, no margin/padding on html/body, Figtree as the base family with antialiased rendering. |
| 11 | oklch color space | **Conscious choice — modern browsers only** | oklch() is supported in Chrome 111+, Firefox 113+, Safari 15.4+. Acceptable for this hackathon demo targeting modern desktop browsers (PRD non-goal: no legacy browser support). |

## Design Tokens (from `Deloitter.dc.html`)

Referenced throughout the plan. Implementation should extract these into a shared CSS custom properties file or at minimum use them consistently:

| Token | Value | Usage |
|-------|-------|-------|
| `--dl-green` | `oklch(0.70 0.16 145)` | Primary button, logo bg, accents |
| `--dl-bg` | `oklch(0.985 0.012 135)` | Page background |
| `--dl-text` | `oklch(0.26 0.03 152)` | Primary text |
| `--dl-text-muted` | `oklch(0.53 0.02 152)` | Secondary text |
| `--dl-text-label` | `oklch(0.42 0.02 152)` | Form labels |
| `--dl-card-border` | `oklch(0.91 0.012 150)` | Card borders |
| `--dl-input-border` | `oklch(0.89 0.012 150)` | Input borders |
| `--dl-input-bg` | `oklch(0.985 0.008 145)` | Input background |
| `--dl-card-shadow` | `0 24px 60px -28px oklch(0.4 0.05 150 / .45)` | Card elevation |
| `--dl-btn-shadow` | `0 12px 26px -12px oklch(0.70 0.16 145 / .9)` | Primary button shadow |
| `--dl-radius-card` | `28px` | Card border-radius |
| `--dl-radius-input` | `13px` | Input border-radius |
| `--dl-radius-btn` | `14px` | Button border-radius |
| `--dl-font` | `'Figtree', system-ui, -apple-system, sans-serif` | Base font-family |

## Phases

### Phase 1: Global styles & design tokens

**Goal:** Establish the Figtree font, global resets, and CSS custom properties that all pages will use — ensuring visual consistency with the design comp from the start.

#### Backend

- (no backend work — F-02 delivers all required endpoints)

#### Frontend

- [x] Update `frontend/index.html`:
  - Add Google Fonts `<link>` for Figtree (weights 400, 500, 600, 700, 800, 900)
  - Add `<link rel="preconnect" href="https://fonts.googleapis.com">` and `<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>`
  - Update `<title>` from "bootstrap-scaffold" to "Deloitter"
- [x] Update `frontend/package.json`:
  - Rename `"name"` from `"bootstrap-scaffold"` to `"deloitter"` (aligns with project identity)
- [x] Create `frontend/src/styles/tokens.css`:
  - Define CSS custom properties for all design tokens listed above
  - Include the `@keyframes` from the design comp that may be needed later (`dl-pop`, `dl-fadein`, `dl-rise`)
- [x] Update `frontend/src/index.css`:
  - Import `./styles/tokens.css`
  - Apply global resets: `* { box-sizing: border-box }`, `html, body { margin: 0; padding: 0 }`
  - Set body font-family to `var(--dl-font)`, `-webkit-font-smoothing: antialiased`, `text-rendering: optimizeLegibility`
  - Set body background to `var(--dl-bg)`, color to `var(--dl-text)`
  - Set `button { font-family: inherit }`
  - Remove the default Vite template styles (the old counter/logo styles in `App.css`)
- [x] Delete `frontend/src/App.css` (default Vite template styles — no longer needed)

#### Verification

- [x] `npm run build` succeeds
- [x] `npm run dev` — page loads with Figtree font visible (check DevTools → Computed → font-family)
- [x] Background color is the light greenish `oklch(0.985 0.012 135)`

---

### Phase 2: Login page

**Goal:** A pixel-accurate login form at `/login` matching the design comp — branded card with email/password inputs, green CTA button, decorative background, error handling.

#### Backend

- (no backend work)

#### Frontend

- [x] Delete `frontend/src/pages/LoginPlaceholder.tsx` (the F-02 temporary placeholder — never existed, F-02 not yet implemented; skipped)
- [x] Create `frontend/src/pages/LoginPage.tsx`:
  - Full-viewport centered layout with `min-height: 100vh`, flexbox center, `padding: 32px`
  - **Decorative background circles** (two absolutely-positioned blurred circles):
    - Top-left: 520px circle, `oklch(0.82 0.11 145 / .35)`, `filter: blur(40px)`, offset `top: -160px; left: -120px`
    - Bottom-right: 460px circle, `oklch(0.85 0.09 175 / .3)`, `filter: blur(40px)`, offset `bottom: -180px; right: -100px`
  - **Card** (400px max-width, relative positioned):
    - White background, border `1px solid var(--dl-card-border)`, border-radius `28px`
    - Box-shadow `var(--dl-card-shadow)`
    - Padding `38px 34px`
  - **Logo + app name** (flex row, gap 10px, margin-bottom 26px):
    - Logo: 40×40px `div`, border-radius `13px`, bg `var(--dl-green)`, white bold "d" (22px, weight 900), shadow `0 6px 16px -6px oklch(0.70 0.16 145 / .8)`
    - "Deloitter" text: 23px, weight 900, letter-spacing `-0.02em`
  - **Heading**: "Find your people inside the firm." — 27px, weight 800, letter-spacing `-0.02em`, line-height 1.15, margin-bottom 8px (use `<br>` between "people" and "inside")
  - **Subtext**: "Swipe through colleagues who share your interests and skills. Match, then take it to Teams." — 15px, color `var(--dl-text-muted)`, line-height 1.45, margin-bottom 26px
  - **Form fields**:
    - Label "Work email": 13px, weight 600, color `var(--dl-text-label)`, margin-bottom 7px
    - Email input: full width, border `1px solid var(--dl-input-border)`, bg `var(--dl-input-bg)`, border-radius 13px, padding `13px 15px`, font-size 15px, color `oklch(0.30 0.02 152)`, margin-bottom 16px
    - Label "Password": same style as email label
    - Password input: same style as email input, margin-bottom 24px
  - **Submit button** ("Log in"):
    - Full width, bg `var(--dl-green)`, color white, font-size 16px, weight 800, padding 15px, border-radius 14px
    - Box-shadow `var(--dl-btn-shadow)`
    - Hover: `filter: brightness(1.05); transform: translateY(-1px)`
    - Disabled state while loading: reduced opacity, "Logging in…" text
  - **Footer text**: "Pre-seeded demo account · no real data" — 12.5px, centered, color `oklch(0.6 0.015 152)`, margin-top 16px
  - **Error message** (shown below button when credentials fail):
    - Red/orange text, 14px, weight 600, margin-top 12px, `role="alert"`
  - **State**: `email`, `password`, `error` (string | null), `loading` (boolean)
  - **Submit handler**:
    - Prevent default, set loading, clear error
    - Call `login(email, password)` from `useAuth()`
    - On success: navigate to `/` (programmatic via `useNavigate()`)
    - On failure: set error "Invalid email or password"
  - **Redirect if authenticated**: if `useAuth().user` is not null, redirect to `/` (no reason to show login to authenticated user)
- [x] Create `frontend/src/pages/LoginPage.module.css`:
  - All styles matching the design spec above
  - Media query for small screens: card padding slightly reduced, background circles hidden below ~480px
- [x] Update route in `frontend/src/App.tsx`:
  - Replace `LoginPlaceholder` import with `LoginPage`
  - `/login` route renders `<LoginPage />`

#### Verification

- [x] `npm run build` succeeds
- [x] `npm run lint` passes
- [ ] `npm run dev` — visiting `/login`:
  - Decorative background circles visible
  - Centered white card with logo, heading, subtext
  - Email + password inputs styled per design
  - Green "Log in" button with shadow
  - Footer text about pre-seeded accounts
- [ ] Submit empty form → browser validation prevents (required attribute)
- [ ] Submit invalid credentials → inline "Invalid email or password" error
- [ ] Submit valid credentials → navigates to authenticated area
- [ ] Visit `/login` while authenticated → redirects to `/`

---

### Phase 3: App shell & authenticated landing

**Goal:** After login, the user sees the app shell header (logo + nav + avatar) from the design comp, with a simple landing/welcome area. This is the "reach the app" part of the S-01 outcome.

#### Backend

- (no backend work)

#### Frontend

- [x] Delete `frontend/src/pages/Home.tsx` (the F-02 temporary placeholder — replaced by `HomePage.tsx`)
- [x] Create `frontend/src/components/AppShell.tsx`:
  - Wraps authenticated pages (used inside `<ProtectedRoute>` or as the layout for protected routes)
  - **Header** (from design comp lines 58–80):
    - `max-width: 1180px`, centered (`margin: 0 auto`), horizontal padding `28px`
    - Flex row, `height: 72px`, sticky top, blurred background: `oklch(0.985 0.012 135 / .85); backdrop-filter: blur(10px); z-index: 50`
    - Left: logo (34×34px, border-radius 11px, green bg, white "d" 19px bold) + "Deloitter" (19px, weight 900, letter-spacing -0.02em)
    - Right: nav buttons + user avatar
      - Nav buttons: "Discover", "Matches", "Profile" — 15px, weight 700, color `oklch(0.30 0.02 152)`, padding `8px 14px`, cursor pointer, border-radius 10px
      - Active tab: green underline bar (3px tall, border-radius 3px, bg `var(--dl-green)`) positioned absolutely at bottom
      - User avatar: 36px circle, bg `var(--dl-green)`, white initials (14px, weight 800), margin-left 10px
  - Nav buttons are non-functional placeholders for now (Discover/Matches/Profile tabs will be wired in S-02+). Active tab defaults to "Discover".
  - Renders `<Outlet />` below the header for nested route content
- [x] Create `frontend/src/components/AppShell.module.css`:
  - Header styles matching design
  - Nav button styles with hover and active states
- [x] Create `frontend/src/pages/HomePage.tsx`:
  - Simple welcome content (rendered inside AppShell):
    - Heading: "Welcome, {firstName}!" — 26px, weight 900
    - Subtext: "Your next connection is one swipe away. Start discovering colleagues who share your interests."
    - Logout button (styled as secondary/outlined): calls `logout()` from `useAuth()`
  - This is a placeholder landing; S-02/S-03 will replace it with real feature content
- [x] Create `frontend/src/pages/HomePage.module.css`
- [x] Update `frontend/src/App.tsx` route structure:
  - Protected routes render inside `<AppShell>` as a layout route:
    ```
    <Route element={<ProtectedRoute />}>
      <Route element={<AppShell />}>
        <Route path="/" element={<HomePage />} />
        {/* Future: /discover, /matches, /profile */}
      </Route>
    </Route>
    ```
  - This gives all authenticated pages the shell header automatically

#### Verification

- [ ] `npm run build` succeeds
- [ ] `npm run dev` — after logging in:
  - Sticky header visible with "d" logo + "Deloitter" text
  - Nav tabs visible (Discover, Matches, Profile) — "Discover" has green underline
  - User initials avatar in top-right
  - Welcome message with user's first name displayed
  - Logout button works → returns to login
- [ ] Header remains sticky on scroll (when content is long enough)
- [ ] Visual comparison with design comp screenshot (`login.png`, `warm-default.png`) — consistent branding, colors, typography

---

### Phase 4: Polish & accessibility

**Goal:** Final polish — keyboard navigation, loading states, document titles, and visual refinement to make the demo look production-quality.

#### Backend

- (no backend work)

#### Frontend

- [ ] Add `autofocus` to the email input on the login page (focuses on mount)
- [ ] Ensure Enter key submits (natural via `<form>` + `<button type="submit">`)
- [ ] Loading indicator on submit button: text changes to "Logging in…", slight opacity reduction, `cursor: not-allowed`
- [ ] Tab order: email → password → submit (natural DOM order)
- [ ] `aria-invalid="true"` on both inputs when error is shown
- [ ] Error message uses `role="alert"` and `aria-live="assertive"` so screen readers announce it
- [ ] Document title management:
  - Login page: `document.title = "Deloitter — Log in"`
  - Home page: `document.title = "Deloitter"`
  - Use `useEffect` with title update on mount
- [ ] Hover/focus states on login button (`:focus-visible` ring for keyboard users)
- [ ] Verify no layout breakage at narrow viewport widths (down to ~360px) — the card should shrink gracefully with `max-width: 100%`
- [ ] Remove any leftover F-02 placeholder files/components that are now superseded
- [ ] Verify `npm run lint` passes with all new files

#### Verification

- [ ] Keyboard-only login flow: Tab → Email, Tab → Password, Enter → submits
- [ ] Error announced by screen reader (role="alert")
- [ ] Page title says "Deloitter — Log in" on login, "Deloitter" on home
- [ ] Login button shows "Logging in…" briefly while request is in flight
- [ ] Focus-visible ring visible on button when tabbing
- [ ] `npm run build` passes
- [ ] `npm run lint` passes

---

## Integration & Smoke Test

- [ ] From clean state: Postgres running, backend started (`.\mvnw.cmd spring-boot:run`), frontend started (`npm run dev`)
- [ ] Open `http://localhost:5173` → redirected to `/login`
- [ ] Login page matches design comp: decorative circles, centered card, Figtree font, green button, "Find your people" heading
- [ ] Submit with wrong password → inline error "Invalid email or password"
- [ ] Submit with valid seeded credentials (e.g., `alice.johnson@deloitte.demo` / `password123`) → lands on authenticated app with shell header
- [ ] App shell header: logo, nav tabs, user avatar visible
- [ ] Welcome message shows user's first name
- [ ] Refresh → still authenticated (session cookie persists)
- [ ] Click Logout → redirected to `/login`, session cleared
- [ ] Navigate directly to `http://localhost:5173/` while unauthenticated → redirected to `/login`
- [ ] Navigate directly to `http://localhost:5173/login` while authenticated → redirected to `/`
- [ ] **Design check:** Visual parity with `frontend/context/foundation/design/login.png` screenshot
- [ ] **Guardrail check:** Login does not expose any other user's data — only the authenticated user's own name/email/initials are shown after login.
- [ ] **Guardrail check:** No compatibility score, swipe intent, or match data is exposed anywhere (those features don't exist yet).

## Open Questions

1. **Figtree font — self-host or Google Fonts CDN?** — Plan uses Google Fonts CDN (fastest for a hackathon POC). If offline/self-hosted is needed, download and serve from `public/fonts/`. Non-blocking.
2. **Exact seeded employee emails for demo?** — Plan assumes F-01 seeds employees like `alice.johnson@deloitte.demo`. Verification steps use these. If seed data uses different emails, adjust accordingly. Non-blocking.
3. **Nav tab routing for Discover/Matches/Profile?** — S-01 renders the tabs in the header but they are non-functional placeholders (no click routing). S-02+ will wire them to real routes. Non-blocking.

