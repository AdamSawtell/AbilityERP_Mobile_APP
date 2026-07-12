# SAW014 — Deploy to another build (agent)

**Ticket / slug:** `SAW014_support_location_contact_grid`  
**Kind:** idempiere · **JAR:** No

## Required host access

- SSH · `psql` · WebUI Admin · Cache Reset

## Agent one-liner

```bash
cd Tickets/SAW014_support_location_contact_grid/sql
psql -d idempiere -v ON_ERROR_STOP=1 \
  -f 00-preflight.sql \
  -f 01-fix-contact-columnsql.sql \
  -f 04-verify.sql
# Cache Reset (or log out/in)
```

Thin prod pack: `Downloads\AbilityERP-ProdUpdate-SAW014_support_location_contact_grid-20260713\` → `HOW-TO.txt`.

## Package

`Tickets/SAW014_support_location_contact_grid/sql/` — UU lookups only.

| Script | Purpose |
|--------|---------|
| `00-preflight.sql` | Fail closed if Support Location / column UUs missing |
| `01-fix-contact-columnsql.sql` | `@SQL=` → subquery ColumnSQL |
| `04-verify.sql` | Confirm no remaining `@SQL=` on targets |
| `99-rollback.sql` | Restore prior `@SQL=` definitions |

## AbilityERP Admin access

No new window/process. Existing **Support Location** window access unchanged. Smoke as **Admin** (HCO) or AbilityERP Admin.

## WebUI smoke

1. Cache Reset / re-login.
2. Open **Support Location** → Grid View (do not select a row first).
3. Confirm **Email**, **Phone**, **Phone 2** populated for rows that have contact on the linked BP Location.
4. Select several rows / next-prev — values stay correct.
5. Rows with empty contact on `C_BPartner_Location` show blank (expected).

## Safety

- Never change existing `*_UU` values on the client.
- Does not write to business tables — AD `AD_Column.ColumnSQL` only.

## Packs

- Staging: `AbilityERP-ClientUpdate-SAW014_support_location_contact_grid-20260713`
- Prod: `AbilityERP-ProdUpdate-SAW014_support_location_contact_grid-20260713`

## External ticket text

`EXTERNAL-SUMMARY.md`
