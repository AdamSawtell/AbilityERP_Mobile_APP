# SAW015 — Deploy to another build (agent)

**Ticket / slug:** `SAW015_skip_dates_copy_from`  
**Kind:** idempiere · **JAR:** TBD (likely Yes if Java `SvrProcess`) · **Status:** in-progress (scaffold only)

## Required host access

- SSH · `psql` · WebUI Admin · Cache Reset  
- OSGi console / restart if JAR ships

## Agent one-liner

```bash
# Filled after implementation — placeholder:
# cd Tickets/SAW015_skip_dates_copy_from/sql   # and/or idempiere-plugins/...
# psql -d idempiere -v ON_ERROR_STOP=1 -f 00-preflight.sql -f 01-install.sql
# # if JAR: copy plugins + OSGi install/start + restart per host runbook
# # Cache Reset / logout-in
```

## Package

| | |
|--|--|
| Path | TBD — `Tickets/SAW015_skip_dates_copy_from/sql/` and/or `idempiere-plugins/…` |
| Process | **Copy Dates From** on **AbERP_Skip_Dates** |
| Window / tab | `AbERP_Skip_Dates` / Dates tab `AbERP_Dates` |
| Primary AD script | TBD (UU/name lookups only — never hardcode `AD_*_ID`) |

## AbilityERP Admin access

Install SQL **must** grant `AD_Process_Access` by role **name** to:

- **AbilityERP Admin**
- **Admin** (HCO / operational)

Smoke **as Admin**.

## WebUI smoke

1. Cache Reset / re-login.
2. Open **Skip Dates** → create and save a new header (no dates yet).
3. Run **Copy Dates From** → select an existing Skip Dates with date lines.
4. Confirm warning about reviewing dates/years.
5. Confirm process reports **N** lines copied; Dates tab shows new rows.
6. Confirm source record’s Dates tab unchanged; edit/delete a copied line on the target.

## Safety

- Never change existing client `*_UU` values.
- Copy creates **new** `AbERP_Dates` rows linked to the **current** header only; do not update source rows.
- Resolve all AD objects by `*_UU` or stable name.

## Packs

- Staging: `AbilityERP-ClientUpdate-SAW015_skip_dates_copy_from-<YYYYMMDD>` (TBD)
- Prod: `AbilityERP-ProdUpdate-SAW015_skip_dates_copy_from-<YYYYMMDD>` (TBD)

## External ticket text

`EXTERNAL-SUMMARY.md` (draft until UAT-ready)
