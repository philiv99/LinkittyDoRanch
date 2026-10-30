# 01 — Architecture

Follows the agentic
[architecture guide](../../agentic/guides/architecture.md): **one shared
API/service plus front‑ends**, two environments, backward‑compatible
API‑before‑consumer releases.

## System shape

```text
                 ┌─────────────────────────────────────────────┐
  Browser  ─────▶│  linkittydo-web  (React 16 + Redux SPA)      │
   (user)        │  public game site + admin console (role-gated)│
                 └───────────────┬─────────────────────────────┘
                                 │  HTTPS / JSON  (separate origin, CORS)
                                 ▼
                 ┌─────────────────────────────────────────────┐
                 │  api.linkittydo.com  (ASP.NET Web API 2)     │
                 │  Api ▸ Logic ▸ Service(Tool) ▸ Data(EF6)     │
                 └───────────────┬─────────────────────────────┘
                                 │  EF6
                                 ▼
                 ┌─────────────────────────────────────────────┐
                 │  MySQL  (linkittydo / linkittydo_test)       │
                 └─────────────────────────────────────────────┘

  External (pluggable, server-side): NLP parser (OpenNLP), WordNet,
  search provider(s) for clue discovery.   [Crawler + Linkitty engine = future]
```

Two deployable parts, each its own repo, endpoint, build, and release cadence,
both calling one API contract.

## Repositories & stacks

### `philiv99/api.linkittydo.com` — shared API

- **Stack:** [dotnet-webapi](../../agentic/stacks/dotnet-webapi.md) — ASP.NET Web
  API 2 on **.NET Framework 4.7.2**, **Entity Framework 6**, **MySQL**
  (`MySql.Data` / `MySql.Data.Entity` EF6 provider). Web API 2 / EF6 — **not**
  ASP.NET Core / EF Core.
- **Language:** C# (mainstream for Web API 2). The original VB.NET app is
  reference only; namespaces mirror the original `lk.*` layering (see mapping
  below). Language choice is recorded as a decision in
  [08-risks-and-decisions.md](./08-risks-and-decisions.md).
- **Owns:** the versioned HTTP contract, business logic (managers), the parser
  tool, and all data access. Full values live in
  [projects/api.linkittydo.com.PROJECT.md](./projects/api.linkittydo.com.PROJECT.md).

### `philiv99/linkittydo-web` — single SPA

- **Stack:** [react-spa](../../agentic/stacks/react-spa.md) — React 16 + Redux,
  webpack 4, webpack‑dev‑server 3 (`NODE_OPTIONS=--openssl-legacy-provider`).
- **Owns:** all UI. Player and admin experiences live in **one** SPA; admin
  routes are gated by the `Administrator` role. A webpack **alias** switches the
  dev vs prod API base URL. Full values live in
  [projects/linkittydo-web.PROJECT.md](./projects/linkittydo-web.PROJECT.md).

## Mapping: original layers → new components

The [System Block Diagram](../design/LinkittyDo/Architecture/System%20Block%20Diagram.jpg)
defines five layers under the `lk` namespace. They map as follows:

| Original layer (`lk.*`) | Original pieces | New home |
| --- | --- | --- |
| **UI** | Home, Profile, Society, Game Play, Admin | **`linkittydo-web`** SPA screens/routes ([04-frontend-plan.md](./04-frontend-plan.md)). |
| **Logic** | LinkittyMgr, SiteMgr, User, Society, Game, WordRelations, GameAdmin | API **`Logic/`** managers behind controllers ([03-api-contract.md](./03-api-contract.md)). |
| **Service ▸ Tool** | Search, **Parser** (in‑dev), Crawler (future) | API **`Service/Tool/`**: Parser (OpenNLP) ships in MVP; Search is a pluggable provider; **Crawler = deferred**. |
| **Service ▸ WordInfo / Search** | HTTP, WordNet, DB; Yahoo/Google/MSN/Amazon/**Linkitty** | API **`Service/WordInfo/`** (WordNet) + **`Service/Search/`** provider adapters; **Linkitty engine = deferred**. |
| **DAL** | Users, Played Games, Societies, Games, Guesses, Clues, Nav/Styling/Content | API **`Data/`** — EF6 `DbContext` + entity configs over MySQL ([02-data-model.md](./02-data-model.md)). |
| **System** | Object, Util | API **`System/`** cross‑cutting helpers (base types, result/paging, logging). |

The original **DTO / DTOParser / DAL** hand‑rolled ADO.NET pattern (see
`lk/DAL/*.vb` in the backup) is **replaced by EF6** entities + a thin repository
layer. The optimistic‑concurrency `sysversion` column is preserved (see
[02-data-model.md](./02-data-model.md)).

## Accounts & access

- Implement **registration, activation, sign‑in, recovery, and user/admin
  authorization** compatible with the stack.
- The original schema stores `upassword` as clear `varchar(100)`. **This plan
  hashes passwords** (PBKDF2 or bcrypt) and never returns the hash. This is a
  mandatory security hardening over the prototype.
- **Auth mechanism:** token‑based (a signed bearer token / JWT) issued by
  `POST /api/auth/login`, sent by the SPA as `Authorization: Bearer …`. Roles are
  carried as claims and checked server‑side on every protected route; the SPA
  only *hides* admin UI, it never *enforces* it.
- **ReCaptcha** on the join form (per the
  [not‑logged‑in wireframe](../design/LinkittyDo/Wireframes/1%20-%20Home%20%28not%20logged%20in%29.docx)),
  verified server‑side.

## CORS & origins

The browser origin and the API origin are **separate**; the API allows only the
approved SPA origins:

| Environment | SPA origin | API base URL |
| --- | --- | --- |
| Development | `http://localhost:3000` | `http://localhost:52080/api` |
| Production | `https://www.linkittydo.com` (and `https://linkittydo.com`) | `https://api.linkittydo.com/api` |

Exact origins/ports are recorded per repo in `PROJECT.md`; a CORS **preflight** is
part of the API integration tests.

## Data

- **One engine, MySQL**, with **separate dev and prod data** and a dedicated
  **test** database (`linkittydo_test`) for integration tests.
- The API repo records the database name, app user (never `root`), schema/grants
  scripts, and connection source (git‑ignored `connectionStrings.config` via
  `configSource`) in its `PROJECT.md`.
- Schema changes stay backward‑compatible with the previous API version so a
  rollback is safe; schema is scripted (DDL + grants + seed) under the API repo's
  `db/` folder, drafted in [schema/schema.sql](./schema/schema.sql).

## Environments & releases

- **Two environments only:** development (local) and production. No staging; CI
  runners are disposable build VMs, not a third environment.
- Deploy a **backward‑compatible API change before** the dependent SPA release;
  verify the deployed API ↔ SPA pair and record both commit IDs; approve each
  production deploy separately (see
  [07-testing-ci-release.md](./07-testing-ci-release.md)).
- Each repo has its own protected default branch, PRs, `verify.ps1` gate, and
  human‑run deploy script. Secrets stay out of Git; production detailed errors are
  **off**.

## Cross‑cutting non‑functional requirements

- **Security:** hashed passwords; parameterized data access (EF6); server‑side
  authorization on every protected route; no secrets in source; production errors
  reveal no internals.
- **Performance:** catalog browse and play endpoints are paged; clue discovery
  (web search) runs **server‑side and asynchronously** during game *creation*, not
  during play — play reads pre‑generated clues/links.
- **Observability:** structured server logs; a `GET /api/health` meta endpoint.
- **Config:** dev/prod switching via the stack's config model (API `configSource`
  + `Web.Release.config` XDT; SPA webpack config alias).
