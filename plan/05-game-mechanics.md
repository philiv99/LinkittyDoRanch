# 05 — Game Mechanics & Algorithms

Consolidates the game logic from
[Architecture.docx](../design/LinkittyDo/Architecture/Architecture.docx),
[Algorithms - Game Creation.docx](../design/LinkittyDo/Software%20Design/Algorithms%20-%20Game%20Creation.docx),
the [Parser class diagram](../design/LinkittyDo/Software%20Design/lk.Logic.Service.Tool.Parser.jpg),
and the [Play](../design/LinkittyDo/Wireframes/2%20-%20Play.docx) /
[Admin](../design/LinkittyDo/Wireframes/6%20-%20Admin.docx) wireframes. These
algorithms drive the API endpoints in [03-api-contract.md](./03-api-contract.md)
and the schema in [02-data-model.md](./02-data-model.md).

## The parse tree & positions

The parser (`iParser.parse(phrase) → Parse`) returns a syntactic **tree** plus a
likelihood **score** (`pascore`). Each node is a **position**:

- **Position numbering** (from the Algorithms doc): integers start at **1 at the
  lower‑left** of the tree and count **left‑to‑right, moving up the levels**;
  upper‑level positions sit as close to the terminal leaf nodes as possible.
- A node (`LK_PARSE_NODES`) records `pnposition` (ordinal), `pnrow` (tree level;
  row 1 = leaf row), the sub‑phrase (`pnsub_phrase`), word span
  (`pnword_start`/`pnword_length`), character span
  (`pnchar_start`/`pnchar_length`), and `pnpart_of_speech`.
- A phrase can have **several parses** (the Admin wireframe shows *"complete: 3
  parses"*); one is the default (`LK_PHRASES.pdefault_parse_id`). A played game is
  pinned to a single chosen `parse_id`.

`Parse` carries `rowCount`/`wordCount`/`charCount`; `ParseNode[]` is `1..*`.

## Game‑creation pipeline

Triggered by `POST /api/games` (or re‑run by
`POST /api/admin/games/{id}/process`). The Admin wireframe enumerates the steps
and their completion states:

1. **Phrase validation** — normalize/validate the input phrase; reject empty or
   unparseable input. Creates/【finds】`LK_PHRASES`.
2. **Linguistic processing — stemming** — morphologic analysis/stemming of tokens.
3. **Linguistic processing — parsing** — run the parser → one or more
   `LK_PARSES` + `LK_PARSE_NODES`; set `pascore` and the default parse.
4. **Related‑word generation** — for each relevant position's sub‑phrase, expand
   words via the **profile's relations** (original / synonyms / antonyms /
   meronyms) using WordNet (`Service.WordInfo`). "By POS / not by POS" filters the
   expansion by part of speech.
5. **Clue discovery** — for each position (and its related words), run web
   searches via the **profile's search engine(s)** and **search styles** (seed
   with original word or context tags, quote text or not). Each result becomes a
   `LK_LINKS` row (url, title, engine); grouped results become a `LK_CLUES` row
   (targeting `game_id`+`parse_id`+`pnordinal`, with `ccontext` = encoded
   grammatical context and the WordNet rank), joined through `LK_CLUE_LINKS`.
6. **Status transition** — `new → processing → processed → approval_ready`; an
   administrator then approves to **`live`** (or `not_approved` / `unavailable`).

> **MVP boundary:** steps 1–4 run in‑process (parser + WordNet). Step 5 uses a
> **pluggable search provider** (or curated/stored links); the automated web
> **Crawler** and the custom **Linkitty** index are deferred (see
> [08-risks-and-decisions.md](./08-risks-and-decisions.md)). Because discovery can
> be slow and rate‑limited, the pipeline runs **asynchronously** server‑side and
> the game stays `processing` until done — play only ever reads pre‑generated
> clues.

### Game profile → generation parameters

A profile (`LK_PROFILES` row‑set) is interpreted as:

| `prtype` | Values | Effect |
| --- | --- | --- |
| `relation` | original_word, synonyms, antonyms, meronyms | Which related words to expand (step 4). |
| `grammatical_depth` | phrase, parse | Expand whole‑phrase vs per‑parse‑node. |
| `search_style` | related_words, by_pos, not_by_pos, seed_with_original, seed_with_tags, quote_text | How search queries are built (step 5). |
| `context_style` | reference, non_reference | Whether reference pages count as clues. |
| `display_style` | web_pages, words, context_tags | How a clue is shown to the player. |
| `search_engine` | yahoo, google, msn, amazon, linkitty* | Provider(s) queried (*linkitty = future). |

## Play algorithm

### Start — `POST /api/plays`
Create `LK_PLAYED_GAMES` (player, game, chosen `parse_id`), `pgstatus=started`,
counts 0, `pgstart_date=now`. Increment the game's `gplay_count` and set
`glast_played_dt`.

### Request a clue — `POST /api/plays/{id}/clues`
For a target unsolved `ordinal`, select one of the game's clues for that position
(`LK_CLUES` where `game_id`+`parse_id`+`pnordinal`) that the player has not yet
revealed. Selection **method** (from Architecture.docx *New Clue*):

- **Random**, or
- **Favor prior weighted clues** — bias toward clues with higher accumulated
  `cpweight`.

Record `LK_CLUES_PLAYED` (initial `cpweight`), increment `pgclue_count`, and return
the clue's links (url + title) rendered per the profile **display style**. Only
URLs for words **not yet guessed** are generated/shown.

### Submit a guess — `POST /api/plays/{id}/guesses`
Record `LK_GUESSES` (`guordinal`, `guwords`), increment `pgguess_count`, then
evaluate against the target position's `pnsub_phrase`:

- **Correct:**
  - Add `soordinal` to `LK_SOLVED_ORDINALS`.
  - **Reinforce weights:** add a *fractional weight* to each revealed clue for the
    correct word(s), **decreasing in proportion to** the nth‑prior clue and the
    number of guesses (so earlier/efficient clues gain more).
  - **Score:** add to `pgscore` based on the number of clues and guesses for the
    correct word(s) — fewer clues/guesses ⇒ more points.
  - If **all** positions are solved → `pgstatus=solved`, `pgsolve_date=now`;
    increment the game's `gsolve_count`, set `glast_solved_dt`.
- **Incorrect:** no solve, no reinforcement; the guess is retained in history.

### Give up — `POST /api/plays/{id}/giveup`
`pgstatus=quit`. No score change.

### Scoring summary
Score accrues per correctly solved position as a function of **(clues revealed,
guesses made)** for that position; the weight‑reinforcement loop makes clues that
led to correct guesses more likely to be favored in future "favor prior weighted"
selections (a crowd‑sourced signal about which clues are good). Exact point
constants are a **tuning decision** recorded in
[08-risks-and-decisions.md](./08-risks-and-decisions.md); the data model already
captures every input needed (`pgclue_count`, `pgguess_count`, per‑clue `cpweight`,
counts per ordinal).

## Status lifecycles

```text
GAME (gstatus):
  new ─▶ processing ─▶ processed ─▶ approval_ready ─▶ live
                                           │
                                           ├─▶ not_approved
                                           └─▶ unavailable  (admin can toggle)

PLAYED GAME (pgstatus):
  started ─▶ solved        (all ordinals solved)
         └─▶ quit          (gave up)
```

## Services behind the logic

| Service (`lk.Service`) | MVP implementation | Notes |
| --- | --- | --- |
| **Tool.Parser** (`iParser`) | **OpenNLP** models via `OpenNLP.NET` in‑process (fallback: a small Java sidecar exposing `POST /parse`). | Produces `Parse`/`ParseNode`. Decision in [08](./08-risks-and-decisions.md). |
| **WordInfo** (WordNet) | WordNet lookups for synonyms/antonyms/meronyms (`relation` expansion, by‑POS filter). | HTTP/DB/local dict. |
| **Search** | One pluggable provider adapter (e.g. a current web‑search API) + curated/stored links for seed games. | Yahoo/Google as named in the design are historical; the adapter is provider‑agnostic. |
| **Tool.Crawler** + **Linkitty** engine/index | **Deferred (future).** | Heritrix/Lucene in the original design. |
