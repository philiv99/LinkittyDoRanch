# PROJECT.md — `api.linkittydo.com`

<!--
DRAFT authored during planning (plan/projects/). When the repo is created, copy
this file to the repo root as PROJECT.md and adjust the relative links to the
sibling `agentic` repo. Authored from the dotnet-webapi stack profile; this file
supplies only concrete values. NO CREDENTIALS HERE — record only the *location* of
git-ignored settings and their committed *.example templates.
-->

## Stack

- **Profile:** `dotnet-webapi` (ASP.NET Web API 2, .NET Framework 4.7.2, EF6, MySQL)
- **Summary:** Shared HTTP API for Linkitty‑Do Ranch — accounts, games, play,
  admin, and the NLP parser tool; owns the data model and the versioned contract.

## Paths

- **Solution / project / package paths:** `src/LinkittyDo.Api.sln` ·
  `src/LinkittyDo.Api/LinkittyDo.Api.csproj` · `packages.config` ·
  tests `src/LinkittyDo.Api.Tests/`
- **Entry points:** `src/LinkittyDo.Api/Global.asax` +
  `App_Start/WebApiConfig.cs`. Layers: `Api/` (controllers) ▸ `Logic/` (managers)
  ▸ `Service/` (Tool.Parser, WordInfo, Search) ▸ `Data/` (EF6 `DbContext`) ▸
  `System/`.

## Build, run, deploy

| Action | Command / script |
| --- | --- |
| Install / restore | `nuget restore src/LinkittyDo.Api.sln` (restore `packages.config`) |
| Build | `msbuild src/LinkittyDo.Api.sln /p:Configuration=Release` |
| Run (local) | IIS Express on port **52080** (or `dotnet`‑less MSBuild + IIS) |
| Deploy (production, human‑run) | `deploy/deploy.ps1` (FTPS: publish Release → back up site+DB → validate → upload → generate prod `connectionStrings.config` → smoke test) |

## Hosts, URLs, ports

- **Local run port(s):** `52080`
- **Local base URL:** `http://localhost:52080`
- **API base URL — dev / prod:** `http://localhost:52080/api` /
  `https://api.linkittydo.com/api`
- **Config module / alias that switches dev vs prod (SPA):** `n/a (API)`
- **Public / production URL:** `https://api.linkittydo.com`
- **Deploy host / remote path:** `<ftp-host>` / `<remote-path>` *(confirm — O1)*

## Database

- **Engine:** MySQL 8.x (EF6 via `MySql.Data` / `MySql.Data.Entity`)
- **Database name / app user:** `linkittydo` / `lk_app` *(never `root`)*
- **Connection source:** `connectionStrings.config` (git‑ignored) loaded via
  `<connectionStrings configSource="connectionStrings.config" />` in `Web.config`
- **Test database name:** `linkittydo_test`
- **Schema & grants scripts:** `db/schema.sql` · `db/grants.sql` · `db/seed.sql`
  (draft: [../schema/schema.sql](../schema/schema.sql))

## CORS

- **Allowed origins — dev / prod:** `http://localhost:3000` /
  `https://www.linkittydo.com`, `https://linkittydo.com`

## Secrets & configuration

- **Git‑ignored settings / `.env` file:** `connectionStrings.config`
- **Committed example template:** `connectionStrings.config.example`
- **Secrets injected at:** deploy time (deploy script generates the prod
  connection‑string file); `Web.Release.config` XDT sets non‑secret prod values
  (detailed errors off, remove `debug`)
- **Client‑side tokens, if any:** `n/a` (ReCaptcha **secret** is server‑side;
  store its location here when chosen — O2)

## Tests

- **Unit test command:** `vstest.console.exe src/LinkittyDo.Api.Tests/bin/Release/LinkittyDo.Api.Tests.dll`
- **Integration test command:** same assembly, `Integration/` tests gated by the
  `linkittydo_test` connection string
- **Test location / layout:** `src/LinkittyDo.Api.Tests/` (mirror namespace for
  unit; `Integration/` for route tests) — per the stack profile
- **Coverage baseline:** `<set at M0>`
- **Local verify gate:** `./verify.ps1`

## Routes / API contract (API repos)

- **Controller / route inventory:** see
  [../03-api-contract.md](../03-api-contract.md)
- **Shared/meta endpoints read by multiple SPAs:** `GET /api/health`,
  `GET /api/meta/profile-options`, `GET /api/content/{key}`, `GET /api/news`
  (shapes defined in the contract doc)

## Release

- **Version file(s):** `VERSION` + a `schema-version` row (row‑level `sysversion`
  concurrency token continues per the data model)
- **Changelog:** `CHANGELOG.md`
- **Rollback choice convention:** previous tagged commit (schema stays
  backward‑compatible with the prior API version; keep the pre‑deploy DB backup)
