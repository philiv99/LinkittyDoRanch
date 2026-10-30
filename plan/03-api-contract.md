# 03 — API Contract

The versioned HTTP contract owned by
[`api.linkittydo.com`](./projects/api.linkittydo.com.PROJECT.md). All routes are
JSON over HTTPS under the base path **`/api`**. The SPA is the only consumer today,
but endpoints are designed as a stable contract. This inventory is the
authoritative route list referenced from the API repo's `PROJECT.md`.

## Conventions

- **Base URLs** — dev `http://localhost:52080/api`, prod
  `https://api.linkittydo.com/api`.
- **Auth** — bearer token from `POST /api/auth/login` sent as
  `Authorization: Bearer <token>`; roles are claims. Every protected route checks
  the role **server‑side** (the SPA only hides admin UI).
- **Access levels** used below: `public` (no auth), `player` (any authenticated
  user), `owner` (the authenticated user must own the resource), `admin`
  (`Administrator` role).
- **Paging** — list endpoints accept `?page=&pageSize=&sort=` and return
  `{ items, page, pageSize, total }`.
- **Errors** — a uniform shape `{ error: { code, message, details? } }`; **4xx**
  for client faults, **5xx** sanitized (no stack/internal details in production).
- **Concurrency** — writes echo `sysversion`; a stale token yields `409 Conflict`.
- **Validation** — request bodies validated in the logic layer; `422` for
  validation failures.
- **Versioning** — breaking changes ship as additive v2 routes; the current
  contract stays backward‑compatible (see
  [07-testing-ci-release.md](./07-testing-ci-release.md)).

## Controllers ↔ original Logic managers

| Controller | Backing manager (`lk.Logic`) | Area |
| --- | --- | --- |
| `AuthController`, `UsersController`, `ProfilesController` | `User`, `SiteMgr` | Accounts (P1) |
| `GamesController`, `ParserController` | `Game`, `WordRelations`, `Service.Tool.Parser` | Catalog + creation (P1) |
| `PlaysController` | `Game`, `LinkittyMgr` | Play (P1) |
| `AdminController` | `GameAdmin` | Admin console (P1) |
| `MetaController`, `NewsController`, `ContentController` | `SiteMgr` | Meta/home (P1 meta; News P3) |
| `SocietiesController` | `Society` | Social (P2) |

## Endpoint inventory

### Auth & accounts (P1)

| Method & path | Access | Purpose |
| --- | --- | --- |
| `POST /api/auth/register` | public | Create an account (nickname, email, password, ReCaptcha token). Creates a `pending` user with role `Player`. |
| `POST /api/auth/activate` | public | Activate via emailed token (`iUser.activate`). |
| `POST /api/auth/login` | public | Validate credentials (`iSecurable.match`) → `{ token, user, roles }`. |
| `POST /api/auth/logout` | player | Invalidate the current token. |
| `POST /api/auth/recover` | public | Recover **name or password** (the two "Click here" links in the login wireframe) by email. |
| `GET /api/auth/me` | player | Current user + roles (session bootstrap). |

### Users & profile (P1)

| Method & path | Access | Purpose |
| --- | --- | --- |
| `GET /api/users/{id}` | owner/admin | Profile (nickname, email, thumbnail URL, status). |
| `PUT /api/users/{id}` | owner | Edit nickname/email/password/thumbnail (profile wireframe). |
| `GET /api/users/{id}/props` | owner | Generic user properties (`LK_USER_PROPS`). |
| `PUT /api/users/{id}/props` | owner | Upsert properties. |
| `GET /api/users/{id}/default-profile` | owner | The user's **default game profile** set. |
| `PUT /api/users/{id}/default-profile` | owner | Replace the default game profile (the profile editor). |

### Games — catalog & creation (P1)

| Method & path | Access | Purpose |
| --- | --- | --- |
| `GET /api/games` | player | Browse/search catalog. Filters: `q` (title), `tag`, `creator`, `status` (defaults to `live` for players). Returns play status per the caller. |
| `GET /api/games/{id}` | player | Game detail: title, phrase, tags, status, counts, default parse id. |
| `GET /api/games/{id}/parses` | player | Parses for the game (for choosing which to play). |
| `GET /api/games/{id}/profile` | player | The game's creation profile (read‑only to players). |
| `POST /api/games` | player | **Create a game** (title, phrase, tags, profile). Creates the phrase, kicks off the creation pipeline, returns `gstatus=processing`. See [05-game-mechanics.md](./05-game-mechanics.md). |
| `PUT /api/games/{id}` | admin | Edit game (admin "Game Edit": title, phrase, tags, profile, status). |

### Parser tool (P1)

| Method & path | Access | Purpose |
| --- | --- | --- |
| `POST /api/parser/parse` | player | `iParser.parse(phrase)` → candidate parses with nodes & scores (preview before create). Body `{ phrase }`; response includes `parses[].nodes[]` (position, row, wordStart/Length, charStart/Length, partOfSpeech) and `pascore`. |
| `GET /api/parses/{id}` | player | A stored parse + its nodes. |

### Play (P1)

| Method & path | Access | Purpose |
| --- | --- | --- |
| `POST /api/plays` | player | Start a played game `{ gameId, parseId }` → `playedGameId`, status `started`. |
| `GET /api/plays` | player | Caller's play history (Games History: new/old games). |
| `GET /api/plays/{id}` | owner | Play state: counts, solved ordinals, score, status, the parse skeleton. |
| `POST /api/plays/{id}/clues` | owner | **Request a new clue** for an unsolved position `{ ordinal }`. Server selects a clue (random / favor prior weighted), records `LK_CLUES_PLAYED`, returns the clue's links (url, title) per the profile display style. |
| `GET /api/plays/{id}/clues` | owner | Clues revealed so far (the Clues tab: date, URL, page title). |
| `POST /api/plays/{id}/guesses` | owner | **Submit a guess** `{ ordinal, words }`. Returns correctness, updated solved ordinals, score, and whether the game is solved. Applies weight reinforcement. |
| `GET /api/plays/{id}/guesses` | owner | Guess history (the Guesses tab). |
| `POST /api/plays/{id}/giveup` | owner | "I give up" → status `quit`. |

### Admin (P1)

| Method & path | Access | Purpose |
| --- | --- | --- |
| `GET /api/admin/games` | admin | All games, any status, with admin stats (played/gave‑up/solved/clues/guesses). |
| `POST /api/admin/games/{id}/process` | admin | (Re)run the creation pipeline (parse → related words → clue discovery). |
| `POST /api/admin/games/{id}/status` | admin | Transition status `{ status }` (`approval_ready`→`live`/`not_approved`/`unavailable`). |
| `GET /api/admin/users` | admin | User management list/search. |
| `POST /api/admin/users/{id}/roles` | admin | Grant/revoke roles. |
| `GET /api/admin/societies` | admin | Societies overview (read‑only in P1). |
| `GET/POST/PUT/DELETE /api/admin/news` | admin | News CRUD (**P3**; stubbed in P1). |

### Meta / shared endpoints (P1)

These are **read by the whole SPA** (and any future consumer); their shape is
defined once here and recorded in the API repo's `PROJECT.md` so every consumer
reads them identically.

| Method & path | Access | Purpose |
| --- | --- | --- |
| `GET /api/health` | public | Liveness/readiness. |
| `GET /api/meta/profile-options` | public | The **catalog of game‑profile properties** (relations, search styles, context styles, display styles, search engines, grammatical depth) used to render profile editors. |
| `GET /api/meta/roles` | admin | Role list. |
| `GET /api/news` | public | Home news feed (published). **P3** content; returns seed data in P1. |
| `GET /api/content/{key}` | public | Site content blocks (home intro, about, privacy, help). |

### Societies (P2)

`GET/POST /api/societies`, `GET/PUT/DELETE /api/societies/{id}`,
`POST /api/societies/{id}/members` (join), `DELETE …/members/{userId}` (quit),
`GET/POST /api/societies/{id}/comments`, `PUT …/comments/{commentId}` (moderate).

## Game‑profile property catalog (for `GET /api/meta/profile-options`)

Drives both the game‑creation and default‑profile editors (wireframes 1, 3).
Grouped by `prtype`:

- **relation** — `original_word`, `synonyms`, `antonyms`, `meronyms`
- **search_style** — `related_words`, `by_pos`, `not_by_pos`, `seed_with_original`,
  `seed_with_tags`, `quote_text`
- **context_style** — `reference`, `non_reference`
- **display_style** — `web_pages`, `words`, `context_tags`
- **search_engine** — `yahoo`, `google`, `msn`, `amazon`, `linkitty` *(linkitty =
  future/disabled)*
- **grammatical_depth** — `phrase`, `parse`

A **profile** persisted in `LK_PROFILES` is the set of selected flags (as
`prtype`/`prname`/`prvalue` rows) sharing one `profile_id`.

## CORS

Allowed origins: dev `http://localhost:3000`; prod `https://www.linkittydo.com`,
`https://linkittydo.com`. Preflight (`OPTIONS`) is covered by an integration test
(per the [dotnet-webapi profile](../../agentic/stacks/dotnet-webapi.md)).
