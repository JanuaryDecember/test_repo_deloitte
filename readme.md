# Deloitter

A Tinder-style internal networking app for Deloitte employees. Swipe through colleagues ranked by shared interests and competencies, and when two people mutually like each other, they become a **match** that reveals compatibility scores and contact information.

> **Note:** This is a hackathon POC built with seeded, disposable data. Not hardened for production use.

## 🎯 Product Guardrails

- **No rejection signals** — Users never learn if someone passed on or liked them. Intent is revealed only on mutual matches.
- **Explainable compatibility** — Scores are based on proportional overlap of interests/competencies/background, never random or black-box.
- **Seeded demo data** — Pre-seeded accounts with no self-registration or production auth/PII hardening.

## 🏗 Architecture

Split monorepo with two independently-run tiers:

```
deloitter/
├── backend/        Spring Boot 4.1 + Java 21 REST API
├── frontend/       Vite 8 + React 19 + TypeScript SPA/PWA
├── context/        Product specs, roadmap, and change plans
└── scripts/        Deployment and automation scripts
```

Each tier has its own `AGENTS.md` with commands, conventions, and tier-specific rules.

## 🚀 Quick Start

### Prerequisites

- **Java 21** (for backend)
- **Node.js 20+** (for frontend)
- **PostgreSQL 16** (for local development without Docker)
- **Docker & Docker Compose** (optional, for containerized deployment)

### Running with Docker Compose (Recommended)

```bash
# Start Postgres, backend, and frontend
docker-compose up --build

# Postgres: localhost:5432 (user: postgres, password: postgres, db: appdb)
# Backend: http://localhost:8080
# Frontend: http://localhost:5173
```

The Docker Compose setup includes:

- **Postgres 16 Alpine** container with persistent volume
- Backend connected to Postgres with auto-migration
- Frontend served via Nginx

### Running Locally

**Postgres (required for backend):**

```bash
# Option 1: Run only Postgres from Docker Compose
docker-compose up postgres

# Option 2: Use local Postgres installation
# Ensure Postgres is running on localhost:5432
# Database: appdb, User: postgres, Password: postgres
```

**Backend:**

```bash
cd backend
./mvnw spring-boot:run
# API runs on http://localhost:8080
# Connects to Postgres on localhost:5432
```

**Frontend:**

```bash
cd frontend
npm install
npm run dev
# App runs on http://localhost:5173
```

## 📁 Project Structure

- **`backend/`** — Spring Boot REST API (see [`backend/AGENTS.md`](backend/AGENTS.md))
- **`frontend/`** — React TypeScript SPA/PWA (see [`frontend/AGENTS.md`](frontend/AGENTS.md))
- **`context/`** — Product documentation and planning
  - `foundation/` — PRD, roadmap, shape notes, tech stack decisions
  - `changes/` — Active feature plans
  - `archive/` — Completed change plans
- **`scripts/`** — Deployment and automation scripts
- **`docker-compose.yml`** — Multi-container orchestration (Postgres + Backend + Frontend)

## 🗄️ Database

The project uses **PostgreSQL 16** for data persistence.

**Default credentials (development only):**

- Host: `localhost:5432`
- Database: `appdb`
- Username: `postgres`
- Password: `postgres`

The backend handles schema migrations automatically via Spring Boot's Hibernate DDL.

## 📚 Documentation

- **[Product Requirements](context/foundation/prd.md)** — Full product spec
- **[Roadmap](context/foundation/roadmap.md)** — Feature sequence and milestones
- **[Root AGENTS.md](AGENTS.md)** — Architecture overview and guardrails
- **[Backend AGENTS.md](backend/AGENTS.md)** — Backend conventions and commands
- **[Frontend AGENTS.md](frontend/AGENTS.md)** — Frontend conventions and commands

## 🔧 Development Workflow

This project follows the **10x workflow** with structured planning and implementation:

1. **Shape** → Define the problem and scope
2. **Plan** → Create detailed implementation plans (stored in `context/changes/`)
3. **Implement** → Build according to the plan
4. **Review** → Verify implementation against plan
5. **Archive** → Move completed changes to `context/archive/`

See individual feature plans in `context/changes/` for active work.

## 🎨 Key Features

- **Login & Auth Gate** — Employee authentication (demo only)
- **Interest Selection** — Pick interests and competencies for matching
- **Swipe Discovery** — Browse candidate stack ranked by compatibility
- **Mutual Matches** — Reveal compatibility scores and contact info on mutual likes
- **Profile Management** — View and edit your profile and interests
- **Match History** — See all your matches with scores and contact details

## 🤝 Contributing

Read the root [`AGENTS.md`](AGENTS.md) and tier-specific `AGENTS.md` files before making changes. Follow the product guardrails and architectural decisions documented there.

## 📄 License

Internal Deloitte hackathon project. Not licensed for external use.
