# Changelog — LinkittyDoRanch plan

Notable revisions to the delivery plan. The plan is documentation; the application
itself changes in the implementing repos (`api.infogoer.com`, `linkittydo-web`).

## 2026-10-31 — Follow-ups complete; M0/M1 API backlog + SPA repo created

- **`api.infogoer.com` M0-API-7 seed scripts** delivered as PR #19: idempotent
  `db/linkittydo/seed_admin.sql` + `Seed-Admin.ps1` (PBKDF2 admin seed, no
  credentials committed) and `seed_sample_games.sql` (6 live sample games via a
  temporary stored procedure); forward-compatible smoke test added.
- **`api.infogoer.com` M1 backlog captured** as issues #20–#23: activate (#20),
  login/logout/me JWT flow (#21), password recovery (#22), user/profile endpoints
  (#23).
- **`philiv99/linkittydo-web` created** via `agentic/scripts/new-repo.ps1
  -Stack react-spa`; PROJECT.md filled in from this draft; AGENTS.md and agentic
  skills synced; standard labels applied; CHANGELOG.md stub added.
- **`agentic` consumers.json** updated to register `linkittydo-web` (PR #22).
- **`linkittydo-web` M0 WEB issues** captured: deployment files (#1), SPA shell
  (#2), apiClient + bootstrap (#3).
- **`workspaces/linkittydo.code-workspace`** created listing agentic, API, SPA,
  and plan folders.
- **Plan §08 follow-ups** all marked done (see the revised follow-ups section).

## 2026-10-31 — Backend consolidation + SPA deployment workflow

- **Backend consolidated into `api.infogoer.com`** (schema `ExploreInfoGoer`) instead
  of a new `api.linkittydo.com`. Updated base URLs (dev `:10152`, prod
  `https://api.infogoer.com`), DB names (`ExploreInfoGoer` / `ExploreInfoGoer_Test`,
  app user `BirdMan`), and the schema location (`db/linkittydo/schema.sql`). Resolves
  open question **O1** (API on `api.infogoer.com`; SPA stays `www.linkittydo.com`);
  recorded as decision **D12**. Superseded
  `projects/api.linkittydo.com.PROJECT.md` with a pointer stub.
- **`linkittydo-web` adopts the agentic react-spa deployment workflow**
  (`agentic/templates/deployment/react-spa/` + the `setup-spa-deployment` skill):
  webpack 4 build, `ftpdeploy.js` to `ftp.infogoer.com`, `src/devconfig.js` /
  `src/prodconfig.js` exporting `IGAPIURL` pointed at the infogoer API, dev server on
  port `8080`.
- Backend foundation already implemented in `api.infogoer.com#10` (health endpoint +
  `LK_*` schema); remaining backlog captured in `api.infogoer.com#11–#15`.

## 2026-10-30 — Initial delivery plan

- Published the full LinkittyDoRanch delivery plan (`00`–`08`, `PROJECT.md` drafts,
  `schema/schema.sql`) under `plan/` (merged via LinkittyDoRanch #1).
