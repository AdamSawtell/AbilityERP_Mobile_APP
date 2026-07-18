# SAW029 — Deploy

Agent install guide for **another** iDempiere build. SQL-only layout change on **Activity Audit Review**.

## Prerequisites (fail closed)

| Requirement | How to check |
|-------------|--------------|
| **SAW027** Activity Audit installed | Window **Activity Audit Review** exists |
| Reviews tab | Tab UU `27a02751-c0d4-4f01-8e15-000000000001` **or** name `Reviews` on that window |
| AbERP **Audit** field group | UU `3551f0df-bb72-40ab-8b1c-c28a7fec9a46` **or** name `Audit` + `EntityType=Ab_ERP` (from SAW027 `14-format-audit-fieldgroup.sql`) |
| Review columns present | At least `ReviewStatus`, `IsReviewed`, `IsActive`, `ActivityUpdatedAudited` on the Review table |

If the window/tab/Audit group is missing, **stop** and install SAW027 first (`Tickets/SAW027_activity_audit/DEPLOY.md`). Do not invent numeric `AD_*_ID` values.

## Environment (dev reference)

| Tier | Host | Notes |
|------|------|--------|
| Dev / staging verified | `3.27.207.215` | Audit Tool Build |
| SSH | `ubuntu@3.27.207.215` | Key `%USERPROFILE%\.ssh\HCObusiness.pem` |
| WebUI | `http://3.27.207.215/webui/` | SuperUser / `HCOflamingo` · role **Admin** |
| DB | `idempiere` / `adempiere` | `SET search_path TO adempiere;` |

## Plugin / source of truth

| Item | Path |
|------|------|
| Plugin | `idempiere-plugins/com.aberp.activityaudit/` |
| Apply SQL | `idempiere-plugins/com.aberp.activityaudit/sql/18-review-field-groups.sql` |
| Wired in | `deploy.sh` (runs after `17-…`) |
| Ticket verify helpers | `Tickets/SAW029_activity_audit_review_ux/sql/` |

## JAR

**No.** Layout / AD only. Packs use `jar/NO-JAR.txt`.

Do **not** rebuild or redeploy the activityaudit JAR for this ticket alone.

## Ordered SQL

1. **Preflight** — `Tickets/SAW029_activity_audit_review_ux/sql/00-preflight.sql`  
   Must print `OK` rows; any `RAISE EXCEPTION` = abort.
2. **Apply** — `idempiere-plugins/com.aberp.activityaudit/sql/18-review-field-groups.sql`  
   (Packs: `sql/01-APPLY.sql` = same file.)
3. **Verify** — `Tickets/SAW029_activity_audit_review_ux/sql/95-verify.sql`  
   Expect field groups Activity/Match/Review/Audit; Active in Audit; Follow-Up hidden.

Idempotent: safe to re-run `18-…` after layout tweaks.

### Apply example (psql on host)

```bash
psql -d idempiere -U adempiere -v ON_ERROR_STOP=1 \
  -f 00-preflight.sql \
  -f 01-APPLY.sql \
  -f 95-VERIFY.sql
```

Or from repo on a host that already has the plugin tree:

```bash
cd idempiere-plugins/com.aberp.activityaudit
# after SAW027 is present:
psql -d idempiere -v ON_ERROR_STOP=1 -f sql/18-review-field-groups.sql
```

## Restart / cache

- No OSGi / iDempiere restart required for field groups.
- **Cache Reset**, then **close the Review window** (or logout/in) before smoke.  
  Leaving the form open after Cache Reset often keeps the old layout.

## Expected form layout (acceptance)

| Group | Default | Contents |
|-------|---------|----------|
| **Activity** | Open | Activity Date + **Open Activity**; Client / Employee; Activity Type |
| **Match** | Open | Matched Terms; Category + Risk Level; Matched Text Extract |
| **Review** | Open | Review Status + **Reviewed**; Reviewed By / Date; Review Notes |
| **Audit** | Collapsed | Activity Updated Audited + **Active**; Created / Created By / Updated / Updated By |

Also:

- **Follow-Up Required** checkbox: hidden (form + grid). Use Review Status = Follow-Up Required.
- **Reviewed** checkbox: kept (stamps Reviewed By/Date; clears outstanding queue).
- Grid still shows queue essentials (date, client, employee, terms, risk, status, Reviewed).

## Smoke

1. Cache Reset → logout/in (or close all windows).
2. Open **Activity Audit Review** → select a row → **Form** view (`Alt+T` / Grid toggle).
3. Confirm four groups; expand **Audit**.
4. Confirm **Active** on the same line as **Activity Updated Audited**.
5. Confirm no **Follow-Up Required** checkbox in Review.
6. Confirm **Open Activity** still in Activity group and zooms the source activity.

## AbilityERP Admin access

No new windows or processes. Existing SAW027 grants remain.

| Access | Name | Search key |
|--------|------|------------|
| Window | Activity Audit Review | — |
| Process | Open Activity | `AbERP_ActivityAudit_OpenActivity` |

Grant both **AbilityERP Admin** and **Admin** (HCO) if the window is missing for the smoke role — use SAW027 `06-menu-access.sql`, not this ticket.

## Blockers / overlap

| Item | Notes |
|------|--------|
| Missing SAW027 | Install SAW027 fully before SAW029 |
| Missing Audit FG | Re-run SAW027 `14-format-audit-fieldgroup.sql` |
| SAW028 | Unrelated (Activity Viewer links); may share JAR on host — not required for SAW029 |
| HCO `*_UU` | Never change existing client UUs; SQL upserts by UU/name only |

## Downloads packs

| Tier | Path |
|------|------|
| Staging | `Downloads\AbilityERP-ClientUpdate-SAW029_activity_audit_review_ux-20260718\` |
| Production | `Downloads\AbilityERP-ProdUpdate-SAW029_activity_audit_review_ux-20260718\` |

## Rollback

Prefer DB backup restore. Pack `99-ROLLBACK.sql` only reverts the **layout flags** this ticket owns (Follow-Up visible again; Active back toward Review). It does **not** restore every pre-SAW029 seqno. Prefer backup for production rollback.
