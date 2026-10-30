# 04 — Front‑end Plan (`linkittydo-web`)

**One** React 16 + Redux SPA on webpack 4 ([react-spa
profile](../../agentic/stacks/react-spa.md)) serving **both** the public game site
and the admin console. Admin routes are gated by the `Administrator` role; the SPA
hides admin UI, the API enforces it.

Derived from the seven wireframes under
[Wireframes](../design/LinkittyDo/Wireframes) and the
[Site Map](../design/LinkittyDo/Architecture/Site%20Map.docx).

## Layout & shell

The wireframes describe a consistent chrome (Header, Vertical Nav, Horizontal Nav,
Main Panel, Content/News widgets, Footer, and a Modal + Mask overlay). Componentize
as:

- `AppShell` — `Header` (logo "Linkitty‑Do Ranch", tagline, Help/Log in/out),
  `VerticalNav` (primary menu), `HorizontalNav` (section sub‑menu), `MainPanel`
  (routed view), `Footer` (Home | Contact | Privacy | About), and a global
  `Modal`/`Mask` for popups (news article, help, login/join, confirm).
- `VerticalNav` items switch by auth state: **not logged in** → Home, News;
  **logged in** → Home, News, Play, Games Mgr, Society (P2), Profile; **admin** also
  shows Admin.

## Site map → routes

| Route | Screen | Wireframe | Access |
| --- | --- | --- | --- |
| `/` | Home (news feed + intro; logged‑in vs guest variants) | [Home (logged in)](../design/LinkittyDo/Wireframes/1%20-%20Home%20%28logged%20in%29.docx) / [Home (not logged in)](../design/LinkittyDo/Wireframes/1%20-%20Home%20%28not%20logged%20in%29.docx) | public |
| `/login`, `/join`, `/recover` | Auth modals/pages (login, register+ReCaptcha, recover name/password) | Home (not logged in) | public |
| `/games` | Games Mgr — browse/search (title/tags/creator; status key) | [Games Mgr](../design/LinkittyDo/Wireframes/3%20-%20Games%20Mgr_.docx) | player |
| `/games/new` | Add Game (title, phrase, tags, profile flags) | Games Mgr | player |
| `/games/:id` | Game detail / choose parse to play | Games Mgr / Play | player |
| `/play/:playId` | Play screen (parse skeleton, clues, guesses, score, give‑up) | [Play](../design/LinkittyDo/Wireframes/2%20-%20Play.docx) | owner |
| `/history` | Games History (new/old games) | Play | player |
| `/profile` | Profile editor (nickname, email, password, thumbnail, **default game profile**) | Home (logged in) | owner |
| `/society` … | Societies (list/detail/comments) | [Society](../design/LinkittyDo/Wireframes/4%20-%20Society.docx) | player — **P2** |
| `/admin`, `/admin/games`, `/admin/games/:id`, `/admin/users`, `/admin/news` | Admin console (games, users, news, societies) | [Admin](../design/LinkittyDo/Wireframes/6%20-%20Admin.docx) | **admin** |
| Footer modals: Contact, Privacy, About, Help | Overlays on any route | [Footer](../design/LinkittyDo/Wireframes/5%20-%20Footer.docx) | public |

Routing via React Router; admin routes wrapped in a `RequireRole("Administrator")`
guard that redirects non‑admins.

## Redux state shape

| Slice | Holds | Backed by |
| --- | --- | --- |
| `session` | token, currentUser, roles, auth status | `/api/auth/*` |
| `profile` | profile, props, defaultProfile | `/api/users/{id}*` |
| `meta` | `profileOptions`, site `content` | `/api/meta/*`, `/api/content/*` |
| `games` | catalog items, filters, `byId`, `parsesById` | `/api/games*`, `/api/parses/*` |
| `parser` | parse preview results | `/api/parser/parse` |
| `play` | current playedGame, clues, guesses, solvedOrdinals, score, status | `/api/plays/*` |
| `news` | home feed | `/api/news` |
| `admin` | admin games, users, selection | `/api/admin/*` |
| `societies` *(P2)* | societies, members, comments | `/api/societies/*` |
| `ui` | active nav, open modal, notifications | — |

Unit‑tested **reducers, selectors, and thunks** per the react‑spa profile.

## API integration

- A thin `apiClient` (fetch) reads the base URL from the **config module**
  selected by a webpack **alias** (`config` → `config.dev.js` / `config.prod.js`),
  so the SPA points at `http://localhost:52080/api` in dev and
  `https://api.linkittydo.com/api` in prod.
- The client attaches `Authorization: Bearer <token>` from `session`; a `401`
  dispatches logout and routes to `/login`.
- Thunks encapsulate each call; components stay presentational where practical.

## Key screen behaviors (from wireframes)

- **Home** — News widget lists blurbs (date, source) with "read more…" opening a
  **modal** article; RSS link; logged‑in vs guest nav. Vertical/horizontal nav
  click behavior (activate/deactivate panels) maps to route + `ui` state.
- **Play** — renders the chosen parse as a row of **positions**; each position
  shows a clue count ("2 clues…", "no clues…"). "New Clue" opens a modal with the
  web‑page clue (per display style) and a **guess** input. Tabs switch between
  **Clues** (date, URL, page title) and **Guesses** (date, guess). Header shows
  Start Date, Clues, Guesses, score; "I give up" confirms via modal.
- **Games Mgr** — Browse/Search toggle; result rows (Create Date, Creator, Tags,
  Title) colored by the player's status key (not played / in process / completed /
  score). "Add Game" opens the creation form with the profile flag grid.
- **Profile** — edit identity fields and the **default game profile** (the same
  flag grid as Add Game), persisted to `/api/users/{id}/default-profile`.
- **Admin** — Users/Games tabs; game rows show status + stats (played, gave up,
  solved, clues, guesses); "Game Edit" modal edits fields and drives the status
  lifecycle (`approval_ready` → `live`/`not_approved`), showing pipeline step
  results (phrase validation, stemming, parsing, related‑word generation).

## Build, run, test, deploy

Per the [react-spa profile](../../agentic/stacks/react-spa.md) and
[projects/linkittydo-web.PROJECT.md](./projects/linkittydo-web.PROJECT.md):

- `npm start` (webpack‑dev‑server 3, `NODE_OPTIONS=--openssl-legacy-provider`) on
  port **3000**.
- **Jest + @testing-library/react** unit tests (`*.test.jsx` beside components);
  **integration** tests under `src/__tests__/integration/` render connected
  components against a real store with the API mocked via `msw`; optional
  **Playwright** E2E under `e2e/` against the dev server wired to a local API.
- `verify.ps1` runs install + build + unit + integration; deploy is `ftp-deploy`
  of `dist/` (human‑run, credentials from a git‑ignored `.env`).
