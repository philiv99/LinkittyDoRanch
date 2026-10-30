# 02 — Data Model

A **fresh MySQL schema** (InnoDB, `utf8mb4`) derived from the four original
SQL Server ER diagrams. **No data migration** — the schema is scripted (DDL +
grants + seed) and lives in the API repo's `db/` folder. Draft DDL:
[schema/schema.sql](./schema/schema.sql).

Source ERDs:
[Users, Societies & Roles](../design/LinkittyDo/Database/Users,%20Societies%20&%20Roles.jpg) ·
[Games, Phrases, Parses & Profiles](../design/LinkittyDo/Database/Games,%20Phrases,%20Parses%20&%20Profiles.jpg) ·
[Clues & Links](../design/LinkittyDo/Database/Clues%20&%20Links.jpg) ·
[Played Games, Clues & Guesses](../design/LinkittyDo/Database/Played%20Games,%20Clues%20&%20Guesses.jpg).

## Conventions (every table)

- **Audit + concurrency columns:** `create_dt DATETIME`, `update_dt DATETIME`,
  `sysversion VARCHAR(10)`. `sysversion` is the original **optimistic‑concurrency**
  token (an app semantic version string, seeded `0.1.0` in the original
  `app.config`). EF6 maps it as a concurrency token; the manager bumps it on write.
- **Keys:** surrogate integer PKs use `INT AUTO_INCREMENT` (the SQL Server
  identity equivalent). `LK_USERS.user_id` stays a **natural `VARCHAR(50)`** key
  (as in the original `lk_users.sql`). Junctions use composite PKs.
- **Naming:** tables keep the original `LK_*` names and column prefixes
  (`u`=user, `g`=game, `p`=phrase/parse/profile, `c`=clue, `l`=link, `pg`=played
  game, `cp`=clue played, `so`=solved ordinal, `gu`=guess). EF6 entity classes use
  PascalCase mapped to these names.
- **Engine/charset:** `ENGINE=InnoDB DEFAULT CHARSET=utf8mb4` with FK constraints.
- **Enumerated strings** (`gstatus`, `pgstatus`, `prtype`, comment status) are
  `VARCHAR` with the allowed values documented below and validated in the logic
  layer (kept out of the DB as `ENUM` for forward compatibility).

## Group 1 — Users, Societies & Roles

| Table | Key columns | Other columns | Notes |
| --- | --- | --- | --- |
| `LK_USERS` | `user_id` VARCHAR(50) PK | `unickname` VARCHAR(100), `uemail` VARCHAR(255) **UNIQUE NOT NULL**, `upassword_hash` VARCHAR(255), `upassword_salt` VARCHAR(100), `uthumbnail_url` VARCHAR(512), `ustatus` VARCHAR(20) | **Security change:** original `upassword VARCHAR(100)` (clear) → **hash + salt**. **Storage change:** original `uthumbnail VARBINARY(max)` → **URL** to an externalized asset. `ustatus` added for activation (`pending`/`active`/`disabled`). |
| `LK_USER_PROPS` | (`user_id`,`upname`) PK | `upvalue` VARCHAR(255), `updescription` VARCHAR(255) | Generic per‑user key/value attributes. `upvalue` **added** (the ERD shows only `updescription`; a value column is required to actually store a property). |
| `LK_ROLES` | `role_id` INT PK | `rname` VARCHAR(50), `rdescription` VARCHAR(255) | Seeded: `Guest`, `Player`, `Manager`, `Administrator`. |
| `LK_USER_ROLES` | (`user_id`,`role_id`) PK | — | M:N user↔role. |
| `LK_SOCIETIES` | `society_id` INT PK | `sname` VARCHAR(100), `sdescription` VARCHAR(500), `sowner_user_id` VARCHAR(50) FK→`LK_USERS` | **P2.** |
| `LK_USER_SOCIETIES` | (`user_id`,`society_id`) PK | — | **P2.** M:N membership. |
| `LK_SOCIETY_ROLES` | (`society_id`,`role_id`) PK | — | **P2.** Roles within a society (`Manager`/`Guest`/`Member`). |
| `LK_SOCIETY_COMMENTS` | `comment_id` INT PK | `society_id` FK, `user_id` FK, `cstatus` VARCHAR(20), `ctext` VARCHAR(1000) | **P2, added** from Architecture.docx (`Comment`: status `displayed`/`hidden`/`removed`/`private`). Not in the ERD. |

**Default game profile:** the player's default profile (profile edit wireframe) is
stored as a `LK_PROFILES` set owned by the user; the link is
`LK_USERS` → default `profile_id` (see Group 2). Recorded as a nullable
`udefault_profile_id` on `LK_USERS` (**added**, since the ERD shows no user→profile
link).

## Group 2 — Games, Phrases, Parses & Profiles

| Table | Key columns | Other columns | Notes |
| --- | --- | --- | --- |
| `LK_GAMES` | `game_id` INT PK | `gtitle` VARCHAR(150) **(added)**, `gphrase_id` FK→`LK_PHRASES`, `gprofile_id` FK→`LK_PROFILES.profile_id`, `gcreate_user_id` FK→`LK_USERS`, `glast_played_dt`, `gplay_count` INT, `gsolve_count` INT, `glast_solved_dt`, `gstatus` VARCHAR(20) | `gtitle` **added** — wireframes list a Title distinct from the Phrase. `gprofile_id` references the game's creation profile set. |
| `LK_GAME_TAGS` | (`game_id`,`tag`) PK | — | **Added** — wireframes show per‑game Tags (searchable). Not in the ERD. |
| `LK_PHRASES` | `phrase_id` INT PK | `pphrase` VARCHAR(255), `pdefault_parse_id` FK→`LK_PARSES` | The default parse shown first. |
| `LK_PARSES` | `parse_id` INT PK | `pascore` FLOAT, `prow_count` INT, `pword_count` INT, `pchar_count` INT | One parse tree; `pascore` = parser likelihood. |
| `LK_PHRASE_PARSES` | (`phrase_id`,`parse_id`) PK | `parse_source` VARCHAR(50), `owner_id` VARCHAR(50) | M:N phrase↔parse; `parse_source` e.g. `OpenNLP`. |
| `LK_PARSE_NODES` | (`parse_id`,`pnposition`) PK | `pnsub_phrase` VARCHAR(255), `pnrow` INT, `pnword_start` INT, `pnword_length` INT, `pnchar_start` INT, `pnchar_length` INT, `pnpart_of_speech` VARCHAR(20) | A tree **position** (ordinal). `pnposition` numbered from lower‑left leaf upward (see [05-game-mechanics.md](./05-game-mechanics.md)). |
| `LK_PROFILES` | (`profile_id`,`property_id`) PK | `prtype` VARCHAR(30), `prname` VARCHAR(50), `prvalue` VARCHAR(100) | A **profile is a set of property rows** sharing one `profile_id`. Property catalog (relations/search/context/display/engine) in [03-api-contract.md](./03-api-contract.md) and [05-game-mechanics.md](./05-game-mechanics.md). `property_id` is per‑profile sequence. |

## Group 3 — Clues & Links

| Table | Key columns | Other columns | Notes |
| --- | --- | --- | --- |
| `LK_CLUES` | `clue_id` INT PK | `game_id` FK, `parse_id` FK, `pnordinal` INT (→`LK_PARSE_NODES.pnposition`), `profile_id` FK, `ccontext` VARCHAR(255) | A clue targets one parse **position** of a game; `ccontext` = encoded grammatical context. |
| `LK_LINKS` | `link_id` INT PK | `lurl` VARCHAR(2048), `ltitle` VARCHAR(255) **(added)**, `lsearch_engine` VARCHAR(30) | `ltitle` **added** — play wireframe shows a Page Title per link. |
| `LK_CLUE_LINKS` | (`clue_id`,`link_id`) PK | — | M:N clue↔link (a clue is a set of links). |

## Group 4 — Played Games, Clues & Guesses

| Table | Key columns | Other columns | Notes |
| --- | --- | --- | --- |
| `LK_PLAYED_GAMES` | `played_game_id` INT PK | `player_id` FK→`LK_USERS`, `game_id` FK, `parse_id` FK, `pgclue_count` INT, `pgguess_count` INT, `pgstart_date`, `pgsolve_date`, `pgstatus` VARCHAR(20), `pgscore` INT | One player's attempt at a game against a chosen parse. |
| `LK_CLUES_PLAYED` | (`played_game_id`,`clue_id`) PK | `cpweight` FLOAT | Clues revealed in this attempt + their reinforcement weight. |
| `LK_SOLVED_ORDINALS` | (`played_game_id`,`soordinal`) PK | — | Which parse positions are solved. |
| `LK_GUESSES` | `guess_id` INT PK **(added surrogate)** | `played_game_id` FK, `guordinal` INT, `guwords` VARCHAR(255) | **Reconciliation:** the ERD keys on (`played_game_id`,`guordinal`), but the play wireframe shows **multiple guesses per ordinal** over time. A surrogate `guess_id` is added; (`played_game_id`,`guordinal`,`create_dt`) is indexed. |

## Status enumerations

From [Architecture.docx](../design/LinkittyDo/Architecture/Architecture.docx) and
the [Admin wireframe](../design/LinkittyDo/Wireframes/6%20-%20Admin.docx):

- **`LK_GAMES.gstatus`** (creation/approval lifecycle):
  `new` → `processing` → `processed` → `approval_ready` →
  `live` (admin‑approved & active) | `not_approved` | `unavailable`.
- **`LK_PLAYED_GAMES.pgstatus`:** `started` | `solved` | `quit`.
- **`LK_PROFILES.prtype`:** `relation` | `search_style` | `context_style` |
  `display_style` | `search_engine` | `grammatical_depth`.
- **`LK_SOCIETY_COMMENTS.cstatus`** (P2): `displayed` | `hidden` | `removed` |
  `private`.
- **`LK_USERS.ustatus`:** `pending` | `active` | `disabled`.

## Documented deviations from the ERDs

These additions/changes are required to satisfy the wireframes, use cases, or
security, and are called out so the schema is auditable:

1. **Password hashing** — `upassword` → `upassword_hash` + `upassword_salt`.
2. **Thumbnail externalized** — `uthumbnail VARBINARY(max)` → `uthumbnail_url`.
3. **`LK_USER_PROPS.upvalue`** added (value column).
4. **`LK_USERS.ustatus`** and **`udefault_profile_id`** added.
5. **`LK_GAMES.gtitle`** and **`LK_GAME_TAGS`** added (title/tags from wireframes).
6. **`LK_LINKS.ltitle`** added (page title from wireframe).
7. **`LK_GUESSES.guess_id`** surrogate added (multiple guesses per ordinal).
8. **`LK_SOCIETY_COMMENTS`** added (P2) from the functional description.
9. **`LK_NEWS`** / **`LK_CONTENT`** added as P3 stubs for home News and site
   navigation/styling/content (the DAL "Navigation, Styling, and Content" box).

## Seed data (scripted, not migrated)

- `LK_ROLES`: the four roles.
- One `Administrator` user (credentials provisioned at deploy, not committed).
- A **profile‑property catalog** reference (default game profile) and 5–6 sample
  **games** (title, phrase, pre‑computed parse + clues/links) so the catalog and
  play flows are demonstrable without running the full creation pipeline. See
  [06-roadmap-and-backlog.md](./06-roadmap-and-backlog.md) (M0/M2).
