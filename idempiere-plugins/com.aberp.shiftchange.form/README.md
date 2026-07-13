# com.aberp.shiftchange.form

SAW013 — HCO Forms and Approvals (`AbERP_ShiftChange`) enhancements.

## Changes (SQL only — no JAR)

1. **Auto Status** — physical `R_Status_ID` kept read-only; synced from linked `R_Request` via DB trigger (virtual ColumnSQL timed out on 3.8k-row grid).
2. **Request Submitted** — physical Yes/No `AbERP_RequestSubmitted` on the main tab (synced by same trigger + one-time backfill).
3. **Create button** — DisplayLogic `@AbERP_RequestSubmitted@=N` hides **Create Request From Template** once submitted.
4. **Dup block** — BEFORE INSERT trigger rejects a second active `R_Request` for the same Shift Change.
5. **Template match** — Create Request popup lists/defaults only the Request Template whose type matches the window `R_RequestType_ID`.

## Link model

Child tab WhereClause:

`AD_Table_ID=@0|_TabInfo_AD_Table_ID@ AND record_id=@0|AbERP_ShiftChange_ID@`

## Install order

```bash
psql -d idempiere -v ON_ERROR_STOP=1 \
  -f sql/00-preflight.sql \
  -f sql/01-virtual-status-and-submitted.sql \
  -f sql/02-prevent-dup-trigger.sql \
  -f sql/03-fix-columnsql-no-orderby.sql \
  -f sql/05-match-request-template-type.sql \
  -f sql/04-verify.sql
```

Then Cache Reset / re-login.

See `Tickets/SAW013_shift_change_form_enhancements/DEPLOY.md`.
