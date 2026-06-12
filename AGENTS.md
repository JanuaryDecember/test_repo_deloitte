# AGENTS.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project: Deloitter

A Tinder-style internal networking app (hackathon POC). A Deloitte employee logs in, swipes through colleagues ranked by shared interests/competencies, and when two people mutually like each other they become a **match** that reveals a compatibility score + contact info. The product spec lives in `context/foundation/prd.md`; the build sequence in `context/foundation/roadmap.md`.

**Current state:** both tiers are bare bootstrap scaffolds. The backend has a single `DeloitterApplication` class and zero controllers; the frontend is the default Vite+React template. No persistence, auth, or domain code exists yet — the roadmap (F-01 → S-05) is the plan for building it.

### Hard product guardrails (from PRD — do not violate)

- **No rejection signals.** A user must never be able to learn that someone passed on or liked them. Intent is revealed _only_ on a mutual match.
- **Compatibility score is explainable** — proportional overlap of interests/competencies/background, never random or black-box. The score is **hidden while swiping** and revealed only on a match.
- Demo runs on **seeded, disposable data** — accounts are pre-seeded (no self-registration); no production auth/PII hardening.

## Architecture

Split monorepo, two independently-run tiers. **Each tier has its own `AGENTS.md` with commands, conventions, and tier-specific rules — read it before working in that directory:**

- **`backend/`** — Spring Boot 4.1 / Java 21 REST API. See [`backend/AGENTS.md`](backend/AGENTS.md).
- **`frontend/`** — Vite 8 + React 19 + TypeScript SPA/PWA that consumes the Java API. See [`frontend/AGENTS.md`](frontend/AGENTS.md).

The two tiers are decoupled: the frontend talks to the backend only over HTTP. There is no shared build — each is bootstrapped, run, and tested independently.
