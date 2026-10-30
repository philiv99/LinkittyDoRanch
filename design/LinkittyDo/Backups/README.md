# Backups (not committed)

The original Linkitty‑Do binary backups are **intentionally excluded from Git**
(via the repo‑root `.gitignore`) to keep history small. They are **reference‑only**
inputs and are **not migrated** — the new project uses a fresh MySQL schema (see
[../../../plan/02-data-model.md](../../../plan/02-data-model.md)).

Excluded archives (kept locally only):

- `LinkittyDoDB.zip` — SQL Server database backup (`LinkittyDO.mdf`,
  `LKCodeGen.mdf`), ~35 MB.
- `LinkittyDo.zip` — original VB.NET WinForms solution + build output, ~0.8 MB.

Everything the plan needs from these backups (the data model, DAL pattern,
connection style, and web prototype) is already summarized under
[`../../../plan`](../../../plan), so the repository does not need the binaries.
