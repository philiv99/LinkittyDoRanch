# Changelog — LinkittyDoRanch plan

Notable revisions to the delivery plan. The plan is documentation; the application
itself changes in the implementing repos (`api.infogoer.com`, `linkittydo-web`).

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
