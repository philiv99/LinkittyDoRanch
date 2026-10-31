# LinkittyDoRanch — Project Plan

This folder is the **full delivery plan** for rebuilding *Linkitty‑Do Ranch* — a
web word game — from the original 2010‑era VB.NET/SQL Server desktop prototype
onto the reusable **agentic workflow**.

It is a *planning* deliverable only (no application code). It translates the
design documents under [`../design/LinkittyDo`](../design/LinkittyDo) into:

- a concrete **architecture** (one shared API + one React SPA) on the approved
  agentic stacks,
- a **MySQL data model** derived from the original `LK_*` tables,
- an **HTTP API contract**, a **front‑end plan**, and the **game mechanics**,
- a **milestone roadmap** broken into a prioritized, cross‑repo **issue backlog**,
- **`PROJECT.md` drafts** for each new repo, ready for onboarding.

## How this plan maps to the agentic workflow

The plan obeys the rules in the sibling [`../../agentic`](../../agentic) repo:

- **Shape** — one shared API/service plus front‑ends, per
  [agentic/guides/architecture.md](../../agentic/guides/architecture.md).
- **Stacks** — the API uses
  [`dotnet-webapi`](../../agentic/stacks/dotnet-webapi.md) (ASP.NET Web API 2 /
  .NET Framework 4.7.2 / EF6 / MySQL); the SPA uses
  [`react-spa`](../../agentic/stacks/react-spa.md) (React 16 + Redux / webpack 4).
- **Two environments only** — development (local) and production. No staging.
- **Delivery** — every change is one issue → one repo → one small branch → a PR
  that `Closes #N`, with unit + integration tests green via `verify.ps1` locally
  before push, per the [issue lifecycle](../../agentic/issue-process.md) and the
  [operator's manual](../../agentic/workflow.md).

## Confirmed decisions (product owner)

| Decision | Choice |
| --- | --- |
| Front‑end topology | **One SPA** (`linkittydo-web`) serving both player and admin routes; admin routes gated by the `Administrator` role. |
| Backend repo | **Consolidated into the existing `api.infogoer.com`** (shared backend, schema `ExploreInfoGoer`) — not a new `api.linkittydo.com`. |
| SPA deployment | `linkittydo-web` uses the agentic **react-spa deployment workflow** (webpack 4 + `ftpdeploy.js` to `ftp.infogoer.com`). |
| First release (P1) scope | Accounts & auth · Game catalog & browse · Game play · Game creation + NLP parser · Admin console. |
| Deferred to P2/P3 | **Societies** (social) and **News / home content** polish. |
| Data strategy | **Fresh MySQL schema**, scripted seed only. No migration of the SQL Server backup. |
| "Future" tooling | **Deferred**: web Crawler, custom "Linkitty" search engine, and crawler index DB. Clue discovery uses pluggable search providers / stored links for now. |
| GitHub owner | `philiv99` |

## Repositories this plan creates

| Repo | Stack | Role |
| --- | --- | --- |
| `philiv99/api.infogoer.com` *(existing, extended)* | [dotnet-webapi](../../agentic/stacks/dotnet-webapi.md) | Shared HTTP API: accounts, games, play, admin, parser tool, data access to MySQL. LinkittyDo is delivered into this existing backend (schema `ExploreInfoGoer`) rather than a new repo. |
| `philiv99/linkittydo-web` *(new)* | [react-spa](../../agentic/stacks/react-spa.md) | Single React SPA: public game site **and** admin console (role‑gated); built/deployed via the agentic react-spa deployment workflow. |

> **Consolidation (confirmed):** the backend is **not** a new `api.linkittydo.com`
> repo — LinkittyDo ships into the existing `philiv99/api.infogoer.com` (already
> onboarded to agentic and registered in
> [agentic/consumers.json](../../agentic/consumers.json)). Only `linkittydo-web` is a
> new repo. See decision **D12** / open question **O1** in
> [08-risks-and-decisions.md](./08-risks-and-decisions.md).

## Documents

| # | Document | What it covers |
| --- | --- | --- |
| — | [README.md](./README.md) | This index. |
| — | [CHANGELOG.md](./CHANGELOG.md) | Notable revisions to this plan. |
| 00 | [00-product-overview.md](./00-product-overview.md) | Vision, the game in one page, agents/roles, scope. |
| 01 | [01-architecture.md](./01-architecture.md) | System shape, repos, stacks, environments, security, CORS, and the original‑layer → new‑component mapping. |
| 02 | [02-data-model.md](./02-data-model.md) | The MySQL schema derived from the `LK_*` tables, conventions, status enums, and seed data. |
| 03 | [03-api-contract.md](./03-api-contract.md) | REST route inventory, request/response shapes, auth, and shared/meta endpoints. |
| 04 | [04-frontend-plan.md](./04-frontend-plan.md) | The single SPA: site map, screens, routes, Redux state, and dev/prod config switching. |
| 05 | [05-game-mechanics.md](./05-game-mechanics.md) | Game‑creation pipeline (parse → profile → clue discovery) and play (clue/guess/scoring) algorithms. |
| 06 | [06-roadmap-and-backlog.md](./06-roadmap-and-backlog.md) | Milestones M0–M5 (+ deferred), and the prioritized, cross‑repo issue backlog. |
| 07 | [07-testing-ci-release.md](./07-testing-ci-release.md) | Unit + integration test strategy, `verify.ps1`, CI, versioning, and release. |
| 08 | [08-risks-and-decisions.md](./08-risks-and-decisions.md) | Assumptions, open questions, and deferred "future" work. |
| P | [projects/api.linkittydo.com.PROJECT.md](./projects/api.linkittydo.com.PROJECT.md) | **Superseded** pointer — the API lives in `api.infogoer.com` (see that repo's `PROJECT.md`). |
| P | [projects/linkittydo-web.PROJECT.md](./projects/linkittydo-web.PROJECT.md) | `PROJECT.md` draft for the SPA repo. |
| S | [schema/schema.sql](./schema/schema.sql) | Full MySQL DDL for the v1 schema. |

## Source design documents (read‑only inputs)

All under [`../design/LinkittyDo`](../design/LinkittyDo):

- **Architecture** — [Architecture.docx](../design/LinkittyDo/Architecture/Architecture.docx),
  [Site Map.docx](../design/LinkittyDo/Architecture/Site%20Map.docx),
  [System Block Diagram.jpg](../design/LinkittyDo/Architecture/System%20Block%20Diagram.jpg).
- **Database ERDs** — [Users, Societies & Roles](../design/LinkittyDo/Database/Users,%20Societies%20&%20Roles.jpg),
  [Games, Phrases, Parses & Profiles](../design/LinkittyDo/Database/Games,%20Phrases,%20Parses%20&%20Profiles.jpg),
  [Clues & Links](../design/LinkittyDo/Database/Clues%20&%20Links.jpg),
  [Played Games, Clues & Guesses](../design/LinkittyDo/Database/Played%20Games,%20Clues%20&%20Guesses.jpg).
- **Software Design** — [Use Cases.docx](../design/LinkittyDo/Software%20Design/Use%20Cases.docx),
  [Algorithms - Game Creation.docx](../design/LinkittyDo/Software%20Design/Algorithms%20-%20Game%20Creation.docx),
  class & logic diagrams (`*.jpg`).
- **Wireframes** — the seven `.docx` files under
  [Wireframes](../design/LinkittyDo/Wireframes).
- **Backups** — the original VB.NET solution and SQL Server `.mdf` under
  [Backups](../design/LinkittyDo/Backups) (reference only; not migrated).
