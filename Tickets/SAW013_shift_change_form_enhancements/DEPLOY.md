# SAW013 — Deploy to another build (agent)

**Ticket / slug:** `SAW013_shift_change_form_enhancements`  
**Kind:** idempiere · **JAR:** No · **Status:** staging green on HCO Test

## Required host access

- SSH · `psql` · WebUI Admin · Cache Reset

## Agent one-liner

```bash
cd idempiere-plugins/com.aberp.shiftchange.form
psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/00-preflight.sql \
  -f sql/01-virtual-status-and-submitted.sql \
  -f sql/02-prevent-dup-trigger.sql \
  -f sql/03-fix-columnsql-no-orderby.sql \
  -f sql/05-match-request-template-type.sql \
  -f sql/04-verify.sql
# Cache Reset or logout/in
```

Rollback: `sql/99-rollback.sql`

## Package

`idempiere-plugins/com.aberp.shiftchange.form/sql/` — UU/name lookups only. Never hardcode `AD_*_ID` across clients. Never overwrite existing HCO `*_UU` when matching by name.

`01-*.sql` embeds resolved `AD_Table_ID` into sync logic only via runtime lookup (not seed IDs in source). Physical column `aberp_requestsubmitted` is added with `ADD COLUMN IF NOT EXISTS`.

## AbilityERP Admin access

No new window/process. Existing **HCO Forms and Approvals** + **Create Request From Template** access unchanged. Confirm Admin / AbilityERP Admin still have window access.

## WebUI smoke

1. Cache Reset / re-login.
2. Open **HCO Forms and Approvals** — grid loads without “Timeout loading row 1”.
3. Record with Requests: **Status** matches Requests tab; **Request Submitted** = Yes; **Create Request From Template** hidden.
4. Record without request: Submitted = No; Create visible; after create + refresh, Submitted = Yes / Create gone.
5. **Create Request From Template** popup: **Request Template** defaults to (and lists only) the template matching the window **Request Type** (e.g. Additional Shift → only Additional Shift template).
6. Forced second insert blocked by trigger (clear exception).

## Safety

- Historical duplicate requests are **not** deleted.
- Sync trigger fires on R_Request insert/update/delete for AbERP_ShiftChange links only.

## Packs

- Staging: `AbilityERP-ClientUpdate-SAW013_shift_change_form_enhancements-20260713`
- Prod: `AbilityERP-ProdUpdate-SAW013_shift_change_form_enhancements-20260713`

## External ticket text

`EXTERNAL-SUMMARY.md`
