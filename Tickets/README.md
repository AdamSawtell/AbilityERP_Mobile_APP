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
  README.md             # goal, status, GitHub, source paths
  EXTERNAL-SUMMARY.md   # REQUIRED — copy/paste into the external customer ticket
  DEPLOY.md             # REQUIRED — agent install on another build
  NOTES.md              # decisions, blockers, smoke results
  CHECKLIST.md          # staging install → review → fix → packs
  sql/                  # optional pack/verify copies
```

### `EXTERNAL-SUMMARY.md` (end user / external ticket)

Plain-language update for the **external ticket** (not for agents). Must be ready to copy/paste and cover:

- **Windows / processes / objects affected** — standalone table near the top (windows, tabs, Info Windows, processes, buttons, menus, forms)  
- What’s been done  
- What changed (behaviour)  
- Impact / who is affected  
- How to test (business smoke)  
- Access note: **AbilityERP Admin** can see/use all new windows, tabs, Info Windows, and processes  
- Any residual caveats  

### `DEPLOY.md` (agents)

Enough for a new agent to install on another build. Must also grant **AbilityERP Admin** access to every new window / process / Info Window / form (see `docs/DEV-REQUIREMENTS.md`).

**GitHub issue** for Kind `idempiere` / `both`: Deploy section + link to `DEPLOY.md`. Link or attach `EXTERNAL-SUMMARY.md` when advising the customer ticket is ready.

**Source of truth** for plugin migrations remains under `idempiere-plugins/…`.

## Naming

Same slug everywhere: Agents chat, branch, Downloads packs, this folder.

See `.cursor/rules/ticket-ids.mdc`, `client-update-staging-loop.mdc`, `hco-deployment.mdc`, and `docs/DEV-REQUIREMENTS.md`.

**HCO client installs:** [`HCO_Deployment/`](HCO_Deployment/) — access, hard rules (never change HCO UUIDs), and [`LEARNINGS.md`](HCO_Deployment/LEARNINGS.md) (append after every HCO install). Per-ticket: keep **HCO Future Deployments variables** in that ticket’s `NOTES.md`.

**Final agent readiness matrix:** [`AGENT-READY.md`](AGENT-READY.md).
