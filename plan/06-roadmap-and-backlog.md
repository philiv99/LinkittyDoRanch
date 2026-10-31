# 06 — Roadmap & Backlog

Delivery sequenced into milestones and expressed as a **capture‑ready issue
backlog** for the [issue lifecycle](../../agentic/issue-process.md). Each row is a
candidate GitHub issue created via the `create-issue` skill.

## Delivery principles

- **One issue → one repo → one small change.** Cross‑repo outcomes are split into
  **linked, API‑first** issues: land the backward‑compatible API change, then the
  SPA consumer ([workflow.md](../../agentic/workflow.md)).
- **Every change ships unit + integration tests** and passes that repo's
  `verify.ps1` locally before push; a PR `Closes #N`; a person merges.
- **Priority labels:** `P1` (MVP), `P2`, `P3`. Status flows Backlog → Ready → In
  progress → Review → Done.
- Legend: **API** = `api.infogoer.com` (consolidated backend), **WEB** =
  `linkittydo-web`.

## Milestones

| Milestone | Goal | Priority |
| --- | --- | --- |
| **M0 — Foundation** | Both repos onboarded to agentic; schema v1; health/meta; CORS; SPA shell + nav/footer; seed data. | P1 |
| **M1 — Accounts & auth** | Register/activate/login/logout/recover; roles; profile + default game profile. | P1 |
| **M2 — Game catalog & browse** | Browse/search games; game detail; seeded playable games. | P1 |
| **M3 — Game play** | Start, request clues, guess, scoring, solve/give‑up, history. | P1 |
| **M4 — Game creation + NLP parser** | Parser tool; profile editor; creation pipeline → clues/links. | P1 |
| **M5 — Admin console** | Game admin (process/approve/activate/edit), users, stats. | P1 |
| **M6 — Societies** | Social groups, membership, comments. | P2 |
| **M7 — News / home content** | News CRUD + home feed + site content blocks. | P3 |
| **Future** | Web Crawler, Linkitty search engine, crawler index DB. | Deferred |

## M0 — Foundation

> **Status (consolidation):** the API is the existing **`api.infogoer.com`** repo,
> already onboarded to agentic (so `M0‑API‑1` is done). The foundation health
> endpoint + LinkittyDo schema landed in `api.infogoer.com#10`; the remaining M0/M1
> items are captured as issues `api.infogoer.com#11–#15`. DB names below are the
> consolidated `ExploreInfoGoer` / `ExploreInfoGoer_Test`.

**API**
- `M0‑API‑1` Onboard repo: author `PROJECT.md` from the dotnet‑webapi profile, sync
  agentic assets, `.gitignore`, `README`. *Accept:* synced agents/skills appear;
  no secrets committed.
- `M0‑API‑2` Web API 2 skeleton + `GET /api/health` + global error handling (prod
  detailed errors off). *Accept:* health returns 200; integration test green.
- `M0‑API‑3` EF6 + MySQL wiring via `configSource`; apply `db/linkittydo/schema.sql`
  (v1) into `ExploreInfoGoer` (covered by the existing `BirdMan` grants). *Accept:*
  app connects to `ExploreInfoGoer`; `ExploreInfoGoer_Test` used for tests.
- `M0‑API‑4` CORS policy (dev/prod origins) + preflight. *Accept:* `OPTIONS`
  preflight integration test passes.
- `M0‑API‑5` `GET /api/meta/profile-options` + `GET /api/content/{key}` (seedable).
  *Accept:* returns the profile‑property catalog.
- `M0‑API‑6` `verify.ps1` (install/build/unit+integration) + thin CI re‑run.
- `M0‑API‑7` Seed scripts: roles + an admin user (credentials at deploy) + 5–6
  sample games with precomputed parses/clues/links. *Accept:* catalog has live
  games without running the pipeline.

**WEB**
- `M0‑WEB‑1` Onboard repo: `PROJECT.md` from react‑spa profile, sync assets,
  `.env.example`, `README`.
- `M0‑WEB‑2` SPA shell: `AppShell`, `Header`, `VerticalNav`, `HorizontalNav`,
  `Footer`, `Modal`/`Mask`; React Router; config alias (dev/prod API base).
- `M0‑WEB‑3` `apiClient` + `session`‑less bootstrap calling `/api/health` &
  `/api/meta/profile-options`. *Accept:* shell renders; dev server proxies to local
  API; unit + integration (msw) tests green; `verify.ps1` green.

## M1 — Accounts & auth (API‑first)

**API**
- `M1‑API‑1` `POST /api/auth/register` (+ ReCaptcha verify) creating a `pending`
  `Player`. *Accept:* duplicate email → 409; password stored **hashed+salted**.
- `M1‑API‑2` `POST /api/auth/activate`.
- `M1‑API‑3` `POST /api/auth/login` → bearer token with role claims;
  `POST /api/auth/logout`; `GET /api/auth/me`.
- `M1‑API‑4` `POST /api/auth/recover` (name/password by email).
- `M1‑API‑5` Users/profile: `GET/PUT /api/users/{id}`, `/props`,
  `/default-profile`. *Accept:* owner‑only; validation (`422`); concurrency via
  `sysversion` (`409`).

**WEB**
- `M1‑WEB‑1` Auth UI (login, join + ReCaptcha, recover) + `session` slice; token
  persistence; `401` → logout.
- `M1‑WEB‑2` Profile editor incl. the **default game profile** flag grid.
- `M1‑WEB‑3` Role‑aware nav + `RequireRole` guard (admin hidden for non‑admins).

## M2 — Game catalog & browse (API‑first)

**API**
- `M2‑API‑1` `GET /api/games` (filters: q/tag/creator/status, paged; players see
  `live`). *Accept:* search by title/tag/creator returns expected rows.
- `M2‑API‑2` `GET /api/games/{id}`, `/parses`, `/profile`.

**WEB**
- `M2‑WEB‑1` Games Mgr browse/search list with the status key coloring.
- `M2‑WEB‑2` Game detail + "choose parse to play" entry point.

## M3 — Game play (API‑first)

**API**
- `M3‑API‑1` `POST /api/plays` (start) + `GET /api/plays`, `GET /api/plays/{id}`.
- `M3‑API‑2` `POST /api/plays/{id}/clues` (clue selection: random / favor prior
  weighted) + `GET …/clues`. *Accept:* only unrevealed clues for unsolved ordinals.
- `M3‑API‑3` `POST /api/plays/{id}/guesses` (evaluate, solve ordinals, reinforce
  weights, score) + `GET …/guesses`. *Accept:* solving all ordinals ⇒ `solved`,
  score computed; integration tests cover correct/incorrect/solve paths.
- `M3‑API‑4` `POST /api/plays/{id}/giveup`.

**WEB**
- `M3‑WEB‑1` Play screen: parse skeleton with per‑position clue counts; New Clue
  modal; guess input; Clues/Guesses tabs; give‑up confirm; score/header.
- `M3‑WEB‑2` Games History view.

## M4 — Game creation + NLP parser (API‑first)

**API**
- `M4‑API‑1` Parser service (`iParser`/OpenNLP) + `POST /api/parser/parse` &
  `GET /api/parses/{id}`. *Accept:* a phrase returns parses with scored nodes;
  unit tests mock the model, one integration test runs a real parse.
- `M4‑API‑2` `POST /api/games` creation pipeline (validate → stem → parse →
  related words (WordNet) → clue discovery via search provider), async; status
  `new→processing→processed→approval_ready`. *Accept:* creating a game yields
  parses + clues/links; provider is mockable in tests.
- `M4‑API‑3` Search provider adapter + WordNet relation expansion (by/!by POS).

**WEB**
- `M4‑WEB‑1` Add Game form (title/phrase/tags + profile grid) with a **parse
  preview** (calls `/api/parser/parse`).
- `M4‑WEB‑2` Creation status feedback (pipeline steps) until `approval_ready`.

## M5 — Admin console (API‑first)

**API**
- `M5‑API‑1` `GET /api/admin/games` (all statuses + stats).
- `M5‑API‑2` `POST /api/admin/games/{id}/process` (re‑run pipeline).
- `M5‑API‑3` `POST /api/admin/games/{id}/status` (approve → live / not_approved /
  unavailable) + `PUT /api/games/{id}` admin edit.
- `M5‑API‑4` `GET /api/admin/users` + `POST /api/admin/users/{id}/roles`.

**WEB**
- `M5‑WEB‑1` Admin Games tab + Game Edit modal (fields, status actions, pipeline
  results, stats).
- `M5‑WEB‑2` Admin Users tab (role grant/revoke).

## Deferred backlog (P2 / P3 / Future)

- **M6 Societies (P2):** `LK_SOCIETIES`/membership/comments tables already in
  [schema.sql](./schema/schema.sql); `SocietiesController` CRUD + join/quit +
  comment moderation; SPA Society screens.
- **M7 News/content (P3):** `LK_NEWS`/`LK_CONTENT`; News CRUD + home feed + Footer
  content blocks (Contact/Privacy/About/Help) sourced from `/api/content/{key}`.
- **Future:** web Crawler (Heritrix/Lucene), custom **Linkitty** search engine, and
  the crawler index DB — new stack profile(s) likely required; keep clue discovery
  behind the provider adapter so this is a drop‑in later.

## Critical path & dependencies

```text
M0 ─▶ M1 ─▶ M2 ─▶ M3                 (play uses seeded games from M0/M2)
          └▶ M4 ─▶ M5                 (admin approves created games to live)
M6 (P2), M7 (P3), Future  ── independent, after MVP
```

Within every milestone the **API issue lands first** (backward‑compatible), then
the WEB issue that consumes it, each closing its own issue in its own repo.
