# PROJECT.md — LinkittyDo API (SUPERSEDED)

> **Superseded by consolidation.** The LinkittyDo HTTP API is **not** a new
> `api.linkittydo.com` repo. It is delivered into the existing
> **`philiv99/api.infogoer.com`** shared backend, per decision **D12** and the
> resolution of open question **O1** in
> [../08-risks-and-decisions.md](../08-risks-and-decisions.md).
>
> The authoritative, live `PROJECT.md` is in that repo
> (`api.infogoer.com/PROJECT.md`). This draft is kept only as a historical pointer;
> its original contents remain in git history.

## Consolidated values (see `api.infogoer.com/PROJECT.md` for the source of truth)

| Field | Value |
| --- | --- |
| Repo | `philiv99/api.infogoer.com` (`dotnet-webapi`: Web API 2 / .NET 4.7.2 / EF6 / MySQL) |
| Local base URL | `http://localhost:10152/api` |
| Production base URL | `https://api.infogoer.com/api` |
| Database / test DB | `ExploreInfoGoer` / `ExploreInfoGoer_Test` |
| App DB user | `BirdMan` (never `root`) |
| LinkittyDo schema | `db/linkittydo/schema.sql` (LK_* tables in `ExploreInfoGoer`) |
| Build / verify | `verify.ps1` (restore → MSBuild Release → `dotnet test`) |
| Deploy (human-run) | `deploy/Deploy-Ftp.ps1` (FTPS; database backup first) |

The HTTP contract remains [../03-api-contract.md](../03-api-contract.md).
