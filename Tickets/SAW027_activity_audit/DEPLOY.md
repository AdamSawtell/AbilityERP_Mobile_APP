# SAW027 — Deploy

## Environment

| Tier | Host | Notes |
|------|------|--------|
| Dev | `3.27.207.215` | Same as SAW025 / Audit Tool Build V1 |
| SSH | `ubuntu@3.27.207.215` | Key `C:\Users\sawte\Documents\SSH Keys\HCObusiness.pem` |
| WebUI | `http://3.27.207.215/webui/` | SuperUser / `HCOflamingo` · role **Admin** |

## Plugin

`idempiere-plugins/com.aberp.activityaudit/`

## JAR

Yes — `com.aberp.activityaudit_7.1.0.202607171400.jar`

## Ordered SQL

1. `sql/00-preflight.sql`
2. `sql/01-create-tables.sql`
3. `sql/02-ad-references.sql`
4. `sql/03-ad-table-columns.sql`
5. `sql/04-windows.sql`
6. `sql/05-processes.sql`
7. `sql/06-menu-access.sql`
8. `sql/07-scheduler.sql`
9. `sql/08-seed-terms.sql`
10. `sql/09-verify.sql`
11. `sql/10-fix-review-grid.sql`
12. `sql/11-fix-processing-column.sql` — adds physical `Processing` column (legacy; kept for pack compatibility)
13. `sql/12-open-activity-button.sql` — dedicated `AbERP_OpenActivity` Button → Open Activity process (SAW024-style zoom to Activity Viewer)
14. `sql/13-fix-terms-grid.sql` — Terms grid: PK field + `IsSingleRow=N`
15. `sql/14-format-audit-fieldgroup.sql` — hide Organisation; Created/Created By/Updated/Updated By in Ab_ERP **Audit** field group (all three windows)
16. `sql/15-fix-isactive-edit.sql` — add **Active (IsActive)** field on Review/Runs tabs (required for WebUI editability)

Or `deploy.sh` (build JAR + SQL + restart).

## Restart / cache

OSGi install/start JAR. After SQL: restart iDempiere (or Cache Reset + logout/in).

## Smoke

1. Menu → Ability ERP → **Activity Audit** → **Activity Audit Terms** — confirm seed terms (Hospital, Fall, etc.)
2. Edit an Activity Description to include `fall` (exact word) and Save
3. Run **Activity Audit Nightly** (menu process)
4. Open **Activity Audit Review** — outstanding queue shows the match; Matched Terms includes Fall
5. Click **Open Activity** — Contact Activity zooms
6. Check **Reviewed** — Reviewed By / Date populate; status → Reviewed — No Further Action; row leaves outstanding queue
7. Re-run Nightly — unchanged Activity is skipped (no duplicate review)
8. Open **Activity Audit Runs** — confirm counters

## AbilityERP Admin access

Install SQL grants AbilityERP Admin, Admin, and System Administrator by role name.

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Terms | — |
| Window | Activity Audit Review | — |
| Window | Activity Audit Runs | — |
| Process | Activity Audit Nightly | `AbERP_ActivityAudit_Nightly` |
| Process | Historical Activity Audit | `AbERP_ActivityAudit_Historical` |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |

## Match types

| Code | Behaviour |
|------|-----------|
| Exact Word | Word-boundary, case-insensitive (`fall` ≠ `fallback`) |
| Exact Phrase | Phrase with word boundaries |
| Contains | Substring, case-insensitive |

Scan fields: `C_ContactActivity.Description` + `Comments`.
