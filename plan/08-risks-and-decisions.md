# 08 — Risks, Decisions & Open Questions

## Decisions made in this plan (with rationale)

| # | Decision | Choice & rationale | Revisit if |
| --- | --- | --- | --- |
| D1 | **API language** | **C#** for Web API 2 (mainstream, best tooling/library support). The original VB.NET is reference only; `lk.*` layering is preserved as namespaces. | The team prefers to port the VB.NET sources verbatim. |
| D2 | **ORM** | **EF6** (per the stack) replaces the original hand‑rolled DAL/DTO/DTOParser ADO.NET pattern. `sysversion` kept as an EF6 concurrency token. | A route needs raw SQL for performance (allowed case‑by‑case). |
| D3 | **Parser integration** | **`OpenNLP.NET`** (IKVM port) in‑process for MVP; fallback a small **Java sidecar** exposing `POST /parse` behind `iParser`. | OpenNLP.NET proves unstable on net472, or model quality is insufficient. |
| D4 | **Passwords** | Hash + salt (PBKDF2/bcrypt); never stored or returned in clear — a change from the original `upassword` column. | — (non‑negotiable). |
| D5 | **Auth** | Stateless **bearer token (JWT)** with role claims; server‑side role checks on every protected route. | A session‑cookie model is preferred. |
| D6 | **Thumbnail storage** | Store a **URL** (`uthumbnail_url`) to an externalized asset instead of `VARBINARY(max)` bytes in the row. | A blob store isn't available; revert to a BLOB column. |
| D7 | **IDs** | `user_id` stays a natural `VARCHAR(50)`; all other PKs are `INT AUTO_INCREMENT`. | A global switch to GUIDs is desired. |
| D8 | **Clue discovery** | A single **pluggable search‑provider adapter** (+ curated/stored links for seed games) behind the `Search` service; the crawler/Linkitty engine are deferred. | A provider is chosen and funded; or the crawler is prioritized. |
| D9 | **Front‑end topology** | **One SPA** with role‑gated admin routes (per the product‑owner choice). | Admin needs an independent release cadence → split into a second SPA. |
| D10 | **Data** | **Fresh MySQL schema**, scripted seed, **no migration** of the SQL Server `.mdf`. | A later migration pass is requested (the backup is retained for reference). |
| D11 | **Game title/tags** | Added `gtitle`, `LK_GAME_TAGS`, `ltitle` to satisfy the wireframes (not in the ERDs). | The ERD is treated as authoritative and titles derive from the phrase. |

## Risks & mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| **Search‑provider ToS / keys / rate limits** (Yahoo/Google from 2010 are not usable as‑is) | Clue discovery blocked | Provider‑agnostic adapter; seed games ship with curated links; run discovery async; make it mockable in tests. |
| **OpenNLP model size/licensing & net472 interop** | Parser instability, large artifacts | D3 fallback sidecar; pin model versions; one real‑parse integration test; keep models out of Git (fetched at setup). |
| **Clue‑discovery latency** | Slow game creation | Pipeline is async; game stays `processing`; play only reads pre‑generated clues. |
| **Scoring constants undefined** in the design | Inconsistent scoring | Centralize scoring in one Logic component with config constants; cover with unit tests; tune later (O3 below). |
| **Legacy toolchains** (.NET Framework 4.7.2 / webpack 4 + `--openssl-legacy-provider`) | Setup friction on new machines | Documented in each `PROJECT.md`; `verify.ps1` encapsulates the exact steps; CI OS matches the stack. |
| **EF6 MySQL provider quirks** (vs the original SQL Server) | Schema/mapping surprises | `db/schema.sql` is the source of truth; integration tests run against real MySQL `linkittydo_test`; avoid SQL‑Server‑only constructs. |
| **Secrets hygiene** | Leakage | `configSource`/`.env` git‑ignored with committed `*.example`; deploy‑time injection; any ever‑committed secret rotated at source. |
| **ReCaptcha / email deliverability** for register/activate/recover | Users can't onboard | Choose providers early (O2); verify server‑side; integration‑test with the provider mocked. |

## Open questions for the product owner

1. **O1 — Domains/hosting:** confirm `linkittydo.com` / `www.linkittydo.com` and
   `api.linkittydo.com`, and the **FTP host + remote paths** for both deploys.
   (The original footer lists `linkittydo.com`; wireframes show
   `freddy@linkittydo.com`.)
2. **O2 — Providers & keys:** which **web‑search provider** for clue discovery;
   **email** provider for activation/recovery; **ReCaptcha** site/secret keys.
   (These are *locations of secrets* only — never committed.)
3. **O3 — Scoring constants:** the exact point/weight formula (the design specifies
   the *shape* — fewer clues/guesses ⇒ more points — not the constants).
4. **O4 — Societies timing (P2):** when to pull M6 forward, if at all.
5. **O5 — Admin bootstrap:** how the first `Administrator` is provisioned in prod
   (seed script with deploy‑time credentials vs manual).
6. **O6 — WordNet source:** bundled dictionary vs a service, and its licensing.

## Deferred ("future") scope — recap

Marked red in the
[System Block Diagram](../design/LinkittyDo/Architecture/System%20Block%20Diagram.jpg)
and confirmed deferred:

- Web **Crawler** (Heritrix) + **Lucene** indexer.
- Custom **Linkitty** search engine and the **Linkitty crawler index DB**.
- The broader **language‑model / semantic‑search** ambitions from the "About" copy.
- The **Store / purchase** flow from the Site Map.

Keep clue discovery behind the `Search` adapter so the crawler/engine drop in later
as a new [stack profile](../../agentic/stacks/README.md) without touching callers.

## Follow‑ups when the repos are created (outside this plan)

These touch the `agentic` repo or new repos and are **not** performed by this
planning task:

1. Create `philiv99/api.linkittydo.com` and `philiv99/linkittydo-web`; copy the
   drafted `PROJECT.md` files from [projects/](./projects) into each repo root.
2. Run `agentic/scripts/sync.ps1 -TargetRepo <path>` for each; commit the synced
   `AGENTS.md`, agents, skills, and `.agentic-version`.
3. Register both in [agentic/consumers.json](../../agentic/consumers.json) and run
   `agentic/scripts/setup-labels.ps1 -Repo <owner/name>` to create the priority /
   type / status labels.
4. Add a multi‑root `workspaces/linkittydo.code-workspace`
   ([workspace guide](../../agentic/guides/workspace.md)) listing `agentic`, the
   API repo, and the SPA repo.
5. Capture the M0 issues (above) and begin the loop.
