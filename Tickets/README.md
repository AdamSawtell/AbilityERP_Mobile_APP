# AbilityERP Tickets (iDempiere + dependencies)

Workstream homes for **iDempiere / client-update** delivery. Pure mobile/web app work stays in the app tree and is tracked in [`docs/TICKETS.md`](../docs/TICKETS.md) as `Kind: app` (no folder here).

## When to create a folder

Create `Tickets/SAW###_<short_snake_function>/` when the work includes:

- AD / SQL / OSGi plugin / WebUI changes, **or**
- An app/API change that exists **only** as a dependency of that ERP drop

Do **not** create a folder for app-only or meta/process tickets (`Kind: app` / `Kind: meta`).

**One folder per project.** If two ticket IDs describe the same deliverable, keep a single `Tickets/SAW###_…` home and point the other ID at it in `docs/TICKETS.md` — do not leave a duplicate stub folder.

## Folder layout (mandatory for idempiere / both)

```
Tickets/SAW###_<slug>/
  README.md      # goal, status, GitHub, source paths, dependencies
  DEPLOY.md      # REQUIRED — enough for a new agent to install on another build
  NOTES.md       # decisions, blockers, smoke results
  CHECKLIST.md   # staging install → review → fix → packs
  sql/           # optional: pack/apply/verify/rollback copies or pointers
```

### `DEPLOY.md` must include

1. Plugin / package path in this repo  
2. JAR yes/no (and symbolic name / restart if yes)  
3. Ordered SQL (or `deploy.sh` as the single command)  
4. Preflight / verify  
5. Cache Reset vs `systemctl restart idempiere`  
6. WebUI smoke steps  
7. Known blockers / portability risks  
8. Pack paths (Downloads) **or** “apply from repo; no pack yet”

**GitHub issue body** for Kind `idempiere` / `both` must contain the same Deploy block (or an explicit link to `Tickets/SAW###_…/DEPLOY.md` plus the one-liner install command). A new agent pointed at the repository must be able to deploy without hunting chat history.

**Source of truth** for plugin migrations remains under `idempiere-plugins/…`. Prefer pointers in `DEPLOY.md` over duplicating evolving SQL.

## Naming

Same slug everywhere: Agents chat, branch, Downloads packs, this folder.

See `.cursor/rules/ticket-ids.mdc` and `client-update-staging-loop.mdc`.
