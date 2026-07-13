# SAW015 — Deploy to another build (agent)

**Ticket / slug:** `SAW015_skip_dates_copy_from`  
**Kind:** idempiere · **JAR:** Yes · **Status:** HCO Test green (2026-07-13)

## Required host access

- SSH · `psql` · WebUI Admin · stop/start iDempiere · OSGi status

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.skipdates.copyfrom
chmod +x build.sh deploy.sh
./deploy.sh
# Cache Reset / logout-in
```

Or manual: copy JAR + `sql/00-preflight.sql` + `sql/01-install-copy-dates-from.sql` (+ optional `02-button-window-style.sql`) then **stop then start** iDempiere (do not wipe OSGi cache).

## Package / bundle

| | |
|--|--|
| Path | `idempiere-plugins/com.aberp.skipdates.copyfrom/` |
| Process class | `com.aberp.skipdates.copyfrom.CopyDatesFrom` |
| Bundle symbolic name | `com.aberp.skipdates.copyfrom` |
| Version | `7.1.0.202607131830` |
| Primary AD script | `sql/01-install-copy-dates-from.sql` |

## AbilityERP Admin access

Install SQL grants `AD_Process_Access` by role **name** to **AbilityERP Admin**, **Admin**, and System Administrator (`0`). Smoke **as Admin**.

## WebUI smoke

1. Cache Reset / re-login as Admin.
2. Open **Skip Dates** → create/save header (or use empty header).
3. **Copy Dates From** → select source Skip Dates with date lines.
4. Confirm help warning about reviewing dates/years.
5. Confirm success message includes copy count; Dates tab populated.
6. Confirm source Dates unchanged; edit/delete a copied line on target.

## Safety

- Never change existing client `*_UU`.
- New `AbERP_Dates` rows only; source read-only.
- Resolve AD by UU/name.

## Packs

- Staging: `Downloads\AbilityERP-ClientUpdate-SAW015_skip_dates_copy_from-20260713\`
- Prod: `Downloads\AbilityERP-ProdUpdate-SAW015_skip_dates_copy_from-20260713\`

## External ticket text

`EXTERNAL-SUMMARY.md`
