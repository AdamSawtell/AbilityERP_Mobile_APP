# SAW027 — Deploy (Activity Audit — full product)

One install for the whole Activity Audit function (terms, engine, review UX, Activity Viewer links).  
Former SAW028 / SAW029 SQL is included here — do **not** run those tickets separately.

## Environment

| Tier | Host | Notes |
|------|------|--------|
| Dev / staging | `3.27.207.215` | Audit Tool Build |
| SSH | `ubuntu@3.27.207.215` | Key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| WebUI | `http://3.27.207.215/webui/` | SuperUser / `HCOflamingo` · role **Admin** |
| DB | `idempiere` / `adempiere` | `SET search_path TO adempiere;` |

## Plugin

`idempiere-plugins/com.aberp.activityaudit/`

## JAR

Yes — `com.aberp.activityaudit_7.1.0.202607191400.jar`

Includes: Nightly / Historical engine, Open Activity, Activity Viewer Open Client / Employee / Support Location (`WebUiZoom`).

Reviewed By/Date stamping is **not** via classic Callout — use SQL `21` trigger (see below). Keep AD_ModelValidator from SQL `20` **INACTIVE** (activating breaks login).

Manual OSGi console install/start (or host `deploy.sh` for non-client builds).

## Ordered SQL

Prefer **`deploy.sh`** on a reachable host (build JAR + apply all SQL + restart).

Manual order under `idempiere-plugins/com.aberp.activityaudit/sql/`:

| # | File | Purpose |
|---|------|---------|
| 00 | `00-preflight.sql` | Fail closed |
| 01 | `01-create-tables.sql` | Physical tables |
| 02 | `02-ad-references.sql` | References / lists |
| 03 | `03-ad-table-columns.sql` | AD table/columns |
| 04 | `04-windows.sql` | Terms / Review / Runs windows |
| 05 | `05-processes.sql` | Nightly / Historical / Open Activity |
| 06 | `06-menu-access.sql` | Menu + role grants |
| 07 | `07-scheduler.sql` | Nightly scheduler |
| 08 | `08-seed-terms.sql` | Seed terms |
| 09 | `09-verify.sql` | Core verify |
| 10 | `10-fix-review-grid.sql` | Review grid |
| 11 | `11-fix-processing-column.sql` | Processing column (legacy pack compat) |
| 12 | `12-open-activity-button.sql` | Open Activity button |
| 13 | `13-fix-terms-grid.sql` | Terms grid |
| 14 | `14-format-audit-fieldgroup.sql` | AbERP Audit field group |
| 15 | `15-fix-isactive-edit.sql` | Active field for WebUI edit |
| 16 | `16-activity-viewer-links.sql` | Viewer Client / Employee / SL buttons |
| 17 | `17-activity-viewer-links-display.sql` | DisplayLogic / placement |
| 18 | `18-review-field-groups.sql` | Review form: Activity / Match / Review / Audit |
| 19 | `19-fix-reviewed-callout.sql` | Clear classic Callout on IsReviewed (ClassNotFound under OSGi) |
| 20 | `20-reviewed-model-validator.sql` | AD_ModelValidator metadata — **must stay INACTIVE** |
| 21 | `21-reviewed-stamp-trigger.sql` | BEFORE UPDATE trigger stamps Reviewed By/Date/status |

UUID-safe upserts throughout — never hardcode `AD_*_ID` across clients. Never change existing HCO `*_UU`.

## Restart / cache

1. Install/start JAR (OSGi).
2. Apply SQL (or `deploy.sh`).
3. Restart iDempiere if JAR changed; otherwise Cache Reset.
4. **Logout/in** (or close windows) before smoke — field groups especially need a fresh window open.

## Smoke (end-to-end)

### Core audit loop

1. **Activity Audit Terms** — seed terms present (Hospital, Fall, …).
2. Edit a Contact Activity Description with exact word `fall` → Save.
3. Run **Activity Audit Nightly**.
4. **Activity Audit Review** — outstanding row; Matched Terms includes Fall.
5. Form view: groups **Activity** → **Match** → **Review** → **Audit** (collapsed). Expand Audit: **Active** beside Activity Updated Audited. No Follow-Up checkbox.
6. **Open Activity** → Activity Viewer on that activity.
7. Check **Reviewed** → Reviewed By/Date; status → Reviewed — No Further Action; leaves outstanding queue.
8. Re-run Nightly → no duplicate while Activity unchanged.
9. **Activity Audit Runs** — counters look sane.

### Activity Viewer links

10. On an Activity with Client / Employee / Support Location — **Activity Links** buttons show and open the named AbilityERP windows (not generic BP/User).

## AbilityERP Admin access

Install SQL grants by role **name** to **AbilityERP Admin**, **Admin**, and System Administrator where scripted.

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Terms | — |
| Window | Activity Audit Review | — |
| Window | Activity Audit Runs | — |
| Window | Activity Viewer | — |
| Window | Client | — |
| Window | Employee | — |
| Window | Support Location | — |
| Process | Activity Audit Nightly | `AbERP_ActivityAudit_Nightly` |
| Process | Historical Activity Audit | `AbERP_ActivityAudit_Historical` |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |
| Process | Open Client | `AbERP_ActivityViewer_OpenClient` |
| Process | Open Employee | `AbERP_ActivityViewer_OpenEmployee` |
| Process | Open Support Location | `AbERP_ActivityViewer_OpenSupportLocation` |

## Match types

| Code | Behaviour |
|------|-----------|
| Exact Word | Word-boundary, case-insensitive (`fall` ≠ `fallback`) |
| Exact Phrase | Phrase with word boundaries |
| Contains | Substring, case-insensitive |

Scan fields: `C_ContactActivity.Description` + `Comments`.

## Review UX notes (included)

- **Reviewed** checkbox kept — stamps By/Date and clears outstanding queue.
- **Follow-Up Required** checkbox hidden — use Review Status = Follow-Up Required.
- **Active** lives in Audit group (same line as Activity Updated Audited).

## Packs

| Tier | Path |
|------|------|
| Staging | `Downloads\AbilityERP-ClientUpdate-SAW027_activity_audit-20260719\` |
| Production | `Downloads\AbilityERP-ProdUpdate-SAW027_activity_audit-20260719\` |

One pack for the whole function (JAR `191400` + SQL `00`–`21`). Do not ship separate SAW028/SAW029 packs for new installs.

## Blockers

| Item | Notes |
|------|--------|
| Named zoom windows missing | Client / Employee / Support Location windows must exist for viewer links |
| Stale form layout | Cache Reset + reopen window after SQL 18 |
| AD_ModelValidator active | Never activate SQL `20` validator — breaks login; stamp uses SQL `21` trigger |
