# 00 — Product Overview

## Vision

*Linkitty‑Do Ranch* is a social web **word game**. The object is to **guess a
hidden phrase**, where every clue is a **web page**. A phrase is broken down by a
natural‑language **parser** into a tree of positions; clues are web links
discovered by searching for words *related* to the phrase (synonyms, antonyms,
meronyms) according to a configurable **game profile**. Players reveal clues one
at a time and guess positions; fewer clues and fewer guesses mean a higher score.

Beyond the game, the original design states three stretch ambitions (see
[About, in Wireframes/5 - Footer.docx](../design/LinkittyDo/Wireframes/5%20-%20Footer.docx)):
a crowd‑sourced **language model**, a statistics‑based **semantic search**
experiment, and some educational value. Those are **explicitly out of MVP scope**
and tracked as deferred "future" work.

## The game in one page

- **Phrase** — a short English phrase chosen by a creator (e.g. *"One of Daisy's
  Predecessors"*).
- **Parse** — the parser produces one or more parse **trees**; each tree node is a
  **position** (ordinal), numbered from the lower‑left leaf upward. A game is
  played against one chosen parse.
- **Profile** — a set of flags that control clue generation and display: which
  **word relations** to use (original / synonyms / antonyms / meronyms), **search
  styles** (related words, by/!by part‑of‑speech, seed with original or context
  tags, quote text), **context styles** (reference / non‑reference), **display
  styles** (web pages / words / context tags), and **search engine(s)**.
- **Clue** — generated per position: a set of **links** (URLs with page titles)
  found by searching for related words. Each clue carries an encoded grammatical
  context and a WordNet rank.
- **Play** — a player starts a *played game*, requests clues for unsolved
  positions, and submits **guesses** (words) per position. Correct guesses solve
  ordinals, reinforce the weights of the clues that led to them, and add to the
  **score**. A player may **give up**.
- **Society** — an optional social group of users with its own roles and
  comments (deferred to P2).

See [05-game-mechanics.md](./05-game-mechanics.md) for the full creation and play
algorithms.

## Agents / roles

From [Use Cases.docx](../design/LinkittyDo/Software%20Design/Use%20Cases.docx)
and the [lk.Logic.User class diagram](../design/LinkittyDo/Software%20Design/lk.Logic.User.jpg),
there are five agents. Four are **roles** on the `User` class; the fifth is the
programmatic API consumer.

| Agent | Can do | Notes |
| --- | --- | --- |
| **Guest** | Read news/home, view "about/help", register, log in. | Unauthenticated visitor. |
| **Player** | Everything a Guest can, plus browse/search games, play games, create games, edit own profile, (join societies — P2). | Default role after registration. |
| **Manager** | Society management (owner/manager of a society). | P2, tied to Societies. |
| **Administrator** | Manage games (process/approve/activate/edit), users, societies, and news. | Admin console routes in the SPA. |
| **API** | Programmatic access to the shared endpoints. | Not a `User` role — it is the HTTP contract itself. |

A single `User` may hold multiple roles (`LK_USER_ROLES`). The SPA shows or hides
the **admin** area based on the `Administrator` role.

## Scope

### In scope for the first release (P1)

1. **Accounts & authentication** — register (with ReCaptcha), activate, log in/out,
   recover name/password, hold roles, edit profile, set a **default game profile**.
2. **Game catalog & browse** — list/search games by title, tags, and creator;
   view game details; see per‑user play status.
3. **Game play** — start a played game, request clues, guess positions, scoring,
   solve/give‑up, and play history.
4. **Game creation + NLP parser** — submit a phrase, parse it (OpenNLP), choose a
   profile, run the creation pipeline to generate clues/links from search
   providers.
5. **Admin console** — game administration (process/approve/activate/edit), user
   and (read‑only) society/news management, inside the single SPA.

### Deferred (P2 / P3)

- **Societies** (social groups, membership, comments) — full feature set.
- **News / home content** management beyond a minimal seed.
- **"Future" tooling** from the
  [System Block Diagram](../design/LinkittyDo/Architecture/System%20Block%20Diagram.jpg)
  (shown in red): the web **Crawler** (Heritrix/Lucene), the custom **Linkitty**
  search engine, and the **crawler index DB**. For MVP, clue discovery uses a
  pluggable external search provider and/or curated stored links.

### Explicitly out of scope

- Payments / "Store" (the [Site Map](../design/LinkittyDo/Architecture/Site%20Map.docx)
  mentions a Store/catalog/purchase flow — not pursued).
- Migrating the original SQL Server data (a fresh schema with seed data is used).
- Desktop/WinForms parity — the original VB.NET app is reference only.

## Success criteria for MVP

- A visitor can register, verify, and log in; passwords are **hashed** (never
  stored in clear — a change from the original schema).
- A player can browse seeded games, play one end‑to‑end (clues → guesses →
  solve/score), and see their history.
- A creator can submit a phrase, see it parsed, pick a profile, and produce a
  playable game after admin approval.
- An administrator can move a game through its status lifecycle to **live**.
- Both repos build and pass unit + integration tests via `verify.ps1`, and deploy
  to production via their documented human‑run scripts.
