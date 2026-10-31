# PROJECT.md — `linkittydo-web`

<!--
DRAFT authored during planning (plan/projects/). When the repo is created, copy
this file to the repo root as PROJECT.md and adjust the relative links to the
sibling `agentic` repo. Authored from the react-spa stack profile; this file
supplies only concrete values. NO CREDENTIALS HERE — record only the *location* of
git-ignored settings and their committed *.example templates.
-->

## Stack

- **Profile:** `react-spa` (React 16 + Redux, webpack 4, webpack‑dev‑server 3)
- **Summary:** Single‑page app for Linkitty‑Do Ranch — the public game site **and**
  the admin console in one SPA; admin routes gated by the `Administrator` role.

## Paths

- **Solution / project / package paths:** `package.json` · `webpack.common.js` /
  `webpack.dev.js` / `webpack.prod.js` · `ftpdeploy.js` · `src/`
- **Entry points:** `src/index.js` (`AppShell` + React Router) with
  `src/template.html` (HtmlWebpackPlugin). Config modules `src/devconfig.js` /
  `src/prodconfig.js`, selected by the webpack alias `config`, each default-exporting
  `{ IGAPIURL }` (the API base URL) plus any client-side values.

## Build, run, deploy

Build/deploy files come from the agentic **react-spa deployment workflow**
([`templates/deployment/react-spa/`](../../../agentic/templates/deployment/react-spa/README.md)),
installed/updated by the
[`setup-spa-deployment`](../../../agentic/templates/.github/skills/setup-spa-deployment/SKILL.md)
skill. Each npm script sets `NODE_OPTIONS=--openssl-legacy-provider` inline.

| Action | Command / script |
| --- | --- |
| Install / restore | `npm ci` |
| Run (local) | `npm start` (webpack‑dev‑server on port **8080**, `webpack.dev.js`) |
| Build only | `npm run deploynoftp` (`webpack.prod.js` → `dist/`) |
| Deploy (production, human‑run) | `npm run deploy` (build **plus** `node ftpdeploy.js`; aborts if `FTP_USER`/`FTP_PASSWORD`/`FTP_REMOTE_PATH` unset) |

## Hosts, URLs, ports

- **Local run port(s):** `8080`
- **Local base URL:** `http://localhost:8080`
- **API base URL — dev / prod (`IGAPIURL`):** `http://localhost:10152/api` /
  `https://api.infogoer.com/api` (the consolidated **api.infogoer.com** backend)
- **Config module / alias that switches dev vs prod (SPA):** webpack alias
  `config` → `src/devconfig.js` / `src/prodconfig.js`
- **Public / production URL:** `https://www.linkittydo.com` (and `https://linkittydo.com`)
- **Deploy host / remote path:** `ftp.infogoer.com` (`FTP_HOST` default) /
  `FTP_REMOTE_PATH` = the LinkittyDo SPA web root on that host *(confirm the remote path)*

## Database

- **Engine:** `n/a` (consumes the API)

## CORS

- **Allowed origins — dev / prod:** `n/a` (the API owns CORS; this SPA's origins
  are `http://localhost:8080` dev and `https://www.linkittydo.com` prod)

## Secrets & configuration

- **Git‑ignored settings / `.env` file:** `.env` — FTP deploy credentials
  (`FTP_USER`, `FTP_PASSWORD`, `FTP_REMOTE_PATH`, optional `FTP_HOST`)
- **Committed example template:** `.env.example`
- **Secrets injected at:** deploy time (shell env / `.env`); `ftpdeploy.js` aborts
  if required vars are unset
- **Client‑side tokens, if any:** `IGAPIURL` and the ReCaptcha **site key** are
  compiled into the public bundle by design — treat as public; restrict & rotate at
  the provider (O2)

## Tests

- **Unit test command:** `npm test` (`jest --ci --coverage`)
- **Integration test command:** `npm test` (integration specs under
  `src/__tests__/integration/`, API mocked via `msw`)
- **Test location / layout:** `*.test.jsx` beside components or under
  `__tests__/`; integration under `src/__tests__/integration/`; optional Playwright
  E2E under `e2e/`
- **Coverage baseline:** `<set at M0>`
- **Local verify gate:** `./verify.ps1`

## Routes / API contract (API repos)

- **Controller / route inventory:** `n/a` (consumer) — calls the contract in
  [../03-api-contract.md](../03-api-contract.md)
- **Shared/meta endpoints read by multiple SPAs:** consumes
  `GET /api/meta/profile-options`, `GET /api/content/{key}`, `GET /api/news`,
  `GET /api/health`

## Release

- **Version file(s):** `package.json` (`version`)
- **Changelog:** `CHANGELOG.md`
- **Rollback choice convention:** redeploy the previous tagged commit's `dist/`
