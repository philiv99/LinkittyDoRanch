# 07 — Testing, CI & Release

Testing is **mandatory** on both stacks: new or changed behavior ships with
**unit + integration** tests, both suites pass locally via `verify.ps1` before
push, and CI is a thin re‑run. Deployment is human‑run, API‑before‑SPA.

## API — `api.infogoer.com` (dotnet‑webapi, consolidated backend)

Per the [dotnet-webapi profile](../../agentic/stacks/dotnet-webapi.md):

- **Test project:** `V1.Tests` (`net472`, SDK‑style `PackageReference`) in
  `api.infogoer.com` using **xUnit** + **Moq**.
- **Unit tests** — Logic managers, scoring/weighting, parser result mapping,
  profile interpretation, validators — with **EF6 and external calls (parser,
  WordNet, search provider) mocked**. Mirror the namespace under test.
- **Integration tests** (`Integration/` folder) — each controller route
  end‑to‑end against a dedicated **`ExploreInfoGoer_Test`** MySQL database (schema
  from `db/linkittydo/schema.sql`), gated by `INFOGOER_TEST_BASEURL` and driven with
  `HttpClient`. Assert status codes, payload shape, auth/role enforcement,
  `sysversion` conflict (`409`), and a **CORS preflight**.
- **Gated behind the test DB** so unit tests always run without a database.
- **Run:** `vstest.console.exe` / `dotnet test` emitting TRX + coverage.

Representative must‑have integration tests: register→activate→login happy path and
duplicate‑email conflict; play a seeded game to `solved` with a correct score;
create a game (mocked provider) reaching `approval_ready`; admin approve → `live`;
players cannot reach admin routes (403).

## WEB — `linkittydo-web` (react‑spa)

Per the [react-spa profile](../../agentic/stacks/react-spa.md):

- **Jest** + `@testing-library/react` (+ `@testing-library/jest-dom`).
- **Unit tests** — components, reducers, selectors, thunks (`*.test.jsx` beside
  the unit or under `__tests__/`).
- **Integration tests** (`src/__tests__/integration/`) — connected components
  against a **real Redux store** with the API mocked via **`msw`** (login flow,
  catalog search, a play round, add‑game preview, admin guard redirect).
- **Optional E2E** (`e2e/`, Playwright) against the dev server wired to a local
  API — opt‑in, not a CI gate.
- **Run:** `npm test` (`jest --ci --coverage`).

## `verify.ps1` (local authoritative gate, both repos)

Each repo has a `verify.ps1` that **installs, builds, and runs unit +
integration** suites and must be **green before any commit/push**:

- **API:** restore → MSBuild Release (`V1`) → `dotnet test` (`V1.Tests`); integration
  tests self‑skip unless `INFOGOER_TEST_BASEURL` points at an `ExploreInfoGoer_Test`‑backed API.
- **WEB:** `npm ci` → build → `jest --ci --coverage` (unit + integration).

`verify.ps1` runs **only locally** (it needs DB/credentials a GitHub runner
lacks). Record the exact commands and the test‑DB name in each repo's `PROJECT.md`.

## CI (thin re‑run, no secrets, never deploys)

A PR workflow per repo re‑runs the **build + unit/integration** portion on a runner
whose OS matches the stack (Windows for the API). CI runners are disposable build
VMs — **not** a third environment — and they do not run the credential‑dependent
parts of `verify.ps1` or deploy. The CI **verify** workflow is disabled by design;
human review + local `verify.ps1` is the gate.

## Versioning & release

- **Semantic versioning** (`MAJOR.MINOR.PATCH`). Version files per stack:
  - **API** — a `VERSION` file and/or a `schema-version` row; the `sysversion`
    concurrency token continues at the row level.
  - **WEB** — `package.json` `version`.
- Each repo keeps a `CHANGELOG.md`.
- **Release order (cross‑repo):** deploy the **backward‑compatible API first**,
  smoke‑test it, then deploy the SPA that depends on it. Record the **paired
  commit IDs** and the **rollback choice** via the `review-release` skill.
- **Deploy scripts (human‑run):**
  - **API** — PowerShell FTPS: publish Release → back up live site + DB → read‑only
    pre‑deploy validation → upload → generate the git‑ignored connection‑string
    file for prod → post‑deploy smoke test.
  - **WEB** — the agentic react-spa deployment workflow: `npm run deploy`
    (`webpack.prod.js` → `dist/`, then `node ftpdeploy.js` to `ftp.infogoer.com`);
    credentials from a git‑ignored `.env` (aborts if `FTP_*` unset).
- **Rollback:** redeploy the previous tagged commit; because schema changes stay
  backward‑compatible with the prior API version, an API rollback is safe without a
  DB restore (keep the pre‑deploy DB backup regardless).

## Definition of done (per issue)

1. Code + unit + integration tests on a `<type>/<issue>-<slug>` branch.
2. `verify.ps1` green locally.
3. PR opened with tests listed and `Closes #N`; draft until checks pass.
4. `review` agent checks it against the plan's acceptance checks.
5. A person merges (closing the issue); release recorded when deployed.
