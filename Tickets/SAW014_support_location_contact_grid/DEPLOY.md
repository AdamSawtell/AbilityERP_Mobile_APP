# SAW014 — Deploy to another build (agent)

**Ticket / slug:** `SAW014_support_location_contact_grid`  
**Kind:** idempiere · **JAR:** No · **Restart:** No · **Status:** done  
**GitHub:** [#14](https://github.com/AdamSawtell/AbilityERP_Mobile_APP/issues/14)

Point agents here (not chat history). Repo SQL is the source of truth; Downloads packs are optional mirrors.

## Required host access

- SSH (or local) · `psql` on `idempiere` / `adempiere`  
- WebUI Admin (or AbilityERP Admin) · **Cache Reset** (or logout/in)

## Agent one-liner

```bash
cd Tickets/SAW014_support_location_contact_grid/sql
psql -d idempiere -U adempiere -v ON_ERROR_STOP=1 \
  -f 00-preflight.sql \
  -f 01-fix-contact-columnsql.sql \
  -f 04-verify.sql
# WebUI: Cache Reset (or log out/in). No OSGi restart. No JAR.
```

**Thin prod pack (if present on the machine):**  
`Downloads\AbilityERP-ProdUpdate-SAW014_support_location_contact_grid-20260713\` → `HOW-TO.txt` (`01-APPLY.sql` then Cache Reset).

**Staging / full pack:**  
`Downloads\AbilityERP-ClientUpdate-SAW014_support_location_contact_grid-20260713\` → `HOW-TO-UPDATE.md`.

## What this changes

| Object | Resolve by | Change |
|--------|------------|--------|
| Window **Support Location** | UU `6ef3c558-3ec8-4f0c-be40-89f35d8acebf` (name fallback) | Behaviour only — grid contact columns |
| Table `AbERP_Support_Location` | UU `4ed40b98-ca31-4404-a20b-ea9000d5c51d` | No DDL |
| Col `AbERP_Email` | UU `bd54d23d-44b6-42d7-b8c8-30b3e7b826e6` | ColumnSQL: `@SQL=` → subquery |
| Col `AbERP_Phone` | UU `5f9a40e5-248b-48bd-848f-532ae4601006` | same |
| Col `AbERP_Phone2` | UU `f41c821a-90fb-4b8b-95c6-8bf2f181f8e7` | same |
| Col `AbERP_LocationName` | UU `21b6490e-5aea-4035-b64c-c45c7cc05161` | same (same defect) |
| Col `AbERP_Location_IsActive` | UU `a77b2962-807c-464b-a8f5-1871ffd9fd1c` | same |

New ColumnSQL pattern (live join, no duplicated data):

```sql
(SELECT Email FROM C_BPartner_Location
 WHERE C_BPartner_Location_ID=AbERP_Support_Location.C_BPartner_Location_ID)
```

(same for Phone / Phone2 / Name / IsActive)

## Ordered SQL (repo)

| # | Script | Purpose |
|---|--------|---------|
| 1 | `sql/00-preflight.sql` | Fail closed if window/table/column UUs missing |
| 2 | `sql/01-fix-contact-columnsql.sql` | Apply ColumnSQL updates by `AD_Column_UU` |
| 3 | `sql/04-verify.sql` | Confirm no remaining `@SQL=` on targets + spot-check subquery |
| — | `sql/99-rollback.sql` | Restore prior `@SQL=` definitions |

Discover-only helpers (`00-discover*.sql`, `00-verify-named.sql`) are optional diagnostics — **do not** require them for install.

## AbilityERP Admin access

No new window / process / Info / form. Existing **Support Location** access unchanged.  
Smoke as **AbilityERP Admin** (or operational **Admin** on HCO). No grant SQL in this ticket.

## Blockers / portability

- Preflight **RAISE EXCEPTION** if any target `AD_Column_UU` is missing — do not invent IDs; confirm AbERP Support Location columns exist on that build.
- **Never change** existing client `*_UU` values.
- No JAR · no `bundles.info` · no iDempiere restart.
- Safe to re-run `01-fix-contact-columnsql.sql` (idempotent UPDATE by UU).

## WebUI smoke

1. Cache Reset / re-login.  
2. Open **Support Location** → **Grid View** (do not select a row first).  
3. Confirm **Email**, **Phone**, **Phone 2** filled for rows that have contact on the linked `C_BPartner_Location`.  
4. Next/prev or select other rows — values stay correct.  
5. Rows with empty contact on BP Location stay blank (expected).

## HCO

Already applied and smoked on HCO Test (`32.236.127.117`) 2026-07-13.  
See `NOTES.md` → **HCO Future Deployments variables** and `Tickets/HCO_Deployment/LEARNINGS.md`.

## Packs

| Tier | Folder |
|------|--------|
| Staging | `AbilityERP-ClientUpdate-SAW014_support_location_contact_grid-20260713` |
| Prod thin | `AbilityERP-ProdUpdate-SAW014_support_location_contact_grid-20260713` |

## External ticket text

`Tickets/SAW014_support_location_contact_grid/EXTERNAL-SUMMARY.md`
